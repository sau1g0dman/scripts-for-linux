#!/bin/bash

# =============================================================================
# 测试修复效果的脚本
# 作者: saul
# 版本: 1.0
# 描述: 验证修复后的脚本功能是否正常
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

# 显示头部信息
show_header() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE} 测试修复效果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
}

# 测试脚本语法
test_syntax() {
    local script="$1"
    local name="$2"
    
    log_info "测试 $name 语法..."
    if bash -n "$script" 2>/dev/null; then
        log_success "$name 语法检查通过"
        return 0
    else
        log_error "$name 语法检查失败"
        return 1
    fi
}

# 测试emoji清理
test_emoji_cleanup() {
    log_info "检查emoji清理效果..."
    
    local emoji_files=()
    while IFS= read -r -d '' file; do
        if grep -P "[\x{1F300}-\x{1F9FF}]|[\x{2600}-\x{26FF}]|[\x{2700}-\x{27BF}]" "$file" 2>/dev/null; then
            emoji_files+=("$file")
        fi
    done < <(find /root/scripts-for-linux -name "*.sh" -type f -print0 2>/dev/null)
    
    if [ ${#emoji_files[@]} -eq 0 ]; then
        log_success "所有Shell脚本已清理emoji图标"
        return 0
    else
        log_error "以下文件仍包含emoji图标:"
        for file in "${emoji_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
}

# 测试日志格式一致性
test_log_format() {
    log_info "检查日志格式一致性..."
    
    # 检查install.sh的日志格式
    if grep -q 'echo -e "${CYAN}\[INFO\] $(date' install.sh; then
        log_success "install.sh 日志格式正确"
    else
        log_error "install.sh 日志格式不正确"
        return 1
    fi
    
    # 检查zsh-install.sh的错误处理
    if grep -q 'if \[ \$error_code -ne 0 \]' scripts/shell/zsh-install.sh; then
        log_success "zsh-install.sh 错误处理逻辑正确"
    else
        log_error "zsh-install.sh 错误处理逻辑不正确"
        return 1
    fi
    
    return 0
}

# 测试nvim-setup.sh改进
test_nvim_setup() {
    log_info "检查nvim-setup.sh改进..."
    
    # 检查是否有错误处理函数
    if grep -q 'handle_error()' scripts/development/nvim-setup.sh; then
        log_success "nvim-setup.sh 包含错误处理函数"
    else
        log_error "nvim-setup.sh 缺少错误处理函数"
        return 1
    fi
    
    # 检查是否移除了emoji
    if ! grep -q '📧\|🔖' scripts/development/nvim-setup.sh; then
        log_success "nvim-setup.sh 已移除emoji图标"
    else
        log_error "nvim-setup.sh 仍包含emoji图标"
        return 1
    fi
    
    return 0
}

# 主测试函数
main() {
    show_header
    
    local test_count=0
    local pass_count=0
    
    # 测试脚本语法
    if test_syntax "install.sh" "install.sh"; then
        ((pass_count++))
    fi
    ((test_count++))
    
    if test_syntax "scripts/shell/zsh-install.sh" "zsh-install.sh"; then
        ((pass_count++))
    fi
    ((test_count++))
    
    if test_syntax "scripts/development/nvim-setup.sh" "nvim-setup.sh"; then
        ((pass_count++))
    fi
    ((test_count++))
    
    # 测试emoji清理
    if test_emoji_cleanup; then
        ((pass_count++))
    fi
    ((test_count++))
    
    # 测试日志格式
    if test_log_format; then
        ((pass_count++))
    fi
    ((test_count++))
    
    # 测试nvim-setup改进
    if test_nvim_setup; then
        ((pass_count++))
    fi
    ((test_count++))
    
    echo
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE} 测试结果统计${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "总测试项: ${CYAN}$test_count${RESET}"
    echo -e "通过测试: ${GREEN}$pass_count${RESET}"
    echo -e "失败测试: ${RED}$((test_count - pass_count))${RESET}"
    echo
    
    if [ $pass_count -eq $test_count ]; then
        log_success "所有测试通过！修复效果良好"
        return 0
    else
        log_error "部分测试失败，需要进一步修复"
        return 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
