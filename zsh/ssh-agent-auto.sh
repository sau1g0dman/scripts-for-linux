#!/bin/bash
generate_sshkey() {
    echo "请输入rsa密钥的名称："
    echo "默认键入enter为id_rsa"
    echo "如果不是，请输入rsa密钥的名称："
    read keyname
    keyname=${keyname:-id_rsa}  # 优化默认值赋值方式

    # 使用环境变量和命令获取当前的用户和主机名作为注释的默认值
    default_comment="${USER}@$(hostname)"
    echo "请输入密钥的注释（例如你的邮箱），默认为${default_comment}："
    read comment
    comment=${comment:-$default_comment}

    # 直接使用-C参数指定注释，无需判断comment是否为空
    ssh-keygen -t rsa -b 4096 -C "$comment" -f $HOME/.ssh/$keyname
}
#添加所选择的公钥到服务器
add_sshkey() {
        sudo apt install sshpass -y &> /dev/null
        prompt="`whoami`@`hostname` > "
        echo -n "${prompt}请输入服务器ip地址："
        read ip
        echo "输入的IP为: $ip"

        echo -n "${prompt}请输入服务器端口：(默认为22) "
        read port
        port=${port:-22}
        echo "输入的端口为: $port"

        echo -n "${prompt}请输入服务器用户名：(默认为root) "
        read username
        username=${username:-root}
        echo "输入的用户名为: $username"

        echo -n "${prompt}请输入服务器密码："
        read -s password
        echo -e "\n密码已输入。"

        echo "以下是可用的公钥文件："
        pub_keys=($HOME/.ssh/*.pub) # 将公钥文件名存储到数组
        for i in "${!pub_keys[@]}"; do
            echo "$((i+1))) ${pub_keys[$i]##*/}" # 显示序号和文件名
        done

        echo "请输入公钥文件对应的序号（默认为1）："
        read key_index
        key_index=${key_index:-1}  # 默认选择第一个公钥文件

        # 验证输入的序号是否有效
        if [[ $key_index -le 0 || $key_index -gt ${#pub_keys[@]} ]]; then
            echo "输入的序号无效，将使用默认的公钥文件。"
            keyname="${pub_keys[0]##*/}" # 如果输入无效，默认使用数组中的第一个公钥文件
        else
            keyname="${pub_keys[$key_index-1]##*/}" # 从数组中获取选择的公钥文件名
        fi

        echo "选择的公钥文件为: $keyname"
    if ! sshpass -p "$password" ssh-copy-id -i "$HOME/.ssh/$keyname" -p "$port" "$username@$ip"; then
        echo "sshpass的命令为: sshpass -p $password ssh-copy-id -i $HOME/.ssh/$keyname -p $port $username@$ip "
        echo -e "\033[31m公钥添加失败，请检查以下可能的原因：\033[0m"
        echo "1. 服务器IP地址或端口号输入错误。"
        echo "2. 服务器用户名或密码错误。"
        echo "3. 指定的公钥文件不存在。"
        echo "4. ssh-copy-id命令未正确执行，可能是因为sshpass未安装，或远程服务器不允许密码认证。"
        echo "请根据上述提示检查您的输入或配置，然后重试。"
        return 1  # 返回一个非零值表示失败

    else
        ssh-add $HOME/.ssh/* &> /dev/null
        echo -e "\033[32m公钥 $HOME/.ssh/$keyname 添加成功\033[0m"
        echo "ssh-agent已经添加了新的密钥。"
        echo "现在您可以通过ssh $username@$ip -p $port登录服务器。"
    fi
}
echo "================================================="
echo "作者：saul"
echo "时间：2024-04-05"
echo "程序描述：本脚本用于自动生成sshkey,并将公钥添加到指定服务器"
echo "使用方法：./ssh-agent-auto.sh"
echo "根据提示输入rsa密钥的名称,并生成密钥"
echo "================================================="
PS3="请选择操作："
select action in "生成密钥" "添加公钥到服务器" "退出"; do
    case $action in
        "生成密钥")
            generate_sshkey
            ;;
        "添加公钥到服务器")
            add_sshkey
            ;;
        "退出")
            break
            ;;
        *)
            echo "无效的选择，请重新选择。"
            ;;
    esac
done
