#!/bin/bash

# =============================================================================
# 软件源配置脚本
# 作者: saul
# 版本: 1.0
# 描述: 自动配置Ubuntu/Debian系统的软件源为国内镜像，支持x64/ARM64
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# =============================================================================
# 配置变量
# =============================================================================

# 镜像源配置
readonly MIRRORS=(
    "mirrors.aliyun.com"
    "mirrors.tuna.tsinghua.edu.cn"
    "mirrors.ustc.edu.cn"
    "mirrors.163.com"
    "mirrors.huaweicloud.com"
)

# =============================================================================
# 软件源配置函数
# =============================================================================

# 检测Ubuntu版本
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        UBUNTU_CODENAME=$VERSION_CODENAME
        UBUNTU_VERSION=$VERSION_ID
        log_info "检测到Ubuntu版本: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
    else
        log_error "无法检测Ubuntu版本"
        return 1
    fi
}

# 测试镜像源连通性
test_mirror() {
    local mirror=$1
    local timeout=5
    
    log_debug "测试镜像源: $mirror"
    
    if curl -s --connect-timeout $timeout --max-time $timeout \
        "http://$mirror/ubuntu/ls-lR.gz" -o /dev/null 2>/dev/null; then
        log_debug "镜像源 $mirror 可用"
        return 0
    fi
    
    log_debug "镜像源 $mirror 不可用"
    return 1
}

# 查找最快的镜像源
find_fastest_mirror() {
    log_info "查找最快的镜像源..."
    
    for mirror in "${MIRRORS[@]}"; do
        if test_mirror "$mirror"; then
            log_info "选择镜像源: $mirror"
            echo "$mirror"
            return 0
        fi
    done
    
    log_warn "未找到可用的镜像源，使用默认源"
    echo "archive.ubuntu.com"
    return 1
}

# 备份原始sources.list
backup_sources_list() {
    local backup_file="/etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f /etc/apt/sources.list ]; then
        log_info "备份原始sources.list到: $backup_file"
        $SUDO cp /etc/apt/sources.list "$backup_file"
    fi
}

# 生成新的sources.list
generate_sources_list() {
    local mirror=$1
    local codename=$2
    local arch_suffix=""
    
    # 根据架构设置后缀
    if [ "$ARCH" = "arm64" ]; then
        arch_suffix="-ports"
        mirror="ports.ubuntu.com"
    fi
    
    log_info "生成新的sources.list文件..."
    
    cat << EOF | $SUDO tee /etc/apt/sources.list > /dev/null
# Ubuntu $codename 软件源配置
# 生成时间: $(date)
# 架构: $ARCH
# 镜像源: $mirror

# 主要软件源
deb http://$mirror/ubuntu$arch_suffix/ $codename main restricted universe multiverse
deb-src http://$mirror/ubuntu$arch_suffix/ $codename main restricted universe multiverse

# 安全更新
deb http://$mirror/ubuntu$arch_suffix/ $codename-security main restricted universe multiverse
deb-src http://$mirror/ubuntu$arch_suffix/ $codename-security main restricted universe multiverse

# 推荐更新
deb http://$mirror/ubuntu$arch_suffix/ $codename-updates main restricted universe multiverse
deb-src http://$mirror/ubuntu$arch_suffix/ $codename-updates main restricted universe multiverse

# 预发布更新（可选）
# deb http://$mirror/ubuntu$arch_suffix/ $codename-proposed main restricted universe multiverse
# deb-src http://$mirror/ubuntu$arch_suffix/ $codename-proposed main restricted universe multiverse

# 回退更新
deb http://$mirror/ubuntu$arch_suffix/ $codename-backports main restricted universe multiverse
deb-src http://$mirror/ubuntu$arch_suffix/ $codename-backports main restricted universe multiverse
EOF

    log_info "sources.list文件生成完成"
}

# 更新软件包列表
update_package_list() {
    log_info "更新软件包列表..."
    
    if $SUDO apt update; then
        log_info "软件包列表更新成功"
        return 0
    else
        log_error "软件包列表更新失败"
        return 1
    fi
}

# 升级系统软件包
upgrade_system() {
    if ask_confirmation "是否升级系统软件包？" "n"; then
        log_info "开始升级系统软件包..."
        
        if $SUDO apt upgrade -y; then
            log_info "系统软件包升级完成"
        else
            log_warn "系统软件包升级过程中出现问题"
        fi
        
        if ask_confirmation "是否清理不需要的软件包？" "y"; then
            $SUDO apt autoremove -y
            $SUDO apt autoclean
            log_info "系统清理完成"
        fi
    fi
}

# 配置额外的软件源
configure_additional_sources() {
    log_info "配置额外的软件源..."
    
    # Docker官方源
    if ask_confirmation "是否添加Docker官方软件源？" "n"; then
        log_info "添加Docker官方软件源..."
        
        # 安装必要的包
        install_package ca-certificates
        install_package curl
        install_package gnupg
        install_package lsb-release
        
        # 添加Docker GPG密钥
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # 添加Docker软件源
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        log_info "Docker软件源添加完成"
    fi
    
    # Node.js官方源
    if ask_confirmation "是否添加Node.js官方软件源？" "n"; then
        log_info "添加Node.js官方软件源..."
        
        curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO -E bash -
        
        log_info "Node.js软件源添加完成"
    fi
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    # 初始化环境
    init_environment
    
    # 显示脚本信息
    show_header "软件源配置脚本" "1.0" "自动配置Ubuntu/Debian系统的软件源"
    
    # 检查是否为Ubuntu/Debian系统
    if [ ! -f /etc/debian_version ]; then
        log_error "此脚本仅支持Ubuntu/Debian系统"
        exit 1
    fi
    
    # 检测Ubuntu版本
    if ! detect_ubuntu_version; then
        exit 1
    fi
    
    # 检查网络连接
    if ! check_network; then
        log_error "网络连接失败，无法配置软件源"
        exit 1
    fi
    
    # 查找最快的镜像源
    local mirror
    if ! mirror=$(find_fastest_mirror); then
        log_warn "使用默认镜像源"
        mirror="archive.ubuntu.com"
    fi
    
    # 确认是否继续
    echo
    log_info "即将配置软件源:"
    echo "  - 镜像源: $mirror"
    echo "  - Ubuntu版本: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
    echo "  - CPU架构: $ARCH"
    echo
    
    if ! ask_confirmation "是否继续配置软件源？" "y"; then
        log_info "用户取消操作"
        exit 0
    fi
    
    # 备份原始配置
    backup_sources_list
    
    # 生成新的sources.list
    generate_sources_list "$mirror" "$UBUNTU_CODENAME"
    
    # 更新软件包列表
    if ! update_package_list; then
        log_error "软件包列表更新失败，请检查配置"
        exit 1
    fi
    
    # 升级系统
    upgrade_system
    
    # 配置额外的软件源
    configure_additional_sources
    
    # 显示完成信息
    show_footer
    
    log_info "软件源配置完成"
    log_info "可以使用 'apt list --upgradable' 查看可升级的软件包"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
