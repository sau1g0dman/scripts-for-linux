#!/bin/bash

# =============================================================================
# ZSH安装脚本测试工具
# 用于本地测试和调试ZSH安装脚本的问题
# =============================================================================

set -euo pipefail

# 测试配置
readonly TEST_SCRIPT_URL="https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install.sh"
readonly TEST_LOG_FILE="/tmp/zsh-test-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$TEST_LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$TEST_LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$TEST_LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$TEST_LOG_FILE"
}

# 测试1: 检查脚本语法
test_script_syntax() {
    log_info "🔍 测试1: 检查脚本语法..."
    
    local temp_script=$(mktemp)
    
    if curl -fsSL "$TEST_SCRIPT_URL" -o "$temp_script"; then
        log_info "✅ 脚本下载成功"
        
        if bash -n "$temp_script"; then
            log_success "✅ 脚本语法检查通过"
            rm -f "$temp_script"
            return 0
        else
            log_error "❌ 脚本语法检查失败"
            rm -f "$temp_script"
            return 1
        fi
    else
        log_error "❌ 脚本下载失败"
        return 1
    fi
}

# 测试2: 检查BASH_SOURCE问题
test_bash_source_issue() {
    log_info "🔍 测试2: 检查BASH_SOURCE变量问题..."
    
    # 模拟curl | bash环境
    local test_code='
set -euo pipefail
echo "Testing BASH_SOURCE in pipe environment..."
echo "BASH_SOURCE[0]: ${BASH_SOURCE[0]:-UNDEFINED}"
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    echo "BASH_SOURCE check passed"
else
    echo "BASH_SOURCE check failed"
fi
'
    
    if echo "$test_code" | bash; then
        log_success "✅ BASH_SOURCE处理正确"
        return 0
    else
        log_error "❌ BASH_SOURCE处理有问题"
        return 1
    fi
}

# 测试3: 模拟远程执行环境
test_remote_execution() {
    log_info "🔍 测试3: 模拟远程执行环境..."
    
    # 创建简化的测试脚本
    local test_script=$(mktemp)
    cat > "$test_script" << 'EOF'
#!/bin/bash
set -euo pipefail

# 测试BASH_SOURCE处理
echo "Testing BASH_SOURCE handling..."
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    echo "✅ BASH_SOURCE check passed"
else
    echo "❌ BASH_SOURCE check failed"
    exit 1
fi

# 测试基本功能
echo "Testing basic functionality..."
if command -v curl >/dev/null 2>&1; then
    echo "✅ curl available"
else
    echo "❌ curl not available"
fi

echo "Test completed successfully"
EOF

    # 测试直接执行
    log_info "测试直接执行..."
    if bash "$test_script"; then
        log_success "✅ 直接执行成功"
    else
        log_error "❌ 直接执行失败"
        rm -f "$test_script"
        return 1
    fi
    
    # 测试管道执行
    log_info "测试管道执行..."
    if cat "$test_script" | bash; then
        log_success "✅ 管道执行成功"
    else
        log_error "❌ 管道执行失败"
        rm -f "$test_script"
        return 1
    fi
    
    rm -f "$test_script"
    return 0
}

# 测试4: 检查依赖项
test_dependencies() {
    log_info "🔍 测试4: 检查系统依赖项..."
    
    local required_commands=("curl" "git" "bash")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_info "✅ $cmd 可用"
        else
            log_error "❌ $cmd 不可用"
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -eq 0 ]; then
        log_success "✅ 所有依赖项都可用"
        return 0
    else
        log_error "❌ 缺少依赖项: ${missing_commands[*]}"
        return 1
    fi
}

# 测试5: 网络连接测试
test_network_connectivity() {
    log_info "🔍 测试5: 网络连接测试..."
    
    local test_urls=(
        "github.com"
        "raw.githubusercontent.com"
    )
    
    for url in "${test_urls[@]}"; do
        if curl -fsSL --connect-timeout 5 --max-time 10 "https://$url" >/dev/null 2>&1; then
            log_info "✅ $url 连接正常"
        else
            log_error "❌ $url 连接失败"
            return 1
        fi
    done
    
    log_success "✅ 网络连接测试通过"
    return 0
}

# 主测试函数
run_tests() {
    log_info "🚀 开始ZSH安装脚本测试..."
    log_info "📝 测试日志: $TEST_LOG_FILE"
    echo
    
    local test_results=()
    local failed_tests=0
    
    # 运行所有测试
    if test_dependencies; then
        test_results+=("✅ 依赖项检查")
    else
        test_results+=("❌ 依赖项检查")
        ((failed_tests++))
    fi
    
    if test_network_connectivity; then
        test_results+=("✅ 网络连接测试")
    else
        test_results+=("❌ 网络连接测试")
        ((failed_tests++))
    fi
    
    if test_bash_source_issue; then
        test_results+=("✅ BASH_SOURCE处理")
    else
        test_results+=("❌ BASH_SOURCE处理")
        ((failed_tests++))
    fi
    
    if test_remote_execution; then
        test_results+=("✅ 远程执行模拟")
    else
        test_results+=("❌ 远程执行模拟")
        ((failed_tests++))
    fi
    
    if test_script_syntax; then
        test_results+=("✅ 脚本语法检查")
    else
        test_results+=("❌ 脚本语法检查")
        ((failed_tests++))
    fi
    
    # 显示测试结果
    echo
    log_info "📋 测试结果摘要:"
    for result in "${test_results[@]}"; do
        log_info "   $result"
    done
    
    echo
    if [ $failed_tests -eq 0 ]; then
        log_success "🎉 所有测试通过！"
        log_info "💡 可以尝试运行实际的ZSH安装脚本"
        return 0
    else
        log_error "❌ $failed_tests 个测试失败"
        log_error "💡 请修复上述问题后再运行ZSH安装脚本"
        return 1
    fi
}

# 脚本入口点
main() {
    echo "================================================================"
    echo "🧪 ZSH安装脚本测试工具"
    echo "================================================================"
    echo
    
    run_tests
}

# 执行主函数
main "$@"
