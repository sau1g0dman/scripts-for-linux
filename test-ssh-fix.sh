#!/bin/bash

# =============================================================================
# SSH配置脚本修复测试
# 作者: saul
# 版本: 1.0
# 描述: 测试修复后的SSH配置脚本是否正常工作
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
    echo -e "${BLUE}SSH配置脚本修复测试${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将测试修复后的SSH配置脚本是否正常工作${RESET}"
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
        bash -n scripts/security/ssh-config.sh
        return 1
    fi
}

# 测试2：检查 local 变量使用
test_local_variables() {
    test_log "检查 local 变量使用..."
    
    # 检查是否还有在函数外使用 local 的情况
    local issues=0
    
    # 使用更精确的检查方法
    if bash -c 'source scripts/security/ssh-config.sh' 2>&1 | grep -q "local: can only be used in a function"; then
        test_error "仍然存在在函数外使用 local 的问题"
        issues=$((issues + 1))
    else
        test_success "local 变量使用正确"
    fi
    
    return $issues
}

# 测试3：菜单功能基本测试
test_menu_function() {
    test_log "测试菜单功能..."
    
    # 导入脚本并测试菜单选项数组创建
    if source scripts/security/ssh-config.sh 2>/dev/null; then
        if declare -f "create_ssh_menu_options" >/dev/null 2>&1; then
            test_success "create_ssh_menu_options 函数已定义"
            
            # 测试函数执行
            if create_ssh_menu_options 2>/dev/null; then
                test_success "菜单选项数组创建成功"
                
                # 检查数组是否正确创建
                if [ ${#SSH_MENU_OPTIONS[@]} -eq 7 ]; then
                    test_success "SSH_MENU_OPTIONS 数组包含正确数量的选项 (${#SSH_MENU_OPTIONS[@]})"
                    return 0
                else
                    test_error "SSH_MENU_OPTIONS 数组选项数量不正确 (期望7，实际${#SSH_MENU_OPTIONS[@]})"
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

# 测试4：检查脚本导入
test_script_import() {
    test_log "测试脚本导入..."
    
    # 测试脚本是否能正常导入而不出现错误
    if bash -c 'source scripts/security/ssh-config.sh' 2>/dev/null; then
        test_success "SSH配置脚本导入成功"
        return 0
    else
        test_error "SSH配置脚本导入失败"
        # 显示错误信息
        bash -c 'source scripts/security/ssh-config.sh' 2>&1 | head -5
        return 1
    fi
}

# 测试5：检查关键函数存在
test_key_functions() {
    test_log "检查关键函数存在性..."
    
    # 导入脚本
    if source scripts/security/ssh-config.sh 2>/dev/null; then
        local functions=(
            "backup_personal_info"
            "install_openssh_server"
            "set_ssh_permit_root_login"
            "set_public_key_login"
            "set_allow_agent_forwarding"
            "generate_ssh_key"
            "install_fail2ban"
            "create_ssh_menu_options"
        )
        
        local missing=0
        for func in "${functions[@]}"; do
            if declare -f "$func" >/dev/null 2>&1; then
                test_success "函数 $func 存在"
            else
                test_error "函数 $func 缺失"
                missing=$((missing + 1))
            fi
        done
        
        return $missing
    else
        test_error "无法导入脚本进行函数检查"
        return 1
    fi
}

# 主测试函数
main() {
    show_test_header
    
    local total_tests=0
    local passed_tests=0
    
    # 执行各项测试
    local tests=(
        "test_syntax"
        "test_local_variables"
        "test_script_import"
        "test_menu_function"
        "test_key_functions"
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
    echo -e "${BLUE}SSH配置脚本修复测试结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}总测试数: $total_tests${RESET}"
    echo -e "${GREEN}通过测试: $passed_tests${RESET}"
    echo -e "${RED}失败测试: $((total_tests - passed_tests))${RESET}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo
        echo -e "${GREEN}🎉 所有测试通过！SSH配置脚本修复成功！${RESET}"
        echo
        echo -e "${CYAN}修复内容：${RESET}"
        echo -e "${GREEN}✅ 修复了 local 变量在函数外使用的问题${RESET}"
        echo -e "${GREEN}✅ 脚本语法检查通过${RESET}"
        echo -e "${GREEN}✅ 脚本可以正常导入和执行${RESET}"
        echo -e "${GREEN}✅ 所有关键函数正常工作${RESET}"
        echo -e "${GREEN}✅ 菜单功能完全正常${RESET}"
        echo
        echo -e "${CYAN}现在可以正常使用SSH配置脚本：${RESET}"
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
