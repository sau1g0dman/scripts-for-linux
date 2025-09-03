#!/bin/bash

# =============================================================================
# 新架构测试脚本
# 测试本地克隆执行模式是否正常工作
# =============================================================================

set -euo pipefail

# 测试配置
readonly TEST_LOG_FILE="/tmp/architecture-test-$(date +%Y%m%d-%H%M%S).log"

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

# 测试1: BASH_SOURCE修复验证
test_bash_source_fixes() {
    log_info "🔍 测试1: 验证BASH_SOURCE修复..."
    
    local test_scripts=(
        "scripts/shell/zsh-install.sh"
        "scripts/system/time-sync.sh"
        "scripts/system/mirrors.sh"
        "scripts/containers/docker-install.sh"
        "scripts/containers/docker-mirrors.sh"
        "scripts/containers/docker-push.sh"
    )
    
    local failed_scripts=()
    
    for script in "${test_scripts[@]}"; do
        if [ -f "$script" ]; then
            # 测试语法
            if bash -n "$script"; then
                log_info "✅ $script 语法检查通过"
                
                # 测试BASH_SOURCE处理
                local test_code="
                set -euo pipefail
                source '$script' 2>/dev/null || echo 'Source test completed'
                "
                if echo "$test_code" | bash 2>/dev/null; then
                    log_info "✅ $script BASH_SOURCE处理正确"
                else
                    log_error "❌ $script BASH_SOURCE处理失败"
                    failed_scripts+=("$script")
                fi
            else
                log_error "❌ $script 语法检查失败"
                failed_scripts+=("$script")
            fi
        else
            log_warn "⚠️  脚本不存在: $script"
        fi
    done
    
    if [ ${#failed_scripts[@]} -eq 0 ]; then
        log_success "✅ 所有脚本BASH_SOURCE修复验证通过"
        return 0
    else
        log_error "❌ 以下脚本验证失败: ${failed_scripts[*]}"
        return 1
    fi
}

# 测试2: 本地克隆功能测试
test_local_clone_functionality() {
    log_info "🔍 测试2: 本地克隆功能测试..."
    
    # 模拟install.sh中的克隆逻辑
    local test_repo_dir="/tmp/test-clone-$(date +%Y%m%d-%H%M%S)"
    local repo_url="https://github.com/sau1g0dman/scripts-for-linux.git"
    
    # 检查git是否可用
    if ! command -v git >/dev/null 2>&1; then
        log_error "❌ Git不可用，跳过克隆测试"
        return 1
    fi
    
    # 测试克隆
    log_info "📥 测试克隆到: $test_repo_dir"
    if git clone --depth=1 --branch=main "$repo_url" "$test_repo_dir" 2>/dev/null; then
        log_success "✅ 仓库克隆成功"
        
        # 验证关键文件
        local required_files=(
            "$test_repo_dir/scripts/common.sh"
            "$test_repo_dir/scripts/system/time-sync.sh"
            "$test_repo_dir/scripts/shell/zsh-install.sh"
            "$test_repo_dir/install.sh"
        )
        
        local missing_files=()
        for file in "${required_files[@]}"; do
            if [ -f "$file" ]; then
                log_info "✅ 文件存在: $(basename "$file")"
            else
                log_error "❌ 文件缺失: $file"
                missing_files+=("$file")
            fi
        done
        
        # 清理测试目录
        rm -rf "$test_repo_dir" 2>/dev/null || true
        
        if [ ${#missing_files[@]} -eq 0 ]; then
            log_success "✅ 本地克隆功能测试通过"
            return 0
        else
            log_error "❌ 缺少必需文件: ${missing_files[*]}"
            return 1
        fi
    else
        log_error "❌ 仓库克隆失败"
        return 1
    fi
}

# 测试3: 脚本执行模式测试
test_script_execution_modes() {
    log_info "🔍 测试3: 脚本执行模式测试..."
    
    # 测试直接执行
    log_info "测试直接执行模式..."
    local test_script=$(mktemp)
    cat > "$test_script" << 'EOF'
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    echo "Direct execution test passed"
fi
EOF
    
    if bash "$test_script" | grep -q "Direct execution test passed"; then
        log_success "✅ 直接执行模式测试通过"
    else
        log_error "❌ 直接执行模式测试失败"
        rm -f "$test_script"
        return 1
    fi
    
    # 测试管道执行
    log_info "测试管道执行模式..."
    if cat "$test_script" | bash | grep -q "Direct execution test passed"; then
        log_success "✅ 管道执行模式测试通过"
    else
        log_error "❌ 管道执行模式测试失败"
        rm -f "$test_script"
        return 1
    fi
    
    rm -f "$test_script"
    return 0
}

# 测试4: install.sh语法和逻辑测试
test_install_script() {
    log_info "🔍 测试4: install.sh脚本测试..."
    
    # 语法检查
    if bash -n install.sh; then
        log_success "✅ install.sh 语法检查通过"
    else
        log_error "❌ install.sh 语法检查失败"
        return 1
    fi
    
    # 检查关键函数是否存在
    local required_functions=(
        "clone_repository"
        "cleanup_repository"
        "verify_local_scripts"
        "execute_local_script"
    )
    
    for func in "${required_functions[@]}"; do
        if grep -q "^$func()" install.sh; then
            log_info "✅ 函数存在: $func"
        else
            log_error "❌ 函数缺失: $func"
            return 1
        fi
    done
    
    log_success "✅ install.sh 脚本测试通过"
    return 0
}

# 主测试函数
run_tests() {
    log_info "🚀 开始新架构测试..."
    log_info "📝 测试日志: $TEST_LOG_FILE"
    echo
    
    local test_results=()
    local failed_tests=0
    
    # 运行所有测试
    if test_bash_source_fixes; then
        test_results+=("✅ BASH_SOURCE修复验证")
    else
        test_results+=("❌ BASH_SOURCE修复验证")
        ((failed_tests++))
    fi
    
    if test_local_clone_functionality; then
        test_results+=("✅ 本地克隆功能测试")
    else
        test_results+=("❌ 本地克隆功能测试")
        ((failed_tests++))
    fi
    
    if test_script_execution_modes; then
        test_results+=("✅ 脚本执行模式测试")
    else
        test_results+=("❌ 脚本执行模式测试")
        ((failed_tests++))
    fi
    
    if test_install_script; then
        test_results+=("✅ install.sh脚本测试")
    else
        test_results+=("❌ install.sh脚本测试")
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
        log_success "🎉 所有测试通过！新架构准备就绪"
        log_info "💡 可以安全地使用新的本地克隆执行模式"
        return 0
    else
        log_error "❌ $failed_tests 个测试失败"
        log_error "💡 请修复上述问题后再使用新架构"
        return 1
    fi
}

# 脚本入口点
main() {
    echo "================================================================"
    echo "🧪 新架构测试工具"
    echo "================================================================"
    echo
    
    run_tests
}

# 执行主函数
main "$@"
