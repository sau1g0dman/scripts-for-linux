#!/bin/bash

# =============================================================================
# 通用工具函数库
# 作者: saul
# 版本: 1.0
# 描述: 为Ubuntu 20-22服务器初始化脚本提供通用功能
# 支持平台: x64, ARM64
# =============================================================================

# 检查Bash版本
if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用Bash运行此脚本（当前shell: $0）"
    exit 1
fi

# =============================================================================
# 颜色定义
# =============================================================================
readonly RED=$(printf '\033[31m' 2>/dev/null || echo '')
readonly GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
readonly YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
readonly BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
readonly CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
readonly MAGENTA=$(printf '\033[35m' 2>/dev/null || echo '')
readonly RESET=$(printf '\033[m' 2>/dev/null || echo '')

# =============================================================================
# 日志函数
# =============================================================================

# 日志级别
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

# 当前日志级别（默认INFO）
LOG_LEVEL=${LOG_LEVEL:-$LOG_INFO}

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        $LOG_DEBUG)
            [ $LOG_LEVEL -le $LOG_DEBUG ] && echo -e "${CYAN}[DEBUG]${RESET} ${timestamp} $message" >&2
            ;;
        $LOG_INFO)
            [ $LOG_LEVEL -le $LOG_INFO ] && echo -e "${GREEN}[INFO]${RESET} ${timestamp} $message"
            ;;
        $LOG_WARN)
            [ $LOG_LEVEL -le $LOG_WARN ] && echo -e "${YELLOW}[WARN]${RESET} ${timestamp} $message" >&2
            ;;
        $LOG_ERROR)
            [ $LOG_LEVEL -le $LOG_ERROR ] && echo -e "${RED}[ERROR]${RESET} ${timestamp} $message" >&2
            ;;
    esac
}

# 便捷日志函数
log_debug() { log $LOG_DEBUG "$1"; }
log_info() { log $LOG_INFO "$1"; }
log_warn() { log $LOG_WARN "$1"; }
log_error() { log $LOG_ERROR "$1"; }

# =============================================================================
# 系统检测函数
# =============================================================================

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS=CentOS
        VER=$(cat /etc/redhat-release)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    log_debug "检测到操作系统: $OS $VER"
}

# 检测CPU架构
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="x64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            log_warn "未知的CPU架构: $ARCH"
            ;;
    esac

    log_debug "检测到CPU架构: $ARCH"
}

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
        log_debug "当前用户为root"
    else
        SUDO="sudo"
        log_debug "当前用户非root，将使用sudo"
    fi
}

# =============================================================================
# 网络检测函数
# =============================================================================

# 检查网络连接
check_network() {
    local test_urls=(
        "https://www.baidu.com"
        "https://www.google.com"
        "https://github.com"
    )

    log_info "检查网络连接..."

    for url in "${test_urls[@]}"; do
        if curl -fsSL --connect-timeout 5 --max-time 10 "$url" >/dev/null 2>&1; then
            log_info "网络连接正常 ($url)"
            return 0
        fi
    done

    log_error "网络连接失败，请检查网络设置"
    return 1
}

# 检查DNS解析
check_dns() {
    local test_domain="www.baidu.com"

    if nslookup "$test_domain" >/dev/null 2>&1; then
        log_info "DNS解析正常"
        return 0
    else
        log_error "DNS解析失败"
        return 1
    fi
}

# =============================================================================
# 包管理器函数
# =============================================================================

# 更新包管理器
update_package_manager() {
    log_info "更新包管理器..."

    if command -v apt >/dev/null 2>&1; then
        $SUDO apt update
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum update -y
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf update -y
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -Sy
    else
        log_error "未找到支持的包管理器"
        return 1
    fi
}

# 安装包
install_package() {
    local package=$1

    log_info "安装软件包: $package"

    if command -v apt >/dev/null 2>&1; then
        $SUDO apt install -y "$package"
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y "$package"
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y "$package"
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -S --noconfirm "$package"
    else
        log_error "未找到支持的包管理器"
        return 1
    fi
}

# =============================================================================
# 错误处理函数
# =============================================================================

# 错误处理
handle_error() {
    local exit_code=$?
    local line_number=$1

    log_error "脚本在第 $line_number 行发生错误，退出码: $exit_code"
    exit $exit_code
}

# 设置错误处理
set_error_handling() {
    set -eE  # 遇到错误立即退出，包括管道中的错误
    trap 'handle_error $LINENO' ERR
}

# =============================================================================
# 用户交互函数
# =============================================================================

# 询问用户确认
ask_confirmation() {
    local message=$1
    local default=${2:-"n"}

    while true; do
        if [ "$default" = "y" ]; then
            read -p "$message [Y/n]: " choice
            choice=${choice:-y}
        else
            read -p "$message [y/N]: " choice
            choice=${choice:-n}
        fi

        case $choice in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo "请输入 y 或 n"
                ;;
        esac
    done
}

# =============================================================================
# 初始化函数
# =============================================================================

# 初始化环境
init_environment() {
    # 设置错误处理
    set_error_handling

    # 检测系统信息
    detect_os
    detect_arch
    check_root

    log_info "环境初始化完成"
    log_info "操作系统: $OS $VER"
    log_info "CPU架构: $ARCH"
    log_info "权限模式: $([ -z "$SUDO" ] && echo "root" || echo "sudo")"
}

# =============================================================================
# 脚本信息显示
# =============================================================================

# 显示脚本头部信息
show_header() {
    local script_name=$1
    local script_version=${2:-"1.0"}
    local script_description=$3

    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}🚀 $script_name${RESET}"
    echo -e "${BLUE}版本: $script_version${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}邮箱: sau1@maranth@gmail.com${RESET}"
    if [ -n "$script_description" ]; then
        echo -e "${BLUE}描述: $script_description${RESET}"
    fi
    echo -e "${BLUE}================================================================${RESET}"
}

# 显示脚本尾部信息
show_footer() {
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${GREEN}✅ 脚本执行完成${RESET}"
    echo -e "${GREEN}================================================================${RESET}"
}
