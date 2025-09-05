#!/bin/bash

# =============================================================================
# 重构后的安装脚本测试
# 用于验证所有用户交互点都正常工作
# =============================================================================

set -euo pipefail

# 测试颜色
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly CYAN='\033[36m'
readonly RESET='\033[0m'

# 测试日志函数
test_log() {
    echo -e "${CYAN}[TEST] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

test_success() {
    echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

test_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 测试 common.sh 加载
test_common_loading() {
    test_log "测试 common.sh 加载功能..."
    
    # 测试从当前目录加载
    if [ -f "scripts/common.sh" ]; then
        source "scripts/common.sh"
        test_success "成功从当前目录加载 common.sh"
        return 0
    else
        test_error "无法从当前目录加载 common.sh"
        return 1
    fi
}

# 测试交互式确认功能
test_interactive_confirmation() {
    test_log "测试交互式确认功能..."
    
    # 检查函数是否存在
    if declare -f interactive_ask_confirmation >/dev/null; then
        test_success "interactive_ask_confirmation 函数已加载"
    else
        test_error "interactive_ask_confirmation 函数未找到"
        return 1
    fi
    
    # 检查传统确认功能
    if declare -f traditional_ask_confirmation >/dev/null; then
        test_success "traditional_ask_confirmation 函数已加载"
    else
        test_error "traditional_ask_confirmation 函数未找到"
        return 1
    fi
    
    # 检查智能确认功能
    if declare -f ask_confirmation >/dev/null; then
        test_success "ask_confirmation 函数已加载"
    else
        test_error "ask_confirmation 函数未找到"
        return 1
    fi
    
    return 0
}

# 测试脚本语法
test_script_syntax() {
    test_log "测试脚本语法..."
    
    local scripts=(
        "install.sh"
        "scripts/security/ssh-config.sh"
        "scripts/security/ssh-keygen.sh"
        "scripts/containers/docker-install.sh"
        "scripts/shell/zsh-install.sh"
        "scripts/development/nvim-setup.sh"
    )
    
    local failed=0
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                test_success "语法检查通过: $script"
            else
                test_error "语法检查失败: $script"
                failed=$((failed + 1))
            fi
        else
            test_error "脚本不存在: $script"
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        test_success "所有脚本语法检查通过"
        return 0
    else
        test_error "$failed 个脚本语法检查失败"
        return 1
    fi
}

# 测试函数调用一致性
test_function_consistency() {
    test_log "测试函数调用一致性..."
    
    # 检查 install.sh 中是否还有旧的 ask_confirmation 定义
    if grep -q "^ask_confirmation()" install.sh; then
        test_error "install.sh 中仍存在自定义的 ask_confirmation 函数定义"
        return 1
    else
        test_success "install.sh 中已移除自定义的 ask_confirmation 函数"
    fi
    
    # 检查是否正确使用了 interactive_ask_confirmation
    local interactive_calls=$(grep -c "interactive_ask_confirmation" install.sh || true)
    if [ $interactive_calls -gt 0 ]; then
        test_success "install.sh 中使用了 $interactive_calls 次 interactive_ask_confirmation"
    else
        test_error "install.sh 中未找到 interactive_ask_confirmation 调用"
        return 1
    fi
    
    return 0
}

# 主测试函数
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}重构后的安装脚本测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    
    local tests_passed=0
    local tests_total=4
    
    # 运行测试
    if test_common_loading; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_interactive_confirmation; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_script_syntax; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_function_consistency; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    # 显示测试结果
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}测试结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    
    if [ $tests_passed -eq $tests_total ]; then
        test_success "所有测试通过 ($tests_passed/$tests_total)"
        echo -e "${GREEN}重构成功！所有用户交互点已标准化。${RESET}"
        return 0
    else
        test_error "部分测试失败 ($tests_passed/$tests_total)"
        echo -e "${RED}重构存在问题，请检查失败的测试项。${RESET}"
        return 1
    fi
}

# 运行测试
main "$@"
