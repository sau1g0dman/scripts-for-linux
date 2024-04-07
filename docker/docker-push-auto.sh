#!/usr/bin/env bash
# 检查是否安装了Docker
if ! command -v docker &> /dev/null; then
    echo "错误: 未找到Docker，请先安装Docker。"
    exit 1
fi
# daemon.json 的路径
    DAEMON_JSON_PATH="/etc/docker/daemon.json"
# 启动脚本后清空屏幕
clear
echo "========================================================="
echo "欢迎使用Docker镜像推送脚本"
echo "作者saul"
echo "邮箱sau1amaranth@gmail.com"
echo "version 1.0"
echo "========================================================="
echo "本脚本将帮助您搜索、拉取、标记并推送公共Docker镜像到私有仓库。"
echo "请按照提示输入相关信息，然后脚本将自动完成后续操作。"
echo "========================================================="
docker_push() {
    # 交互式输入公共镜像名称和标签
    echo "请输入要搜索的公共镜像名称："
    read -r IMAGE_NAME

    echo "搜索镜像中..."
    # 使用 docker search 并通过 awk 在每一行前添加行号
    docker search "$IMAGE_NAME" | awk 'NR==1 {print $0; next} {print NR-1 ") " $0}'
    echo "========================================================="
    echo "docker命令为:docker search $IMAGE_NAME"
    # 存储镜像名称到一个数组中，用于后续拉取操作
    mapfile -t IMAGES < <(docker search "$IMAGE_NAME" | awk 'NR>1 {print $1}')

    if [ ${#IMAGES[@]} -eq 0 ]; then
        echo "未找到任何相关镜像。"
        exit 1
    fi

    echo "请输入要拉取的镜像编号："
    read -r IMAGE_INDEX

    # 确保用户输入的编号是有效的数字，并在允许的范围内
    if ! [[ "$IMAGE_INDEX" =~ ^[0-9]+$ ]] || [ "$IMAGE_INDEX" -lt 1 ] || [ "$IMAGE_INDEX" -gt ${#IMAGES[@]} ]; then
        echo "输入的编号无效。"
        exit 1
    fi
    SELECTED_IMAGE="${IMAGES[$IMAGE_INDEX - 1]}"

    echo "您选择的镜像为：$SELECTED_IMAGE"

    # 询问用户需要的标签
    echo "请输入要拉取的镜像标签（默认为latest）："
    read -r IMAGE_TAG
    IMAGE_TAG=${IMAGE_TAG:-latest}

    FULL_IMAGE_NAME="$SELECTED_IMAGE:$IMAGE_TAG"
    echo "正在拉取公共镜像 ${FULL_IMAGE_NAME}..."
    echo "========================================================="
    echo "docker命令为:docker pull $FULL_IMAGE_NAME"
    if docker pull "$FULL_IMAGE_NAME"; then
        echo "公共镜像拉取成功。"
    else
        echo "拉取公共镜像失败，请检查镜像名称或标签是否正确。"
        exit 1
    fi

    # 读取用户输入的私有仓库地址
    echo "请输入私有仓库地址（默认为docker.hcegcorp.com）："
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}

    # 标记并推送到私有仓库
    echo "正在标记镜像并推送到私有仓库..."
    echo "========================================================="
    echo "docker命令为:docker tag $FULL_IMAGE_NAME $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"
    if ! docker tag "$FULL_IMAGE_NAME" "$REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"; then
        echo "标记镜像失败，请检查以下可能的原因："
        echo "1. 输入的镜像名称或标签错误。"
        echo "2. 无法连接到私有仓库。"
        echo "请根据上述提示检查您的输入或网络连接，然后重试。"
        exit 1
    fi
    echo "镜像标记成功。"
    echo "正在推送镜像到私有仓库..."
    echo "========================================================="
    echo "docker命令为:docker push $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"
    if ! docker push "$REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"; then
        echo "推送镜像失败，请检查以下可能的原因："
        echo "1. 输入的镜像名称或标签错误。"
        echo "2. 无法连接到私有仓库。"
        echo "3. 没有权限推送镜像到私有仓库。"
        echo "请根据上述提示检查您的输入、网络连接或权限，然后重试。"
        exit 1
    fi
    echo "镜像推送成功。"
    # 清理本地镜像
    echo "是否删除镜像,请输入yes/y/enter或no/n:"
    read -r DELETE_IMAGE
    echo "========================================================="
    echo "docker命令为:docker rmi $FULL_IMAGE_NAME"
    if [[ $DELETE_IMAGE == "yes" || $DELETE_IMAGE == "y" || $DELETE_IMAGE == "" ]]; then
        echo "正在删除本地镜像..."
        # 首先尝试删除原始镜像名称
        if docker rmi "$FULL_IMAGE_NAME"; then
            echo "原始镜像 $FULL_IMAGE_NAME 已删除。"
        else
            echo "原始镜像 $FULL_IMAGE_NAME 删除失败，可能已被删除或不存在。"
        fi

        # 然后尝试删除推送到私有仓库后的镜像标记
        if docker rmi "$REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"; then
            echo "========================================================="
            echo "docker命令为:docker rmi $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"
            echo "镜像 $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG 已从本地删除。"
        else
            # 如果镜像已经被删除，或者不存在，则会执行这里
            echo "========================================================="
            echo "docker命令为:docker rmi $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"
            echo "镜像 $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG 删除失败，可能已被删除或不存在。"
        fi
    else
        echo "保留本地镜像。"
    fi
    #询问是否修改daemon.json,并重启docker,这样会加速拉取镜像
    echo "是否修改daemon.json,并重启docker,这样会加速拉取镜像,请输入yes/y/enter或no/n:"
    read -r MODIFY_DAEMON_JSON
    echo "脚本执行完成。"
    echo "从私有仓库拉取镜像的命令为："
    echo "docker pull $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"
}

alter_daemon() {
    # 检测jq是否安装，如果没有安装，则尝试安装
    echo "正在检查jq是否安装..."
    if ! command -v jq > /dev/null; then
        echo "jq未安装。正在为您安装jq..."
        if command -v apt > /dev/null; then
            sudo apt update &> /dev/null
            sudo apt install -y jq &> /dev/null
        elif command -v yum > /dev/null; then
            sudo yum install -y jq &> /dev/null
        else
            echo "未知的包管理器。请手动安装jq。"
            exit 1
        fi
    fi
    echo "jq已安装,不用重复安装。"
    # 从用户那里获取私有仓库地址
    echo "请输入私有仓库地址（默认为docker.hcegcorp.com）："
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}

    # 确保daemon.json文件存在，如果不存在，则创建并初始化registry-mirrors
    if [ ! -f "$DAEMON_JSON_PATH" ]; then
        echo "{\"registry-mirrors\": [\"https://$REGISTRY\"]}" > "$DAEMON_JSON_PATH"
    else
        #如果文件已经存在,先备份
        cp "$DAEMON_JSON_PATH" "$DAEMON_JSON_PATH.bak"
        # 使用jq添加私有仓库地址到registry-mirrors数组的开头，如果文件已存在
        TEMP_FILE=$(mktemp)
        jq --arg registry "https://$REGISTRY" '.["registry-mirrors"] = [$registry] + .["registry-mirrors"] // []' "$DAEMON_JSON_PATH" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DAEMON_JSON_PATH"
    fi

    # 重启Docker服务以应用更改
    echo "正在重启Docker服务..."
    sudo systemctl restart docker

    # 检查Docker服务状态
    if systemctl is-active --quiet docker; then
        echo "Docker服务已成功重启。"
    else
        echo "Docker服务重启失败，请检查daemon.json的配置或查看Docker服务的日志获取详细信息。"
    fi
}
#恢复daemon.json
undone_alternation() {
    # 恢复daemon.json
    if [ -f "$DAEMON_JSON_PATH.bak" ]; then
        mv "$DAEMON_JSON_PATH.bak" "$DAEMON_JSON_PATH"
    else
        rm "$DAEMON_JSON_PATH"
    fi

    # 重启Docker服务以应用更改
    echo "正在重启Docker服务..."
    sudo systemctl restart docker

    # 检查Docker服务状态
    if systemctl is-active --quiet docker; then
        echo "Docker服务已成功重启。"
    else
        echo "Docker服务重启失败，请检查daemon.json的配置或查看Docker服务的日志获取详细信息。"
    fi
}
# 列出本地镜像列表,存在数组里,在前面标上序号,方便用户选择,并推送到私有仓库
push_local_images() {
    echo "正在获取本地镜像列表..."
    readarray -t IMAGES < <(docker images --format "{{.Repository}}:{{.Tag}}")
    echo "========================================================="
    echo "docker命令为:docker images --format \"{{.Repository}}:{{.Tag}}\""
    if [ ${#IMAGES[@]} -eq 0 ]; then
        echo "未找到任何本地镜像。"
        exit 1
    fi

    echo "以下是本地镜像列表："
    for i in "${!IMAGES[@]}"; do
        echo "$((i + 1))) ${IMAGES[$i]}"
    done

    echo "请输入要推送的本地镜像编号："
    read -r IMAGE_INDEX

    if ! [[ "$IMAGE_INDEX" =~ ^[0-9]+$ ]] || [ "$IMAGE_INDEX" -lt 1 ] || [ "$IMAGE_INDEX" -gt ${#IMAGES[@]} ]; then
        echo "输入的编号无效。"
        exit 1
    fi

    # 用户输入的是基于1的索引，需要转换为基于0的索引
    SELECTED_IMAGE=${IMAGES[$IMAGE_INDEX - 1]}

    echo "您选择的镜像为：$SELECTED_IMAGE"

    echo "请输入私有仓库地址（默认为docker.hcegcorp.com）："
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}
    # 提取镜像名和标签，移除任何存在的仓库地址
    IFS='/' read -ra ADDR <<< "$SELECTED_IMAGE"
    CLEAN_IMAGE_NAME="${ADDR[-1]}"

    FULL_TAG="$REGISTRY/$CLEAN_IMAGE_NAME"
#    # 从选定的镜像字符串中提取镜像名和标签
#    IFS=':' read -r IMAGE_NAME IMAGE_TAG <<< "$SELECTED_IMAGE"
#
#    # 如果镜像名称包含仓库地址，则移除它
#    IMAGE_NAME="${IMAGE_NAME##*/}"
#
#    FULL_TAG="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

    echo "正在标记镜像并推送到私有仓库..."
    docker tag "$SELECTED_IMAGE" "$FULL_TAG"

    echo "正在推送镜像到私有仓库..."
    if docker push "$FULL_TAG"; then
        echo "镜像成功推送到私有仓库：$FULL_TAG"
        # 列出远端私有仓库镜像列表
        echo "========================================================="
        echo "远端私有仓库列表:"
        # 检测jq是否安装，如果没有安装，则尝试安装
        echo "正在检查jq是否安装..."
        if ! command -v jq > /dev/null; then
            echo "jq未安装。正在为您安装jq..."
            if command -v apt > /dev/null; then
                sudo apt update &> /dev/null
                sudo apt install -y jq &> /dev/null
            elif command -v yum > /dev/null; then
                sudo yum install -y jq &> /dev/null
            else
                echo "未知的包管理器。请手动安装jq。"
                exit 1
            fi
        fi
        echo "jq已安装,不用重复安装。"
        curl -s -X GET "https://$REGISTRY/v2/_catalog" | jq -r '.repositories[]'
        # 列出已推送的镜像的信息
        echo "========================================================="
        echo "已推送镜像信息:"
        curl -s -X GET "https://$REGISTRY/v2/$IMAGE_NAME/tags/list" | jq -r '.tags[]'
    else
        echo "推送镜像失败，请检查网络连接或私有仓库权限。"
        exit 1
    fi
}
# 交互式选择操作
PS3="请选择操作："
select action in "推送公共镜像" "修改daemon.json" "恢复daemon.json" "推送本地镜像" "退出"; do
    case $action in
        "推送公共镜像")
            docker_push
            break
            ;;
        "修改daemon.json")
            alter_daemon
            break
            ;;
        "恢复daemon.json")
            undone_alternation
            break
            ;;
        "推送本地镜像")
            push_local_images
            break
            ;;
        "退出")
            break
            ;;
        *)
            echo "无效的选择，请重新选择。"
            ;;
    esac
done
