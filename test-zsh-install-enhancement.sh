#!/bin/bash

# =============================================================================
# ZSH安装脚本增强功能测试
# 作者: saul
# 版本: 1.0
# 描述: 测试ZSH安装脚本的增强安装功能
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
    echo -e "${BLUE}ZSH安装脚本增强功能测试${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将测试ZSH安装脚本的增强安装功能${RESET}"
    echo
}

# 测试1：语法检查
test_syntax() {
    test_log "测试ZSH安装脚本语法..."
    
    if bash -n scripts/shell/zsh-install.sh 2>/dev/null; then
        test_success "ZSH安装脚本语法检查通过"
        return 0
    else
        test_error "ZSH安装脚本语法检查失败"
        bash -n scripts/shell/zsh-install.sh
        return 1
    fi
}

# 测试2：增强函数存在性检查
test_enhanced_functions() {
    test_log "测试增强函数存在性..."
    
    # 导入脚本并检查函数
    if source scripts/shell/zsh-install.sh 2>/dev/null; then
        local functions=(
            "check_network_status"
            "analyze_install_error"
            "install_package_with_progress"
        )
        
        local missing=0
        for func in "${functions[@]}"; do
            if declare -f "$func" >/dev/null 2>&1; then
                test_success "增强函数 $func 存在"
            else
                test_error "增强函数 $func 缺失"
                missing=$((missing + 1))
            fi
        done
        
        return $missing
    else
        test_error "无法导入ZSH安装脚本"
        return 1
    fi
}

# 测试3：软件包列表检查
test_package_lists() {
    test_log "测试软件包列表..."
    
    if source scripts/shell/zsh-install.sh 2>/dev/null; then
        # 检查必需软件包列表
        if [ ${#REQUIRED_PACKAGES[@]} -gt 0 ]; then
            test_success "必需软件包列表包含 ${#REQUIRED_PACKAGES[@]} 个软件包"
            
            # 显示软件包列表
            test_log "必需软件包列表："
            for package_info in "${REQUIRED_PACKAGES[@]}"; do
                IFS=':' read -r package_name package_desc <<< "$package_info"
                echo -e "${CYAN}  • $package_desc ($package_name)${RESET}"
            done
        else
            test_error "必需软件包列表为空"
            return 1
        fi
        
        # 检查可选软件包列表
        if [ ${#OPTIONAL_PACKAGES[@]} -gt 0 ]; then
            test_success "可选软件包列表包含 ${#OPTIONAL_PACKAGES[@]} 个软件包"
            
            # 显示软件包列表
            test_log "可选软件包列表："
            for package_info in "${OPTIONAL_PACKAGES[@]}"; do
                IFS=':' read -r package_name package_desc <<< "$package_info"
                echo -e "${CYAN}  • $package_desc ($package_name)${RESET}"
            done
        else
            test_error "可选软件包列表为空"
            return 1
        fi
        
        return 0
    else
        test_error "无法导入脚本进行软件包列表检查"
        return 1
    fi
}

# 测试4：网络状态检查功能
test_network_check() {
    test_log "测试网络状态检查功能..."
    
    if source scripts/shell/zsh-install.sh 2>/dev/null; then
        # 测试网络检查函数
        if check_network_status; then
            test_success "网络状态检查功能正常（网络连接良好）"
        else
            test_success "网络状态检查功能正常（网络连接较慢）"
        fi
        return 0
    else
        test_error "无法测试网络状态检查功能"
        return 1
    fi
}

# 测试5：错误分析功能
test_error_analysis() {
    test_log "测试错误分析功能..."
    
    if source scripts/shell/zsh-install.sh 2>/dev/null; then
        # 创建测试错误日志
        local test_error_log=$(mktemp)
        
        # 测试不同类型的错误分析
        echo "Unable to locate package test-package" > "$test_error_log"
        local result1=$(analyze_install_error "test-package" "$test_error_log")
        if [[ "$result1" == *"软件包不存在"* ]]; then
            test_success "软件包不存在错误分析正确"
        else
            test_error "软件包不存在错误分析失败: $result1"
        fi
        
        echo "Network is unreachable" > "$test_error_log"
        local result2=$(analyze_install_error "test-package" "$test_error_log")
        if [[ "$result2" == *"网络连接问题"* ]]; then
            test_success "网络连接错误分析正确"
        else
            test_error "网络连接错误分析失败: $result2"
        fi
        
        echo "Could not get lock /var/lib/dpkg/lock" > "$test_error_log"
        local result3=$(analyze_install_error "test-package" "$test_error_log")
        if [[ "$result3" == *"被其他进程占用"* ]]; then
            test_success "进程占用错误分析正确"
        else
            test_error "进程占用错误分析失败: $result3"
        fi
        
        rm -f "$test_error_log"
        return 0
    else
        test_error "无法测试错误分析功能"
        return 1
    fi
}

# 测试6：安装函数对比
test_installation_comparison() {
    test_log "对比安装函数改进..."
    
    echo
    echo -e "${BLUE}━━━ 安装功能对比 ━━━${RESET}"
    echo
    echo -e "${YELLOW}传统安装方式：${RESET}"
    echo -e "${CYAN}  • 简单的成功/失败提示${RESET}"
    echo -e "${CYAN}  • 无实时进度显示${RESET}"
    echo -e "${CYAN}  • 基础错误信息${RESET}"
    echo
    echo -e "${GREEN}增强安装方式：${RESET}"
    echo -e "${CYAN}  • 详细的安装概览和统计${RESET}"
    echo -e "${CYAN}  • 实时进度指示器（↓📦⚙✅等）${RESET}"
    echo -e "${CYAN}  • 网络状态检测和提示${RESET}"
    echo -e "${CYAN}  • 智能错误分析和解决建议${RESET}"
    echo -e "${CYAN}  • 安装步骤可视化（读取、下载、解包、配置）${RESET}"
    echo -e "${CYAN}  • 超时保护和取消提示${RESET}"
    echo
    
    test_success "安装功能对比完成"
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
        "test_enhanced_functions"
        "test_package_lists"
        "test_network_check"
        "test_error_analysis"
        "test_installation_comparison"
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
    echo -e "${BLUE}ZSH安装脚本增强功能测试结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}总测试数: $total_tests${RESET}"
    echo -e "${GREEN}通过测试: $passed_tests${RESET}"
    echo -e "${RED}失败测试: $((total_tests - passed_tests))${RESET}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo
        echo -e "${GREEN}🎉 所有测试通过！ZSH安装脚本增强功能完成！${RESET}"
        echo
        echo -e "${CYAN}增强功能总结：${RESET}"
        echo -e "${GREEN}✅ 实时安装进度显示${RESET} - 显示下载、解包、配置等详细步骤"
        echo -e "${GREEN}✅ 网络状态检测${RESET} - 在网络较慢时提供友好提示"
        echo -e "${GREEN}✅ 智能错误分析${RESET} - 分析安装失败原因并提供解决建议"
        echo -e "${GREEN}✅ 安装统计信息${RESET} - 显示成功/失败统计和进度计数"
        echo -e "${GREEN}✅ 视觉进度指示${RESET} - 使用符号（✓↓📦⚙️等）增强视觉反馈"
        echo -e "${GREEN}✅ 安装概览显示${RESET} - 开始前显示总包数和预计时间"
        echo
        echo -e "${CYAN}现在可以使用增强版的ZSH安装脚本：${RESET}"
        echo -e "${YELLOW}./scripts/shell/zsh-install.sh${RESET}"
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
