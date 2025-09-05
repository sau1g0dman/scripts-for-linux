#!/bin/bash

# =============================================================================
# 系统配置修改验证测试
# 作者: saul
# 版本: 1.0
# 描述: 验证install.sh中系统配置部分的修改是否正确
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

log_warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 测试系统配置修改
test_system_config_changes() {
    log_info "测试系统配置修改..."

    local test_passed=true

    # 检查是否移除了原有的mirrors.sh调用
    if grep -q 'execute_remote_script "system/mirrors.sh"' install.sh; then
        log_error "仍然包含原有的mirrors.sh脚本调用"
        test_passed=false
    else
        log_success "已移除原有的mirrors.sh脚本调用"
    fi

    # 检查是否添加了第三方脚本调用
    if grep -q 'https://linuxmirrors.cn/main.sh' install.sh; then
        log_success "已添加第三方软件源配置脚本"
    else
        log_error "未找到第三方软件源配置脚本调用"
        test_passed=false
    fi

    # 检查是否保留了时间同步配置
    if grep -q 'execute_remote_script "system/time-sync.sh"' install.sh; then
        log_success "时间同步配置保持不变"
    else
        log_error "时间同步配置被意外移除"
        test_passed=false
    fi

    # 检查是否添加了适当的日志输出
    if grep -q '使用第三方优化脚本' install.sh; then
        log_success "已添加第三方脚本使用说明日志"
    else
        log_error "缺少第三方脚本使用说明日志"
        test_passed=false
    fi

    # 检查是否添加了脚本来源日志
    if grep -q '脚本来源: https://linuxmirrors.cn/main.sh' install.sh; then
        log_success "已添加脚本来源说明日志"
    else
        log_error "缺少脚本来源说明日志"
        test_passed=false
    fi

    # 检查错误处理
    if grep -q 'set +e' install.sh && grep -q 'set -e' install.sh; then
        log_success "已添加适当的错误处理机制"
    else
        log_error "缺少适当的错误处理机制"
        test_passed=false
    fi

    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# 测试函数完整性
test_function_integrity() {
    log_info "测试install_system_config函数完整性..."

    local test_passed=true

    # 检查函数是否存在
    if grep -q "install_system_config()" install.sh; then
        log_success "install_system_config函数存在"
    else
        log_error "install_system_config函数不存在"
        test_passed=false
    fi

    # 检查函数调用是否保持不变
    local call_count=$(grep -c "install_system_config" install.sh)
    if [ $call_count -eq 4 ]; then
        log_success "函数调用次数正确 ($call_count 次)"
    else
        log_error "函数调用次数异常 ($call_count 次，期望4次)"
        test_passed=false
    fi

    # 检查success_count和total_count逻辑
    if grep -q "success_count=0" install.sh && grep -q "total_count=2" install.sh; then
        log_success "计数器逻辑保持正确"
    else
        log_error "计数器逻辑异常"
        test_passed=false
    fi

    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# 测试语法正确性
test_syntax() {
    log_info "测试脚本语法正确性..."

    if bash -n install.sh 2>/dev/null; then
        log_success "install.sh语法检查通过"
        return 0
    else
        log_error "install.sh语法检查失败"
        bash -n install.sh
        return 1
    fi
}

# 显示修改内容
show_changes() {
    log_info "显示主要修改内容..."

    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}主要修改内容：${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${GREEN}1. 移除原有调用：${RESET}"
    echo -e "${YELLOW}   - execute_remote_script \"system/mirrors.sh\" \"软件源配置\"${RESET}"
    echo
    echo -e "${GREEN}2. 添加第三方脚本调用：${RESET}"
    echo -e "${YELLOW}   - bash <(curl -sSL https://linuxmirrors.cn/main.sh)${RESET}"
    echo
    echo -e "${GREEN}3. 保持时间同步配置不变：${RESET}"
    echo -e "${YELLOW}   - execute_remote_script \"system/time-sync.sh\" \"时间同步配置\"${RESET}"
    echo
    echo -e "${GREEN}4. 添加错误处理和日志输出${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
}

# 主测试函数
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}系统配置修改验证测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo

    local test_count=0
    local passed_count=0

    # 显示修改内容
    show_changes

    # 测试1: 系统配置修改
    test_count=$((test_count + 1))
    if test_system_config_changes; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试2: 函数完整性
    test_count=$((test_count + 1))
    if test_function_integrity; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试3: 语法正确性
    test_count=$((test_count + 1))
    if test_syntax; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 显示测试结果
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}测试结果汇总${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${CYAN}总测试数: $test_count${RESET}"
    echo -e "${GREEN}通过测试: $passed_count${RESET}"
    echo -e "${RED}失败测试: $((test_count - passed_count))${RESET}"
    echo

    if [ $passed_count -eq $test_count ]; then
        log_success "所有测试通过！系统配置修改成功完成"
        return 0
    else
        log_error "部分测试失败，请检查上述错误信息"
        return 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
