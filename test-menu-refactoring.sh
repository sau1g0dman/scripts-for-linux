#!/bin/bash

# =============================================================================
# 菜单重构测试脚本
# 作者: saul
# 版本: 1.0
# 描述: 测试所有重构后的交互式菜单功能
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

test_warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 显示测试头部信息
show_test_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}菜单重构测试脚本${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将测试所有重构后的交互式菜单功能${RESET}"
    echo
}

# 测试脚本语法
test_script_syntax() {
    test_log "测试脚本语法..."

    local scripts=(
        "install.sh"
        "scripts/common.sh"
        "scripts/development/nvim-setup.sh"
        "scripts/containers/docker-install.sh"
        "scripts/shell/zsh-install.sh"
        "scripts/security/ssh-config.sh"
        "scripts/security/ssh-keygen.sh"
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

# 测试新增的菜单选择函数
test_menu_functions() {
    test_log "测试新增的菜单选择函数..."

    # 检查 common.sh 中的新函数
    local functions=(
        "interactive_select_menu"
        "traditional_select_menu"
        "select_menu"
    )

    local missing=0
    for func in "${functions[@]}"; do
        if declare -f "$func" >/dev/null 2>&1; then
            test_success "函数 $func 已定义"
        else
            test_error "函数 $func 缺失"
            missing=$((missing + 1))
        fi
    done

    return $missing
}

# 测试菜单选项数组创建函数
test_menu_option_functions() {
    test_log "测试菜单选项数组创建函数..."

    # 导入 install.sh 并测试函数
    if source install.sh 2>/dev/null; then
        local functions=(
            "create_install_menu_options"
            "create_mirrors_menu_options"
        )

        local missing=0
        for func in "${functions[@]}"; do
            if declare -f "$func" >/dev/null 2>&1; then
                test_success "函数 $func 已定义"

                # 测试函数执行
                if $func 2>/dev/null; then
                    test_success "函数 $func 执行成功"
                else
                    test_error "函数 $func 执行失败"
                    missing=$((missing + 1))
                fi
            else
                test_error "函数 $func 缺失"
                missing=$((missing + 1))
            fi
        done

        return $missing
    else
        test_error "无法导入 install.sh"
        return 1
    fi
}

# 测试交互式确认函数的使用
test_interactive_confirmation_usage() {
    test_log "测试交互式确认函数的使用..."

    local scripts=(
        "install.sh"
        "scripts/containers/docker-install.sh"
        "scripts/shell/zsh-install.sh"
        "scripts/development/nvim-setup.sh"
        "scripts/security/ssh-config.sh"
    )

    local total_usage=0

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            local usage=$(grep -c "interactive_ask_confirmation" "$script" 2>/dev/null || echo "0")
            if [ $usage -gt 0 ]; then
                test_success "$script: 使用了 $usage 次 interactive_ask_confirmation"
                total_usage=$((total_usage + usage))
            else
                test_warn "$script: 未使用 interactive_ask_confirmation"
            fi
        fi
    done

    test_success "总计使用 interactive_ask_confirmation: $total_usage 次"
    return 0
}

# 测试传统交互方式的移除
test_traditional_interaction_removal() {
    test_log "测试传统交互方式的移除..."

    local scripts=(
        "install.sh"
        "scripts/development/nvim-setup.sh"
    )

    local found_issues=0

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            # 检查是否还有传统的 read -p 数字选择（排除特殊情况）
            if grep -q "read -p.*\[.*[0-9].*\]" "$script" && ! grep -q "choice < /dev/tty" "$script"; then
                test_warn "可能存在传统数字选择菜单: $script"
                # 显示具体行
                grep -n "read -p.*\[.*[0-9].*\]" "$script" | head -3
            fi

            # 检查是否还有自定义的菜单显示函数调用
            if grep -q "show_.*menu" "$script" && ! grep -q "select_menu" "$script"; then
                test_warn "可能存在传统菜单显示: $script"
            fi
        else
            test_error "脚本不存在: $script"
            found_issues=$((found_issues + 1))
        fi
    done

    if [ $found_issues -eq 0 ]; then
        test_success "传统交互方式检查完成"
        return 0
    else
        test_error "发现 $found_issues 个问题"
        return 1
    fi
}

# 演示新的菜单选择功能
demo_menu_selection() {
    test_log "演示新的菜单选择功能..."

    # 创建演示菜单选项
    local demo_options=(
        "选项1 - 这是第一个选项"
        "选项2 - 这是第二个选项"
        "选项3 - 这是第三个选项"
        "退出演示"
    )

    echo
    echo -e "${BLUE}演示：键盘导航菜单选择${RESET}"
    echo -e "${CYAN}操作说明：${RESET}"
    echo -e "  • 使用 ↑↓ 箭头键或 w/s 键选择"
    echo -e "  • 按回车键确认选择"
    echo -e "  • 按 Ctrl+C 取消操作"
    echo

    if interactive_ask_confirmation "是否进行菜单选择演示？" "false"; then
        select_menu "demo_options" "请选择一个演示选项：" 0

        local selected_index=$MENU_SELECT_INDEX
        local selected_option="$MENU_SELECT_RESULT"

        echo
        test_success "您选择了: $selected_option (索引: $selected_index)"

        if [ $selected_index -eq 3 ]; then
            test_log "演示结束"
        else
            test_log "演示选择完成"
        fi
    else
        test_log "跳过菜单选择演示"
    fi
}

# 主测试函数
main() {
    show_test_header

    local total_tests=0
    local passed_tests=0

    # 执行各项测试
    local tests=(
        "test_script_syntax"
        "test_menu_functions"
        "test_menu_option_functions"
        "test_interactive_confirmation_usage"
        "test_traditional_interaction_removal"
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
        echo -e "${GREEN}✅ 所有测试通过！菜单重构成功完成。${RESET}"

        # 进行演示
        echo
        demo_menu_selection

        return 0
    else
        echo -e "${RED}❌ 部分测试失败，请检查上述错误信息。${RESET}"
        return 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
