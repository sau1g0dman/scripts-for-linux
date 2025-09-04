#!/bin/bash

# =============================================================================
# 软件源配置脚本
# 作者: saul
# 版本: 1.0
# 描述: 自动配置Ubuntu/Debian系统的软件源为国内镜像，支持x64/ARM64
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

# 检测系统版本
detect_system_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        SYSTEM_ID=$ID
        SYSTEM_CODENAME=$VERSION_CODENAME
        SYSTEM_VERSION=$VERSION_ID

        case "$SYSTEM_ID" in
            ubuntu)
                log_info "检测到Ubuntu版本: $SYSTEM_VERSION ($SYSTEM_CODENAME)"
                ;;
            debian)
                log_info "检测到Debian版本: $SYSTEM_VERSION ($SYSTEM_CODENAME)"
                ;;
            *)
                log_warn "检测到系统: $SYSTEM_ID $SYSTEM_VERSION，可能不完全兼容"
                ;;
        esac
    else
        log_error "无法检测系统版本"
        return 1
    fi
}

# 测试镜像源连通性
test_mirror() {
    local mirror=$1
    local timeout=5
    local test_url=""

    log_debug "测试镜像源: $mirror"

    # 根据系统类型选择测试URL
    case "$SYSTEM_ID" in
        ubuntu)
            test_url="http://$mirror/ubuntu/ls-lR.gz"
            ;;
        debian)
            test_url="http://$mirror/debian/ls-lR.gz"
            ;;
        *)
            test_url="http://$mirror/ubuntu/ls-lR.gz"
            ;;
    esac

    if curl -s --connect-timeout $timeout --max-time $timeout \
        "$test_url" -o /dev/null 2>/dev/null; then
        log_debug "镜像源 $mirror 可用"
        return 0
    fi

    log_debug "镜像源 $mirror 不可用"
    return 1
}

# 查找最快的镜像源
find_fastest_mirror() {
    # 将日志输出重定向到stderr，避免污染返回值
    log_info "查找最快的镜像源..." >&2

    for mirror in "${MIRRORS[@]}"; do
        if test_mirror "$mirror"; then
            log_info "选择镜像源: $mirror" >&2
            # 只返回镜像源名称，不包含日志信息
            printf "%s" "$mirror"
            return 0
        fi
    done

    log_warn "未找到可用的镜像源，使用默认源" >&2
    printf "%s" "archive.ubuntu.com"
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
    local system_id=$3
    local arch=$(uname -m)
    local arch_suffix=""
    local repo_path=""
    local components=""

    # 根据系统和架构设置参数
    case "$system_id" in
        ubuntu)
            repo_path="ubuntu"
            components="main restricted universe multiverse"
            if [ "$arch" = "aarch64" ] || [ "$arch" = "armv7l" ]; then
                arch_suffix="-ports"
                mirror="ports.ubuntu.com"
            fi
            ;;
        debian)
            repo_path="debian"
            components="main contrib non-free"
            # Debian不需要ports后缀
            ;;
        *)
            repo_path="ubuntu"
            components="main restricted universe multiverse"
            ;;
    esac

    log_info "生成新的sources.list文件..."

    # 创建sources.list内容
    local sources_content=""

    case "$system_id" in
        ubuntu)
            sources_content="# Ubuntu $codename 软件源配置
# 生成时间: $(date)
# 架构: $arch
# 镜像源: $mirror

# 主要软件源
deb http://$mirror/$repo_path$arch_suffix/ $codename $components
deb-src http://$mirror/$repo_path$arch_suffix/ $codename $components

# 安全更新
deb http://$mirror/$repo_path$arch_suffix/ $codename-security $components
deb-src http://$mirror/$repo_path$arch_suffix/ $codename-security $components

# 推荐更新
deb http://$mirror/$repo_path$arch_suffix/ $codename-updates $components
deb-src http://$mirror/$repo_path$arch_suffix/ $codename-updates $components

# 回退更新
deb http://$mirror/$repo_path$arch_suffix/ $codename-backports $components
deb-src http://$mirror/$repo_path$arch_suffix/ $codename-backports $components"
            ;;
        debian)
            sources_content="# Debian $codename 软件源配置
# 生成时间: $(date)
# 架构: $arch
# 镜像源: $mirror

# 主要软件源
deb http://$mirror/$repo_path/ $codename $components
deb-src http://$mirror/$repo_path/ $codename $components

# 安全更新
deb http://$mirror/$repo_path-security/ $codename-security $components
deb-src http://$mirror/$repo_path-security/ $codename-security $components

# 更新源
deb http://$mirror/$repo_path/ $codename-updates $components
deb-src http://$mirror/$repo_path/ $codename-updates $components"
            ;;
    esac

    # 写入sources.list文件
    echo "$sources_content" | $SUDO tee /etc/apt/sources.list > /dev/null

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

    # 检测系统版本
    if ! detect_system_version; then
        exit 1
    fi

    # 检查网络连接
    if ! check_network; then
        log_error "网络连接失败，无法配置软件源"
        exit 1
    fi

    # 查找最快的镜像源
    local mirror
    mirror=$(find_fastest_mirror)
    if [ $? -ne 0 ] || [ -z "$mirror" ]; then
        log_warn "使用默认镜像源"
        case "$SYSTEM_ID" in
            ubuntu)
                mirror="archive.ubuntu.com"
                ;;
            debian)
                mirror="deb.debian.org"
                ;;
            *)
                mirror="archive.ubuntu.com"
                ;;
        esac
    fi

    # 确认是否继续
    echo
    log_info "即将配置软件源:"
    echo "  - 镜像源: $mirror"
    echo "  - 系统版本: $SYSTEM_VERSION ($SYSTEM_CODENAME)"
    echo "  - CPU架构: $(uname -m)"
    echo

    if ! ask_confirmation "是否继续配置软件源？" "y"; then
        log_info "用户取消操作"
        exit 0
    fi

    # 备份原始配置
    backup_sources_list

    # 生成新的sources.list
    generate_sources_list "$mirror" "$SYSTEM_CODENAME" "$SYSTEM_ID"

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
# 安全检查 BASH_SOURCE 是否存在，兼容 curl | bash 执行方式
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
