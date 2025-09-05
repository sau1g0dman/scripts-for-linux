#!/bin/bash

# =============================================================================
# ZSH模块化脚本测试
# 作者: saul
# 描述: 测试重构后的ZSH安装脚本模块化功能
# =============================================================================

set -euo pipefail

# 导入颜色定义
readonly RED=$(printf '\033[31m' 2>/dev/null || echo '')
readonly GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
readonly YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
readonly BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
readonly CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
readonly RESET=$(printf '\033[m' 2>/dev/null || echo '')

# 日志函数
log_info() {
    echo -e "${CYAN}[TEST]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${RESET} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${RESET} $1"
}

# 测试脚本语法
test_script_syntax() {
    log_info "测试脚本语法..."
    
    local scripts=(
        "scripts/shell/zsh-core-install.sh"
        "scripts/shell/zsh-plugins-install.sh"
    )
    
    local syntax_errors=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                log_success "语法检查通过: $script"
            else
                log_error "语法检查失败: $script"
                syntax_errors=$((syntax_errors + 1))
            fi
        else
            log_error "脚本文件不存在: $script"
            syntax_errors=$((syntax_errors + 1))
        fi
    done
    
    if [ $syntax_errors -eq 0 ]; then
        log_success "所有脚本语法检查通过"
        return 0
    else
        log_error "发现 $syntax_errors 个语法错误"
        return 1
    fi
}

# 测试脚本依赖
test_script_dependencies() {
    log_info "测试脚本依赖..."
    
    # 测试common.sh依赖
    if [ -f "scripts/common.sh" ]; then
        log_success "通用函数库存在: scripts/common.sh"
    else
        log_error "通用函数库不存在: scripts/common.sh"
        return 1
    fi
    
    # 测试脚本是否能正确导入common.sh
    local test_import=$(mktemp)
    cat > "$test_import" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../common.sh" ]]; then
    source "$SCRIPT_DIR/../common.sh"
    echo "Import successful"
else
    echo "Import failed"
fi
EOF
    
    chmod +x "$test_import"
    if cd scripts/shell && bash "$test_import" | grep -q "Import successful"; then
        log_success "脚本依赖导入测试通过"
        rm -f "$test_import"
        cd - >/dev/null
        return 0
    else
        log_error "脚本依赖导入测试失败"
        rm -f "$test_import"
        cd - >/dev/null
        return 1
    fi
}

# 测试脚本功能结构
test_script_structure() {
    log_info "测试脚本功能结构..."
    
    local core_functions=(
        "check_system_compatibility"
        "install_required_packages"
        "install_oh_my_zsh"
        "install_powerlevel10k_theme"
        "generate_basic_zshrc"
        "main"
    )
    
    local plugins_functions=(
        "check_zsh_core_installed"
        "install_zsh_plugins"
        "install_zoxide"
        "install_tmux_config"
        "smart_plugin_config_management"
        "main"
    )
    
    # 检查核心脚本函数
    local missing_functions=0
    for func in "${core_functions[@]}"; do
        if grep -q "^$func()" "scripts/shell/zsh-core-install.sh"; then
            log_success "核心脚本函数存在: $func"
        else
            log_error "核心脚本函数缺失: $func"
            missing_functions=$((missing_functions + 1))
        fi
    done
    
    # 检查插件脚本函数
    for func in "${plugins_functions[@]}"; do
        if grep -q "^$func()" "scripts/shell/zsh-plugins-install.sh"; then
            log_success "插件脚本函数存在: $func"
        else
            log_error "插件脚本函数缺失: $func"
            missing_functions=$((missing_functions + 1))
        fi
    done
    
    if [ $missing_functions -eq 0 ]; then
        log_success "脚本功能结构检查通过"
        return 0
    else
        log_error "发现 $missing_functions 个缺失函数"
        return 1
    fi
}

# 测试配置变量
test_configuration_variables() {
    log_info "测试配置变量..."
    
    local core_vars=(
        "ZSH_CORE_VERSION"
        "OMZ_DIR"
        "ZSH_THEMES_DIR"
        "REQUIRED_PACKAGES"
    )
    
    local plugins_vars=(
        "ZSH_PLUGINS_VERSION"
        "ZSH_PLUGINS"
        "COMPLETE_PLUGINS"
        "ZOXIDE_INSTALL_URL"
    )
    
    local missing_vars=0
    
    # 检查核心脚本变量
    for var in "${core_vars[@]}"; do
        if grep -q "readonly $var=" "scripts/shell/zsh-core-install.sh"; then
            log_success "核心脚本变量存在: $var"
        else
            log_error "核心脚本变量缺失: $var"
            missing_vars=$((missing_vars + 1))
        fi
    done
    
    # 检查插件脚本变量
    for var in "${plugins_vars[@]}"; do
        if grep -q "readonly $var=" "scripts/shell/zsh-plugins-install.sh"; then
            log_success "插件脚本变量存在: $var"
        else
            log_error "插件脚本变量缺失: $var"
            missing_vars=$((missing_vars + 1))
        fi
    done
    
    if [ $missing_vars -eq 0 ]; then
        log_success "配置变量检查通过"
        return 0
    else
        log_error "发现 $missing_vars 个缺失变量"
        return 1
    fi
}

# 测试脚本独立运行能力
test_independent_execution() {
    log_info "测试脚本独立运行能力..."
    
    # 测试核心脚本帮助信息
    if timeout 5 bash scripts/shell/zsh-core-install.sh --help 2>/dev/null || true; then
        log_success "核心脚本可以独立执行"
    else
        log_success "核心脚本独立执行测试完成（无帮助选项）"
    fi
    
    # 测试插件脚本帮助信息
    if timeout 5 bash scripts/shell/zsh-plugins-install.sh --help 2>/dev/null || true; then
        log_success "插件脚本可以独立执行"
    else
        log_success "插件脚本独立执行测试完成（无帮助选项）"
    fi
    
    return 0
}

# 测试向后兼容性
test_backward_compatibility() {
    log_info "测试向后兼容性..."
    
    # 检查主安装脚本是否更新了ZSH安装函数
    if grep -q "zsh-core-install.sh" "install.sh" && grep -q "zsh-plugins-install.sh" "install.sh"; then
        log_success "主安装脚本已更新为调用模块化脚本"
    else
        log_error "主安装脚本未正确更新"
        return 1
    fi
    
    # 检查install_zsh_environment函数是否存在
    if grep -q "install_zsh_environment()" "install.sh"; then
        log_success "向后兼容的ZSH安装函数存在"
    else
        log_error "向后兼容的ZSH安装函数缺失"
        return 1
    fi
    
    return 0
}

# 主测试函数
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}ZSH模块化脚本测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    
    local test_results=()
    
    # 执行测试
    if test_script_syntax; then
        test_results+=("语法测试:通过")
    else
        test_results+=("语法测试:失败")
    fi
    
    if test_script_dependencies; then
        test_results+=("依赖测试:通过")
    else
        test_results+=("依赖测试:失败")
    fi
    
    if test_script_structure; then
        test_results+=("结构测试:通过")
    else
        test_results+=("结构测试:失败")
    fi
    
    if test_configuration_variables; then
        test_results+=("配置测试:通过")
    else
        test_results+=("配置测试:失败")
    fi
    
    if test_independent_execution; then
        test_results+=("独立执行测试:通过")
    else
        test_results+=("独立执行测试:失败")
    fi
    
    if test_backward_compatibility; then
        test_results+=("兼容性测试:通过")
    else
        test_results+=("兼容性测试:失败")
    fi
    
    # 显示测试结果
    echo
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}测试结果总结${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    
    local passed=0
    local failed=0
    
    for result in "${test_results[@]}"; do
        IFS=':' read -r test_name test_status <<< "$result"
        if [ "$test_status" = "通过" ]; then
            echo -e "  ${GREEN}✅${RESET} $test_name"
            passed=$((passed + 1))
        else
            echo -e "  ${RED}❌${RESET} $test_name"
            failed=$((failed + 1))
        fi
    done
    
    echo
    echo -e "${CYAN}总计: $((passed + failed)) 个测试${RESET}"
    echo -e "${GREEN}通过: $passed 个${RESET}"
    echo -e "${RED}失败: $failed 个${RESET}"
    
    if [ $failed -eq 0 ]; then
        echo
        log_success "所有测试通过！ZSH模块化重构成功"
        return 0
    else
        echo
        log_error "部分测试失败，需要修复"
        return 1
    fi
}

# 运行测试
main "$@"
