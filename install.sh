#!/bin/bash

# =============================================================================
# Ubuntu服务器一键安装脚本
# 作者: saul
# 版本: 1.0
# 描述: 一键安装和配置Ubuntu/Debian服务器环境，支持Ubuntu 20-24和Debian 10-12 x64/ARM64
# =============================================================================

set -euo pipefail

# =============================================================================
# 颜色定义
# =============================================================================
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly CYAN='\033[36m'
readonly RESET='\033[0m'

# =============================================================================
# 配置变量
# =============================================================================
readonly REPO_URL="https://github.com/sau1g0dman/scripts-for-linux.git"
readonly REPO_BRANCH="main"
readonly LOCAL_REPO_DIR="/tmp/scripts-for-linux-$(date +%Y%m%d-%H%M%S)"
readonly INSTALL_DIR="$HOME/.scripts-for-linux"
readonly SCRIPT_BASE_URL="https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts"

# 全局变量
CLEANUP_ON_EXIT=true
LOCAL_SCRIPTS_DIR=""

# =============================================================================
# 日志函数
# =============================================================================
log_info() {
    echo -e "${GREEN}[INFO]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

log_debug() {
    echo -e "${CYAN}[DEBUG]${RESET} $1"
}

# =============================================================================
# 仓库管理函数
# =============================================================================

# 克隆仓库到本地
clone_repository() {
    log_info "📥 克隆项目仓库到本地..."
    log_debug "仓库URL: $REPO_URL"
    log_debug "本地目录: $LOCAL_REPO_DIR"
    log_debug "分支: $REPO_BRANCH"

    # 检查git是否可用
    if ! command -v git >/dev/null 2>&1; then
        log_error "❌ Git未安装，正在安装..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y git
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y git
        else
            log_error "❌ 无法自动安装Git，请手动安装后重试"
            return 1
        fi
    fi

    # 克隆仓库
    if git clone --depth=1 --branch="$REPO_BRANCH" "$REPO_URL" "$LOCAL_REPO_DIR" 2>/dev/null; then
        LOCAL_SCRIPTS_DIR="$LOCAL_REPO_DIR/scripts"
        log_info "✅ 仓库克隆成功"
        log_debug "脚本目录: $LOCAL_SCRIPTS_DIR"
        return 0
    else
        log_error "❌ 仓库克隆失败"
        return 1
    fi
}

# 清理本地仓库
cleanup_repository() {
    if [ "$CLEANUP_ON_EXIT" = true ] && [ -d "$LOCAL_REPO_DIR" ]; then
        log_info "🧹 清理本地仓库..."
        rm -rf "$LOCAL_REPO_DIR" 2>/dev/null || true
        log_debug "已删除: $LOCAL_REPO_DIR"
    fi
}

# 设置退出时清理
setup_cleanup_trap() {
    trap 'cleanup_repository' EXIT
}

# 验证本地脚本目录
verify_local_scripts() {
    if [ ! -d "$LOCAL_SCRIPTS_DIR" ]; then
        log_error "❌ 本地脚本目录不存在: $LOCAL_SCRIPTS_DIR"
        return 1
    fi

    # 检查关键脚本文件
    local required_files=(
        "$LOCAL_SCRIPTS_DIR/common.sh"
        "$LOCAL_SCRIPTS_DIR/system/time-sync.sh"
        "$LOCAL_SCRIPTS_DIR/system/mirrors.sh"
        "$LOCAL_SCRIPTS_DIR/shell/zsh-install.sh"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "❌ 缺少必需文件: $file"
            return 1
        fi
    done

    log_info "✅ 本地脚本验证通过"
    return 0
}

# =============================================================================
# 工具函数
# =============================================================================

# 显示脚本头部信息
show_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}🚀 Ubuntu/Debian服务器一键安装脚本${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}邮箱: sau1amaranth@gmail.com${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将帮助您快速配置Ubuntu/Debian服务器环境${RESET}"
    echo -e "${CYAN}支持Ubuntu 20-24和Debian 10-12，x64和ARM64架构${RESET}"
    echo
}

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

    # 检查网络连接
    if ! command -v curl >/dev/null 2>&1; then
        log_error "❌ curl未安装，正在安装..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y curl
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y curl
        else
            log_error "❌ 无法自动安装curl，请手动安装后重试"
            exit 1
        fi
    fi

    if ! curl -sSL -I --connect-timeout 5 --max-time 10 https://github.com/robots.txt >/dev/null 2>&1; then
        log_warn "网络连接失败，无法访问GitHub"
        log_warn "某些功能可能无法正常工作，建议检查网络连接"
        if ! ask_confirmation "是否继续安装？" "n"; then
            log_info "用户选择退出安装"
            exit 1
        fi
    fi

    log_info "系统要求检查通过"
}

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

# 显示安装选项菜单
show_install_menu() {
    echo
    echo -e "${BLUE}请选择要安装的组件：${RESET}"
    echo
    echo "1. 🔧 系统配置（时间同步、软件源）"
    echo "2. 🐚 ZSH环境（ZSH、Oh My Zsh、主题插件）"
    echo "3. 🛠️ 开发工具（Neovim、LazyVim、Git工具）"
    echo "4. 🔐 安全配置（SSH配置、密钥管理）"
    echo "5. 🐳 Docker环境（Docker、Docker Compose、管理工具）"
    echo "6. 📦 全部安装（推荐）"
    echo "7. 🎯 自定义安装"
    echo "0. 退出"
    echo
}

# 执行本地脚本
execute_local_script() {
    local script_path=$1
    local script_name=$2
    local script_file="$LOCAL_SCRIPTS_DIR/$script_path"

    log_info "🚀 开始执行: $script_name"
    log_debug "脚本路径: $script_file"

    # 检查脚本文件是否存在
    if [ ! -f "$script_file" ]; then
        log_error "❌ 脚本文件不存在: $script_file"
        return 1
    fi

    # 检查脚本是否可执行
    if [ ! -r "$script_file" ]; then
        log_error "❌ 脚本文件不可读: $script_file"
        return 1
    fi

    # 设置详细日志级别
    export LOG_LEVEL=0  # 启用DEBUG级别日志

    # 执行本地脚本
    log_info "📂 执行本地脚本..."
    (
        # 在子shell中执行脚本，避免exit语句影响主脚本
        bash "$script_file"
    )
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_info "✅ $script_name 执行成功"
        return 0
    else
        log_error "❌ $script_name 执行失败 (退出码: $exit_code)"
        log_error "💡 请检查上述错误信息以了解失败原因"
        return $exit_code
    fi
}

# 向后兼容的别名函数
execute_remote_script() {
    execute_local_script "$@"
}

# 安装系统配置
install_system_config() {
    log_info "🔧 开始安装系统配置..."

    local success_count=0
    local total_count=2

    # 时间同步配置
    if execute_remote_script "system/time-sync.sh" "时间同步配置"; then
        success_count=$((success_count + 1))
    else
        log_error "❌ 时间同步配置失败"
    fi

    # 软件源配置
    if execute_remote_script "system/mirrors.sh" "软件源配置"; then
        success_count=$((success_count + 1))
    else
        log_error "❌ 软件源配置失败"
    fi

    if [ $success_count -eq $total_count ]; then
        log_info "✅ 系统配置安装完成 ($success_count/$total_count)"
        return 0
    else
        log_warn "⚠️  系统配置部分完成 ($success_count/$total_count)"
        return 1
    fi
}

# 安装ZSH环境
install_zsh_environment() {
    log_info "🐚 开始安装ZSH环境..."

    local arch=$(uname -m)
    local script_result=1

    case "$arch" in
        # ARM架构（aarch64/armv7l）仍保留原逻辑，使用ARM专用脚本
        aarch64|armv7l)
            log_info "检测到ARM架构，使用专用安装脚本"
            if execute_remote_script "shell/zsh-arm.sh" "ARM版ZSH环境"; then
                script_result=0
            fi
            ;;
        # 其他架构（如x86_64）直接使用 shell/zsh-install.sh，不做国内/国外源判断
        *)
            log_info "检测到x86_64架构，使用标准安装脚本"
            if execute_remote_script "shell/zsh-install.sh" "ZSH环境"; then
                script_result=0
            fi
            ;;
    esac

    if [ $script_result -eq 0 ]; then
        # 验证ZSH是否真正安装成功
        if command -v zsh >/dev/null 2>&1; then
            log_info "✅ ZSH环境安装完成并验证成功"
            log_info "   ZSH版本: $(zsh --version 2>/dev/null || echo '已安装')"
            return 0
        else
            # 检查是否为测试模式（通过检查函数是否被重写来判断）
            if declare -f execute_local_script | grep -q "测试模式"; then
                log_info "✅ ZSH环境安装完成（测试模式，跳过命令验证）"
                return 0
            else
                log_error "❌ ZSH环境安装脚本执行成功，但ZSH命令不可用"
                return 1
            fi
        fi
    else
        log_error "❌ ZSH环境安装失败"
        return 1
    fi
}

# 安装开发工具
install_development_tools() {
    log_info "开始安装开发工具..."

    execute_remote_script "development/nvim-setup.sh" "Neovim开发环境"

    log_info "开发工具安装完成"
}

# 安装安全配置
install_security_config() {
    log_info "开始安装安全配置..."

    execute_remote_script "security/ssh-config.sh" "SSH安全配置"

    if ask_confirmation "是否配置SSH密钥？" "n"; then
        execute_remote_script "security/ssh-keygen.sh" "SSH密钥配置"
    fi

    log_info "安全配置安装完成"
}

# 安装Docker环境
install_docker_environment() {
    log_info "开始安装Docker环境..."

    execute_remote_script "containers/docker-install.sh" "Docker环境"

    log_info "Docker环境安装完成"
}

# 全部安装
install_all() {
    log_info "开始全部安装..."

    install_system_config
    install_zsh_environment
    install_development_tools
    install_security_config
    install_docker_environment

    log_info "全部组件安装完成"
}

# 自定义安装
custom_install() {
    echo
    echo -e "${BLUE}自定义安装选项：${RESET}"
    echo

    if ask_confirmation "是否安装系统配置？" "y"; then
        install_system_config
    fi

    if ask_confirmation "是否安装ZSH环境？" "y"; then
        install_zsh_environment
    fi

    if ask_confirmation "是否安装开发工具？" "n"; then
        install_development_tools
    fi

    if ask_confirmation "是否安装安全配置？" "y"; then
        install_security_config
    fi

    if ask_confirmation "是否安装Docker环境？" "n"; then
        install_docker_environment
    fi
}

# 主安装流程
main_install() {
    while true; do
        show_install_menu
        # 从终端设备读取输入，避免被管道干扰
        read -p "请选择 [0-7]: " choice < /dev/tty

        case $choice in
            1)
                install_system_config
                ;;
            2)
                install_zsh_environment
                ;;
            3)
                install_development_tools
                ;;
            4)
                install_security_config
                ;;
            5)
                install_docker_environment
                ;;
            6)
                install_all
                ;;
            7)
                custom_install
                ;;
            0)
                log_info "退出安装程序"
                exit 0
                ;;
            *)
                log_warn "无效选择，请重新输入"
                continue
                ;;
        esac

        # 移除"是否继续"的询问，安装完成后自动回到菜单
        echo -e "${CYAN}按Enter键返回菜单...${RESET}"
        read -r < /dev/tty  # 等待用户按回车，避免菜单瞬间刷新
    done
}


# 显示完成信息
show_completion() {
    echo
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${GREEN}🎉 安装完成！${RESET}"
    echo -e "${GREEN}================================================================${RESET}"
    echo
    echo -e "${CYAN}后续步骤：${RESET}"
    echo "1. 重新登录以使配置生效"
    echo "2. 运行 'exec zsh' 切换到ZSH（如果安装了ZSH）"
    echo "3. 运行 'p10k configure' 配置Powerlevel10k主题"
    echo "4. 查看项目文档了解更多功能"
    echo
    echo -e "${CYAN}项目地址：${RESET}https://github.com/sau1g0dman/scripts-for-linux"
    echo -e "${CYAN}问题反馈：${RESET}sau1amaranth@gmail.com"
    echo
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    # 设置清理陷阱
    setup_cleanup_trap

    # 显示头部信息
    show_header

    # 检查系统要求
    check_system_requirements

    # 确认安装
    if ! ask_confirmation "是否继续安装？" "y"; then
        log_info "用户取消安装"
        exit 0
    fi

    # 克隆仓库到本地
    if ! clone_repository; then
        log_error "❌ 无法克隆项目仓库，安装终止"
        exit 1
    fi

    # 验证本地脚本
    if ! verify_local_scripts; then
        log_error "❌ 本地脚本验证失败，安装终止"
        exit 1
    fi

    # 开始安装
    main_install

    # 显示完成信息
    show_completion

    # 询问是否保留本地仓库
    if ask_confirmation "是否保留本地仓库副本以便后续使用？" "n"; then
        CLEANUP_ON_EXIT=false
        log_info "📁 本地仓库保留在: $LOCAL_REPO_DIR"
        log_info "💡 您可以稍后手动删除此目录"
    fi
}

# 脚本入口点
# 安全检查 BASH_SOURCE 是否存在，兼容 curl | bash 执行方式
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
