#!/bin/bash

# =============================================================================
# Docker镜像源配置脚本
# 作者: saul
# 版本: 1.0
# 描述: 配置Docker国内镜像源，提升镜像下载速度
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
# 主函数
# =============================================================================

main() {
    # 初始化环境
    init_environment

    # 显示脚本信息
    show_header "Docker镜像源配置脚本" "1.0" "配置Docker国内镜像源"

    log_info "开始配置Docker镜像源..."

    # 创建Docker配置目录
    sudo mkdir -p /etc/docker

    # 配置镜像源
    sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://ccr.ccs.tencentyun.com",
    "https://docker.1ms.run",
    "https://docker.mybacc.com",
    "https://hub.littlediary.cn"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

    log_info "重启Docker服务..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    log_info "Docker镜像源配置完成"

    # 显示完成信息
    show_footer
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
