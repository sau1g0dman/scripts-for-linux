#!/bin/bash

# =============================================================================
# 标准化交互演示脚本
# 展示重构后的统一用户交互体验
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# 初始化环境
init_environment

# 显示脚本头部信息
show_header "标准化交互演示" "1.0" "展示重构后的统一用户交互体验"

echo -e "${CYAN}本演示将展示重构后的标准化用户交互功能${RESET}"
echo -e "${CYAN}所有确认提示现在都使用统一的交互式界面${RESET}"
echo

# 检查终端支持情况
if can_use_interactive_selection; then
    log_info "✅ 终端支持高级交互式选择器"
    echo -e "${BLUE}操作说明：${RESET}"
    echo -e "  ${CYAN}• 使用 ←→ 箭头键或 a/d 键选择${RESET}"
    echo -e "  ${CYAN}• 按回车键确认选择${RESET}"
    echo -e "  ${CYAN}• 按 Ctrl+C 取消操作${RESET}"
else
    log_warn "⚠️  终端不支持高级交互式选择器，将使用传统模式"
fi

echo

# 演示1：基本确认（默认否）
log_info "演示1：基本确认（默认选择：否）"
if interactive_ask_confirmation "是否继续演示？" "false"; then
    log_info "✅ 用户选择：是，继续演示"
else
    log_info "❌ 用户选择：否，演示结束"
    exit 0
fi

echo

# 演示2：默认选择是
log_info "演示2：默认选择为是"
if interactive_ask_confirmation "是否安装示例软件？" "true"; then
    log_info "✅ 用户选择：是，开始安装..."
    echo -e "${CYAN}  模拟安装过程...${RESET}"
    sleep 1
    log_info "✅ 安装完成！"
else
    log_info "❌ 用户选择：否，跳过安装"
fi

echo

# 演示3：连续确认流程
log_info "演示3：连续确认流程（模拟安装过程）"
local tasks=("更新系统软件包" "安装开发工具" "配置环境变量" "设置用户权限")
local defaults=("true" "true" "false" "false")

for i in "${!tasks[@]}"; do
    local task="${tasks[$i]}"
    local default="${defaults[$i]}"
    
    if interactive_ask_confirmation "是否执行：${task}？" "$default"; then
        log_info "✅ 执行：$task"
        echo -e "${CYAN}  正在执行 $task...${RESET}"
        sleep 0.5
        log_info "✅ 完成：$task"
    else
        log_info "⏭️  跳过：$task"
    fi
    echo
done

# 演示4：智能确认函数（自动选择最佳方式）
log_info "演示4：智能确认函数测试"
if ask_confirmation "使用智能确认函数，是否继续？" "y"; then
    log_info "✅ 智能确认函数工作正常"
else
    log_info "❌ 智能确认函数返回否"
fi

echo

# 演示5：错误处理演示
log_info "演示5：错误处理（可以按 Ctrl+C 测试取消功能）"
if interactive_ask_confirmation "这是一个可以取消的确认（试试按Ctrl+C）" "false"; then
    log_info "✅ 用户确认了操作"
else
    log_info "❌ 用户拒绝了操作"
fi

echo

# 显示完成信息
echo -e "${GREEN}================================================================${RESET}"
echo -e "${GREEN}演示完成！${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo
echo -e "${CYAN}重构成果总结：${RESET}"
echo -e "  ${GREEN}✅ 统一的用户交互体验${RESET}"
echo -e "  ${GREEN}✅ 支持键盘导航操作${RESET}"
echo -e "  ${GREEN}✅ 自动终端兼容性检测${RESET}"
echo -e "  ${GREEN}✅ 优雅的错误处理机制${RESET}"
echo -e "  ${GREEN}✅ 一致的视觉样式${RESET}"
echo
echo -e "${CYAN}技术改进：${RESET}"
echo -e "  ${BLUE}• 37个交互点已标准化${RESET}"
echo -e "  ${BLUE}• 移除了重复的自定义函数${RESET}"
echo -e "  ${BLUE}• 添加了智能回退机制${RESET}"
echo -e "  ${BLUE}• 保持了完全的向后兼容性${RESET}"
echo
echo -e "${YELLOW}感谢使用标准化交互系统！${RESET}"
