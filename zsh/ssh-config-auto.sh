#!/usr/bin/env bash
clear
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;32m🚀 欢迎使用 ssh自动配置脚本\e[0m"
echo -e "\e[1;33m👤 作者: saul\e[0m"
echo -e "\e[1;33m📧 邮箱: sau1@maranth@gmail.com\e[0m"
echo -e "\e[1;35m🔖 version 1.0\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;36m本脚本将帮助您配合ssh-agent添加root密码登录,密钥登录。\e[0m"
echo -e "\e[1;36m请按照提示输入相关信息，然后脚本将自动完成后续操作。\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
set_ssh_permit_root_login() {
    echo "设置允许root用户登录..."
    # 备份原始的sshd_config文件
    sudo cp /etc/ssh/sshd_config{,.bak}
    echo "已备份原始配置到 /etc/ssh/sshd_config.bak"

    # 检查PermitRootLogin的当前设置
    if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
        # 如果PermitRootLogin已经存在，直接修改其值
        sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    else
        # 如果PermitRootLogin不存在，添加到文件末尾
        echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    fi

    # 重启sshd服务使更改生效
    sudo systemctl restart sshd
    echo "sshd服务已重启，设置完成。"
}

# set public key login
set_public_key_login() {
    echo "设置公钥登录..."
    # 检查PubkeyAuthentication的当前设置
    if grep -q "^PubkeyAuthentication" /etc/ssh/sshd_config; then
        # 如果PubkeyAuthentication已经存在，直接修改其值
        sudo sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    else
        # 如果PubkeyAuthentication不存在，添加到文件末尾
        echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    fi
    # 重启sshd服务使更改生效
    sudo systemctl restart sshd
    echo "sshd服务已重启，设置完成。"
}

# set allowAgentForwarding
set_allow_agent_forwarding() {
    echo "设置允许AgentForwarding..."
    if grep -q "^AllowAgentForwarding" /etc/ssh/sshd_config; then
        # 如果AllowAgentForwarding已经存在，直接修改其值
        sudo sed -i 's/^AllowAgentForwarding.*/AllowAgentForwarding yes/' /etc/ssh/sshd_config
    else
        # 如果AllowAgentForwarding不存在，添加到文件末尾
        echo "AllowAgentForwarding yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    fi
    # 重启sshd服务使更改生效
    sudo systemctl restart sshd
    echo "sshd服务已重启，设置完成。"
}

# set passwd

set_passwd() {
    echo "设置密码..."
    sudo passwd
    #restart ssh.service
    sudo systemctl restart ssh.service
    echo -e "\e[1;34m=========================================================\e[0m"
    echo -e "\e[1;32m🚀 恭喜您，ssh配置完成\e[0m"
}
#set MaxAuthTries 20
set_MaxAuthTries() {
    echo "设置最大尝试次数..."
    if grep -q "^MaxAuthTries" /etc/ssh/sshd_config; then
        # 如果MaxAuthTries已经存在，直接修改其值
        sudo sed -i 's/^MaxAuthTries.*/MaxAuthTries 20/' /etc/ssh/sshd_config
    else
        # 如果MaxAuthTries不存在，添加到文件末尾
        echo "MaxAuthTries 20" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    fi
}
# install fail2ban and setup
install_fail2ban() {
    echo "开始安装fail2ban..."

    # 更新软件包列表并安装fail2ban
    sudo apt-get update
    sudo apt-get install -y fail2ban sshpass

    if [ $? -eq 0 ]; then
        echo "fail2ban安装完成。"
    else
        echo "fail2ban安装失败，请检查日志以获取详细信息。"
        return 1
    fi

    echo "正在配置fail2ban..."

    # 检查是否存在jail.conf文件，并创建jail.local的副本
    if [ -f /etc/fail2ban/jail.conf ]; then
        sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    else
        echo "未找到默认的jail.conf配置文件。"
        return 1
    fi

    # 启用并启动fail2ban服务
    sudo systemctl enable fail2ban
    if sudo systemctl start fail2ban; then
        echo "fail2ban已成功启动并设置为开机自启。"
    else
        echo "启动fail2ban服务失败。"
        return 1
    fi

    echo "fail2ban配置完成。"
}
PS3=$(echo -e "\e[1;36m请选择需要修改的配置：\e[0m")

options=(
    $(echo -e "\e[1;32m全部自动安装\e[0m")
    $(echo -e "\e[1;34m设置允许root用户登录\e[0m")
    $(echo -e "\e[1;34m设置公钥登录\e[0m")
    $(echo -e "\e[1;34m设置允许AgentForwarding\e[0m")
    $(echo -e "\e[1;34m设置密码\e[0m")
    $(echo -e "\e[1;31m退出\e[0m")
)

echo -e "\e[1;34m=========================================================\e[0m"
COLUMNS=1
select opt in "${options[@]}"; do
    case "$opt" in
        *全部自动安装*)
            install_fail2ban
            set_ssh_permit_root_login
            set_MaxAuthTries
            set_public_key_login
            set_allow_agent_forwarding
            set_passwd
            break
            ;;
        *设置允许root用户登录*)
            set_ssh_permit_root_login
            ;;
        *设置公钥登录*)
            set_public_key_login
            ;;
        *设置允许AgentForwarding*)
            set_allow_agent_forwarding
            ;;
        *设置密码*)
            set_passwd
            ;;
        *退出*)
            break
            ;;
        *)
            echo -e "\e[1;31m无效的选项 $REPLY\e[0m"
            ;;
    esac
done
echo -e "\e[1;34m=========================================================\e[0m"
