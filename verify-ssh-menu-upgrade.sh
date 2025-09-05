#!/bin/bash

# =============================================================================
# SSH菜单升级验证脚本
# 作者: saul
# 版本: 1.0
# 描述: 验证SSH配置脚本的菜单升级是否成功
# =============================================================================

set -euo pipefail

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# =============================================================================
# 验证函数
# =============================================================================

# 验证日志函数
verify_log() {
    echo -e "${CYAN}[VERIFY] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

verify_success() {
    echo -e "${GREEN}[PASS] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

verify_error() {
    echo -e "${RED}[FAIL] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 显示验证头部信息
show_verification_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}SSH菜单升级验证${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将验证SSH配置脚本的菜单升级是否成功${RESET}"
    echo
}

# 验证1：语法检查
verify_syntax() {
    verify_log "验证SSH配置脚本语法..."
    
    if bash -n scripts/security/ssh-config.sh 2>/dev/null; then
        verify_success "SSH配置脚本语法检查通过"
        return 0
    else
        verify_error "SSH配置脚本语法检查失败"
        return 1
    fi
}

# 验证2：传统菜单移除
verify_traditional_menu_removal() {
    verify_log "验证传统菜单移除..."
    
    local issues=0
    
    # 检查是否还有 select 语句
    if grep -q "^select.*in.*options" scripts/security/ssh-config.sh; then
        verify_error "仍然存在传统的 select 菜单"
        issues=$((issues + 1))
    else
        verify_success "传统的 select 菜单已移除"
    fi
    
    # 检查是否还有 PS3 提示符定义
    if grep -q "^PS3=" scripts/security/ssh-config.sh; then
        verify_error "仍然存在 PS3 提示符定义"
        issues=$((issues + 1))
    else
        verify_success "PS3 提示符定义已移除"
    fi
    
    # 检查是否还有传统的 case "$REPLY" 模式
    if grep -q 'case "$REPLY"' scripts/security/ssh-config.sh; then
        verify_error "仍然存在传统的 case \$REPLY 模式"
        issues=$((issues + 1))
    else
        verify_success "传统的 case \$REPLY 模式已移除"
    fi
    
    return $issues
}

# 验证3：新菜单功能
verify_new_menu_features() {
    verify_log "验证新菜单功能..."
    
    local issues=0
    
    # 检查是否有菜单选项数组创建函数
    if grep -q "create_ssh_menu_options" scripts/security/ssh-config.sh; then
        verify_success "菜单选项数组创建函数已添加"
    else
        verify_error "菜单选项数组创建函数缺失"
        issues=$((issues + 1))
    fi
    
    # 检查是否使用了新的菜单选择方式
    if grep -q "select_menu.*SSH_MENU_OPTIONS" scripts/security/ssh-config.sh; then
        verify_success "使用了新的键盘导航菜单选择方式"
    else
        verify_error "未使用新的键盘导航菜单选择方式"
        issues=$((issues + 1))
    fi
    
    # 检查是否有 while true 循环
    if grep -q "while true; do" scripts/security/ssh-config.sh; then
        verify_success "添加了菜单循环结构"
    else
        verify_error "缺少菜单循环结构"
        issues=$((issues + 1))
    fi
    
    # 检查是否使用了 interactive_ask_confirmation
    if grep -q "interactive_ask_confirmation" scripts/security/ssh-config.sh; then
        verify_success "使用了标准化确认交互"
    else
        verify_error "未使用标准化确认交互"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# 验证4：功能完整性
verify_functionality() {
    verify_log "验证功能完整性..."
    
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
            verify_success "功能函数 $func 已保留"
        else
            verify_error "功能函数 $func 缺失"
            missing=$((missing + 1))
        fi
    done
    
    return $missing
}

# 验证5：菜单选项内容
verify_menu_options() {
    verify_log "验证菜单选项内容..."
    
    # 导入脚本并创建菜单选项
    if source scripts/security/ssh-config.sh 2>/dev/null; then
        if create_ssh_menu_options 2>/dev/null; then
            if [ ${#SSH_MENU_OPTIONS[@]} -eq 7 ]; then
                verify_success "菜单选项数量正确 (${#SSH_MENU_OPTIONS[@]} 个)"
                
                # 显示菜单选项
                verify_log "菜单选项内容："
                for ((i = 0; i < ${#SSH_MENU_OPTIONS[@]}; i++)); do
                    echo -e "${CYAN}  $((i + 1)). ${SSH_MENU_OPTIONS[$i]}${RESET}"
                done
                
                return 0
            else
                verify_error "菜单选项数量不正确 (期望7个，实际${#SSH_MENU_OPTIONS[@]}个)"
                return 1
            fi
        else
            verify_error "菜单选项数组创建失败"
            return 1
        fi
    else
        verify_error "无法导入SSH配置脚本"
        return 1
    fi
}

# 验证6：颜色变量使用
verify_color_usage() {
    verify_log "验证颜色变量使用..."
    
    # 检查是否正确使用了标准颜色变量
    local color_usage=$(grep -c "\${RED}\|\${GREEN}\|\${YELLOW}\|\${BLUE}\|\${CYAN}\|\${RESET}" scripts/security/ssh-config.sh 2>/dev/null || echo "0")
    
    if [ $color_usage -gt 0 ]; then
        verify_success "正确使用了标准颜色变量 ($color_usage 次)"
        return 0
    else
        verify_error "未使用标准颜色变量"
        return 1
    fi
}

# 主验证函数
main() {
    show_verification_header
    
    local total_verifications=0
    local passed_verifications=0
    
    # 执行各项验证
    local verifications=(
        "verify_syntax"
        "verify_traditional_menu_removal"
        "verify_new_menu_features"
        "verify_functionality"
        "verify_menu_options"
        "verify_color_usage"
    )
    
    for verify_func in "${verifications[@]}"; do
        echo
        total_verifications=$((total_verifications + 1))
        if $verify_func; then
            passed_verifications=$((passed_verifications + 1))
        fi
    done
    
    # 显示验证结果
    echo
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}SSH菜单升级验证结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}总验证项: $total_verifications${RESET}"
    echo -e "${GREEN}通过验证: $passed_verifications${RESET}"
    echo -e "${RED}失败验证: $((total_verifications - passed_verifications))${RESET}"
    
    if [ $passed_verifications -eq $total_verifications ]; then
        echo
        echo -e "${GREEN}🎉 所有验证通过！SSH配置脚本菜单升级完全成功！${RESET}"
        echo
        echo -e "${CYAN}升级成果总结：${RESET}"
        echo -e "${GREEN}✅ 传统数字选择菜单 → 键盘导航菜单${RESET}"
        echo -e "${GREEN}✅ 移除了 select 语句和 PS3 提示符${RESET}"
        echo -e "${GREEN}✅ 使用标准化的 select_menu 函数${RESET}"
        echo -e "${GREEN}✅ 保持了所有原有功能 (7个功能函数)${RESET}"
        echo -e "${GREEN}✅ 添加了操作完成后的继续询问${RESET}"
        echo -e "${GREEN}✅ 使用标准化的颜色变量${RESET}"
        echo
        echo -e "${CYAN}新菜单特性：${RESET}"
        echo -e "${YELLOW}• 键盘导航${RESET} - 使用 ↑↓ 箭头键选择选项"
        echo -e "${YELLOW}• 实时高亮${RESET} - 当前选中项高亮显示"
        echo -e "${YELLOW}• Enter确认${RESET} - 按回车键确认选择"
        echo -e "${YELLOW}• 操作提示${RESET} - 清晰的操作指导"
        echo -e "${YELLOW}• 继续询问${RESET} - 操作完成后询问是否继续"
        echo
        echo -e "${CYAN}现在可以运行以下命令体验新菜单：${RESET}"
        echo -e "${YELLOW}sudo ./scripts/security/ssh-config.sh${RESET}"
        echo
        return 0
    else
        echo
        echo -e "${RED}❌ 部分验证失败，请检查上述错误信息。${RESET}"
        return 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
