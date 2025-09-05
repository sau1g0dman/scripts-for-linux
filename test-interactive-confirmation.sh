#!/bin/bash

# =============================================================================
# 交互式确认功能测试脚本
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# 初始化环境
init_environment

echo -e "${BLUE}=== 交互式确认功能测试 ===${RESET}"
echo

# 检查终端支持情况
if can_use_interactive_selection; then
    log_info "✅ 终端支持高级交互式选择器"
    log_info "操作说明："
    log_info "  - 使用 ←→ 箭头键或 a/d 键选择"
    log_info "  - 按回车键确认"
    log_info "  - 按 Ctrl+C 取消"
else
    log_warn "⚠️  终端不支持高级交互式选择器，将使用传统模式"
fi

echo

# 测试1：基本确认（默认否）
log_info "测试1：基本确认（默认选择：否）"
if ask_confirmation "是否继续测试？"; then
    log_success "用户选择：是"
else
    log_info "用户选择：否"
fi

echo

# 测试2：默认选择是
log_info "测试2：默认选择为是"
if ask_confirmation "是否安装示例软件？" "y"; then
    log_success "用户选择：是，开始安装..."
    log_info "模拟安装过程..."
    sleep 1
    log_success "安装完成！"
else
    log_info "用户选择：否，跳过安装"
fi

echo

# 测试3：连续确认
log_info "测试3：连续确认流程"
local tasks=("更新系统" "安装工具" "配置环境")
for task in "${tasks[@]}"; do
    if ask_confirmation "是否执行：${task}？" "y"; then
        log_success "执行：$task"
    else
        log_info "跳过：$task"
    fi
done

echo
log_success "所有测试完成！"
