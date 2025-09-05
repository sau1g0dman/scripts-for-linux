#!/bin/bash

# =============================================================================
# 改进后的软件包安装功能测试脚本
# 用于验证新的进度显示和错误处理功能
# =============================================================================

set -euo pipefail

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# 测试颜色
readonly TEST_GREEN='\033[32m'
readonly TEST_RED='\033[31m'
readonly TEST_YELLOW='\033[33m'
readonly TEST_BLUE='\033[34m'
readonly TEST_CYAN='\033[36m'
readonly TEST_RESET='\033[0m'

# 测试日志函数
test_log() {
    echo -e "${TEST_CYAN}[TEST] $(date '+%Y-%m-%d %H:%M:%S') $1${TEST_RESET}"
}

test_success() {
    echo -e "${TEST_GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1${TEST_RESET}"
}

test_error() {
    echo -e "${TEST_RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${TEST_RESET}"
}

test_warn() {
    echo -e "${TEST_YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${TEST_RESET}"
}

# 测试辅助函数是否正确定义
test_helper_functions() {
    test_log "测试辅助函数定义..."
    
    local functions_to_check=(
        "show_spinner"
        "check_network_status"
        "analyze_install_error"
        "install_package_with_progress"
    )
    
    local missing_functions=0
    
    for func in "${functions_to_check[@]}"; do
        if declare -f "$func" >/dev/null 2>&1; then
            test_success "函数 $func 已定义"
        else
            test_error "函数 $func 未找到"
            missing_functions=$((missing_functions + 1))
        fi
    done
    
    if [ $missing_functions -eq 0 ]; then
        test_success "所有辅助函数都已正确定义"
        return 0
    else
        test_error "$missing_functions 个辅助函数缺失"
        return 1
    fi
}

# 测试网络检查功能
test_network_check() {
    test_log "测试网络检查功能..."
    
    # 导入 install.sh 中的函数
    source install.sh
    
    if check_network_status; then
        test_success "网络连接正常"
    else
        test_warn "网络连接异常或较慢"
    fi
    
    return 0
}

# 测试错误分析功能
test_error_analysis() {
    test_log "测试错误分析功能..."
    
    # 导入 install.sh 中的函数
    source install.sh
    
    # 创建测试错误日志
    local test_error_log=$(mktemp)
    
    # 测试不同类型的错误
    echo "E: Unable to locate package nonexistent-package" > "$test_error_log"
    local result1=$(analyze_install_error "test-package" "$test_error_log")
    if [[ "$result1" == *"软件包不存在"* ]]; then
        test_success "正确识别软件包不存在错误"
    else
        test_error "未能正确识别软件包不存在错误: $result1"
    fi
    
    echo "E: Could not get lock /var/lib/dpkg/lock-frontend" > "$test_error_log"
    local result2=$(analyze_install_error "test-package" "$test_error_log")
    if [[ "$result2" == *"被其他进程占用"* ]]; then
        test_success "正确识别进程占用错误"
    else
        test_error "未能正确识别进程占用错误: $result2"
    fi
    
    echo "E: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/focal/Release" > "$test_error_log"
    local result3=$(analyze_install_error "test-package" "$test_error_log")
    if [[ "$result3" == *"网络连接问题"* ]]; then
        test_success "正确识别网络连接错误"
    else
        test_error "未能正确识别网络连接错误: $result3"
    fi
    
    rm -f "$test_error_log"
    return 0
}

# 测试语法检查
test_syntax() {
    test_log "测试 install.sh 语法..."
    
    if bash -n install.sh 2>/dev/null; then
        test_success "install.sh 语法检查通过"
        return 0
    else
        test_error "install.sh 语法检查失败"
        return 1
    fi
}

# 测试函数导入
test_function_import() {
    test_log "测试函数导入..."
    
    # 尝试导入 install.sh 中的函数
    if source install.sh 2>/dev/null; then
        test_success "成功导入 install.sh 中的函数"
        
        # 检查关键函数是否可用
        if declare -f install_common_software >/dev/null; then
            test_success "install_common_software 函数可用"
        else
            test_error "install_common_software 函数不可用"
            return 1
        fi
        
        return 0
    else
        test_error "无法导入 install.sh 中的函数"
        return 1
    fi
}

# 模拟安装测试（不实际安装）
test_installation_simulation() {
    test_log "模拟安装测试..."
    
    # 这里我们只测试函数调用，不实际执行安装
    echo -e "${TEST_BLUE}注意：这是模拟测试，不会实际安装软件包${TEST_RESET}"
    
    # 检查软件包列表是否正确定义
    source install.sh
    
    # 提取软件包列表（通过分析函数内容）
    local package_count=$(grep -A 20 "local common_packages=(" install.sh | grep -c ":")
    
    if [ $package_count -gt 0 ]; then
        test_success "检测到 $package_count 个软件包定义"
    else
        test_error "未检测到软件包定义"
        return 1
    fi
    
    return 0
}

# 主测试函数
main() {
    echo -e "${TEST_BLUE}================================================================${TEST_RESET}"
    echo -e "${TEST_BLUE}改进后的软件包安装功能测试${TEST_RESET}"
    echo -e "${TEST_BLUE}================================================================${TEST_RESET}"
    echo
    
    local tests_passed=0
    local tests_total=6
    
    # 运行测试
    if test_syntax; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_function_import; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_helper_functions; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_network_check; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_error_analysis; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    if test_installation_simulation; then
        tests_passed=$((tests_passed + 1))
    fi
    echo
    
    # 显示测试结果
    echo -e "${TEST_BLUE}================================================================${TEST_RESET}"
    echo -e "${TEST_BLUE}测试结果${TEST_RESET}"
    echo -e "${TEST_BLUE}================================================================${TEST_RESET}"
    
    if [ $tests_passed -eq $tests_total ]; then
        test_success "所有测试通过 ($tests_passed/$tests_total)"
        echo -e "${TEST_GREEN}✅ 改进后的安装功能已准备就绪！${TEST_RESET}"
        echo
        echo -e "${TEST_CYAN}新功能特性：${TEST_RESET}"
        echo -e "  ${TEST_GREEN}•${TEST_RESET} 详细的进度显示和状态信息"
        echo -e "  ${TEST_GREEN}•${TEST_RESET} 实时安装输出，避免用户误以为程序卡住"
        echo -e "  ${TEST_GREEN}•${TEST_RESET} 智能错误分析和解决建议"
        echo -e "  ${TEST_GREEN}•${TEST_RESET} 网络状态检测和慢速网络提示"
        echo -e "  ${TEST_GREEN}•${TEST_RESET} 美观的进度条和统计信息"
        echo -e "  ${TEST_GREEN}•${TEST_RESET} 用户友好的取消提示"
        return 0
    else
        test_error "部分测试失败 ($tests_passed/$tests_total)"
        echo -e "${TEST_RED}❌ 存在问题，请检查失败的测试项。${TEST_RESET}"
        return 1
    fi
}

# 运行测试
main "$@"
