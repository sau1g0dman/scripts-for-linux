#!/bin/bash

# =============================================================================
# 脚本修复验证测试
# 作者: saul
# 版本: 1.0
# 描述: 验证所有脚本修复是否正确
# =============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly CYAN='\033[36m'
readonly RESET='\033[0m'

# 日志函数
log_info() {
    echo -e "${CYAN}[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 测试日志颜色
test_log_colors() {
    log_info "测试日志颜色配置..."

    log_info "这是INFO级别日志 - 应该是青色"
    log_warn "这是WARN级别日志 - 应该是黄色"
    log_error "这是ERROR级别日志 - 应该是红色"
    log_success "这是SUCCESS级别日志 - 应该是绿色"

    log_success "日志颜色测试完成"
}

# 测试emoji清理
test_emoji_cleanup() {
    log_info "检查emoji图标清理情况..."

    local emoji_found=false
    local files_with_emoji=()

    # 检查主要脚本文件
    for script in install.sh scripts/shell/zsh-install.sh scripts/development/nvim-setup.sh scripts/containers/harbor-push.sh scripts/security/ssh-keygen.sh; do
        if [ -f "$script" ]; then
            if grep -q "🚀\|📥\|❌\|✅\|🧹\|🔧\|🐚\|🛠️\|🔐\|🐳\|📦\|🎯\|💡\|🔄\|⚠️\|📝\|📋\|🎨\|🎉\|📧\|🔖" "$script" 2>/dev/null; then
                emoji_found=true
                files_with_emoji+=("$script")
            fi
        fi
    done

    if [ "$emoji_found" = true ]; then
        log_error "发现以下文件仍包含emoji图标:"
        for file in "${files_with_emoji[@]}"; do
            log_error "  - $file"
        done
        return 1
    else
        log_success "所有脚本的emoji图标已清理完成"
        return 0
    fi
}

# 测试错误处理逻辑
test_error_handling() {
    log_info "测试错误处理逻辑..."

    # 检查zsh-install.sh的错误处理函数
    if [ -f "scripts/shell/zsh-install.sh" ]; then
        if grep -q "local error_code=\${2:-\$?\}" "scripts/shell/zsh-install.sh"; then
            log_success "zsh-install.sh错误处理函数已修复"
        else
            log_error "zsh-install.sh错误处理函数未正确修复"
            return 1
        fi

        if grep -q "trap.*handle_error.*LINENO.*?" "scripts/shell/zsh-install.sh"; then
            log_success "zsh-install.sh错误trap已修复"
        else
            log_error "zsh-install.sh错误trap未正确修复"
            return 1
        fi
    fi

    # 检查nvim-setup.sh的错误处理函数
    if [ -f "scripts/development/nvim-setup.sh" ]; then
        if grep -q "local error_code=\${2:-\$?\}" "scripts/development/nvim-setup.sh"; then
            log_success "nvim-setup.sh错误处理函数已修复"
        else
            log_error "nvim-setup.sh错误处理函数未正确修复"
            return 1
        fi
    fi

    log_success "错误处理逻辑测试通过"
}

# 测试用户界面美化
test_ui_improvements() {
    log_info "测试用户界面美化..."

    # 检查install.sh的ask_confirmation函数
    if [ -f "install.sh" ]; then
        if grep -q "echo -e.*GREEN.*message.*RESET.*tr -d" "install.sh"; then
            log_success "install.sh的ask_confirmation函数已美化"
        else
            log_error "install.sh的ask_confirmation函数未正确美化"
            return 1
        fi

        if grep -q "echo -e.*BLUE.*================================================================.*RESET" "install.sh"; then
            log_success "install.sh的show_install_menu函数已美化"
        else
            log_error "install.sh的show_install_menu函数未正确美化"
            return 1
        fi
    fi

    # 检查nvim-setup.sh的ask_confirmation函数
    if [ -f "scripts/development/nvim-setup.sh" ]; then
        if grep -q "echo -e.*COLOR_GREEN.*message.*COLOR_RESET.*tr -d" "scripts/development/nvim-setup.sh"; then
            log_success "nvim-setup.sh的ask_confirmation函数已美化"
        else
            log_error "nvim-setup.sh的ask_confirmation函数未正确美化"
            return 1
        fi
    fi

    log_success "用户界面美化测试通过"
}

# 测试ZSH主题配置功能
test_zsh_theme_config() {
    log_info "测试ZSH主题配置功能..."

    if [ -f "scripts/shell/zsh-install.sh" ]; then
        if grep -q "configure_rainbow_theme" "scripts/shell/zsh-install.sh"; then
            log_success "ZSH Rainbow主题配置功能已存在"
        else
            log_error "ZSH Rainbow主题配置功能缺失"
            return 1
        fi

        if grep -q "智能配置合并" "scripts/shell/zsh-install.sh"; then
            log_success "ZSH智能配置合并功能已存在"
        else
            log_error "ZSH智能配置合并功能缺失"
            return 1
        fi
    fi

    log_success "ZSH主题配置功能测试通过"
}

# 主测试函数
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}开始脚本修复验证测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo

    local test_count=0
    local passed_count=0

    # 测试1: 日志颜色
    test_count=$((test_count + 1))
    if test_log_colors; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试2: emoji清理
    test_count=$((test_count + 1))
    if test_emoji_cleanup; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试3: 错误处理逻辑
    test_count=$((test_count + 1))
    if test_error_handling; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试4: 用户界面美化
    test_count=$((test_count + 1))
    if test_ui_improvements; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试5: ZSH主题配置
    test_count=$((test_count + 1))
    if test_zsh_theme_config; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 显示测试结果
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}测试结果汇总${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${CYAN}总测试数: $test_count${RESET}"
    echo -e "${GREEN}通过测试: $passed_count${RESET}"
    echo -e "${RED}失败测试: $((test_count - passed_count))${RESET}"
    echo

    if [ $passed_count -eq $test_count ]; then
        log_success "所有测试通过！脚本修复成功完成"
        return 0
    else
        log_error "部分测试失败，请检查上述错误信息"
        return 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
