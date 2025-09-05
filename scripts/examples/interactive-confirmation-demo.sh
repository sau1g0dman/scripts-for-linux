#!/bin/bash

# =============================================================================
# 交互式确认功能演示脚本
# 作者: saul
# 版本: 1.0
# 描述: 演示新的交互式确认功能的使用方法
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# =============================================================================
# 演示函数
# =============================================================================

# 演示基本用法
demo_basic_usage() {
    echo -e "${BLUE}=== 基本用法演示 ===${RESET}"
    echo
    
    # 默认选择"否"
    if ask_confirmation "是否继续安装Docker？"; then
        log_info "用户选择：是，继续安装Docker"
    else
        log_info "用户选择：否，取消安装"
    fi
    
    echo
    
    # 默认选择"是"
    if ask_confirmation "是否更新系统软件包？" "y"; then
        log_info "用户选择：是，更新系统软件包"
    else
        log_info "用户选择：否，跳过更新"
    fi
}

# 演示在实际场景中的应用
demo_real_scenario() {
    echo -e "${BLUE}=== 实际应用场景演示 ===${RESET}"
    echo
    
    # 模拟Docker安装场景
    log_info "检查Docker安装状态..."
    
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker已安装: $(docker --version)"
        
        if ask_confirmation "Docker已安装，是否重新安装？"; then
            log_info "开始重新安装Docker..."
            # 这里会是实际的安装逻辑
            log_info "Docker重新安装完成"
        else
            log_info "跳过Docker安装"
        fi
    else
        log_info "Docker未安装"
        
        if ask_confirmation "是否安装Docker？" "y"; then
            log_info "开始安装Docker..."
            # 这里会是实际的安装逻辑
            log_info "Docker安装完成"
            
            if ask_confirmation "是否配置Docker镜像加速？" "y"; then
                log_info "配置Docker镜像加速..."
                log_info "镜像加速配置完成"
            fi
        else
            log_info "跳过Docker安装"
        fi
    fi
}

# 演示多个连续确认
demo_multiple_confirmations() {
    echo -e "${BLUE}=== 多个连续确认演示 ===${RESET}"
    echo
    
    local tasks=("更新系统" "安装基础工具" "配置SSH" "设置防火墙" "重启系统")
    local task_defaults=("y" "y" "n" "n" "n")
    
    for i in "${!tasks[@]}"; do
        local task="${tasks[$i]}"
        local default="${task_defaults[$i]}"
        
        if ask_confirmation "是否执行：${task}？" "$default"; then
            log_info "执行任务：$task"
            # 模拟任务执行
            sleep 1
            log_info "任务完成：$task"
        else
            log_info "跳过任务：$task"
        fi
        echo
    done
}

# 演示错误处理
demo_error_handling() {
    echo -e "${BLUE}=== 错误处理演示 ===${RESET}"
    echo
    
    log_info "提示：在交互式选择器中按 Ctrl+C 可以取消操作"
    
    # 设置陷阱来捕获中断信号
    trap 'log_warn "用户取消了操作"; return 1' INT
    
    if ask_confirmation "这是一个可以取消的确认（试试按Ctrl+C）"; then
        log_info "用户确认了操作"
    else
        log_info "用户拒绝了操作"
    fi
    
    # 重置陷阱
    trap - INT
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    # 初始化环境
    init_environment
    
    # 显示脚本头部信息
    show_header "交互式确认功能演示" "1.0" "演示新的交互式确认功能"
    
    # 检查终端支持情况
    if can_use_interactive_selection; then
        log_info "检测到终端支持高级交互式选择器"
        log_info "使用方法："
        log_info "  - 使用左右箭头键或 a/d 键选择"
        log_info "  - 按回车键确认选择"
        log_info "  - 按 Ctrl+C 取消操作"
    else
        log_warn "终端不支持高级交互式选择器，将使用传统文本模式"
    fi
    
    echo
    
    # 运行演示
    demo_basic_usage
    echo
    
    demo_real_scenario
    echo
    
    demo_multiple_confirmations
    echo
    
    demo_error_handling
    
    # 显示脚本尾部信息
    show_footer
}

# 运行主函数
main "$@"
