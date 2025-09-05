#!/bin/bash

# =============================================================================
# 新菜单系统演示脚本
# 作者: saul
# 版本: 1.0
# 描述: 演示重构后的键盘导航菜单和标准化确认交互
# =============================================================================

set -euo pipefail

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# =============================================================================
# 演示函数
# =============================================================================

# 显示演示头部信息
show_demo_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}新菜单系统演示${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本演示将展示重构后的交互功能：${RESET}"
    echo -e "${CYAN}• 键盘导航菜单选择${RESET}"
    echo -e "${CYAN}• 标准化确认交互${RESET}"
    echo -e "${CYAN}• 自动兼容性检测${RESET}"
    echo
}

# 演示1：基本确认交互
demo_confirmation() {
    echo -e "${BLUE}━━━ 演示1：标准化确认交互 ━━━${RESET}"
    echo
    echo -e "${CYAN}特性：${RESET}"
    echo -e "• 支持左右箭头键选择是/否"
    echo -e "• 支持 a/d 键快速选择"
    echo -e "• 支持默认值设置"
    echo -e "• 统一的视觉样式"
    echo

    # 演示默认为"否"的确认
    if interactive_ask_confirmation "是否继续演示？（默认：否）" "false"; then
        echo -e "${GREEN}✅ 您选择了：是${RESET}"
    else
        echo -e "${YELLOW}❌ 您选择了：否${RESET}"
        return 1
    fi

    echo

    # 演示默认为"是"的确认
    if interactive_ask_confirmation "是否安装示例软件？（默认：是）" "true"; then
        echo -e "${GREEN}✅ 您选择了：是，开始模拟安装...${RESET}"
        echo -e "${CYAN}  [1/3] 下载软件包...${RESET}"
        sleep 1
        echo -e "${CYAN}  [2/3] 解压安装...${RESET}"
        sleep 1
        echo -e "${CYAN}  [3/3] 配置完成...${RESET}"
        sleep 1
        echo -e "${GREEN}✅ 安装完成！${RESET}"
    else
        echo -e "${YELLOW}❌ 您选择了：否，跳过安装${RESET}"
    fi

    return 0
}

# 演示2：键盘导航菜单
demo_menu_selection() {
    echo
    echo -e "${BLUE}━━━ 演示2：键盘导航菜单选择 ━━━${RESET}"
    echo
    echo -e "${CYAN}特性：${RESET}"
    echo -e "• 使用 ↑↓ 箭头键或 w/s/j/k 键导航"
    echo -e "• 实时高亮显示当前选项"
    echo -e "• 支持分页显示（选项过多时）"
    echo -e "• Enter 确认，Ctrl+C 取消"
    echo

    # 创建演示菜单选项
    local demo_menu_options=(
        "查看系统信息 - 显示当前系统详细信息"
        "网络连接测试 - 测试网络连接状态"
        "磁盘空间检查 - 查看磁盘使用情况"
        "内存使用情况 - 显示内存使用统计"
        "进程管理 - 查看和管理系统进程"
        "服务状态 - 检查系统服务运行状态"
        "日志查看 - 查看系统日志文件"
        "返回上级菜单 - 返回主演示菜单"
    )

    # 使用键盘导航菜单
    select_menu "demo_menu_options" "请选择要执行的操作：" 0

    local selected_index=$MENU_SELECT_INDEX
    local selected_option="$MENU_SELECT_RESULT"

    echo
    echo -e "${GREEN}✅ 您选择了：$selected_option${RESET}"
    echo -e "${CYAN}选项索引：$selected_index${RESET}"

    # 根据选择执行相应操作
    case $selected_index in
        0)  # 查看系统信息
            echo -e "${CYAN}正在获取系统信息...${RESET}"
            echo -e "${YELLOW}系统：$(uname -s)${RESET}"
            echo -e "${YELLOW}内核：$(uname -r)${RESET}"
            echo -e "${YELLOW}架构：$(uname -m)${RESET}"
            ;;
        1)  # 网络连接测试
            echo -e "${CYAN}正在测试网络连接...${RESET}"
            if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
                echo -e "${GREEN}✅ 网络连接正常${RESET}"
            else
                echo -e "${RED}❌ 网络连接异常${RESET}"
            fi
            ;;
        2)  # 磁盘空间检查
            echo -e "${CYAN}正在检查磁盘空间...${RESET}"
            df -h | head -5
            ;;
        3)  # 内存使用情况
            echo -e "${CYAN}正在检查内存使用情况...${RESET}"
            free -h
            ;;
        4)  # 进程管理
            echo -e "${CYAN}显示前10个进程...${RESET}"
            ps aux | head -11
            ;;
        5)  # 服务状态
            echo -e "${CYAN}检查关键服务状态...${RESET}"
            systemctl is-active ssh 2>/dev/null && echo -e "${GREEN}✅ SSH服务运行中${RESET}" || echo -e "${YELLOW}⚠️  SSH服务未运行${RESET}"
            ;;
        6)  # 日志查看
            echo -e "${CYAN}显示最近的系统日志...${RESET}"
            journalctl -n 5 --no-pager 2>/dev/null || echo -e "${YELLOW}⚠️  无法访问系统日志${RESET}"
            ;;
        7)  # 返回上级菜单
            echo -e "${CYAN}返回主演示菜单...${RESET}"
            ;;
    esac

    return 0
}

# 演示3：兼容性检测
demo_compatibility() {
    echo
    echo -e "${BLUE}━━━ 演示3：兼容性检测 ━━━${RESET}"
    echo
    echo -e "${CYAN}系统兼容性检测结果：${RESET}"

    # 检查终端能力
    if can_use_interactive_selection; then
        echo -e "${GREEN}✅ 终端支持高级交互式选择器${RESET}"
        echo -e "${CYAN}  • 支持 tput 命令${RESET}"
        echo -e "${CYAN}  • 支持光标控制${RESET}"
        echo -e "${CYAN}  • 支持颜色显示${RESET}"
    else
        echo -e "${YELLOW}⚠️  终端不支持高级交互式选择器${RESET}"
        echo -e "${CYAN}  • 将自动降级到传统文本模式${RESET}"
    fi

    # 检查终端尺寸
    local term_lines=$(tput lines 2>/dev/null || echo "未知")
    local term_cols=$(tput cols 2>/dev/null || echo "未知")
    echo -e "${CYAN}终端尺寸：${term_lines} 行 × ${term_cols} 列${RESET}"

    # 检查 Bash 版本
    echo -e "${CYAN}Bash 版本：$BASH_VERSION${RESET}"

    return 0
}

# 主演示菜单
main_demo_menu() {
    local main_menu_options=(
        "标准化确认交互演示 - 展示新的确认交互方式"
        "键盘导航菜单演示 - 展示新的菜单选择方式"
        "兼容性检测演示 - 展示系统兼容性检测"
        "查看重构总结 - 显示重构内容和改进点"
        "退出演示 - 结束演示程序"
    )

    while true; do
        echo
        echo -e "${BLUE}================================================================${RESET}"
        echo -e "${BLUE}主演示菜单${RESET}"
        echo -e "${BLUE}================================================================${RESET}"
        echo

        # 使用键盘导航菜单
        select_menu "main_menu_options" "请选择演示内容：" 0

        local selected_index=$MENU_SELECT_INDEX

        case $selected_index in
            0)  # 标准化确认交互演示
                demo_confirmation || continue
                ;;
            1)  # 键盘导航菜单演示
                demo_menu_selection
                ;;
            2)  # 兼容性检测演示
                demo_compatibility
                ;;
            3)  # 查看重构总结
                show_refactoring_summary
                ;;
            4)  # 退出演示
                echo -e "${GREEN}感谢使用新菜单系统演示！${RESET}"
                exit 0
                ;;
        esac

        echo
        if ! interactive_ask_confirmation "是否继续其他演示？" "true"; then
            echo -e "${GREEN}感谢使用新菜单系统演示！${RESET}"
            break
        fi
    done
}

# 显示重构总结
show_refactoring_summary() {
    echo
    echo -e "${BLUE}━━━ 重构总结 ━━━${RESET}"
    echo
    echo -e "${GREEN}✅ 已完成的改进：${RESET}"
    echo -e "${CYAN}1. 统一确认交互${RESET} - 所有 y/n 确认使用标准化函数"
    echo -e "${CYAN}2. 升级菜单选择${RESET} - 从数字输入升级为键盘导航"
    echo -e "${CYAN}3. 改进安装进度${RESET} - 详细的软件包安装进度显示"
    echo -e "${CYAN}4. 保持兼容性${RESET} - 自动检测并降级到传统模式"
    echo
    echo -e "${GREEN}📊 使用统计：${RESET}"
    echo -e "${CYAN}• interactive_ask_confirmation: 27 次调用${RESET}"
    echo -e "${CYAN}• 键盘导航菜单: 3 个主要菜单升级${RESET}"
    echo -e "${CYAN}• 脚本语法检查: 7 个脚本全部通过${RESET}"
    echo
    echo -e "${GREEN}🎯 用户体验提升：${RESET}"
    echo -e "${CYAN}• 减少输入错误 - 键盘导航避免数字输入错误${RESET}"
    echo -e "${CYAN}• 提高操作效率 - 箭头键比输入数字更快速${RESET}"
    echo -e "${CYAN}• 增强视觉反馈 - 高亮显示和实时进度${RESET}"
    echo -e "${CYAN}• 改善错误处理 - 智能错误分析和解决建议${RESET}"
}

# 主函数
main() {
    show_demo_header

    if interactive_ask_confirmation "是否开始新菜单系统演示？" "true"; then
        main_demo_menu
    else
        echo -e "${YELLOW}演示已取消${RESET}"
        exit 0
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
