#!/bin/bash

# =============================================================================
# 新功能集成验证测试
# 作者: saul
# 版本: 1.0
# 描述: 验证软件源管理功能和ZSH插件配置修复
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

# 测试软件源管理功能集成
test_mirrors_management() {
    log_info "测试软件源管理功能集成..."

    local test_passed=true

    # 检查是否添加了软件源管理菜单选项
    if grep -q "软件源管理" install.sh; then
        log_success "已添加软件源管理菜单选项"
    else
        log_error "缺少软件源管理菜单选项"
        test_passed=false
    fi

    # 检查是否添加了manage_mirrors函数
    if grep -q "manage_mirrors()" install.sh; then
        log_success "已添加manage_mirrors函数"
    else
        log_error "缺少manage_mirrors函数"
        test_passed=false
    fi

    # 检查三个软件源脚本的集成
    if grep -q "https://linuxmirrors.cn/main.sh" install.sh; then
        log_success "已集成脚本: https://linuxmirrors.cn/main.sh"
    else
        log_error "缺少脚本集成: https://linuxmirrors.cn/main.sh"
        test_passed=false
    fi

    if grep -q "https://linuxmirrors.cn/docker.sh" install.sh; then
        log_success "已集成脚本: https://linuxmirrors.cn/docker.sh"
    else
        log_error "缺少脚本集成: https://linuxmirrors.cn/docker.sh"
        test_passed=false
    fi

    if grep -q "\-\-only-registry" install.sh; then
        log_success "已集成参数: --only-registry"
    else
        log_error "缺少参数集成: --only-registry"
        test_passed=false
    fi

    # 检查菜单选项数量是否正确更新
    if grep -q "请选择 \[0-8\]" install.sh; then
        log_success "菜单选项数量已正确更新"
    else
        log_error "菜单选项数量未正确更新"
        test_passed=false
    fi

    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# 测试ZSH插件配置修复
test_zsh_plugin_config() {
    log_info "测试ZSH插件配置修复..."

    local test_passed=true

    # 检查是否修复了插件配置逻辑
    if grep -q "智能合并插件配置" scripts/shell/zsh-install.sh; then
        log_success "已添加智能插件配置合并逻辑"
    else
        log_error "缺少智能插件配置合并逻辑"
        test_passed=false
    fi

    # 检查是否包含标准插件列表
    local standard_plugins="git extract systemadmin zsh-interactive-cd systemd sudo docker ubuntu man command-not-found common-aliases docker-compose"
    if grep -q "$standard_plugins" scripts/shell/zsh-install.sh; then
        log_success "已包含标准插件列表"
    else
        log_error "缺少标准插件列表"
        test_passed=false
    fi

    # 检查是否正确处理现有插件配置
    if grep -q "在现有插件配置基础上添加新插件" scripts/shell/zsh-install.sh; then
        log_success "已添加现有插件配置处理逻辑"
    else
        log_error "缺少现有插件配置处理逻辑"
        test_passed=false
    fi

    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# 测试菜单结构完整性
test_menu_structure() {
    log_info "测试菜单结构完整性..."

    local test_passed=true

    # 检查主菜单选项
    local menu_options=("系统配置" "ZSH环境" "开发工具" "安全配置" "Docker环境" "软件源管理" "全部安装" "自定义安装")
    for option in "${menu_options[@]}"; do
        if grep -q "$option" install.sh; then
            log_success "菜单包含选项: $option"
        else
            log_error "菜单缺少选项: $option"
            test_passed=false
        fi
    done

    # 检查case语句是否正确更新
    if grep -A 20 "case \$choice in" install.sh | grep -q "6)" && \
       grep -A 20 "case \$choice in" install.sh | grep -q "manage_mirrors"; then
        log_success "case语句已正确更新"
    else
        log_error "case语句未正确更新"
        test_passed=false
    fi

    # 检查自定义安装是否包含软件源管理
    if grep -A 30 "custom_install()" install.sh | grep -q "manage_mirrors"; then
        log_success "自定义安装已包含软件源管理选项"
    else
        log_error "自定义安装缺少软件源管理选项"
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

    local test_passed=true

    # 测试install.sh语法
    if bash -n install.sh 2>/dev/null; then
        log_success "install.sh语法检查通过"
    else
        log_error "install.sh语法检查失败"
        bash -n install.sh
        test_passed=false
    fi

    # 测试zsh-install.sh语法
    if bash -n scripts/shell/zsh-install.sh 2>/dev/null; then
        log_success "zsh-install.sh语法检查通过"
    else
        log_error "zsh-install.sh语法检查失败"
        bash -n scripts/shell/zsh-install.sh
        test_passed=false
    fi

    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# 显示新功能说明
show_new_features() {
    log_info "显示新增功能说明..."

    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}新增功能说明：${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${GREEN}1. 软件源管理功能：${RESET}"
    echo -e "${YELLOW}   - 更换系统软件源 (linuxmirrors.cn/main.sh)${RESET}"
    echo -e "${YELLOW}   - Docker安装与换源 (linuxmirrors.cn/docker.sh)${RESET}"
    echo -e "${YELLOW}   - Docker镜像加速器 (linuxmirrors.cn/docker.sh --only-registry)${RESET}"
    echo
    echo -e "${GREEN}2. ZSH插件配置修复：${RESET}"
    echo -e "${YELLOW}   - 智能合并现有插件配置${RESET}"
    echo -e "${YELLOW}   - 保持标准插件列表格式${RESET}"
    echo -e "${YELLOW}   - 避免重复创建plugins=()行${RESET}"
    echo
    echo -e "${GREEN}3. 菜单结构优化：${RESET}"
    echo -e "${YELLOW}   - 新增软件源管理菜单选项${RESET}"
    echo -e "${YELLOW}   - 更新选项编号 [0-8]${RESET}"
    echo -e "${YELLOW}   - 自定义安装包含软件源管理${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
}

# 主测试函数
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}新功能集成验证测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo

    local test_count=0
    local passed_count=0

    # 显示新功能说明
    show_new_features

    # 测试1: 软件源管理功能
    test_count=$((test_count + 1))
    if test_mirrors_management; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试2: ZSH插件配置修复
    test_count=$((test_count + 1))
    if test_zsh_plugin_config; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试3: 菜单结构完整性
    test_count=$((test_count + 1))
    if test_menu_structure; then
        passed_count=$((passed_count + 1))
    fi
    echo

    # 测试4: 语法正确性
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
        log_success "所有测试通过！新功能集成成功完成"
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
