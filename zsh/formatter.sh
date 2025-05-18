#!/usr/bin/env bash
set -euo pipefail

# ==============================================
# 1. 权限检查（必须以 root 运行）
# ==============================================
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用 sudo 运行此脚本（需 root 权限）"
    exit 1
fi

# ==============================================
# 2. 依赖检查（安装必要工具）
# ==============================================
required_tools=("fdisk" "parted" "mkfs.ext4" "lsblk" "awk" "grep" "sed" "partprobe" "udevadm" "wipefs" "lsof")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo "检测到缺少以下工具：${missing_tools[*]}"
    echo "正在尝试自动安装..."
    apt-get update && apt-get install -y util-linux parted e2fsprogs udev lsof
    if [ $? -ne 0 ]; then
        echo "错误：工具安装失败，请手动安装后重试"
        exit 1
    fi
fi

# ==============================================
# 3. 获取系统盘设备名（正确识别物理磁盘）
# ==============================================
system_partition=$(df / | awk 'NR==2 {print $1}')
system_disk=$(echo "$system_partition" | sed 's/[0-9]*$//' | xargs basename)
echo "检测到系统盘为：/dev/$system_disk（已自动过滤）"

# ==============================================
# 4. 列出可用磁盘（排除系统盘和虚拟设备）
# ==============================================
echo -e "\n==================== 可用磁盘列表 ===================="
disk_list=($(
    lsblk -d -o NAME,SIZE,TYPE -n | 
    grep ' disk$' | 
    grep -v "^$system_disk" | 
    awk '{print $1}'
))

lsblk -d -o NAME,SIZE,TYPE -n | 
grep ' disk$' | 
grep -v "^$system_disk" | 
awk '{print NR")", $0}'

if [ ${#disk_list[@]} -eq 0 ]; then
    echo "错误：无可用磁盘（已过滤系统盘和虚拟设备）"
    exit 1
fi
echo "注：以上为可格式化的外部存储设备，系统盘已自动过滤"

# ==============================================
# 5. 用户选择目标磁盘（带输入验证）
# ==============================================
read -p $'\n请输入要格式化的磁盘序号（如 1）: ' disk_idx

if ! [[ "$disk_idx" =~ ^[0-9]+$ ]]; then
    echo "错误：输入必须为数字"
    exit 1
fi

disk_count=${#disk_list[@]}
if [ "$disk_idx" -lt 1 ] || [ "$disk_idx" -gt "$disk_count" ]; then
    echo "错误：输入序号超出范围（有效范围：1-$disk_count）"
    exit 1
fi

target_disk="/dev/${disk_list[$((disk_idx-1))]}"

if ! lsblk "$target_disk" &> /dev/null; then
    echo "错误：磁盘 $target_disk 不存在（可能已被移除）"
    exit 1
fi

# ==============================================
# 6. 数据丢失确认（强提示）
# ==============================================
disk_size=$(lsblk -d -o SIZE "$target_disk" | tail -n 1)
echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "警告：即将格式化磁盘 $target_disk（容量 $disk_size）"
echo "此操作将删除该磁盘的所有分区和数据！！！"
read -p "请确认是否继续？（输入 YES 继续，其他退出）: " confirm
if [ "$confirm" != "YES" ]; then
    echo "已取消格式化操作"
    exit 1
fi

# ==============================================
# 7. 卸载所有关联分区（明确提示流程）
# ==============================================
echo -e "\n===== 步骤 7/9：卸载分区 ====="
echo "正在卸载磁盘 $target_disk 的所有分区..."

unmount_partitions() {
    local target_disk="$1"
    local umount_log=$(mktemp)

    echo "尝试正常卸载（umount -A）..."
    umount -A "$target_disk"* &> "$umount_log" || true

    local mounted=$(mount | grep "$target_disk" | awk '{print $1}')
    if [ -n "$mounted" ]; then
        echo "警告：以下分区仍未卸载：$mounted"
        echo "尝试强制卸载（umount -lf）..."
        umount -lf "$mounted" &> "$umount_log" || true
    fi

    echo "卸载结果：$(grep -v 'not mounted' "$umount_log" || echo "无需要卸载的分区")"
    rm "$umount_log"
}

unmount_partitions "$target_disk"
echo "√ 分区卸载完成（无需要卸载的分区或已成功卸载）"

# ==============================================
# 8. 清除旧文件系统签名
# ==============================================
echo -e "\n===== 步骤 8/9：清除旧文件系统签名 ====="
echo "正在清除 $target_disk 的旧文件系统签名..."
wipefs -a "$target_disk" 2>&1 | tee wipefs.log
echo "√ 旧文件系统签名清除完成"

# ==============================================
# 9. 快速格式化（明确变量作用域）
# ==============================================
echo -e "\n===== 步骤 9/9：格式化磁盘 ====="
echo "正在格式化 $target_disk ..."
format_log=$(mktemp)
new_partition="${target_disk}p1"  # 在子shell外定义变量（关键修复）

{
    echo -e "g\nn\n1\n\n\nw" | fdisk "$target_disk" 2>&1
    
    partprobe "$target_disk" 2>&1
    udevadm trigger 2>&1
    
    echo "等待内核更新分区表（10秒）..."
    for i in {1..10}; do
        echo -n "$i "
        sleep 1
    done
    echo "√ 内核分区表更新完成"
    
    # 检查新分区是否存在（增强错误处理）
    if ! lsblk "$new_partition" &> /dev/null; then
        echo "错误：新分区 $new_partition 未创建成功"
        exit 1
    fi
    
    # 检查挂载状态（使用全局变量）
    is_mounted=$(mount | grep -q "$new_partition" && echo "已挂载" || echo "未挂载")
    echo "新分区挂载状态：$is_mounted"
    
    if [ "$is_mounted" = "已挂载" ]; then
        echo "警告：新分区 $new_partition 被自动挂载，尝试强制卸载..."
        umount -lf "$new_partition" 2>&1 || {
            echo "错误：无法卸载自动挂载的分区 $new_partition"
            exit 1
        }
        echo "√ 新分区强制卸载完成"
    fi
    
    # 再次验证卸载状态（使用全局变量）
    if mount | grep -q "$new_partition"; then
        echo "错误：新分区 $new_partition 仍未卸载，无法格式化"
        exit 1
    fi
    
    # 格式化新分区（使用全局变量）
    echo "===== 开始格式化 $new_partition ====="
    mkfs.ext4 -F -O ^has_journal "$new_partition" 2>&1
} | tee "$format_log"

echo "√ 磁盘格式化完成"

# ==============================================
# 10. 挂载验证并提示完成（使用全局变量）
# ==============================================
echo -e "\n===== 步骤 10/10：挂载验证 ====="
mount_point="/mnt/${disk_list[$((disk_idx-1))]}_ext4"
mkdir -p "$mount_point"

# 验证 new_partition 变量是否存在（增强鲁棒性）
if [ -z "$new_partition" ] || ! lsblk "$new_partition" &> /dev/null; then
    echo "错误：新分区未正确创建，无法挂载"
    exit 1
fi

mount "$new_partition" "$mount_point" 2>&1 | tee mount.log
echo "√ 分区挂载完成"

echo -e "\n==================== 格式化完成 ===================="
echo "目标磁盘：$target_disk"
echo "新分区：$new_partition"
echo "挂载路径：$mount_point"
echo "文件系统：ext4（已禁用日志，速度更快）"
echo "验证命令：df -hT $mount_point"
echo "完整调试日志：$format_log"
