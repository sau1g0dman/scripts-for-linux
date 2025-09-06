#!/usr/bin/env python3

"""
磁盘格式化工具 - Python版本
作者: saul
版本: 1.0
描述: 安全的磁盘格式化工具，支持多种文件系统
"""

import os
import sys
import subprocess
import time
import re
from pathlib import Path

# 添加scripts目录到Python路径
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir.parent))

try:
    from common import *
except ImportError:
    print("错误：无法导入common模块")
    print("请确保common.py文件存在于scripts目录中")
    sys.exit(1)

# =============================================================================
# 权限和依赖检查
# =============================================================================

def check_root_permission():
    """检查root权限"""
    if os.getuid() != 0:
        log_error("请使用 sudo 运行此脚本（需 root 权限）")
        return False
    return True

def check_dependencies():
    """检查依赖工具"""
    required_tools = [
        "fdisk", "parted", "mkfs.ext4", "lsblk", 
        "awk", "grep", "sed", "partprobe", "udevadm", 
        "wipefs", "lsof"
    ]
    
    missing_tools = []
    for tool in required_tools:
        try:
            subprocess.run(['which', tool], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            missing_tools.append(tool)
    
    if missing_tools:
        log_info(f"检测到缺少以下工具：{' '.join(missing_tools)}")
        log_info("正在尝试自动安装...")
        try:
            execute_command("apt-get update", "更新包列表")
            execute_command("apt-get install -y util-linux parted e2fsprogs udev lsof", "安装依赖工具")
            log_info("工具安装完成")
            return True
        except Exception as e:
            log_error(f"工具安装失败: {e}")
            log_error("请手动安装后重试")
            return False
    
    log_info("依赖工具检查完成")
    return True

# =============================================================================
# 磁盘检测和管理
# =============================================================================

def get_system_disk():
    """获取系统盘设备名"""
    try:
        # 获取根分区
        result = subprocess.run(['df', '/'], capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split('\n')
        if len(lines) >= 2:
            system_partition = lines[1].split()[0]
            # 提取磁盘名（去掉分区号）
            system_disk = re.sub(r'[0-9]+$', '', system_partition)
            system_disk = os.path.basename(system_disk)
            log_info(f"检测到系统盘为：/dev/{system_disk}（已自动过滤）")
            return system_disk
    except Exception as e:
        log_error(f"获取系统盘信息失败: {e}")
    
    return None

def list_available_disks():
    """列出可用磁盘"""
    log_info("获取可用磁盘列表...")
    
    system_disk = get_system_disk()
    
    try:
        # 使用lsblk获取磁盘信息
        result = subprocess.run(['lsblk', '-d', '-o', 'NAME,SIZE,TYPE', '-n'], 
                              capture_output=True, text=True, check=True)
        
        available_disks = []
        for line in result.stdout.strip().split('\n'):
            if line.strip():
                parts = line.strip().split()
                if len(parts) >= 3 and parts[2] == 'disk':
                    disk_name = parts[0]
                    disk_size = parts[1]
                    
                    # 过滤系统盘
                    if disk_name != system_disk:
                        available_disks.append({
                            'name': disk_name,
                            'size': disk_size,
                            'device': f'/dev/{disk_name}'
                        })
        
        return available_disks
    except Exception as e:
        log_error(f"获取磁盘列表失败: {e}")
        return []

def show_disk_info(disk_device):
    """显示磁盘详细信息"""
    log_info(f"磁盘 {disk_device} 详细信息:")
    
    try:
        # 显示磁盘基本信息
        result = subprocess.run(['lsblk', '-f', disk_device], 
                              capture_output=True, text=True, check=True)
        print("磁盘分区信息:")
        print(result.stdout)
        
        # 显示磁盘使用情况
        result = subprocess.run(['df', '-h', disk_device], 
                              capture_output=True, text=True, check=False)
        if result.returncode == 0:
            print("磁盘使用情况:")
            print(result.stdout)
        
    except Exception as e:
        log_warn(f"获取磁盘信息失败: {e}")

def check_disk_usage(disk_device):
    """检查磁盘是否正在使用"""
    log_info(f"检查磁盘 {disk_device} 使用状态...")
    
    try:
        # 检查是否有进程正在使用该磁盘
        result = subprocess.run(['lsof', disk_device], 
                              capture_output=True, text=True, check=False)
        if result.returncode == 0 and result.stdout.strip():
            log_warn(f"磁盘 {disk_device} 正在被以下进程使用:")
            print(result.stdout)
            return True
        
        # 检查是否已挂载
        result = subprocess.run(['mount'], capture_output=True, text=True, check=True)
        if disk_device in result.stdout:
            log_warn(f"磁盘 {disk_device} 或其分区已被挂载")
            return True
        
        return False
    except Exception as e:
        log_warn(f"检查磁盘使用状态失败: {e}")
        return False

# =============================================================================
# 磁盘格式化功能
# =============================================================================

def unmount_disk(disk_device):
    """卸载磁盘所有分区"""
    log_info(f"卸载磁盘 {disk_device} 的所有分区...")
    
    try:
        # 获取所有分区
        result = subprocess.run(['lsblk', '-ln', '-o', 'NAME', disk_device], 
                              capture_output=True, text=True, check=True)
        
        partitions = []
        for line in result.stdout.strip().split('\n'):
            if line.strip():
                partition = line.strip()
                if partition != os.path.basename(disk_device):
                    partitions.append(f'/dev/{partition}')
        
        # 卸载所有分区
        for partition in partitions:
            try:
                subprocess.run(['umount', partition], 
                              capture_output=True, check=True)
                log_info(f"已卸载分区: {partition}")
            except subprocess.CalledProcessError:
                # 分区可能未挂载，忽略错误
                pass
        
        return True
    except Exception as e:
        log_error(f"卸载磁盘分区失败: {e}")
        return False

def wipe_disk(disk_device):
    """清除磁盘签名"""
    log_info(f"清除磁盘 {disk_device} 的文件系统签名...")
    
    try:
        # 使用wipefs清除所有签名
        execute_command(f"wipefs -a {disk_device}", "清除磁盘签名")
        
        # 刷新分区表
        execute_command(f"partprobe {disk_device}", "刷新分区表")
        execute_command("udevadm settle", "等待设备稳定")
        
        return True
    except Exception as e:
        log_error(f"清除磁盘签名失败: {e}")
        return False

def create_partition_table(disk_device, table_type="gpt"):
    """创建分区表"""
    log_info(f"在磁盘 {disk_device} 上创建 {table_type} 分区表...")
    
    try:
        # 使用parted创建分区表
        cmd = f"parted -s {disk_device} mklabel {table_type}"
        execute_command(cmd, f"创建{table_type}分区表")
        
        return True
    except Exception as e:
        log_error(f"创建分区表失败: {e}")
        return False

def create_partition(disk_device, start="0%", end="100%"):
    """创建分区"""
    log_info(f"在磁盘 {disk_device} 上创建分区...")
    
    try:
        # 创建主分区
        cmd = f"parted -s {disk_device} mkpart primary {start} {end}"
        execute_command(cmd, "创建分区")
        
        # 刷新分区表
        execute_command(f"partprobe {disk_device}", "刷新分区表")
        execute_command("udevadm settle", "等待设备稳定")
        
        # 等待分区设备出现
        time.sleep(2)
        
        return f"{disk_device}1"  # 返回第一个分区
    except Exception as e:
        log_error(f"创建分区失败: {e}")
        return None

def format_partition(partition_device, filesystem="ext4", label=None):
    """格式化分区"""
    log_info(f"格式化分区 {partition_device} 为 {filesystem} 文件系统...")
    
    try:
        if filesystem == "ext4":
            cmd = f"mkfs.ext4 -F {partition_device}"
            if label:
                cmd += f" -L {label}"
        elif filesystem == "ext3":
            cmd = f"mkfs.ext3 -F {partition_device}"
            if label:
                cmd += f" -L {label}"
        elif filesystem == "xfs":
            cmd = f"mkfs.xfs -f {partition_device}"
            if label:
                cmd += f" -L {label}"
        elif filesystem == "ntfs":
            cmd = f"mkfs.ntfs -f {partition_device}"
            if label:
                cmd += f" -L {label}"
        else:
            log_error(f"不支持的文件系统: {filesystem}")
            return False
        
        execute_command(cmd, f"格式化为{filesystem}")
        return True
    except Exception as e:
        log_error(f"格式化分区失败: {e}")
        return False

def select_filesystem():
    """选择文件系统"""
    filesystems = {
        "1": "ext4",
        "2": "ext3", 
        "3": "xfs",
        "4": "ntfs"
    }
    
    print("\n请选择文件系统:")
    print("1. ext4 (推荐，Linux默认)")
    print("2. ext3 (兼容性好)")
    print("3. xfs (高性能)")
    print("4. ntfs (Windows兼容)")
    
    while True:
        choice = input("请选择文件系统 (1-4): ").strip()
        if choice in filesystems:
            return filesystems[choice]
        else:
            log_warn("请输入有效的选择 (1-4)")

def main():
    """主函数"""
    try:
        # 检查root权限
        if not check_root_permission():
            sys.exit(1)
        
        # 检查依赖
        if not check_dependencies():
            sys.exit(1)
        
        # 显示脚本信息
        show_header("磁盘格式化工具", "1.0", "安全的磁盘格式化工具")
        
        # 获取可用磁盘
        available_disks = list_available_disks()
        if not available_disks:
            log_error("未找到可用的磁盘")
            sys.exit(1)
        
        print("\n" + "="*50)
        print("可用磁盘列表")
        print("="*50)
        
        for i, disk in enumerate(available_disks, 1):
            print(f"{i}. {disk['device']} ({disk['size']})")
        
        # 选择磁盘
        while True:
            try:
                choice = input(f"\n请选择要格式化的磁盘 (1-{len(available_disks)}): ").strip()
                choice_num = int(choice)
                if 1 <= choice_num <= len(available_disks):
                    selected_disk = available_disks[choice_num - 1]
                    break
                else:
                    log_warn(f"请输入有效的选择 (1-{len(available_disks)})")
            except ValueError:
                log_warn("请输入有效的数字")
        
        disk_device = selected_disk['device']
        log_info(f"已选择磁盘: {disk_device}")
        
        # 显示磁盘信息
        show_disk_info(disk_device)
        
        # 检查磁盘使用状态
        if check_disk_usage(disk_device):
            if not interactive_ask_confirmation("磁盘正在使用中，是否强制继续？", False):
                log_info("用户取消操作")
                return
        
        # 最终确认
        print(f"\n{COLOR_RED}警告：此操作将完全清除磁盘 {disk_device} 上的所有数据！{COLOR_RESET}")
        if not interactive_ask_confirmation("确定要继续吗？", False):
            log_info("用户取消操作")
            return
        
        # 选择文件系统
        filesystem = select_filesystem()
        
        # 输入卷标
        label = input("请输入卷标（可选，直接回车跳过）: ").strip() or None
        
        # 开始格式化流程
        log_info("开始磁盘格式化流程...")
        
        # 1. 卸载磁盘
        if not unmount_disk(disk_device):
            log_error("卸载磁盘失败")
            sys.exit(1)
        
        # 2. 清除磁盘签名
        if not wipe_disk(disk_device):
            log_error("清除磁盘签名失败")
            sys.exit(1)
        
        # 3. 创建分区表
        if not create_partition_table(disk_device):
            log_error("创建分区表失败")
            sys.exit(1)
        
        # 4. 创建分区
        partition_device = create_partition(disk_device)
        if not partition_device:
            log_error("创建分区失败")
            sys.exit(1)
        
        # 5. 格式化分区
        if not format_partition(partition_device, filesystem, label):
            log_error("格式化分区失败")
            sys.exit(1)
        
        log_info("磁盘格式化完成！")
        log_info(f"磁盘: {disk_device}")
        log_info(f"分区: {partition_device}")
        log_info(f"文件系统: {filesystem}")
        if label:
            log_info(f"卷标: {label}")
        
        # 显示最终结果
        show_disk_info(disk_device)
        
    except KeyboardInterrupt:
        log_info("\n用户中断操作")
        sys.exit(1)
    except Exception as e:
        log_error(f"程序执行过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
