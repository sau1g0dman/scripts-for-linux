#!/usr/bin/env bash
# set ssh permit root login
set_ssh_permit_root_login() {
    echo "设置允许root用户登录..."
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    echo "设置完成。"
}
# set public key login
set_public_key_login() {
    echo "设置公钥登录..."
    sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    echo "设置完成。"
}

# set allowAgentForwarding
set_allow_agent_forwarding() {
    echo "设置允许AgentForwarding..."
    sudo sed -i 's/#AllowAgentForwarding yes/AllowAgentForwarding yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    echo "设置完成。"
}
# set passwd
set_passwd() {
    echo "设置密码..."
    sudo passwd
    echo "设置完成。"
}
# set sshd_config
PS3="请选择需要修改的配置："
options=("全部自动安装" "设置允许root用户登录" "设置公钥登录" "设置允许AgentForwarding" "设置密码" "退出")
select opt in "${options[@]}"
    case $opt in
        "全部自动安装")
        set_ssh_permit_root_login
        set_public_key_login
        set_allow_agent_forwarding
        set_passwd
        break
        ;;
        "设置允许root用户登录")
            set_ssh_permit_root_login
            ;;
        "设置公钥登录")
            set_public_key_login
            ;;
        "设置允许AgentForwarding")
            set_allow_agent_forwarding
            ;;
        "设置密码")
            set_passwd
            ;;
        "退出")
            break
            ;;
        *) echo "无效的选项 $REPLY";;
    esac
done


