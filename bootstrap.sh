#!/bin/bash

# =============================================================================
# Ubuntu/Debian服务器安装脚本 - 简化引导程序
# 作者: saul
# 版本: 2.0
# 描述: 简化的三步安装流程：克隆仓库 -> 进入目录 -> 执行安装脚本
# =============================================================================

set -euo pipefail

# =============================================================================
# 配置变量
# =============================================================================
readonly REPO_URL="https://github.com/sau1g0dman/scripts-for-linux.git"
readonly REPO_DIR="scripts-for-linux"

# 颜色定义
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
    echo -e "${CYAN}[步骤]${RESET} $1"
}

log_error() {
    echo -e "${RED}[错误]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${RESET} $1"
}

# =============================================================================
# 主要功能函数
# =============================================================================

# 步骤1：克隆仓库
clone_repository() {
    log_info "正在克隆仓库..."

    # 如果目录已存在，先删除
    if [ -d "$REPO_DIR" ]; then
        log_info "删除已存在的目录: $REPO_DIR"
        rm -rf "$REPO_DIR"
    fi

    # 克隆仓库
    if git clone "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1; then
        log_success "仓库克隆成功"
        return 0
    else
        log_error "仓库克隆失败，请检查网络连接"
        return 1
    fi
}

# 步骤2：进入仓库目录
enter_directory() {
    log_info "进入仓库目录..."

    if [ ! -d "$REPO_DIR" ]; then
        log_error "仓库目录不存在: $REPO_DIR"
        return 1
    fi

    if cd "$REPO_DIR"; then
        log_success "已进入目录: $(pwd)"
        return 0
    else
        log_error "无法进入目录: $REPO_DIR"
        return 1
    fi
}

# 步骤3：执行安装脚本
execute_install_script() {
    log_info "启动安装脚本..."

    if [ ! -f "install.sh" ]; then
        log_error "安装脚本不存在: install.sh"
        return 1
    fi

    echo
    echo -e "${YELLOW}即将启动交互式安装菜单...${RESET}"
    echo

    # 执行安装脚本
    exec bash install.sh
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}Ubuntu/Debian服务器安装脚本 - 简化引导程序${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo

    # 检查git是否安装
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git 未安装，正在尝试安装..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update >/dev/null 2>&1 && sudo apt install -y git >/dev/null 2>&1
            log_success "Git 安装成功"
        else
            log_error "无法自动安装 Git，请手动安装后重试"
            exit 1
        fi
    fi

    # 执行三个核心步骤
    clone_repository || exit 1
    enter_directory || exit 1
    execute_install_script || exit 1
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
