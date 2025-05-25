#!/bin/bash
# 强制使用Bash运行（避免dash兼容性问题）
if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用Bash运行此脚本（当前shell: $0）"
    exit 1
fi
set -euo pipefail  # Bash专属特性，保证管道错误能被捕获

# ---------------------------
# 系统检测（增强健壮性）
# ---------------------------
if [ ! -f "/etc/os-release" ]; then
    echo "错误：未找到系统标识文件 /etc/os-release"
    exit 1
fi
OS=$(awk -F'=' '/^ID=/ {print $2}' /etc/os-release | tr -d '"')
ARCH=$(uname -m)
PKG_MANAGER=""
SSH_SERVICE=""
SSH_RESTART_CMD=""

case "$OS" in
    openwrt)
        PKG_MANAGER="opkg"
        SSH_SERVICE="dropbear"
        SSH_RESTART_CMD="/etc/init.d/${SSH_SERVICE} restart"
        ;;
    ubuntu|debian)
        PKG_MANAGER="apt-get"
        SSH_SERVICE="ssh"
        SSH_RESTART_CMD="systemctl restart ${SSH_SERVICE}"
        ;;
    *)
        echo "错误：不支持的操作系统 $OS"
        exit 1
        ;;
esac

# 定义颜色变量（兼容老旧终端）
RED=$(printf '\033[31m' 2>/dev/null || echo '')
GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
MAGENTA=$(printf '\033[35m' 2>/dev/null || echo '')
CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
RESET=$(printf '\033[m' 2>/dev/null || echo '')

# 检查root权限（Ubuntu非root用户自动使用sudo）
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
    echo "${YELLOW}提示：非root用户运行，将自动使用sudo${RESET}"
fi

# 通用执行函数（自动处理sudo）
run() {
    if [ -n "${SUDO:-}" ]; then
        ${SUDO} "$@"
    else
        "$@"
    fi
}

# ---------------------------
# 个人信息保护：备份关键文件
# ---------------------------
backup_personal_info() {
    local backup_dir="$HOME/.ssh_backup_$(date +%Y%m%d%H%M%S)"
    local backup_files=(
        "$HOME/.ssh/authorized_keys"  # 用户已授权的公钥
        "/etc/ssh/sshd_config"        # SSH服务配置
    )

    echo "${BLUE}🔒 正在备份个人信息...${RESET}"
    run mkdir -p "$backup_dir"

    for file in "${backup_files[@]}"; do
        if [ -f "$file" ]; then
            run cp -n "$file" "$backup_dir/"
            echo "${GREEN}✔ 已备份：${file} → ${backup_dir}/${file##*/}${RESET}"
        fi
    done
    echo "${YELLOW}ℹ 所有个人信息备份至：${backup_dir}${RESET}"
}

# ---------------------------
# 操作确认提示（最终版逻辑）
# y/Y/回车：继续操作
# n/N：跳过当前操作
# a/A：终止整个脚本
# ---------------------------
confirm_operation() {
    read -p "${YELLOW}⚠ 此操作可能影响SSH配置，继续请按(y/Y/回车)，跳过按(n/N)，取消按(a/A)：${RESET}" -n 1 -r
    echo

    case "$REPLY" in
        [yY])  # y/Y 继续操作
            echo "${GREEN}▶ 继续执行操作...${RESET}"
            return 0
            ;;
        [nN])  # n/N 跳过当前操作
            echo "${YELLOW}ℹ 已跳过当前操作${RESET}"
            return 1
            ;;
        [aA])  # a/A 终止脚本
            echo "${RED}✖ 已取消所有操作${RESET}"
            exit 1
            ;;
        *)     # 回车或其他键视为继续
            echo "${GREEN}▶ 继续执行操作...${RESET}"
            return 0
            ;;
    esac
}

clear
echo -e "${BLUE}================================================================${RESET}"
echo -e "${GREEN}🚀 SSH 多系统自动配置脚本 ${OS} ${ARCH}${RESET}"
echo -e "${YELLOW}👤 作者: saul${RESET}"
echo -e "${YELLOW}📧 邮箱: sau1@maranth@gmail.com${RESET}"
echo -e "${MAGENTA}🔖 version 1.7 (确认逻辑最终版)${RESET}"
echo -e "${BLUE}================================================================${RESET}"
echo -e "${CYAN}本脚本支持：OpenWrt / Ubuntu 22 / Debian 12${RESET}"
echo -e "${CYAN}已自动检测到当前系统：Ubuntu 22.04${RESET}"
echo -e "${CYAN}⚠ 注意：所有操作前会备份个人信息（如SSH公钥、配置文件）${RESET}"
echo -e "${BLUE}================================================================${RESET}"

# ---------------------------
# 一、设置允许root用户登录
# ---------------------------
set_ssh_permit_root_login() {
    echo "${BLUE}[1/5] 设置允许root用户登录${RESET}"
    if ! confirm_operation; then  # 返回1时跳过
        return
    fi
    local config_file="/etc/ssh/sshd_config"

    # 备份配置（带时间戳）
    run cp -n "$config_file" "$config_file.bak.$(date +%Y%m%d%H%M%S)"
    echo "${GREEN}✔ 已备份配置到 ${config_file}.bak.时间戳${RESET}"

    # 仅修改PermitRootLogin行，保留其他配置
    if run grep -q "^PermitRootLogin" "$config_file"; then
        run sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$config_file"
    else
        echo "PermitRootLogin yes" | run tee -a "$config_file" >/dev/null
    fi

    # 重启服务
    echo "${BLUE}• 重启SSH服务...${RESET}"
    run ${SSH_RESTART_CMD} || {
        echo "${RED}✖ 失败：重启SSH服务失败（命令：${SSH_RESTART_CMD}）${RESET}"
        exit 1
    }
    echo "${GREEN}✔ 允许root登录已启用${RESET}"
}

# ---------------------------
# 二、安装OpenSSH服务器（Ubuntu/Debian专用）
# ---------------------------
install_openssh_server() {
    [ "$OS" = "openwrt" ] && return  # OpenWrt跳过
    echo "${BLUE}[2/5] 安装OpenSSH服务器${RESET}"
    if ! confirm_operation; then  # 返回1时跳过
        return
    fi

    run ${PKG_MANAGER} update
    run ${PKG_MANAGER} install -y openssh-server || {
        echo "${RED}✖ 失败：OpenSSH服务器安装失败${RESET}"
        exit 1
    }
    echo "${GREEN}✔ OpenSSH服务器已安装${RESET}"
}

# ---------------------------
# 三、设置公钥登录（保护现有authorized_keys）
# ---------------------------
set_public_key_login() {
    echo "${BLUE}[3/5] 设置公钥登录${RESET}"
    if ! confirm_operation; then  # 返回1时跳过
        return
    fi
    local config_file="/etc/ssh/sshd_config"

    # 备份用户已有的authorized_keys
    if [ -f "$HOME/.ssh/authorized_keys" ]; then
        run cp -n "$HOME/.ssh/authorized_keys" "$HOME/.ssh/authorized_keys.bak.$(date +%Y%m%d%H%M%S)"
        echo "${GREEN}✔ 已备份用户公钥到 ~/.ssh/authorized_keys.bak.时间戳${RESET}"
    fi

    # 仅修改PubkeyAuthentication行
    if run grep -q "^PubkeyAuthentication" "$config_file"; then
        run sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$config_file"
    else
        echo "PubkeyAuthentication yes" | run tee -a "$config_file" >/dev/null
    fi

    run ${SSH_RESTART_CMD}
    echo "${GREEN}✔ 公钥登录已启用${RESET}"
}

# ---------------------------
# 四、设置AgentForwarding
# ---------------------------
set_allow_agent_forwarding() {
    echo "${BLUE}[4/5] 设置允许AgentForwarding${RESET}"
    if ! confirm_operation; then  # 返回1时跳过
        return
    fi
    local config_file="/etc/ssh/sshd_config"

    # 仅修改AllowAgentForwarding行
    if run grep -q "^AllowAgentForwarding" "$config_file"; then
        run sed -i 's/^AllowAgentForwarding.*/AllowAgentForwarding yes/' "$config_file"
    else
        echo "AllowAgentForwarding yes" | run tee -a "$config_file" >/dev/null
    fi

    run ${SSH_RESTART_CMD}
    echo "${GREEN}✔ AgentForwarding已启用${RESET}"
}

# ---------------------------
# 五、安装fail2ban（Ubuntu/Debian专用）
# ---------------------------
install_fail2ban() {
    [ "$OS" = "openwrt" ] && echo "${YELLOW}ℹ 提示：OpenWrt需手动安装fail2ban${RESET}" && return
    echo "${BLUE}[5/5] 安装fail2ban${RESET}"
    if ! confirm_operation; then  # 返回1时跳过
        return
    fi

    run ${PKG_MANAGER} update
    run ${PKG_MANAGER} install -y fail2ban sshpass || {
        echo "${RED}✖ 失败：fail2ban安装失败${RESET}"
        exit 1
    }
    run systemctl enable --now fail2ban
    echo "${GREEN}✔ fail2ban已安装并启动${RESET}"
}

# ---------------------------
# 交互式菜单（移除密码设置选项）
# ---------------------------
PS3="${CYAN}请选择操作（${OS}系统）：${RESET}"
options=(
    "${GREEN}1. 全流程自动配置（推荐）${RESET}"
    "${BLUE}2. 单独设置允许root登录${RESET}"
    "${BLUE}3. 安装OpenSSH服务器${RESET}"
    "${BLUE}4. 设置公钥登录${RESET}"
    "${BLUE}5. 设置AgentForwarding${RESET}"
    "${RED}6. 退出${RESET}"
)

select opt in "${options[@]}"; do
    case "$REPLY" in
        1)
            backup_personal_info  # 全流程前备份个人信息
            install_openssh_server
            set_ssh_permit_root_login
            set_public_key_login
            set_allow_agent_forwarding
            install_fail2ban
            echo "${GREEN}🎉 所有配置已完成！${RESET}"
            break
            ;;
        2)
            backup_personal_info  # 单独操作前备份
            set_ssh_permit_root_login ;;
        3)
            backup_personal_info  # 单独操作前备份
            install_openssh_server ;;
        4)
            backup_personal_info  # 单独操作前备份
            set_public_key_login ;;
        5)
            backup_personal_info  # 单独操作前备份
            set_allow_agent_forwarding ;;
        6) break ;;
        *) echo "${RED}✖ 无效选项，请输入1-6${RESET}" ;;
    esac
done

echo -e "${BLUE}================================================================${RESET}"
echo -e "${YELLOW}ℹ 系统信息：${OS} ${ARCH}${RESET}"
echo -e "${YELLOW}ℹ SSH服务状态：$(run systemctl status ${SSH_SERVICE} --no-pager)${RESET}"
echo -e "${YELLOW}ℹ 配置文件路径：/etc/ssh/sshd_config${RESET}"
echo -e "${YELLOW}ℹ 个人信息备份路径：$(ls -td ~/.ssh_backup_* 2>/dev/null | head -1)${RESET}"  # 提示最新备份
