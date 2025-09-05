#!/bin/bash

# =============================================================================
# 常用软件安装脚本
# 作者: saul
# 版本: 1.0
# 描述: 独立的常用软件包安装脚本，从主安装脚本中提取
# 支持平台: Ubuntu 20-24, Debian 10-12, x64/ARM64
# =============================================================================

set -euo pipefail

# =============================================================================
# 颜色定义（安全方式，避免重复定义）
# =============================================================================
# 使用非 readonly 变量以避免冲突
if [ -z "${RED:-}" ]; then
    RED=$(printf '\033[31m' 2>/dev/null || echo '')
    GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
    YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
    BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
    CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
    MAGENTA=$(printf '\033[35m' 2>/dev/null || echo '')
    GRAY=$(printf '\033[90m' 2>/dev/null || echo '')
    RESET=$(printf '\033[m' 2>/dev/null || echo '')
fi

# =============================================================================
# 日志函数
# =============================================================================
log_info() {
    echo -e "${CYAN}[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_debug() {
    echo -e "${BLUE}[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# =============================================================================
# 软件包安装辅助函数
# =============================================================================

# 显示旋转进度指示器
show_spinner() {
    local pid=$1
    local message=$2
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0

    echo -n "$message "
    while kill -0 $pid 2>/dev/null; do
        printf "\r$message ${CYAN}%c${RESET}" "${spinner_chars:$i:1}"
        i=$(( (i + 1) % ${#spinner_chars} ))
        sleep 0.1
    done
    printf "\r$message ${GREEN}✓${RESET}\n"
}

# 检查网络连接状态
check_network_status() {
    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        return 0  # 网络正常
    else
        return 1  # 网络异常
    fi
}

# 分析安装错误类型
analyze_install_error() {
    local package_name=$1
    local error_log=$2

    if grep -q "Unable to locate package" "$error_log"; then
        echo "软件包不存在或软件源未更新"
    elif grep -q "Could not get lock" "$error_log"; then
        echo "软件包管理器被其他进程占用"
    elif grep -q "Failed to fetch" "$error_log"; then
        echo "网络连接问题，无法下载软件包"
    elif grep -q "dpkg: error processing" "$error_log"; then
        echo "软件包配置错误或依赖问题"
    elif grep -q "Permission denied" "$error_log"; then
        echo "权限不足，需要管理员权限"
    else
        echo "未知错误"
    fi
}

# 显示安装进度的实时输出
install_package_with_progress() {
    local package_name=$1
    local package_desc=$2
    local current=$3
    local total=$4

    log_info "安装 ($current/$total): $package_desc ($package_name)"

    # 检查是否已安装
    if dpkg -l | grep -q "^ii  $package_name "; then
        echo -e "  ${GREEN}✓${RESET} $package_desc 已安装，跳过"
        return 0
    fi

    # 创建临时文件存储错误信息
    local error_log=$(mktemp)
    local install_log=$(mktemp)

    # 显示安装提示
    echo -e "  ${CYAN}↓${RESET} 正在下载 $package_desc..."
    echo -e "  ${YELLOW}ℹ${RESET} 提示：按 Ctrl+C 可取消安装"

    # 检查网络状态
    if ! check_network_status; then
        echo -e "  ${YELLOW}⚠${RESET} 网络连接较慢，请耐心等待..."
    fi

    # 执行安装并显示实时输出
    echo -e "  ${CYAN}📦${RESET} 开始安装 $package_desc..."

    # 使用 apt install 并显示进度（优化触发器处理）
    if timeout 300 sudo apt install -y --no-install-recommends "$package_name" 2>"$error_log" | while IFS= read -r line; do
        # 过滤并显示关键信息
        if [[ "$line" =~ "Reading package lists" ]]; then
            echo -e "  ${CYAN}📋${RESET} 读取软件包列表..."
        elif [[ "$line" =~ "Building dependency tree" ]]; then
            echo -e "  ${CYAN}🔗${RESET} 分析依赖关系..."
        elif [[ "$line" =~ "The following NEW packages will be installed" ]]; then
            echo -e "  ${CYAN}📦${RESET} 准备安装新软件包..."
        elif [[ "$line" =~ "Need to get" ]]; then
            local size=$(echo "$line" | grep -o '[0-9,.]* [kMG]B')
            echo -e "  ${CYAN}↓${RESET} 需要下载: $size"
        elif [[ "$line" =~ "Get:" ]]; then
            local url=$(echo "$line" | awk '{print $2}')
            echo -e "  ${CYAN}↓${RESET} 下载中: $(basename "$url")"
        elif [[ "$line" =~ "Unpacking" ]]; then
            echo -e "  ${CYAN}📂${RESET} 解包中..."
        elif [[ "$line" =~ "Setting up" ]]; then
            echo -e "  ${CYAN}⚙${RESET} 配置中..."
        elif [[ "$line" =~ "Processing triggers" ]]; then
            echo -e "  ${CYAN}🔄${RESET} 处理触发器..."
        fi
    done; then
        echo -e "  ${GREEN}✅${RESET} $package_desc 安装成功"
        rm -f "$error_log" "$install_log"
        return 0
    else
        local exit_code=$?
        echo -e "  ${RED}❌${RESET} $package_desc 安装失败"

        # 分析错误原因
        if [ -s "$error_log" ]; then
            local error_type=$(analyze_install_error "$package_name" "$error_log")
            echo -e "  ${RED}💡${RESET} 错误原因: $error_type"

            # 显示详细错误信息（前3行）
            echo -e "  ${YELLOW}📝${RESET} 详细错误:"
            head -3 "$error_log" | sed 's/^/    /'

            # 提供解决建议
            case "$error_type" in
                *"软件包不存在"*)
                    echo -e "  ${CYAN}💡${RESET} 建议: 运行 'sudo apt update' 更新软件源"
                    ;;
                *"网络连接问题"*)
                    echo -e "  ${CYAN}💡${RESET} 建议: 检查网络连接或稍后重试"
                    ;;
                *"被其他进程占用"*)
                    echo -e "  ${CYAN}💡${RESET} 建议: 等待其他安装进程完成或重启系统"
                    ;;
                *"权限不足"*)
                    echo -e "  ${CYAN}💡${RESET} 建议: 确保以管理员权限运行脚本"
                    ;;
            esac
        fi

        rm -f "$error_log" "$install_log"
        return 1
    fi
}

# =============================================================================
# 触发器优化函数
# =============================================================================

# 配置 APT 以优化触发器处理
configure_apt_for_speed() {
    log_info "配置 APT 以优化安装速度..."

    # 创建临时的 APT 配置文件
    local apt_config_file="/tmp/apt-speed-config"
    cat > "$apt_config_file" << 'EOF'
# 优化触发器处理
DPkg::Options {
    "--force-confdef";
    "--force-confold";
}

# 延迟触发器处理
DPkg::TriggersPending "true";
DPkg::ConfigurePending "true";

# 减少不必要的同步
DPkg::Post-Invoke {
    "if [ -d /var/lib/update-notifier ]; then touch /var/lib/update-notifier/dpkg-run-stamp; fi";
};

# 优化 man-db 触发器
DPkg::Pre-Install-Pkgs {
    "/bin/sh -c 'if [ \"$1\" = \"configure\" ] && [ -n \"$2\" ]; then /usr/bin/dpkg-trigger --no-await man-db 2>/dev/null || true; fi' sh";
};
EOF

    export APT_CONFIG="$apt_config_file"
    log_info "APT 优化配置已应用"
}

# 批量处理触发器
process_triggers_batch() {
    log_info "批量处理待处理的触发器..."

    # 检查是否有待处理的触发器
    if dpkg --audit 2>/dev/null | grep -q "triggers-awaited\|triggers-pending"; then
        echo -e "  ${CYAN}🔄${RESET} 处理待处理的触发器..."

        # 批量处理所有待处理的触发器
        if sudo dpkg --configure --pending >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅${RESET} 触发器处理完成"
        else
            echo -e "  ${YELLOW}⚠${RESET} 部分触发器处理失败，但不影响安装"
        fi
    else
        echo -e "  ${GREEN}✅${RESET} 无待处理的触发器"
    fi
}

# 清理 APT 配置
cleanup_apt_config() {
    if [ -n "${APT_CONFIG:-}" ] && [ -f "$APT_CONFIG" ]; then
        rm -f "$APT_CONFIG"
        unset APT_CONFIG
        log_debug "APT 优化配置已清理"
    fi
}

# =============================================================================
# 主要安装函数
# =============================================================================

# 安装常用软件（改进版，带详细进度显示和触发器优化）
install_common_software() {
    log_info "开始安装常用软件..."
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    # 配置 APT 优化
    configure_apt_for_speed

    # 定义常用软件包列表
    local common_packages=(
        "curl:网络请求工具"
        "wget:文件下载工具"
        "git:版本控制系统"
        "vim:文本编辑器"
        "htop:系统监控工具"
        "tree:目录树显示工具"
        "unzip:解压缩工具"
        "zip:压缩工具"
        "build-essential:编译工具链"
        "software-properties-common:软件源管理工具"
        "apt-transport-https:HTTPS传输支持"
        "ca-certificates:证书管理"
        "gnupg:加密工具"
        "lsb-release:系统信息工具"
    )

    local success_count=0
    local failed_count=0
    local skipped_count=0
    local total_count=${#common_packages[@]}
    local failed_packages=()

    # 显示安装概览
    echo -e "${BLUE}📦 软件包安装概览${RESET}"
    echo -e "  ${CYAN}总数量:${RESET} $total_count 个软件包"
    echo -e "  ${CYAN}预计时间:${RESET} 根据网络速度而定"
    echo -e "  ${YELLOW}提示:${RESET} 整个过程中可以按 Ctrl+C 取消安装"
    echo

    # 更新软件包列表（带进度显示）
    log_info "第一步：更新软件包列表"
    echo -e "  ${CYAN}🔄${RESET} 正在更新软件包列表，请稍候..."

    local update_error=$(mktemp)
    if timeout 60 sudo apt update 2>"$update_error" | while IFS= read -r line; do
        if [[ "$line" =~ "Hit:" ]]; then
            echo -e "  ${GREEN}✓${RESET} 检查: $(echo "$line" | awk '{print $2}')"
        elif [[ "$line" =~ "Get:" ]]; then
            echo -e "  ${CYAN}↓${RESET} 获取: $(echo "$line" | awk '{print $2}')"
        elif [[ "$line" =~ "Reading package lists" ]]; then
            echo -e "  ${CYAN}📋${RESET} 读取软件包列表..."
        fi
    done; then
        echo -e "  ${GREEN}✅${RESET} 软件包列表更新成功"
        rm -f "$update_error"
    else
        echo -e "  ${YELLOW}⚠${RESET} 软件包列表更新失败，但将继续安装"
        if [ -s "$update_error" ]; then
            echo -e "  ${YELLOW}📝${RESET} 错误信息:"
            head -2 "$update_error" | sed 's/^/    /'
        fi
        rm -f "$update_error"
    fi

    echo
    log_info "第二步：开始安装软件包"
    echo

    # 安装每个软件包
    local current_num=1
    for package_info in "${common_packages[@]}"; do
        IFS=':' read -r package_name package_desc <<< "$package_info"

        echo -e "${BLUE}━━━ 软件包 $current_num/$total_count ━━━${RESET}"

        if install_package_with_progress "$package_name" "$package_desc" "$current_num" "$total_count"; then
            success_count=$((success_count + 1))
        else
            failed_count=$((failed_count + 1))
            failed_packages+=("$package_name:$package_desc")
        fi

        echo
        current_num=$((current_num + 1))

        # 在每个软件包安装后稍作停顿，让用户看清进度
        sleep 0.2  # 减少等待时间以加速安装
    done

    # 批量处理触发器
    echo
    process_triggers_batch

    # 显示安装总结
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    log_info "第三步：安装总结"
    echo

    echo -e "${BLUE}📊 安装统计${RESET}"
    echo -e "  ${GREEN}✅ 成功安装:${RESET} $success_count 个"
    echo -e "  ${RED}❌ 安装失败:${RESET} $failed_count 个"
    echo -e "  ${YELLOW}⏭️  已跳过:${RESET} $skipped_count 个"
    echo -e "  ${CYAN}📦 总计:${RESET} $total_count 个"

    # 显示安装进度条
    local progress=$((success_count * 100 / total_count))
    local bar_length=50
    local filled_length=$((progress * bar_length / 100))
    local bar=""

    for ((i=0; i<filled_length; i++)); do
        bar+="█"
    done
    for ((i=filled_length; i<bar_length; i++)); do
        bar+="░"
    done

    echo -e "  ${CYAN}进度:${RESET} [$bar] $progress%"
    echo

    # 如果有失败的软件包，显示详细信息
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}❌ 安装失败的软件包:${RESET}"
        for failed_pkg in "${failed_packages[@]}"; do
            IFS=':' read -r pkg_name pkg_desc <<< "$failed_pkg"
            echo -e "  ${RED}•${RESET} $pkg_desc ($pkg_name)"
        done
        echo
        echo -e "${YELLOW}💡 建议:${RESET}"
        echo -e "  • 检查网络连接是否正常"
        echo -e "  • 运行 'sudo apt update' 更新软件源"
        echo -e "  • 稍后重新运行安装脚本"
        echo
    fi

    # 清理 APT 配置
    cleanup_apt_config

    # 返回结果
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}🎉 常用软件安装完成！所有 $total_count 个软件包都已成功安装。${RESET}"
        return 0
    elif [ $success_count -gt 0 ]; then
        echo -e "${YELLOW}⚠️  常用软件部分完成。成功安装 $success_count/$total_count 个软件包。${RESET}"
        return 1
    else
        echo -e "${RED}💥 常用软件安装失败。没有成功安装任何软件包。${RESET}"
        return 1
    fi
}

# =============================================================================
# 系统检查函数
# =============================================================================

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."

    # 检查操作系统
    if [ ! -f /etc/os-release ]; then
        log_error "无法检测操作系统版本"
        exit 1
    fi

    . /etc/os-release

    case "$ID" in
        ubuntu)
            case "$VERSION_ID" in
                "20.04"|"22.04"|"22.10"|"24.04")
                    log_info "检测到支持的Ubuntu版本: $VERSION_ID"
                    ;;
                *)
                    log_warn "检测到Ubuntu版本: $VERSION_ID，可能不完全兼容"
                    ;;
            esac
            ;;
        debian)
            case "$VERSION_ID" in
                "10"|"11"|"12")
                    log_info "检测到支持的Debian版本: $VERSION_ID"
                    ;;
                *)
                    log_warn "检测到Debian版本: $VERSION_ID，可能不完全兼容"
                    ;;
            esac
            ;;
        *)
            log_error "不支持的操作系统: $ID"
            log_error "本脚本仅支持Ubuntu 20-24和Debian 10-12"
            exit 1
            ;;
    esac

    # 检查架构
    local arch=$(uname -m)
    case "$arch" in
        x86_64|aarch64|armv7l)
            log_info "检测到支持的架构: $arch"
            ;;
        *)
            log_warn "检测到架构: $arch，可能不完全兼容"
            ;;
    esac

    log_info "系统要求检查通过"
}

# 显示脚本头部信息
show_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}常用软件安装脚本${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}邮箱: sau1amaranth@gmail.com${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将安装常用的开发工具和实用软件${RESET}"
    echo -e "${CYAN}支持Ubuntu 20-24和Debian 10-12，x64和ARM64架构${RESET}"
    echo
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    # 显示头部信息
    show_header

    # 检查系统要求
    check_system_requirements

    # 确认安装
    echo -e "是否继续安装常用软件？ [Y/n]: " | tr -d '\n'
    read choice
    choice=${choice:-y}
    case $choice in
        [Yy]|[Yy][Ee][Ss])
            log_info "用户确认继续安装"
            ;;
        *)
            log_info "用户取消安装"
            exit 0
            ;;
    esac

    # 开始安装
    install_common_software

    # 显示完成信息
    echo
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${GREEN}常用软件安装完成！${RESET}"
    echo -e "${GREEN}================================================================${RESET}"
    echo
}

# 检查是否被其他脚本调用
is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
