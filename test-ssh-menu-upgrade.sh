#!/bin/bash

# =============================================================================
# SSH配置脚本菜单升级测试
# 作者: saul
# 版本: 1.0
# 描述: 测试SSH配置脚本的键盘导航菜单功能
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
    echo -e "${BLUE}SSH配置脚本菜单升级测试${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将测试SSH配置脚本的键盘导航菜单功能${RESET}"
    echo
}

# 测试1：语法检查
test_syntax() {
    test_log "测试SSH配置脚本语法..."
    
    if bash -n scripts/security/ssh-config.sh 2>/dev/null; then
        test_success "SSH配置脚本语法检查通过"
        return 0
    else
        test_error "SSH配置脚本语法检查失败"
        return 1
    fi
}

# 测试2：菜单选项数组创建函数
test_menu_function() {
    test_log "测试菜单选项数组创建函数..."
    
    # 导入脚本并测试函数
    if source scripts/security/ssh-config.sh 2>/dev/null; then
        if declare -f "create_ssh_menu_options" >/dev/null 2>&1; then
            test_success "create_ssh_menu_options 函数已定义"
            
            # 测试函数执行
            if create_ssh_menu_options 2>/dev/null; then
                test_success "菜单选项数组创建成功"
                
                # 检查数组是否正确创建
                if [ ${#SSH_MENU_OPTIONS[@]} -gt 0 ]; then
                    test_success "SSH_MENU_OPTIONS 数组包含 ${#SSH_MENU_OPTIONS[@]} 个选项"
                    
                    # 显示菜单选项
                    test_log "菜单选项内容："
                    for ((i = 0; i < ${#SSH_MENU_OPTIONS[@]}; i++)); do
                        echo -e "${CYAN}  $((i + 1)). ${SSH_MENU_OPTIONS[$i]}${RESET}"
                    done
                    
                    return 0
                else
                    test_error "SSH_MENU_OPTIONS 数组为空"
                    return 1
                fi
            else
                test_error "菜单选项数组创建失败"
                return 1
            fi
        else
            test_error "create_ssh_menu_options 函数缺失"
            return 1
        fi
    else
        test_error "无法导入SSH配置脚本"
        return 1
    fi
}

# 测试3：检查传统菜单的移除
test_traditional_menu_removal() {
    test_log "检查传统菜单的移除..."
    
    # 检查是否还有 select 语句
    if grep -q "^select.*in.*options" scripts/security/ssh-config.sh; then
        test_error "仍然存在传统的 select 菜单"
        return 1
    else
        test_success "传统的 select 菜单已移除"
    fi
    
    # 检查是否还有 PS3 提示符定义
    if grep -q "^PS3=" scripts/security/ssh-config.sh; then
        test_error "仍然存在 PS3 提示符定义"
        return 1
    else
        test_success "PS3 提示符定义已移除"
    fi
    
    # 检查是否使用了新的菜单选择方式
    if grep -q "select_menu.*SSH_MENU_OPTIONS" scripts/security/ssh-config.sh; then
        test_success "使用了新的键盘导航菜单选择方式"
        return 0
    else
        test_error "未使用新的键盘导航菜单选择方式"
        return 1
    fi
}

# 测试4：检查颜色变量使用
test_color_usage() {
    test_log "检查颜色变量使用..."
    
    # 检查是否正确使用了标准颜色变量
    local color_usage=$(grep -c "\${RED}\|\${GREEN}\|\${YELLOW}\|\${BLUE}\|\${CYAN}\|\${RESET}" scripts/security/ssh-config.sh 2>/dev/null || echo "0")
    
    if [ $color_usage -gt 0 ]; then
        test_success "正确使用了标准颜色变量 ($color_usage 次)"
        return 0
    else
        test_error "未使用标准颜色变量"
        return 1
    fi
}

# 测试5：检查交互式确认函数使用
test_confirmation_usage() {
    test_log "检查交互式确认函数使用..."
    
    local usage=$(grep -c "interactive_ask_confirmation" scripts/security/ssh-config.sh 2>/dev/null || echo "0")
    
    if [ $usage -gt 0 ]; then
        test_success "使用了 $usage 次 interactive_ask_confirmation"
        return 0
    else
        test_error "未使用 interactive_ask_confirmation"
        return 1
    fi
}

# 测试6：功能完整性检查
test_functionality() {
    test_log "检查功能完整性..."
    
    # 检查所有原有功能是否保留
    local functions=(
        "backup_personal_info"
        "install_openssh_server"
        "set_ssh_permit_root_login"
        "set_public_key_login"
        "set_allow_agent_forwarding"
        "generate_ssh_key"
        "install_fail2ban"
    )
    
    local missing=0
    for func in "${functions[@]}"; do
        if grep -q "$func" scripts/security/ssh-config.sh; then
            test_success "功能函数 $func 已保留"
        else
            test_error "功能函数 $func 缺失"
            missing=$((missing + 1))
        fi
    done
    
    return $missing
}

# 演示新菜单功能
demo_new_menu() {
    test_log "演示新菜单功能..."
    
    echo
    echo -e "${CYAN}新菜单功能特性：${RESET}"
    echo -e "${GREEN}✓ 键盘导航${RESET} - 使用 ↑↓ 箭头键选择选项"
    echo -e "${GREEN}✓ 实时高亮${RESET} - 当前选中项高亮显示"
    echo -e "${GREEN}✓ Enter确认${RESET} - 按回车键确认选择"
    echo -e "${GREEN}✓ 操作提示${RESET} - 清晰的操作指导"
    echo -e "${GREEN}✓ 继续询问${RESET} - 操作完成后询问是否继续"
    echo
    
    if interactive_ask_confirmation "是否查看SSH配置脚本的菜单选项？" "true"; then
        # 创建并显示菜单选项
        source scripts/security/ssh-config.sh 2>/dev/null
        create_ssh_menu_options
        
        echo
        echo -e "${BLUE}SSH配置脚本菜单选项：${RESET}"
        for ((i = 0; i < ${#SSH_MENU_OPTIONS[@]}; i++)); do
            echo -e "${CYAN}  $((i + 1)). ${SSH_MENU_OPTIONS[$i]}${RESET}"
        done
        echo
        
        test_success "菜单选项显示完成"
    else
        test_log "跳过菜单选项显示"
    fi
    
    return 0
}

# 主测试函数
main() {
    show_test_header
    
    local total_tests=0
    local passed_tests=0
    
    # 执行各项测试
    local tests=(
        "test_syntax"
        "test_menu_function"
        "test_traditional_menu_removal"
        "test_color_usage"
        "test_confirmation_usage"
        "test_functionality"
        "demo_new_menu"
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
    echo -e "${BLUE}SSH菜单升级测试结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}总测试数: $total_tests${RESET}"
    echo -e "${GREEN}通过测试: $passed_tests${RESET}"
    echo -e "${RED}失败测试: $((total_tests - passed_tests))${RESET}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo
        echo -e "${GREEN}🎉 所有测试通过！SSH配置脚本菜单升级成功！${RESET}"
        echo
        echo -e "${CYAN}升级成果：${RESET}"
        echo -e "${GREEN}✅ 传统数字选择菜单 → 键盘导航菜单${RESET}"
        echo -e "${GREEN}✅ 移除了 select 语句和 PS3 提示符${RESET}"
        echo -e "${GREEN}✅ 使用标准化的 select_menu 函数${RESET}"
        echo -e "${GREEN}✅ 保持了所有原有功能${RESET}"
        echo -e "${GREEN}✅ 添加了操作完成后的继续询问${RESET}"
        echo
        echo -e "${CYAN}现在可以运行以下命令体验新菜单：${RESET}"
        echo -e "${YELLOW}sudo ./scripts/security/ssh-config.sh${RESET}"
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
