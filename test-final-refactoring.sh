#!/bin/bash

# =============================================================================
# 最终重构验证测试脚本
# 用于验证所有传统用户确认交互都已替换为标准化形式
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

test_warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 检查脚本中是否还有传统的确认交互
check_traditional_confirmations() {
    test_log "检查传统确认交互..."
    
    local scripts=(
        "install.sh"
        "uninstall.sh"
        "scripts/security/ssh-config.sh"
        "scripts/security/ssh-keygen.sh"
        "scripts/containers/docker-install.sh"
        "scripts/containers/docker-push.sh"
        "scripts/shell/zsh-install.sh"
        "scripts/development/nvim-setup.sh"
    )
    
    local found_issues=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            # 检查是否还有自定义的 ask_confirmation 函数定义
            if grep -q "^ask_confirmation()" "$script"; then
                test_error "发现自定义 ask_confirmation 函数: $script"
                found_issues=$((found_issues + 1))
            fi
            
            # 检查是否还有传统的 echo + read + case 模式（排除菜单选择）
            if grep -A5 -B2 "echo.*\[.*\].*read\|read.*choice" "$script" | grep -v "请选择\|choice < /dev/tty" | grep -q "choice.*:-"; then
                test_warn "可能存在传统确认交互: $script"
                # 显示具体行
                grep -n -A3 -B1 "choice.*:-" "$script" | head -10
            fi
        else
            test_error "脚本不存在: $script"
            found_issues=$((found_issues + 1))
        fi
    done
    
    if [ $found_issues -eq 0 ]; then
        test_success "未发现传统确认交互"
        return 0
    else
        test_error "发现 $found_issues 个问题"
        return 1
    fi
}

# 检查标准化函数的使用
check_standardized_usage() {
    test_log "检查标准化函数使用..."
    
    local scripts=(
        "install.sh"
        "uninstall.sh"
        "scripts/containers/docker-install.sh"
        "scripts/containers/docker-push.sh"
        "scripts/shell/zsh-install.sh"
        "scripts/development/nvim-setup.sh"
    )
    
    local total_usage=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            local usage=$(grep -c "interactive_ask_confirmation" "$script" 2>/dev/null || echo "0")
            if [ $usage -gt 0 ]; then
                test_success "$script: 使用了 $usage 次 interactive_ask_confirmation"
                total_usage=$((total_usage + usage))
            fi
        fi
    done
    
    test_success "总计使用 interactive_ask_confirmation: $total_usage 次"
    return 0
}

# 检查 common.sh 导入
check_common_imports() {
    test_log "检查 common.sh 导入..."
    
    local scripts=(
        "install.sh"
        "uninstall.sh"
        "scripts/security/ssh-config.sh"
        "scripts/security/ssh-keygen.sh"
        "scripts/containers/docker-install.sh"
        "scripts/containers/docker-push.sh"
    )
    
    local missing_imports=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if grep -q "source.*common.sh\|source.*\$SCRIPT_DIR.*common.sh" "$script"; then
                test_success "$script: 正确导入 common.sh"
            else
                test_error "$script: 未找到 common.sh 导入"
                missing_imports=$((missing_imports + 1))
            fi
        fi
    done
    
    if [ $missing_imports -eq 0 ]; then
        test_success "所有脚本都正确导入了 common.sh"
        return 0
    else
        test_error "$missing_imports 个脚本缺少 common.sh 导入"
        return 1
    fi
}

# 语法检查
check_syntax() {
    test_log "执行语法检查..."
    
    local scripts=(
        "install.sh"
        "uninstall.sh"
        "scripts/security/ssh-config.sh"
        "scripts/security/ssh-keygen.sh"
        "scripts/containers/docker-install.sh"
        "scripts/containers/docker-push.sh"
        "scripts/shell/zsh-install.sh"
        "scripts/development/nvim-setup.sh"
    )
    
    local syntax_errors=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                test_success "语法检查通过: $script"
            else
                test_error "语法检查失败: $script"
                syntax_errors=$((syntax_errors + 1))
            fi
        fi
    done
    
    if [ $syntax_errors -eq 0 ]; then
        test_success "所有脚本语法检查通过"
        return 0
    else
        test_error "$syntax_errors 个脚本语法检查失败"
        return 1
    fi
}

# 主测试函数
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}最终重构验证测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    
    local tests_passed=0
    local tests_total=4
    
    # 运行测试
    if check_traditional_confirmations; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if check_standardized_usage; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if check_common_imports; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if check_syntax; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    # 显示测试结果
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}测试结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    
    if [ $tests_passed -eq $tests_total ]; then
        test_success "所有测试通过 ($tests_passed/$tests_total)"
        echo -e "${GREEN}✅ 重构完成！所有传统用户确认交互已成功替换为标准化形式。${RESET}"
        return 0
    else
        test_error "部分测试失败 ($tests_passed/$tests_total)"
        echo -e "${RED}❌ 重构存在问题，请检查失败的测试项。${RESET}"
        return 1
    fi
}

# 运行测试
main "$@"
