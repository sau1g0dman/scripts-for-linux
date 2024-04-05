#!/bin/bash
generate_sshkey() {
    echo "请输入rsa密钥的名称："
    echo "默认键入enter为id_rsa"
    echo "如果不是，请输入rsa密钥的名称："
    read keyname
    if [ -z "$keyname" ]; then
        keyname="id_rsa"
    fi
    echo "请输入密钥的注释（例如你的邮箱）默认为sau1amaranth@gmail.com："
    read comment
    comment=${comment:-sau1amaranth@mail.com}

    # 如果用户没有输入注释，可以选择不添加-C参数，或者指定一个默认值
    if [ -z "$comment" ]; then
        ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/$keyname
    else
        ssh-keygen -t rsa -b 4096 -C "$comment" -f $HOME/.ssh/$keyname
    fi
}
#添加所选择的公钥到服务器
add_sshkey() {
        echo "请输入服务器ip地址："
        read ip
        echo "请输入服务器端口：(默认为22)"
        read port
        port=${port:-22}
        echo "请输入服务器用户名：(默认为root)"
        read username
        username=${username:-root}
        echo "请输入服务器密码："
        read -s password
        echo "请输入公钥文件的名称（默认为id_rsa.pub）："
        # 列出所有的公钥文件
        ls $HOME/.ssh/*.pub | xargs -n 1 basename
        read keyname
    keyname=${keyname:-id_rsa.pub}  # 简化的默认值赋值方式

    if ! sshpass -p "$password" ssh-copy-id -i "$HOME/.ssh/$keyname" -p "$port" "$username@$ip"; then
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
echo "使用方法：./ssh-keygen-auto.sh"
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
