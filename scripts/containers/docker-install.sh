#!/bin/bash

# =============================================================================
# Docker安装配置脚本
# 作者: saul
# 版本: 1.0
# 描述: 自动安装Docker和相关工具，支持Ubuntu 20-22 x64/ARM64
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
# 配置变量
# =============================================================================

# Docker安装脚本URL
readonly DOCKER_INSTALL_URL="https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh"
readonly LAZYDOCKER_INSTALL_URL="https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh"

# =============================================================================
# Docker安装函数
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

    # 检查网络连接
    if ! check_network; then
        log_error "网络连接失败，无法下载Docker安装脚本"
        return 1
    fi

    # 下载并执行Docker安装脚本
    log_info "下载Docker安装脚本..."
    if curl -fsSL "$DOCKER_INSTALL_URL" | bash; then
        log_info "Docker安装完成"
    else
        log_error "Docker安装失败"
        return 1
    fi

    # 启动Docker服务
    log_info "启动Docker服务..."
    $SUDO systemctl enable docker
    $SUDO systemctl start docker

    # 将当前用户添加到docker组
    if [ "$(id -u)" -ne 0 ]; then
        log_info "将当前用户添加到docker组..."
        $SUDO usermod -aG docker "$USER"
        log_info "请重新登录以使docker组权限生效"
    fi

    return 0
}

# 安装LazyDocker
install_lazydocker() {
    log_info "开始安装LazyDocker..."

    if command -v lazydocker >/dev/null 2>&1; then
        log_info "LazyDocker已安装"
        return 0
    fi

    # 下载并安装LazyDocker
    if curl -fsSL "$LAZYDOCKER_INSTALL_URL" | bash; then
        log_info "LazyDocker安装完成"
        return 0
    else
        log_error "LazyDocker安装失败"
        return 1
    fi
}

# 安装Docker Compose
install_docker_compose() {
    log_info "开始安装Docker Compose..."

    if command -v docker-compose >/dev/null 2>&1; then
        log_info "Docker Compose已安装: $(docker-compose --version)"
        return 0
    fi

    # 获取最新版本号
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$latest_version" ]; then
        log_warn "无法获取Docker Compose最新版本，使用默认版本"
        latest_version="v2.20.0"
    fi

    log_info "安装Docker Compose版本: $latest_version"

    # 根据架构选择下载URL
    local compose_url
    case "$ARCH" in
        x64)
            compose_url="https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-linux-x86_64"
            ;;
        arm64)
            compose_url="https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-linux-aarch64"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            return 1
            ;;
    esac

    # 下载并安装Docker Compose
    if curl -L "$compose_url" -o /opt/docker-compose; then
        $SUDO mv /opt/docker-compose /usr/local/bin/docker-compose
        $SUDO chmod +x /usr/local/bin/docker-compose
        log_info "Docker Compose安装完成"
        return 0
    else
        log_error "Docker Compose下载失败"
        return 1
    fi
}

# 配置Docker镜像加速器
configure_docker_mirrors() {
    log_info "配置Docker镜像加速器..."

    local daemon_json="/etc/docker/daemon.json"

    # 备份原配置文件
    if [ -f "$daemon_json" ]; then
        $SUDO cp "$daemon_json" "$daemon_json.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # 创建新的daemon.json配置
    cat << 'EOF' | $SUDO tee "$daemon_json" > /dev/null
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://ccr.ccs.tencentyun.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

    # 重启Docker服务
    log_info "重启Docker服务以应用配置..."
    $SUDO systemctl daemon-reload
    $SUDO systemctl restart docker

    log_info "Docker镜像加速器配置完成"
    return 0
}

# 验证Docker安装
verify_docker_installation() {
    log_info "验证Docker安装..."

    # 检查Docker版本
    if docker --version; then
        log_info "Docker版本检查通过"
    else
        log_error "Docker版本检查失败"
        return 1
    fi

    # 检查Docker服务状态
    if $SUDO systemctl is-active docker >/dev/null 2>&1; then
        log_info "Docker服务运行正常"
    else
        log_error "Docker服务未运行"
        return 1
    fi

    # 运行测试容器
    log_info "运行Docker测试容器..."
    if docker run --rm hello-world; then
        log_info "Docker测试容器运行成功"
    else
        log_error "Docker测试容器运行失败"
        return 1
    fi

    return 0
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    # 初始化环境
    init_environment

    # 显示脚本信息
    show_header "Docker安装配置脚本" "1.0" "自动安装Docker和相关工具"

    # 检查网络连接
    if ! check_network; then
        log_error "网络连接失败，无法下载Docker组件"
        exit 1
    fi

    # 检查并安装Docker
    if ! check_docker_installed; then
        if ! install_docker; then
            log_error "Docker安装失败"
            exit 1
        fi
    fi

    # 配置Docker镜像加速器
    if interactive_ask_confirmation "是否配置Docker镜像加速器？" "true"; then
        configure_docker_mirrors
    fi

    # 安装Docker Compose
    if interactive_ask_confirmation "是否安装Docker Compose？" "true"; then
        install_docker_compose
    fi

    # 安装LazyDocker
    if interactive_ask_confirmation "是否安装LazyDocker（Docker管理工具）？" "true"; then
        install_lazydocker
    fi

    # 验证安装
    if ! verify_docker_installation; then
        log_error "Docker安装验证失败"
        exit 1
    fi

    # 显示完成信息
    show_footer

    log_info "Docker安装配置完成！"
    log_info "如果当前用户被添加到docker组，请重新登录以使权限生效"
    log_info "可以运行 'docker run hello-world' 来测试Docker是否正常工作"

    if command -v lazydocker >/dev/null 2>&1; then
        log_info "可以运行 'lazydocker' 来启动Docker管理界面"
    fi
}

# 脚本入口点
# 安全检查 BASH_SOURCE 是否存在，兼容 curl | bash 执行方式
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
