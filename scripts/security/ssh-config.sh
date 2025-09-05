#!/bin/bash
# 强制使用Bash运行（避免dash兼容性问题）
if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用Bash运行此脚本（当前shell: $0）"
    exit 1
fi
set -euo pipefail  # Bash专属特性，保证管道错误能被捕获

# =============================================================================
# 导入通用函数库
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# 尝试从多个可能的位置加载 common.sh
if [ -f "$SCRIPT_DIR/../common.sh" ]; then
    source "$SCRIPT_DIR/../common.sh"
elif [ -f "$SCRIPT_DIR/../../scripts/common.sh" ]; then
    source "$SCRIPT_DIR/../../scripts/common.sh"
else
    echo "错误：无法找到 common.sh 函数库"
    exit 1
fi

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

# 颜色变量已在 common.sh 中定义为 readonly，无需重复定义

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

    echo "${BLUE}正在备份个人信息...${RESET}"
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
# 操作确认提示 - 使用标准化的交互式确认
# ---------------------------
confirm_operation() {
    if interactive_ask_confirmation "此操作可能影响SSH配置，是否继续？" "true"; then
        log_info "▶ 继续执行操作..."
        return 0
    else
        log_warn "ℹ 已跳过当前操作"
        return 1
    fi
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
echo -e "${GREEN} SSH 自动配置脚本（Ubuntu/Debian专用）${RESET}"
echo -e "${YELLOW} 作者: saul${RESET}"
echo -e "${YELLOW}邮箱: sau1amaranth@gmail.com${RESET}"
echo -e "${MAGENTA}version 2.0 (OpenWrt移除版)${RESET}"
echo -e "${BLUE}================================================================${RESET}"
echo -e "${CYAN}本脚本仅支持：Ubuntu 22 / Debian 12${RESET}"
echo -e "${CYAN}已自动检测到当前系统：${OS} ${ARCH}${RESET}"
echo -e "${CYAN}注意：所有操作前会备份个人信息${RESET}"
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
# 创建SSH配置菜单选项数组
# ---------------------------
create_ssh_menu_options() {
    SSH_MENU_OPTIONS=(
        "全流程自动配置（推荐） - 执行所有SSH安全配置"
        "安装OpenSSH服务器 - 安装和启动SSH服务"
        "设置允许root登录 - 配置root用户SSH登录权限"
        "设置公钥登录 - 配置SSH密钥认证"
        "设置AgentForwarding - 配置SSH代理转发"
        "生成带hostname和IP的SSH密钥对 - 创建标识性密钥"
        "退出 - 退出SSH配置程序"
    )
}

# 创建菜单选项
create_ssh_menu_options

# 主菜单循环
while true; do
    echo
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}SSH 自动配置脚本 - 操作菜单${RESET}"
    echo -e "${BLUE}系统: ${OS} ${ARCH}${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo

    # 使用键盘导航菜单选择
    select_menu "SSH_MENU_OPTIONS" "请选择要执行的SSH配置操作：" 0  # 默认选择第一项

    selected_index=$MENU_SELECT_INDEX

    case $selected_index in
        0)  # 全流程自动配置
            backup_personal_info
            install_openssh_server
            set_ssh_permit_root_login
            set_public_key_login
            set_allow_agent_forwarding
            generate_ssh_key  # 全流程包含密钥生成
            install_fail2ban
            echo "${GREEN}✔ 所有配置已完成！${RESET}"
            break
            ;;
        1)  # 安装OpenSSH服务器
            backup_personal_info
            install_openssh_server
            ;;
        2)  # 设置允许root登录
            backup_personal_info
            set_ssh_permit_root_login
            ;;
        3)  # 设置公钥登录
            backup_personal_info
            set_public_key_login
            ;;
        4)  # 设置AgentForwarding
            backup_personal_info
            set_allow_agent_forwarding
            ;;
        5)  # 生成SSH密钥对
            backup_personal_info  # 生成密钥前备份
            generate_ssh_key
            ;;
        6)  # 退出
            echo "${GREEN}退出SSH配置程序${RESET}"
            break
            ;;
        *)
            echo "${RED}✖ 无效选择，请重新选择${RESET}"
            continue
            ;;
    esac

    # 询问是否继续其他操作
    echo
    if interactive_ask_confirmation "是否继续其他SSH配置操作？" "false"; then
        continue
    else
        echo "${GREEN}SSH配置操作完成${RESET}"
        break
    fi
done

echo -e "${BLUE}================================================================${RESET}"
echo -e "${YELLOW}ℹ 系统信息：${OS} ${ARCH}${RESET}"
echo -e "${YELLOW}ℹ SSH服务状态：$(run systemctl status ${SSH_SERVICE} --no-pager)${RESET}"
echo -e "${YELLOW}ℹ 配置文件路径：/etc/ssh/sshd_config${RESET}"
echo -e "${YELLOW}ℹ 最新密钥路径：$(ls -t ~/.ssh/id_rsa_* 2>/dev/null | head -1)${RESET}"
