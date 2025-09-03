#!/bin/bash

# =============================================================================
# Docker镜像推送脚本
# 作者: saul
# 版本: 1.1
# 描述: 搜索、拉取、标记并推送Docker镜像到私有仓库，支持Ubuntu 20-22 x64/ARM64
# =============================================================================

# 导入通用函数库
# 安全获取脚本目录，兼容远程执行环境
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# 检查是否为远程执行（通过curl | bash）
if [[ -f "$SCRIPT_DIR/../common.sh" ]]; then
    # 本地执行
    source "$SCRIPT_DIR/../common.sh"
else
    # 远程执行，下载common.sh
    COMMON_SH_URL="https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/common.sh"
    if ! source <(curl -fsSL "$COMMON_SH_URL"); then
        echo "错误：无法加载通用函数库"
        exit 1
    fi
fi

# =============================================================================
# Docker检查和安装函数
# =============================================================================

# 检查Docker是否已安装
check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker已安装: $(docker --version)"
        return 0
    else
        log_info "Docker未安装"
        return 1
    fi
}

# 安装Docker
install_docker() {
    log_info "开始安装Docker..."

    if ask_confirmation "是否安装Docker？" "y"; then
        log_info "正在安装Docker..."
        bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh)

        log_info "正在安装lazydocker..."
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

        log_info "Docker安装完成"
        return 0
    else
        log_error "用户取消Docker安装"
        return 1
    fi
}

# =============================================================================
# Docker镜像操作函数
# =============================================================================

# 搜索Docker镜像
search_docker_image() {
    local search_term=$1

    if [ -z "$search_term" ]; then
        read -p "请输入要搜索的镜像名称: " search_term
    fi

    log_info "搜索Docker镜像: $search_term"

    if docker search "$search_term" --limit 10; then
        log_info "镜像搜索完成"
        return 0
    else
        log_error "镜像搜索失败"
        return 1
    fi
}

# 拉取Docker镜像
pull_docker_image() {
    local image_name=$1

    if [ -z "$image_name" ]; then
        read -p "请输入要拉取的镜像名称（如nginx:latest）: " image_name
    fi

    log_info "拉取Docker镜像: $image_name"

    if docker pull "$image_name"; then
        log_info "镜像拉取完成"
        return 0
    else
        log_error "镜像拉取失败"
        return 1
    fi
}

# 标记Docker镜像
tag_docker_image() {
    local source_image=$1
    local target_image=$2

    if [ -z "$source_image" ]; then
        read -p "请输入源镜像名称: " source_image
    fi

    if [ -z "$target_image" ]; then
        read -p "请输入目标镜像名称（包含私有仓库地址）: " target_image
    fi

    log_info "标记Docker镜像: $source_image -> $target_image"

    if docker tag "$source_image" "$target_image"; then
        log_info "镜像标记完成"
        return 0
    else
        log_error "镜像标记失败"
        return 1
    fi
}

# 推送Docker镜像
push_docker_image() {
    local image_name=$1

    if [ -z "$image_name" ]; then
        read -p "请输入要推送的镜像名称: " image_name
    fi

    log_info "推送Docker镜像: $image_name"

    if docker push "$image_name"; then
        log_info "镜像推送完成"
        return 0
    else
        log_error "镜像推送失败"
        return 1
    fi
}

# 列出本地Docker镜像
list_local_images() {
    log_info "本地Docker镜像列表:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}"
}

# 登录Docker仓库
docker_login() {
    local registry_url=$1

    if [ -z "$registry_url" ]; then
        read -p "请输入Docker仓库地址（如registry.example.com）: " registry_url
    fi

    log_info "登录Docker仓库: $registry_url"

    if docker login "$registry_url"; then
        log_info "Docker仓库登录成功"
        return 0
    else
        log_error "Docker仓库登录失败"
        return 1
    fi
}

# =============================================================================
# 交互式菜单函数
# =============================================================================

# 显示主菜单
show_menu() {
    echo
    echo "=== Docker镜像推送工具 ==="
    echo "1. 搜索Docker镜像"
    echo "2. 拉取Docker镜像"
    echo "3. 列出本地镜像"
    echo "4. 标记镜像"
    echo "5. 推送镜像"
    echo "6. 登录Docker仓库"
    echo "7. 一键操作（拉取->标记->推送）"
    echo "0. 退出"
    echo
}

# 一键操作
one_click_operation() {
    local source_image target_image

    read -p "请输入要拉取的镜像名称（如nginx:latest）: " source_image
    read -p "请输入目标仓库地址和镜像名称（如registry.example.com/nginx:latest）: " target_image

    # 拉取镜像
    if ! pull_docker_image "$source_image"; then
        return 1
    fi

    # 标记镜像
    if ! tag_docker_image "$source_image" "$target_image"; then
        return 1
    fi

    # 推送镜像
    if ! push_docker_image "$target_image"; then
        return 1
    fi

    log_info "一键操作完成！"
    return 0
}

# 主交互循环
interactive_menu() {
    while true; do
        show_menu
        read -p "请选择操作 [0-7]: " choice

        case $choice in
            1)
                search_docker_image
                ;;
            2)
                pull_docker_image
                ;;
            3)
                list_local_images
                ;;
            4)
                tag_docker_image
                ;;
            5)
                push_docker_image
                ;;
            6)
                docker_login
                ;;
            7)
                one_click_operation
                ;;
            0)
                log_info "退出程序"
                break
                ;;
            *)
                log_warn "无效选择，请重新输入"
                ;;
        esac

        echo
        read -p "按回车键继续..."
    done
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    # 初始化环境
    init_environment

    # 显示脚本信息
    show_header "Docker镜像推送脚本" "1.1" "搜索、拉取、标记并推送Docker镜像到私有仓库"

    echo "本脚本将帮助您搜索、拉取、标记并推送公共Docker镜像到私有仓库。"
    echo "请按照提示输入相关信息，然后脚本将自动完成后续操作。"
    echo

    # 检查并安装Docker
    if ! check_docker_installed; then
        if ! install_docker; then
            log_error "Docker安装失败，无法继续"
            exit 1
        fi
    fi

    # 检查并安装jq工具
    if ! install_package jq; then
        log_error "jq工具安装失败，无法继续"
        exit 1
    fi

    # 检查Docker服务状态
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker服务未运行，请启动Docker服务"
        log_info "可以运行: sudo systemctl start docker"
        exit 1
    fi

    # 启动交互式菜单
    interactive_menu

    # 显示完成信息
    show_footer
}

# 脚本入口点
# 安全检查 BASH_SOURCE 是否存在，兼容 curl | bash 执行方式
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
