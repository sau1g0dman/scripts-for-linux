#!/bin/bash

# 调试版本的安装脚本
set -e

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# 创建安装选项菜单数组
create_install_menu_options() {
    INSTALL_MENU_OPTIONS=(
        "常用软件安装 - 安装开发和系统管理常用软件"
        "系统配置 - 时间同步、系统优化等配置"
        "ZSH环境 - 安装和配置ZSH shell环境"
        "开发工具 - Neovim、Git配置等开发环境"
        "安全配置 - SSH、防火墙等安全设置"
        "Docker环境 - Docker安装和配置"
        "软件源管理 - 更换系统软件源和镜像"
        "全部安装 - 安装所有组件（逐个确认）"
        "自定义安装 - 与全部安装相同"
        "退出 - 退出安装程序"
    )
}

# 简化的测试函数
test_function() {
    echo "测试函数被调用了"
    return 0
}

# 主安装流程
main_install() {
    echo "开始 main_install 函数"
    
    # 创建菜单选项
    create_install_menu_options
    echo "菜单选项已创建，数组长度: ${#INSTALL_MENU_OPTIONS[@]}"

    while true; do
        echo
        echo -e "${BLUE}================================================================${RESET}"
        echo -e "${BLUE}调试版本 - 主菜单${RESET}"
        echo -e "${BLUE}================================================================${RESET}"
        echo

        echo "准备调用 select_menu 函数..."
        
        # 使用键盘导航菜单选择
        if select_menu "INSTALL_MENU_OPTIONS" "请选择要安装的组件：" 0; then
            echo "select_menu 调用成功"
            echo "MENU_SELECT_INDEX = $MENU_SELECT_INDEX"
            echo "MENU_SELECT_RESULT = $MENU_SELECT_RESULT"
        else
            echo "select_menu 调用失败"
            break
        fi

        local selected_index=$MENU_SELECT_INDEX
        echo "处理选择: $selected_index"

        case $selected_index in
            0|1|2|3|4|5|6|7|8)  # 所有选项都调用测试函数
                echo "调用测试函数..."
                test_function
                ;;
            9)  # 退出
                echo "用户选择退出"
                exit 0
                ;;
            *)
                echo "无效选择: $selected_index"
                continue
                ;;
        esac

        # 询问是否继续
        echo
        if interactive_ask_confirmation "是否返回主菜单继续其他操作？" "true"; then
            echo "用户选择继续"
            continue
        else
            echo "用户选择结束"
            break
        fi
    done
    
    echo "main_install 函数结束"
}

# 主函数
main() {
    echo "脚本开始执行"
    main_install
    echo "脚本执行完成"
}

# 执行主函数
main "$@"
