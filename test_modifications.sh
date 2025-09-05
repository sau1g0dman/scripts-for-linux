#!/bin/bash

# =============================================================================
# 测试修改后的脚本功能
# 作者: saul
# 版本: 1.0
# 描述: 验证install.sh脚本的修改是否正确
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

log_success() {
    echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 显示测试头部信息
show_test_header() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}脚本修改验证测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
}

# 测试install.sh脚本的菜单显示
test_install_menu() {
    log_info "测试install.sh菜单显示..."
    
    # 检查是否包含新的菜单项
    if grep -q "1. 常用软件安装" install.sh; then
        log_success "菜单项1已更新为'常用软件安装'"
    else
        log_error "菜单项1未正确更新"
        return 1
    fi
    
    if grep -q "install_common_software" install.sh; then
        log_success "install_common_software函数已添加"
    else
        log_error "install_common_software函数未找到"
        return 1
    fi
    
    # 检查是否移除了mirrors.sh相关代码
    if ! grep -q "system/mirrors.sh" install.sh; then
        log_success "mirrors.sh相关代码已移除"
    else
        log_error "mirrors.sh相关代码仍然存在"
        return 1
    fi
    
    return 0
}

# 测试zsh-install.sh脚本的rainbow主题配置
test_zsh_rainbow_config() {
    log_info "测试zsh-install.sh的rainbow主题配置..."
    
    if grep -q "download_rainbow_theme_config" scripts/shell/zsh-install.sh; then
        log_success "rainbow主题配置函数已添加"
    else
        log_error "rainbow主题配置函数未找到"
        return 1
    fi
    
    if grep -q "p10k-rainbow.zsh" scripts/shell/zsh-install.sh; then
        log_success "rainbow主题配置URL已配置"
    else
        log_error "rainbow主题配置URL未找到"
        return 1
    fi
    
    return 0
}

# 测试nvim-setup.sh脚本的错误处理增强
test_nvim_error_handling() {
    log_info "测试nvim-setup.sh的错误处理增强..."
    
    if grep -q "调试建议" scripts/development/nvim-setup.sh; then
        log_success "增强的错误处理已添加"
    else
        log_error "增强的错误处理未找到"
        return 1
    fi
    
    if grep -q "COLOR_CYAN.*安装Neovim" scripts/development/nvim-setup.sh; then
        log_success "菜单美化已完成"
    else
        log_error "菜单美化未完成"
        return 1
    fi
    
    return 0
}

# 测试日志颜色配置
test_log_colors() {
    log_info "测试日志颜色配置..."
    
    # 测试不同级别的日志颜色
    log_info "这是INFO级别日志 - 应该是青色"
    log_warn "这是WARN级别日志 - 应该是黄色"
    log_error "这是ERROR级别日志 - 应该是红色"
    log_success "这是SUCCESS级别日志 - 应该是绿色"
    
    log_success "日志颜色测试完成"
    return 0
}

# 主测试函数
main() {
    show_test_header
    
    local test_count=0
    local passed_count=0
    
    # 测试install.sh菜单
    test_count=$((test_count + 1))
    if test_install_menu; then
        passed_count=$((passed_count + 1))
    fi
    echo
    
    # 测试zsh-install.sh rainbow配置
    test_count=$((test_count + 1))
    if test_zsh_rainbow_config; then
        passed_count=$((passed_count + 1))
    fi
    echo
    
    # 测试nvim-setup.sh错误处理
    test_count=$((test_count + 1))
    if test_nvim_error_handling; then
        passed_count=$((passed_count + 1))
    fi
    echo
    
    # 测试日志颜色
    test_count=$((test_count + 1))
    if test_log_colors; then
        passed_count=$((passed_count + 1))
    fi
    echo
    
    # 显示测试结果
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}测试结果统计${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${CYAN}总测试数: $test_count${RESET}"
    echo -e "${GREEN}通过测试: $passed_count${RESET}"
    echo -e "${RED}失败测试: $((test_count - passed_count))${RESET}"
    
    if [ $passed_count -eq $test_count ]; then
        echo
        log_success "所有测试通过！脚本修改成功完成。"
        return 0
    else
        echo
        log_error "部分测试失败，请检查修改内容。"
        return 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
