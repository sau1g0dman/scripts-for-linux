#!/bin/bash

# =============================================================================
# 系统时间同步脚本
# 作者: saul
# 版本: 1.0
# 描述: 自动配置和同步系统时间，支持Ubuntu 20-22 x64/ARM64
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否为远程执行（通过curl | bash）
if [[ -f "$SCRIPT_DIR/../common.sh" ]]; then
    # 本地执行
    source "$SCRIPT_DIR/../common.sh"
else
    # 远程执行，下载common.sh
    COMMON_SH_URL="https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/refactor/scripts/common.sh"
    if ! source <(curl -fsSL "$COMMON_SH_URL"); then
        echo "错误：无法加载通用函数库"
        exit 1
    fi
fi

# =============================================================================
# 配置变量
# =============================================================================

# NTP服务器列表（按优先级排序）
readonly NTP_SERVERS=(
    "ntp1.aliyun.com"
    "ntp2.aliyun.com"
    "ntp3.aliyun.com"
    "ntp4.aliyun.com"
    "ntp5.aliyun.com"
    "ntp6.aliyun.com"
    "ntp7.aliyun.com"
    "time1.aliyun.com"
    "time2.aliyun.com"
    "ntp.aliyun.com"
    "cn.pool.ntp.org"
    "ntp.ubuntu.com"
    "time.google.com"
    "time.cloudflare.com"
)

# =============================================================================
# 时间同步函数
# =============================================================================

# 检查并安装NTP工具
install_ntp_tools() {
    log_info "检查NTP时间同步工具..."

    if command -v ntpdate >/dev/null 2>&1 || command -v ntp >/dev/null 2>&1; then
        log_info "NTP工具已安装"
        return 0
    fi

    log_info "NTP工具未安装，开始安装..."

    # 根据系统类型安装NTP工具
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        log_info "检测到Debian/Ubuntu系统，安装ntpdate..."
        if ! install_package ntpdate; then
            log_warn "ntpdate安装失败，尝试安装ntp..."
            if ! install_package ntp; then
                log_error "所有NTP工具安装失败"
                return 1
            fi
        fi
    elif [ -f /etc/redhat-release ]; then
        # RedHat/CentOS系统
        log_info "检测到RedHat/CentOS系统，安装ntpdate..."
        if ! install_package ntpdate; then
            log_warn "ntpdate安装失败，尝试安装ntp..."
            if ! install_package ntp; then
                log_error "所有NTP工具安装失败"
                return 1
            fi
        fi
    else
        log_error "不支持的系统类型，无法安装NTP工具"
        return 1
    fi

    log_info "NTP工具安装完成"
    return 0
}

# 测试NTP服务器连通性
test_ntp_server() {
    local server=$1
    local timeout=5

    log_debug "测试NTP服务器: $server"

    # 使用ntpdate测试（不实际同步）
    if command -v ntpdate >/dev/null 2>&1; then
        if timeout $timeout ntpdate -q "$server" >/dev/null 2>&1; then
            log_debug "NTP服务器 $server 可用"
            return 0
        fi
    fi

    # 备用方法：使用nc测试端口123
    if command -v nc >/dev/null 2>&1; then
        if timeout $timeout nc -u -z "$server" 123 >/dev/null 2>&1; then
            log_debug "NTP服务器 $server 端口可达"
            return 0
        fi
    fi

    log_debug "NTP服务器 $server 不可用"
    return 1
}

# 查找可用的NTP服务器
find_available_ntp_server() {
    log_info "查找可用的NTP服务器..."

    for server in "${NTP_SERVERS[@]}"; do
        if test_ntp_server "$server"; then
            log_info "找到可用的NTP服务器: $server"
            echo "$server"
            return 0
        fi
    done

    log_error "未找到可用的NTP服务器"
    return 1
}

# 同步系统时间
sync_system_time() {
    local ntp_server

    log_info "开始同步系统时间..."

    # 显示当前时间
    log_info "当前系统时间: $(date)"

    # 查找可用的NTP服务器
    if ! ntp_server=$(find_available_ntp_server); then
        log_error "无法找到可用的NTP服务器，时间同步失败"
        return 1
    fi

    # 执行时间同步
    log_info "使用NTP服务器 $ntp_server 同步时间..."

    if command -v ntpdate >/dev/null 2>&1; then
        if $SUDO ntpdate -s "$ntp_server"; then
            log_info "时间同步成功"
        else
            log_error "时间同步失败"
            return 1
        fi
    elif command -v ntp >/dev/null 2>&1; then
        # 如果只有ntp服务，启动并配置
        log_info "配置NTP服务..."

        # 备份原配置文件
        if [ -f /etc/ntp.conf ]; then
            $SUDO cp /etc/ntp.conf /etc/ntp.conf.backup.$(date +%Y%m%d_%H%M%S)
        fi

        # 创建新的NTP配置
        cat << EOF | $SUDO tee /etc/ntp.conf > /dev/null
# NTP配置文件 - 自动生成
driftfile /var/lib/ntp/ntp.drift

# 使用可用的NTP服务器
server $ntp_server iburst
$(for server in "${NTP_SERVERS[@]:1:3}"; do echo "server $server iburst"; done)

# 本地时钟作为备用
server 127.127.1.0
fudge 127.127.1.0 stratum 10

# 访问控制
restrict -4 default kod notrap nomodify nopeer noquery limited
restrict -6 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1
EOF

        # 启动NTP服务
        $SUDO systemctl enable ntp
        $SUDO systemctl restart ntp

        log_info "NTP服务配置完成"
    else
        log_error "未找到可用的NTP工具"
        return 1
    fi

    # 显示同步后的时间
    log_info "同步后系统时间: $(date)"

    return 0
}

# 配置系统时区
configure_timezone() {
    local timezone=${1:-"Asia/Shanghai"}

    log_info "配置系统时区为: $timezone"

    if [ -f /usr/share/zoneinfo/"$timezone" ]; then
        $SUDO timedatectl set-timezone "$timezone" 2>/dev/null || {
            $SUDO ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
        }
        log_info "时区配置完成"
    else
        log_warn "时区 $timezone 不存在，使用默认时区"
    fi
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    # 初始化环境
    init_environment

    # 显示脚本信息
    show_header "系统时间同步脚本" "1.0" "自动配置和同步系统时间"

    log_info "为什么需要时间同步？"
    echo "准确的系统时间是许多网络操作的基础，特别是："
    echo "  1. TLS/SSL握手需要客户端和服务器时间同步（误差<5分钟）"
    echo "  2. apt/yum包管理器验证软件包签名依赖正确时间"
    echo "  3. 日志记录和审计系统依赖准确的时间戳"
    echo "  4. 许多安全协议（如SSH、HTTPS）依赖时间同步"
    echo

    # 检查网络连接
    if ! check_network; then
        log_error "网络连接失败，无法进行时间同步"
        exit 1
    fi

    # 安装NTP工具
    if ! install_ntp_tools; then
        log_error "NTP工具安装失败"
        exit 1
    fi

    # 配置时区
    configure_timezone "Asia/Shanghai"

    # 同步系统时间
    if ! sync_system_time; then
        log_error "系统时间同步失败"
        exit 1
    fi

    # 显示完成信息
    show_footer

    log_info "时间同步脚本执行完成"
    log_info "建议定期运行此脚本或配置cron任务来保持时间同步"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
