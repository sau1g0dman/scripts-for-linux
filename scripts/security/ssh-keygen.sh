#!/bin/bash
clear
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;32m 欢迎使用 ssh-agent自动配置脚本\e[0m"
echo -e "\e[1;33m 作者: saul\e[0m"
echo -e "\e[1;33m 邮箱: sau1amaranth@gmail.com\e[0m"
echo -e "\e[1;35m 版本: 1.0\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;36m本脚本将帮助您配合ssh-agent添加root密码登录,自动生成sshkey,并将公钥添加到指定服务器。\e[0m"
echo -e "\e[1;36m请按照提示输入相关信息，然后脚本将自动完成后续操作。\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
generate_sshkey() {
    echo "请输入rsa密钥的名称："
    echo "默认键入enter为id_rsa"
    echo "如果不是，请输入rsa密钥的名称："
    read keyName
    keyName=${keyName:-id_rsa}  # 优化默认值赋值方式

    # 使用环境变量和命令获取当前的用户和主机名作为注释的默认值
    default_comment="${USER}@$(hostname)"
    echo -e "\e[1;36m请输入密钥的注释（例如你的邮箱），默认为${default_comment}：\e[0m"
    read comment
    comment=${comment:-$default_comment}

    # 直接使用-C参数指定注释，无需判断comment是否为空
    ssh-keygen -t rsa -b 4096 -C "$comment" -f $HOME/.ssh/$keyName
    echo -e "\033[32m密钥已生成，文件保存在 $HOME/.ssh/$keyName\033[0m"
}
#添加所选择的公钥到服务器
add_sshkey() {
        sudo apt install sshpass -y &> /dev/null
        prompt="$(whoami)@$(hostname) > "
        echo -e "\e[1;36m请输入服务器ip地址：\e[0m"
        read ip
        echo "输入的IP为: $ip"
        echo -e "\e[1;36m请输入服务器端口：(默认为22)\e[0m"
        read port
        port=${port:-22}
    #        echo "输入的端口为: $port"
        echo -e "\e[1;36m输入的端口为: $port\e[0m"
        echo -e "\e[1;36m请输入服务器用户名：(默认为root)\e[0m"
        read username
        username=${username:-root}
    echo -e "\e[1;36m输入的用户名为: $username\e[0m"
    echo -e "\e[1;36m请输入服务器密码：\e[0m"
        read -s password
    echo -e "\e[1;36m密码已输入。\e[0m"
            # 自动添加远程主机的SSH公钥到known_hosts以避免手动确认
        echo "正在添加远程主机的SSH公钥到known_hosts..."
        ssh-keyscan -H -p $port $ip >> ~/.ssh/known_hosts 2> /dev/null
        echo -e "\033[32m已添加远程主机的SSH公钥到known_hosts。\033[0m"

        echo "以下是可用的公钥文件："
        pub_keys=($HOME/.ssh/*.pub) # 将公钥文件名存储到数组
        #彩色字体显示公钥文件
        Color='\033[32m'  # 绿色
        for i in "${!pub_keys[@]}"; do
            echo -e "$Color$((i + 1))) ${pub_keys[$i]##*/}\033[0m" # 显示序号和文件名
    done

        echo "请输入公钥文件对应的序号（默认为1）："
        read key_index
        key_index=${key_index:-1}  # 默认选择第一个公钥文件

        # 验证输入的序号是否有效
        if [[ $key_index -le 0 || $key_index -gt ${#pub_keys[@]} ]]; then
            echo "输入的序号无效，将使用默认的公钥文件。"
            keyName="${pub_keys[0]##*/}" # 如果输入无效，默认使用数组中的第一个公钥文件
    else
            keyName="${pub_keys[$key_index - 1]##*/}" # 从数组中获取选择的公钥文件名
    fi

    echo -e "\033[32m选择的公钥文件为: $keyName\033[0m"
    if ! sshpass -p "$password" ssh-copy-id -i "$HOME/.ssh/$keyName" -p "$port" "$username@$ip"; then
        echo "sshpass的命令为: sshpass -p $password ssh-copy-id -i $HOME/.ssh/$keyName -p $port $username@$ip "
        echo -e "\033[31m公钥添加失败，请检查以下可能的原因：\033[0m"
        echo "1. 服务器IP地址或端口号输入错误。"
        echo "2. 服务器用户名或密码错误。"
        echo "3. 指定的公钥文件不存在。"
        echo "4. ssh-copy-id命令未正确执行，可能是因为sshpass未安装，或远程服务器不允许密码认证。"
        echo "请根据上述提示检查您的输入或配置，然后重试。"
        return 1  # 返回一个非零值表示失败

    else
        ssh-add $HOME/.ssh/* &> /dev/null
        echo -e "\033[32m公钥 $HOME/.ssh/$keyName 添加成功\033[0m"
        echo "ssh-agent已经添加了新的密钥。"
        echo -e "\033[32m现在您可以通过ssh $username@$ip -p $port登录服务器。\033[0m"
    fi
}

#PS3="请选择操作："
PS3=$(echo -e "\e[1;36m请选择操作：\e[0m")
options=(
    $(echo -e "\e[1;32m生成密钥\e[0m")
    $(echo -e "\e[1;34m添加公钥到服务器\e[0m")
    $(echo -e "\e[1;31m退出\e[0m")
)
COLUMNS=1
select action in "${options[@]}"; do
    case $action in
        *生成密钥*)
            generate_sshkey
            ;;
        *添加公钥到服务器*)
            add_sshkey
            ;;
        *退出*)
            break
            ;;
        *)
            echo -e "\e[1;31m无效的选择，请重新选择。\e[0m"
            ;;
    esac
done
echo -e "\e[1;34m================================================================\e[0m"
