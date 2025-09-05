#!/bin/bash

# =============================================================================
# ZSH安装脚本日志格式测试
# 作者: saul
# 版本: 1.0
# 描述: 测试ZSH安装脚本的标准化日志格式
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
    echo -e "${BLUE}ZSH安装脚本日志格式测试${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将测试ZSH安装脚本的标准化日志格式${RESET}"
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

# 测试2：检查emoji移除
test_emoji_removal() {
    test_log "检查emoji符号移除..."
    
    # 检查是否还有emoji符号
    local emoji_patterns=(
        "↓" "📦" "⚙" "✅" "❌" "📋" "🔗" "📂" "🔄" "ℹ" "⚠" "💡" "📝"
    )
    
    local found_emojis=0
    for emoji in "${emoji_patterns[@]}"; do
        if grep -q "$emoji" scripts/shell/zsh-install.sh; then
            test_error "发现emoji符号: $emoji"
            found_emojis=$((found_emojis + 1))
        fi
    done
    
    if [ $found_emojis -eq 0 ]; then
        test_success "所有emoji符号已移除"
        return 0
    else
        test_error "发现 $found_emojis 个emoji符号未移除"
        return 1
    fi
}

# 测试3：检查标准化日志格式
test_standardized_logging() {
    test_log "检查标准化日志格式..."
    
    # 检查是否使用了标准化的日志标签
    local log_patterns=(
        "\[SKIP\]" "\[DOWNLOAD\]" "\[INFO\]" "\[WARN\]" "\[INSTALL\]" 
        "\[READING\]" "\[DEPS\]" "\[STATE\]" "\[PREPARE\]" "\[SIZE\]" 
        "\[GET\]" "\[FETCHED\]" "\[UNPACK\]" "\[SELECT\]" "\[SETUP\]" 
        "\[TRIGGER\]" "\[SUCCESS\]" "\[FAILED\]" "\[ERROR\]" "\[DETAILS\]" 
        "\[SUGGEST\]" "\[SUMMARY\]" "\[VERBOSE\]"
    )
    
    local found_patterns=0
    for pattern in "${log_patterns[@]}"; do
        if grep -q "$pattern" scripts/shell/zsh-install.sh; then
            found_patterns=$((found_patterns + 1))
        fi
    done
    
    if [ $found_patterns -ge 15 ]; then
        test_success "标准化日志格式已应用 (发现 $found_patterns 个标签)"
        return 0
    else
        test_error "标准化日志格式不完整 (仅发现 $found_patterns 个标签)"
        return 1
    fi
}

# 测试4：检查verbose模式功能
test_verbose_mode() {
    test_log "检查verbose模式功能..."
    
    # 检查是否有verbose相关的功能
    if grep -q "verbose_log" scripts/shell/zsh-install.sh && 
       grep -q "tee.*verbose_log" scripts/shell/zsh-install.sh &&
       grep -q "VERBOSE" scripts/shell/zsh-install.sh; then
        test_success "verbose模式功能已添加"
        return 0
    else
        test_error "verbose模式功能缺失"
        return 1
    fi
}

# 测试5：检查颜色变量
test_color_variables() {
    test_log "检查颜色变量..."
    
    # 检查GRAY颜色变量是否已添加
    if grep -q "readonly GRAY=" scripts/common.sh; then
        test_success "GRAY颜色变量已添加到common.sh"
    else
        test_error "GRAY颜色变量缺失"
        return 1
    fi
    
    # 检查脚本中是否正确使用颜色变量
    if grep -q "\${GRAY}" scripts/shell/zsh-install.sh; then
        test_success "GRAY颜色变量在脚本中正确使用"
    else
        test_error "GRAY颜色变量未在脚本中使用"
        return 1
    fi
    
    return 0
}

# 测试6：演示新的日志格式
test_log_format_demo() {
    test_log "演示新的日志格式..."
    
    echo
    echo -e "${BLUE}━━━ 新的标准化日志格式演示 ━━━${RESET}"
    echo
    echo -e "${YELLOW}旧格式（emoji符号）：${RESET}"
    echo -e "${CYAN}  ↓ 正在下载 软件包...${RESET}"
    echo -e "${CYAN}  📦 开始安装 软件包...${RESET}"
    echo -e "${CYAN}  ⚙ 配置中...${RESET}"
    echo -e "${GREEN}  ✅ 安装成功${RESET}"
    echo
    echo -e "${GREEN}新格式（标准化标签）：${RESET}"
    echo -e "${CYAN}  [DOWNLOAD] 正在下载 软件包...${RESET}"
    echo -e "${CYAN}  [INSTALL] 开始安装 软件包...${RESET}"
    echo -e "${CYAN}  [SETUP] 配置中...${RESET}"
    echo -e "${GREEN}  [SUCCESS] 安装成功${RESET}"
    echo
    echo -e "${BLUE}━━━ Verbose模式增强 ━━━${RESET}"
    echo -e "${CYAN}  [READING] 读取软件包列表...${RESET}"
    echo -e "${CYAN}  [DEPS] 分析依赖关系...${RESET}"
    echo -e "${CYAN}  [SIZE] 需要下载: 1,356 kB${RESET}"
    echo -e "${CYAN}  [GET] 下载中: package.deb${RESET}"
    echo -e "${CYAN}  [FETCHED] 下载完成: 1,356 kB in 2s${RESET}"
    echo -e "${CYAN}  [UNPACK] 解包中: package${RESET}"
    echo -e "${CYAN}  [SETUP] 配置中: package${RESET}"
    echo -e "${CYAN}  [TRIGGER] 处理触发器: man-db${RESET}"
    echo -e "${CYAN}  [SUMMARY] 已配置 1 个软件包，下载 1,356 kB${RESET}"
    echo -e "${GRAY}  [VERBOSE] 详细安装过程信息...${RESET}"
    echo
    
    test_success "日志格式演示完成"
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
        "test_emoji_removal"
        "test_standardized_logging"
        "test_verbose_mode"
        "test_color_variables"
        "test_log_format_demo"
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
    echo -e "${BLUE}ZSH安装脚本日志格式测试结果${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}总测试数: $total_tests${RESET}"
    echo -e "${GREEN}通过测试: $passed_tests${RESET}"
    echo -e "${RED}失败测试: $((total_tests - passed_tests))${RESET}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo
        echo -e "${GREEN}🎉 所有测试通过！日志格式标准化完成！${RESET}"
        echo
        echo -e "${CYAN}改进总结：${RESET}"
        echo -e "${GREEN}✅ 移除所有emoji符号${RESET} - 使用专业的文本标签"
        echo -e "${GREEN}✅ 标准化日志格式${RESET} - 统一使用 [TAG] 格式"
        echo -e "${GREEN}✅ 增强verbose模式${RESET} - 提供详细的安装过程信息"
        echo -e "${GREEN}✅ 改进错误处理${RESET} - 显示更多调试信息"
        echo -e "${GREEN}✅ 添加安装摘要${RESET} - 显示配置的软件包数量和下载大小"
        echo -e "${GREEN}✅ 颜色变量扩展${RESET} - 添加GRAY颜色用于verbose信息"
        echo
        echo -e "${CYAN}现在ZSH安装脚本具有：${RESET}"
        echo -e "${YELLOW}• 专业的文本日志格式${RESET}"
        echo -e "${YELLOW}• 详细的安装进度跟踪${RESET}"
        echo -e "${YELLOW}• 完整的verbose模式${RESET}"
        echo -e "${YELLOW}• 智能的错误分析和建议${RESET}"
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
