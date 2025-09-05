#!/bin/bash

# =============================================================================
# 改进后的软件包安装功能演示脚本
# 展示新的进度显示和用户体验改进
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

# 初始化环境
init_environment

# 显示脚本头部信息
show_header "改进后的软件包安装演示" "1.0" "展示新的进度显示和用户体验改进"

echo -e "${CYAN}本演示将展示改进后的软件包安装功能${RESET}"
echo -e "${CYAN}包括详细的进度显示、错误处理和用户友好的界面${RESET}"
echo

# 模拟软件包安装演示函数
demo_package_installation() {
    local package_name=$1
    local package_desc=$2
    local current=$3
    local total=$4
    local simulate_status=${5:-"success"}  # success, fail, skip
    
    echo -e "${BLUE}━━━ 软件包 $current/$total ━━━${RESET}"
    log_info "安装 ($current/$total): $package_desc ($package_name)"
    
    case $simulate_status in
        "skip")
            echo -e "  ${GREEN}✓${RESET} $package_desc 已安装，跳过"
            return 0
            ;;
        "fail")
            echo -e "  ${CYAN}↓${RESET} 正在下载 $package_desc..."
            echo -e "  ${YELLOW}ℹ${RESET} 提示：按 Ctrl+C 可取消安装"
            sleep 1
            echo -e "  ${CYAN}📦${RESET} 开始安装 $package_desc..."
            echo -e "  ${CYAN}📋${RESET} 读取软件包列表..."
            sleep 0.5
            echo -e "  ${CYAN}🔗${RESET} 分析依赖关系..."
            sleep 0.5
            echo -e "  ${RED}❌${RESET} $package_desc 安装失败"
            echo -e "  ${RED}💡${RESET} 错误原因: 网络连接问题，无法下载软件包"
            echo -e "  ${YELLOW}📝${RESET} 详细错误:"
            echo -e "    E: Failed to fetch http://archive.ubuntu.com/ubuntu/pool/main/..."
            echo -e "  ${CYAN}💡${RESET} 建议: 检查网络连接或稍后重试"
            return 1
            ;;
        *)
            echo -e "  ${CYAN}↓${RESET} 正在下载 $package_desc..."
            echo -e "  ${YELLOW}ℹ${RESET} 提示：按 Ctrl+C 可取消安装"
            sleep 0.8
            echo -e "  ${CYAN}📦${RESET} 开始安装 $package_desc..."
            echo -e "  ${CYAN}📋${RESET} 读取软件包列表..."
            sleep 0.3
            echo -e "  ${CYAN}🔗${RESET} 分析依赖关系..."
            sleep 0.3
            echo -e "  ${CYAN}📦${RESET} 准备安装新软件包..."
            sleep 0.3
            echo -e "  ${CYAN}↓${RESET} 需要下载: 2.4 MB"
            sleep 0.5
            echo -e "  ${CYAN}↓${RESET} 下载中: ${package_name}_1.0.0_amd64.deb"
            sleep 0.5
            echo -e "  ${CYAN}📂${RESET} 解包中..."
            sleep 0.3
            echo -e "  ${CYAN}⚙${RESET} 配置中..."
            sleep 0.3
            echo -e "  ${CYAN}🔄${RESET} 处理触发器..."
            sleep 0.2
            echo -e "  ${GREEN}✅${RESET} $package_desc 安装成功"
            return 0
            ;;
    esac
}

# 演示改进后的安装过程
demo_installation_process() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    log_info "开始演示改进后的软件包安装过程"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    # 模拟软件包列表
    local demo_packages=(
        "curl:网络请求工具:success"
        "wget:文件下载工具:skip"
        "git:版本控制系统:success"
        "vim:文本编辑器:success"
        "nonexistent-pkg:不存在的软件包:fail"
        "htop:系统监控工具:success"
    )

    local success_count=0
    local failed_count=0
    local skipped_count=0
    local total_count=${#demo_packages[@]}
    local failed_packages=()

    # 显示安装概览
    echo -e "${BLUE}📦 软件包安装概览${RESET}"
    echo -e "  ${CYAN}总数量:${RESET} $total_count 个软件包"
    echo -e "  ${CYAN}预计时间:${RESET} 根据网络速度而定"
    echo -e "  ${YELLOW}提示:${RESET} 整个过程中可以按 Ctrl+C 取消安装"
    echo

    # 模拟更新软件包列表
    log_info "第一步：更新软件包列表"
    echo -e "  ${CYAN}🔄${RESET} 正在更新软件包列表，请稍候..."
    sleep 1
    echo -e "  ${GREEN}✓${RESET} 检查: http://archive.ubuntu.com/ubuntu focal InRelease"
    sleep 0.3
    echo -e "  ${CYAN}↓${RESET} 获取: http://archive.ubuntu.com/ubuntu focal-updates InRelease"
    sleep 0.3
    echo -e "  ${CYAN}📋${RESET} 读取软件包列表..."
    sleep 0.5
    echo -e "  ${GREEN}✅${RESET} 软件包列表更新成功"
    
    echo
    log_info "第二步：开始安装软件包"
    echo

    # 安装每个软件包
    local current_num=1
    for package_info in "${demo_packages[@]}"; do
        IFS=':' read -r package_name package_desc status <<< "$package_info"
        
        if demo_package_installation "$package_name" "$package_desc" "$current_num" "$total_count" "$status"; then
            if [ "$status" = "skip" ]; then
                skipped_count=$((skipped_count + 1))
            else
                success_count=$((success_count + 1))
            fi
        else
            failed_count=$((failed_count + 1))
            failed_packages+=("$package_name:$package_desc")
        fi
        
        echo
        current_num=$((current_num + 1))
        sleep 0.5
    done

    # 显示安装总结
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    log_info "第三步：安装总结"
    echo
    
    echo -e "${BLUE}📊 安装统计${RESET}"
    echo -e "  ${GREEN}✅ 成功安装:${RESET} $success_count 个"
    echo -e "  ${RED}❌ 安装失败:${RESET} $failed_count 个"
    echo -e "  ${YELLOW}⏭️  已跳过:${RESET} $skipped_count 个"
    echo -e "  ${CYAN}📦 总计:${RESET} $total_count 个"
    
    # 显示安装进度条
    local progress=$(((success_count + skipped_count) * 100 / total_count))
    local bar_length=50
    local filled_length=$((progress * bar_length / 100))
    local bar=""
    
    for ((i=0; i<filled_length; i++)); do
        bar+="█"
    done
    for ((i=filled_length; i<bar_length; i++)); do
        bar+="░"
    done
    
    echo -e "  ${CYAN}进度:${RESET} [$bar] $progress%"
    echo

    # 如果有失败的软件包，显示详细信息
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}❌ 安装失败的软件包:${RESET}"
        for failed_pkg in "${failed_packages[@]}"; do
            IFS=':' read -r pkg_name pkg_desc <<< "$failed_pkg"
            echo -e "  ${RED}•${RESET} $pkg_desc ($pkg_name)"
        done
        echo
        echo -e "${YELLOW}💡 建议:${RESET}"
        echo -e "  • 检查网络连接是否正常"
        echo -e "  • 运行 'sudo apt update' 更新软件源"
        echo -e "  • 稍后重新运行安装脚本"
        echo
    fi

    # 显示最终结果
    if [ $failed_count -eq 0 ]; then
        echo -e "${GREEN}🎉 演示完成！所有软件包都已成功处理。${RESET}"
    else
        echo -e "${YELLOW}⚠️  演示完成。部分软件包安装失败（这是正常的演示效果）。${RESET}"
    fi
}

# 主演示函数
main() {
    echo -e "${CYAN}欢迎体验改进后的软件包安装功能！${RESET}"
    echo
    
    if interactive_ask_confirmation "是否开始演示？" "true"; then
        echo
        demo_installation_process
        echo
        
        echo -e "${GREEN}================================================================${RESET}"
        echo -e "${GREEN}演示完成！${RESET}"
        echo -e "${GREEN}================================================================${RESET}"
        echo
        echo -e "${CYAN}改进功能总结：${RESET}"
        echo -e "  ${GREEN}✅ 详细的进度显示${RESET} - 用户始终了解当前状态"
        echo -e "  ${GREEN}✅ 实时安装输出${RESET} - 避免用户误以为程序卡住"
        echo -e "  ${GREEN}✅ 智能错误分析${RESET} - 提供具体的错误原因和解决建议"
        echo -e "  ${GREEN}✅ 网络状态检测${RESET} - 在网络较慢时提供友好提示"
        echo -e "  ${GREEN}✅ 美观的界面设计${RESET} - 使用图标和进度条提升体验"
        echo -e "  ${GREEN}✅ 用户友好的提示${RESET} - 提供取消操作和等待提示"
        echo
        echo -e "${YELLOW}感谢体验改进后的安装功能！${RESET}"
    else
        echo -e "${CYAN}演示已取消。${RESET}"
    fi
}

# 运行演示
main "$@"
