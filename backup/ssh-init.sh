#!/bin/bash
# 强制使用Bash运行（避免dash兼容性问题）
if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用Bash运行此脚本（当前shell: $0）"
    exit 1
fi
set -euo pipefail  # Bash专属特性，保证管道错误能被捕获

# ---------------------------
# 系统检测（仅保留Ubuntu/Debian）
# ---------------------------
if [ ! -f "/etc/os-release" ]; then
    echo "错误：未找到系统标识文件 /etc/os-release"
    exit 1
fi
OS=$(awk -F'=' '/^ID=/ {print $2}' /etc/os-release | tr -d '"')
ARCH=$(uname -m)

# 验证系统兼容性
if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ]; then
    echo "错误：仅支持Ubuntu/Debian系统（当前系统：$OS）"
    exit 1
fi

PKG_MANAGER="apt-get"
SSH_SERVICE="ssh"
SSH_RESTART_CMD="systemctl restart ${SSH_SERVICE}"

# 定义颜色变量（兼容老旧终端）
RED=$(printf '\033[31m' 2>/dev/null || echo '')
GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
MAGENTA=$(printf '\033[35m' 2>/dev/null || echo '')
CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
RESET=$(printf '\033[m' 2>/dev/null || echo '')

# 检查root权限（非root用户自动使用sudo）
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

# ---------------------------
# 新增：获取主机名和IP（仅Ubuntu/Debian）
# ---------------------------
get_host_info() {
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')  # 取第一个非环回IP

    # 备用方案：获取eth0的IP（如果主IP获取失败）
    [ -z "$ip" ] && ip=$(ip -o -4 addr show eth0 | awk '{print $4}' | cut -d'/' -f1)
    [ -z "$ip" ] && ip="unknown-ip"  # 最终备用

    echo "$hostname" "$ip"
}

# ---------------------------
# 新增：生成带hostname和IP的SSH密钥对
# ---------------------------
generate_ssh_key() {
    echo "${BLUE}[5/6] 生成SSH密钥对（含hostname和IP）${RESET}"
    local ssh_dir="$HOME/.ssh"
    local host_info=$(get_host_info)
    local hostname=$(echo "$host_info" | awk '{print $1}')
    local ip=$(echo "$host_info" | awk '{print $2}')
    local key_name="id_rsa_${hostname}_${ip}"
    local key_path="${ssh_dir}/${key_name}"

    # 创建.ssh目录（如果不存在）
    run mkdir -p "$ssh_dir"
    run chmod 700 "$ssh_dir"

    echo "${YELLOW}ℹ 提示：将生成密钥对：${key_path}（无密码）${RESET}"
    if run ssh-keygen -t rsa -b 4096 -f "$key_path" -N "" -q; then
        echo "${GREEN}✔ 成功：SSH密钥对已生成${RESET}"
        echo "${CYAN}私钥路径：${key_path}${RESET}"
        echo "${CYAN}公钥路径：${key_path}.pub${RESET}"
    else
        echo "${RED}✖ 失败：SSH密钥生成失败${RESET}"
        exit 1
    fi
}

clear
echo -e "${BLUE}================================================================${RESET}"
echo -e "${GREEN}🚀 SSH 自动配置脚本（Ubuntu/Debian专用）${RESET}"
echo -e "${YELLOW}👤 作者: saul${RESET}"
echo -e "${YELLOW}📧 邮箱: sau1@maranth@gmail.com${RESET}"
echo -e "${MAGENTA}🔖 version 2.0 (OpenWrt移除版)${RESET}"
echo -e "${BLUE}================================================================${RESET}"
echo -e "${CYAN}本脚本仅支持：Ubuntu 22 / Debian 12${RESET}"
echo -e "${CYAN}已自动检测到当前系统：${OS} ${ARCH}${RESET}"
echo -e "${CYAN}⚠ 注意：所有操作前会备份个人信息${RESET}"
echo -e "${BLUE}================================================================${RESET}"

# ---------------------------
# 一、安装OpenSSH服务器
# ---------------------------
install_openssh_server() {
    echo "${BLUE}[1/6] 安装OpenSSH服务器${RESET}"
    if ! confirm_operation; then
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
# 二、设置允许root用户登录
# ---------------------------
set_ssh_permit_root_login() {
    echo "${BLUE}[2/6] 设置允许root用户登录${RESET}"
    if ! confirm_operation; then
        return
    fi
    local config_file="/etc/ssh/sshd_config"

    run cp -n "$config_file" "$config_file.bak.$(date +%Y%m%d%H%M%S)"
    echo "${GREEN}✔ 已备份配置到 ${config_file}.bak.时间戳${RESET}"

    if run grep -q "^PermitRootLogin" "$config_file"; then
        run sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$config_file"
    else
        echo "PermitRootLogin yes" | run tee -a "$config_file" >/dev/null
    fi

    run ${SSH_RESTART_CMD} || {
        echo "${RED}✖ 失败：重启SSH服务失败${RESET}"
        exit 1
    }
    echo "${GREEN}✔ 允许root登录已启用${RESET}"
}

# ---------------------------
# 三、设置公钥登录
# ---------------------------
set_public_key_login() {
    echo "${BLUE}[3/6] 设置公钥登录${RESET}"
    if ! confirm_operation; then
        return
    fi
    local config_file="/etc/ssh/sshd_config"

    if [ -f "$HOME/.ssh/authorized_keys" ]; then
        run cp -n "$HOME/.ssh/authorized_keys" "$HOME/.ssh/authorized_keys.bak.$(date +%Y%m%d%H%M%S)"
        echo "${GREEN}✔ 已备份用户公钥${RESET}"
    fi

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
    echo "${BLUE}[4/6] 设置允许AgentForwarding${RESET}"
    if ! confirm_operation; then
        return
    fi
    local config_file="/etc/ssh/sshd_config"

    if run grep -q "^AllowAgentForwarding" "$config_file"; then
        run sed -i 's/^AllowAgentForwarding.*/AllowAgentForwarding yes/' "$config_file"
    else
        echo "AllowAgentForwarding yes" | run tee -a "$config_file" >/dev/null
    fi

    run ${SSH_RESTART_CMD}
    echo "${GREEN}✔ AgentForwarding已启用${RESET}"
}

# ---------------------------
# 五、安装fail2ban
# ---------------------------
install_fail2ban() {
    echo "${BLUE}[6/6] 安装fail2ban${RESET}"
    if ! confirm_operation; then
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
# 交互式菜单（新增密钥生成选项）
# ---------------------------
PS3="${CYAN}请选择操作（${OS}系统）：${RESET}"
options=(
    "${GREEN}1. 全流程自动配置（推荐）${RESET}"
    "${BLUE}2. 安装OpenSSH服务器${RESET}"
    "${BLUE}3. 设置允许root登录${RESET}"
    "${BLUE}4. 设置公钥登录${RESET}"
    "${BLUE}5. 设置AgentForwarding${RESET}"
    "${BLUE}6. 生成带hostname和IP的SSH密钥对${RESET}"  # 新增选项
    "${RED}7. 退出${RESET}"
)

select opt in "${options[@]}"; do
    case "$REPLY" in
        1)
            backup_personal_info
            install_openssh_server
            set_ssh_permit_root_login
            set_public_key_login
            set_allow_agent_forwarding
            generate_ssh_key  # 全流程包含密钥生成
            install_fail2ban
            echo "${GREEN}🎉 所有配置已完成！${RESET}"
            break
            ;;
        2)
            backup_personal_info
            install_openssh_server ;;
        3)
            backup_personal_info
            set_ssh_permit_root_login ;;
        4)
            backup_personal_info
            set_public_key_login ;;
        5)
            backup_personal_info
            set_allow_agent_forwarding ;;
        6)
            backup_personal_info  # 生成密钥前备份
            generate_ssh_key ;;
        7) break ;;
        *) echo "${RED}✖ 无效选项，请输入1-7${RESET}" ;;
    esac
done

echo -e "${BLUE}================================================================${RESET}"
echo -e "${YELLOW}ℹ 系统信息：${OS} ${ARCH}${RESET}"
echo -e "${YELLOW}ℹ SSH服务状态：$(run systemctl status ${SSH_SERVICE} --no-pager)${RESET}"
echo -e "${YELLOW}ℹ 配置文件路径：/etc/ssh/sshd_config${RESET}"
echo -e "${YELLOW}ℹ 最新密钥路径：$(ls -t ~/.ssh/id_rsa_* 2>/dev/null | head -1)${RESET}"
