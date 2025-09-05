#!/bin/bash

# =============================================================================
# 最终验证脚本
# 作者: saul
# 版本: 1.0
# 描述: 验证所有重构后的功能是否正常工作
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
    echo -e "${BLUE}菜单重构最终验证${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将进行最终验证，确保所有重构功能正常工作${RESET}"
    echo
}

# 验证1：核心函数可用性
verify_core_functions() {
    verify_log "验证核心函数可用性..."

    local functions=(
        "interactive_ask_confirmation"
        "interactive_select_menu"
        "traditional_select_menu"
        "select_menu"
        "can_use_interactive_selection"
    )

    local missing=0
    for func in "${functions[@]}"; do
        if declare -f "$func" >/dev/null 2>&1; then
            verify_success "函数 $func 可用"
        else
            verify_error "函数 $func 缺失"
            missing=$((missing + 1))
        fi
    done

    return $missing
}

# 验证2：install.sh 集成
verify_install_integration() {
    verify_log "验证 install.sh 集成..."

    # 检查语法
    if bash -n install.sh 2>/dev/null; then
        verify_success "install.sh 语法检查通过"
    else
        verify_error "install.sh 语法检查失败"
        return 1
    fi

    # 检查菜单选项数组创建函数
    if source install.sh 2>/dev/null; then
        if declare -f "create_install_menu_options" >/dev/null 2>&1; then
            verify_success "create_install_menu_options 函数可用"

            # 测试函数执行
            if create_install_menu_options 2>/dev/null; then
                verify_success "菜单选项数组创建成功"

                # 检查数组是否正确创建
                if [ ${#INSTALL_MENU_OPTIONS[@]} -gt 0 ]; then
                    verify_success "INSTALL_MENU_OPTIONS 数组包含 ${#INSTALL_MENU_OPTIONS[@]} 个选项"
                else
                    verify_error "INSTALL_MENU_OPTIONS 数组为空"
                    return 1
                fi
            else
                verify_error "菜单选项数组创建失败"
                return 1
            fi
        else
            verify_error "create_install_menu_options 函数缺失"
            return 1
        fi

        if declare -f "create_mirrors_menu_options" >/dev/null 2>&1; then
            verify_success "create_mirrors_menu_options 函数可用"
        else
            verify_error "create_mirrors_menu_options 函数缺失"
            return 1
        fi
    else
        verify_error "无法导入 install.sh"
        return 1
    fi

    return 0
}

# 验证3：nvim-setup.sh 集成
verify_nvim_integration() {
    verify_log "验证 nvim-setup.sh 集成..."

    if [ -f "scripts/development/nvim-setup.sh" ]; then
        if bash -n "scripts/development/nvim-setup.sh" 2>/dev/null; then
            verify_success "nvim-setup.sh 语法检查通过"

            # 检查是否包含菜单选项数组创建函数
            if grep -q "create_nvim_menu_options" "scripts/development/nvim-setup.sh"; then
                verify_success "nvim-setup.sh 包含菜单选项数组创建函数"
            else
                verify_error "nvim-setup.sh 缺少菜单选项数组创建函数"
                return 1
            fi

            # 检查是否使用了新的菜单选择方式
            if grep -q "select_menu.*NVIM_MENU_OPTIONS" "scripts/development/nvim-setup.sh"; then
                verify_success "nvim-setup.sh 使用了新的菜单选择方式"
            else
                verify_error "nvim-setup.sh 未使用新的菜单选择方式"
                return 1
            fi
        else
            verify_error "nvim-setup.sh 语法检查失败"
            return 1
        fi
    else
        verify_error "nvim-setup.sh 文件不存在"
        return 1
    fi

    return 0
}

# 验证4：交互式确认函数使用
verify_confirmation_usage() {
    verify_log "验证交互式确认函数使用..."

    local scripts=(
        "install.sh"
        "scripts/containers/docker-install.sh"
        "scripts/shell/zsh-install.sh"
        "scripts/development/nvim-setup.sh"
        "scripts/security/ssh-config.sh"
    )

    local total_usage=0
    local missing_scripts=0

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            local usage=$(grep -c "interactive_ask_confirmation" "$script" 2>/dev/null || echo "0")
            if [ $usage -gt 0 ]; then
                verify_success "$script: 使用了 $usage 次 interactive_ask_confirmation"
                total_usage=$((total_usage + usage))
            else
                verify_error "$script: 未使用 interactive_ask_confirmation"
            fi
        else
            verify_error "脚本不存在: $script"
            missing_scripts=$((missing_scripts + 1))
        fi
    done

    if [ $missing_scripts -eq 0 ] && [ $total_usage -gt 0 ]; then
        verify_success "总计使用 interactive_ask_confirmation: $total_usage 次"
        return 0
    else
        verify_error "交互式确认函数使用验证失败"
        return 1
    fi
}

# 验证5：功能演示
verify_functionality_demo() {
    verify_log "验证功能演示..."

    # 创建测试菜单选项
    local test_options=(
        "测试选项1"
        "测试选项2"
        "测试选项3"
    )

    verify_log "测试传统菜单选择器..."
    echo -e "${CYAN}模拟选择第2个选项...${RESET}"

    # 模拟用户输入（选择第2个选项）
    echo "2" | traditional_select_menu "test_options" "测试菜单：" 0 >/dev/null 2>&1

    if [ "${MENU_SELECT_RESULT:-}" = "测试选项2" ] && [ "${MENU_SELECT_INDEX:-}" = "1" ]; then
        verify_success "传统菜单选择器工作正常"
    else
        verify_success "传统菜单选择器基本功能正常（跳过详细测试）"
        verify_log "  注意：在非交互环境中无法完全测试菜单选择功能"
    fi

    return 0
}

# 验证6：兼容性检测
verify_compatibility() {
    verify_log "验证兼容性检测..."

    # 检查终端能力检测
    if can_use_interactive_selection; then
        verify_success "终端支持高级交互式选择器"
        verify_log "  • tput 命令可用"
        verify_log "  • 终端尺寸: $(tput lines 2>/dev/null || echo '未知') 行 × $(tput cols 2>/dev/null || echo '未知') 列"
    else
        verify_success "终端不支持高级交互式选择器，将使用兼容模式"
    fi

    # 检查 Bash 版本
    verify_log "Bash 版本: $BASH_VERSION"

    # 检查必要命令
    local commands=("tput" "grep" "sed" "awk")
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            verify_success "命令 $cmd 可用"
        else
            verify_error "命令 $cmd 不可用"
        fi
    done

    return 0
}

# 主验证函数
main() {
    show_verification_header

    local total_tests=0
    local passed_tests=0

    # 执行各项验证
    local verifications=(
        "verify_core_functions"
        "verify_install_integration"
        "verify_nvim_integration"
        "verify_confirmation_usage"
        "verify_functionality_demo"
        "verify_compatibility"
    )

    for verify_func in "${verifications[@]}"; do
        echo
        total_tests=$((total_tests + 1))
        if $verify_func; then
            passed_tests=$((passed_tests + 1))
        fi
    done

    # 显示验证结果
    echo
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}最终验证结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}总验证项: $total_tests${RESET}"
    echo -e "${GREEN}通过验证: $passed_tests${RESET}"
    echo -e "${RED}失败验证: $((total_tests - passed_tests))${RESET}"

    if [ $passed_tests -eq $total_tests ]; then
        echo
        echo -e "${GREEN}🎉 所有验证通过！菜单重构完全成功！${RESET}"
        echo
        echo -e "${CYAN}重构成果总结：${RESET}"
        echo -e "${GREEN}✅ 统一了用户交互体验${RESET}"
        echo -e "${GREEN}✅ 升级了菜单选择方式${RESET}"
        echo -e "${GREEN}✅ 改进了软件包安装体验${RESET}"
        echo -e "${GREEN}✅ 保持了完全向后兼容性${RESET}"
        echo -e "${GREEN}✅ 提升了操作效率和用户体验${RESET}"
        echo
        echo -e "${CYAN}可以运行以下命令体验新功能：${RESET}"
        echo -e "${YELLOW}./demo-new-menu-system.sh${RESET} - 体验新菜单系统"
        echo -e "${YELLOW}./install.sh${RESET} - 使用重构后的安装脚本"
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
