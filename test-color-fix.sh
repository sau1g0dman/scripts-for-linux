#!/bin/bash

# =============================================================================
# 颜色变量修复测试脚本
# 作者: saul
# 版本: 1.0
# 描述: 测试修复后的颜色变量是否正常工作
# =============================================================================

set -euo pipefail

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# =============================================================================
# 测试函数
# =============================================================================

# 测试日志函数
test_log() {
    echo -e "${CYAN}[TEST] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

test_success() {
    echo -e "${GREEN}[PASS] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

test_error() {
    echo -e "${RED}[FAIL] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 显示测试头部信息
show_test_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}颜色变量修复测试${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将测试修复后的颜色变量是否正常工作${RESET}"
    echo
}

# 测试颜色变量可用性
test_color_variables() {
    test_log "测试颜色变量可用性..."
    
    local colors=("RED" "GREEN" "YELLOW" "BLUE" "CYAN" "MAGENTA" "RESET")
    local missing=0
    
    for color in "${colors[@]}"; do
        if [ -n "${!color:-}" ]; then
            test_success "颜色变量 $color 可用"
        else
            test_error "颜色变量 $color 缺失"
            missing=$((missing + 1))
        fi
    done
    
    return $missing
}

# 测试颜色显示效果
test_color_display() {
    test_log "测试颜色显示效果..."
    
    echo
    echo -e "${RED}这是红色文本${RESET}"
    echo -e "${GREEN}这是绿色文本${RESET}"
    echo -e "${YELLOW}这是黄色文本${RESET}"
    echo -e "${BLUE}这是蓝色文本${RESET}"
    echo -e "${CYAN}这是青色文本${RESET}"
    echo -e "${MAGENTA}这是洋红色文本${RESET}"
    echo -e "这是普通文本"
    echo
    
    test_success "颜色显示测试完成"
    return 0
}

# 测试脚本语法
test_script_syntax() {
    test_log "测试修复后的脚本语法..."
    
    local scripts=(
        "scripts/security/ssh-config.sh"
        "uninstall.sh"
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
    
    return $failed
}

# 测试脚本导入
test_script_import() {
    test_log "测试脚本导入功能..."
    
    # 测试 ssh-config.sh 导入
    if source scripts/security/ssh-config.sh 2>/dev/null; then
        test_success "ssh-config.sh 导入成功"
    else
        test_error "ssh-config.sh 导入失败"
        return 1
    fi
    
    # 测试 uninstall.sh 导入
    if source uninstall.sh 2>/dev/null; then
        test_success "uninstall.sh 导入成功"
    else
        test_error "uninstall.sh 导入失败"
        return 1
    fi
    
    return 0
}

# 测试日志函数
test_log_functions() {
    test_log "测试日志函数..."
    
    echo
    log_debug "这是调试信息"
    log_info "这是信息日志"
    log_warn "这是警告日志"
    log_error "这是错误日志"
    echo
    
    test_success "日志函数测试完成"
    return 0
}

# 测试颜色变量冲突检查
test_color_conflicts() {
    test_log "检查颜色变量冲突..."
    
    local scripts=(
        "scripts/security/ssh-config.sh"
        "uninstall.sh"
    )
    
    local conflicts=0
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            # 检查是否还有重复的颜色变量定义
            if grep -q "^RED=" "$script" || grep -q "^GREEN=" "$script" || grep -q "^YELLOW=" "$script"; then
                test_error "发现颜色变量冲突: $script"
                conflicts=$((conflicts + 1))
            else
                test_success "无颜色变量冲突: $script"
            fi
        fi
    done
    
    return $conflicts
}

# 主测试函数
main() {
    show_test_header
    
    local total_tests=0
    local passed_tests=0
    
    # 执行各项测试
    local tests=(
        "test_color_variables"
        "test_color_display"
        "test_script_syntax"
        "test_script_import"
        "test_log_functions"
        "test_color_conflicts"
    )
    
    for test_func in "${tests[@]}"; do
        echo
        total_tests=$((total_tests + 1))
        if $test_func; then
            passed_tests=$((passed_tests + 1))
        fi
    done
    
    # 显示测试结果
    echo
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}测试结果总结${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}总测试数: $total_tests${RESET}"
    echo -e "${GREEN}通过测试: $passed_tests${RESET}"
    echo -e "${RED}失败测试: $((total_tests - passed_tests))${RESET}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo
        echo -e "${GREEN}🎉 所有测试通过！颜色变量修复成功！${RESET}"
        echo
        echo -e "${CYAN}修复成果：${RESET}"
        echo -e "${GREEN}✅ 移除了重复的颜色变量定义${RESET}"
        echo -e "${GREEN}✅ 统一使用 scripts/common.sh 中的颜色变量${RESET}"
        echo -e "${GREEN}✅ 解决了 readonly 变量冲突问题${RESET}"
        echo -e "${GREEN}✅ 保持了所有脚本的颜色显示功能${RESET}"
        echo
        return 0
    else
        echo
        echo -e "${RED}❌ 部分测试失败，请检查上述错误信息。${RESET}"
        return 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
