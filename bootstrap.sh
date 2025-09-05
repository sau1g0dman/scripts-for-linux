#!/bin/bash

# =============================================================================
# Ubuntu/Debian服务器安装脚本 - 引导程序
# 作者: saul
# 版本: 1.0
# 描述: 自动克隆仓库并执行安装脚本的引导程序
# =============================================================================

set -euo pipefail

# =============================================================================
# 配置变量
# =============================================================================
readonly REPO_URL="https://github.com/sau1g0dman/scripts-for-linux.git"
readonly REPO_BRANCH="main"
readonly TEMP_DIR="/tmp/scripts-for-linux-bootstrap-$(date +%Y%m%d-%H%M%S)"
readonly SCRIPT_NAME="install.sh"

# 颜色定义（引导脚本自带，避免依赖问题）
readonly RED=$(printf '\033[31m' 2>/dev/null || echo '')
readonly GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
readonly YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
readonly BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
readonly CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
readonly RESET=$(printf '\033[m' 2>/dev/null || echo '')

# =============================================================================
# 日志函数
# =============================================================================
log_info() {
    echo -e "${CYAN}[BOOTSTRAP]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[BOOTSTRAP]${RESET} $1"
}

log_error() {
    echo -e "${RED}[BOOTSTRAP]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[BOOTSTRAP]${RESET} $1"
}

# =============================================================================
# 清理函数
# =============================================================================
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        log_info "清理临时目录: $TEMP_DIR"
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}

# 设置退出时清理
trap cleanup EXIT

# =============================================================================
# 主要功能函数
# =============================================================================

# 显示引导程序头部信息
show_bootstrap_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}Ubuntu/Debian服务器安装脚本 - 引导程序${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}此引导程序将：${RESET}"
    echo -e "${CYAN}1. 克隆完整的项目仓库到本地${RESET}"
    echo -e "${CYAN}2. 执行完整的安装脚本${RESET}"
    echo -e "${CYAN}3. 安装完成后自动清理临时文件${RESET}"
    echo
}

# 检查系统要求
check_prerequisites() {
    log_info "检查系统要求..."

    # 检查必需的命令
    local required_commands=("git" "curl")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    # 如果有缺失的命令，尝试安装
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_warn "缺少必需的命令: ${missing_commands[*]}"
        log_info "正在尝试安装缺失的软件包..."

        if command -v apt >/dev/null 2>&1; then
            sudo apt update >/dev/null 2>&1
            for cmd in "${missing_commands[@]}"; do
                log_info "安装 $cmd..."
                if sudo apt install -y "$cmd" >/dev/null 2>&1; then
                    log_success "$cmd 安装成功"
                else
                    log_error "$cmd 安装失败"
                    exit 1
                fi
            done
        else
            log_error "无法自动安装缺失的软件包，请手动安装: ${missing_commands[*]}"
            exit 1
        fi
    fi

    log_success "系统要求检查通过"
}

# 克隆仓库
clone_repository() {
    log_info "克隆项目仓库..."
    log_info "仓库地址: $REPO_URL"
    log_info "目标目录: $TEMP_DIR"

    if git clone --depth=1 --branch="$REPO_BRANCH" "$REPO_URL" "$TEMP_DIR" >/dev/null 2>&1; then
        log_success "仓库克隆成功"
        return 0
    else
        log_error "仓库克隆失败"
        log_error "请检查网络连接或仓库地址是否正确"
        return 1
    fi
}

# 验证安装脚本
verify_install_script() {
    local install_script="$TEMP_DIR/$SCRIPT_NAME"
    
    if [ ! -f "$install_script" ]; then
        log_error "安装脚本不存在: $install_script"
        return 1
    fi

    if [ ! -r "$install_script" ]; then
        log_error "安装脚本不可读: $install_script"
        return 1
    fi

    log_success "安装脚本验证通过"
    return 0
}

# 执行安装脚本
execute_install_script() {
    local install_script="$TEMP_DIR/$SCRIPT_NAME"
    
    log_info "准备执行安装脚本..."
    log_info "脚本路径: $install_script"
    echo
    echo -e "${YELLOW}注意：即将启动完整的安装脚本${RESET}"
    echo -e "${YELLOW}您可以在安装过程中随时按 Ctrl+C 取消安装${RESET}"
    echo

    # 切换到仓库目录并执行脚本
    cd "$TEMP_DIR"
    
    # 执行安装脚本
    if bash "$SCRIPT_NAME"; then
        log_success "安装脚本执行完成"
        return 0
    else
        local exit_code=$?
        log_error "安装脚本执行失败 (退出码: $exit_code)"
        return $exit_code
    fi
}

# 询问用户确认
ask_confirmation() {
    echo -e "${CYAN}是否继续执行安装？ [Y/n]:${RESET} " | tr -d '\n'
    read -r choice
    choice=${choice:-y}
    
    case $choice in
        [Yy]|[Yy][Ee][Ss])
            log_info "用户确认继续安装"
            return 0
            ;;
        *)
            log_info "用户取消安装"
            return 1
            ;;
    esac
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    # 显示头部信息
    show_bootstrap_header

    # 检查系统要求
    check_prerequisites

    # 询问用户确认
    if ! ask_confirmation; then
        exit 0
    fi

    echo
    log_info "开始引导安装过程..."

    # 克隆仓库
    if ! clone_repository; then
        exit 1
    fi

    # 验证安装脚本
    if ! verify_install_script; then
        exit 1
    fi

    # 执行安装脚本
    execute_install_script
    local install_exit_code=$?

    # 显示完成信息
    echo
    if [ $install_exit_code -eq 0 ]; then
        log_success "安装过程完成！"
    else
        log_error "安装过程中出现错误"
    fi

    return $install_exit_code
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
