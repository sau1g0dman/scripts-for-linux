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
# 检测jq是否安装，如果没有安装，则尝试安装
        if ! command -v jq > /dev/null; then
            echo "jq未安装。正在为您安装jq..."
            if command -v apt > /dev/null; then
                sudo apt update &> /dev/null
                sudo apt install -y jq &> /dev/null
    elif         command -v yum > /dev/null; then
                sudo yum install -y jq &> /dev/null
    else
                echo "未知的包管理器。请手动安装jq。"
                exit 1
    fi
fi

# 搜索私有仓库的镜像
search_private_image() {
    echo "请输入私有仓库地址，默认为docker.hcegcorp.com："
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}

    # 获取私有仓库镜像列表，并存储在数组中
    echo "私有仓库列表最近推送前20,并在行的最前端打上编号,从1开始"
    IFS=$'\n' read -r -d '' -a REPOSITORIES < <(curl -s -X GET "https://$REGISTRY/v2/_catalog" | jq -r '.repositories[]' && printf '\0')

    for i in "${!REPOSITORIES[@]}"; do
        echo "$((i + 1))) ${REPOSITORIES[$i]}"
    done

    echo "========================================================="
    echo "请输入镜像名称或者编号："
    read -r INPUT

    # 检测输入是编号还是名称
    if [[ "$INPUT" =~ ^[0-9]+$ ]] && [ "$INPUT" -ge 1 ] && [ "$INPUT" -le ${#REPOSITORIES[@]} ]; then
        IMAGE_NAME="${REPOSITORIES[$INPUT - 1]}"
    else
        IMAGE_NAME="$INPUT"
    fi
    # 获取选择的镜像的标签
    echo "正在获取镜像标签信息："
    TAGS=$(curl -s -X GET "https://$REGISTRY/v2/${IMAGE_NAME}/tags/list" | jq -r '.tags[]')

    if [[ "$TAGS" == "null" ]] || [ -z "$TAGS" ]; then
        echo "该镜像没有找到标签或者获取标签失败。"
        exit 1
    fi

    echo "$TAGS" | awk '{print NR ") " $0}'

    echo "========================================================="
    echo "请选择要拉取的镜像标签编号："
    read -r TAG_INDEX
    SELECTED_TAG=$(echo "$TAGS" | sed -n "${TAG_INDEX}p")

    if [ -z "$SELECTED_TAG" ]; then
        echo "输入的编号无效。"
        exit 1
    fi

    FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$SELECTED_TAG"
    echo "您选择的镜像为：$FULL_IMAGE_NAME"
    echo "正在拉取私有仓库镜像 ${FULL_IMAGE_NAME}..."

    if docker pull "$FULL_IMAGE_NAME"; then
        echo "私有仓库镜像拉取成功。"
        echo "========================================================="
        echo "本地镜像的列表:"
        docker images --format "{{.Repository}}:{{.Tag}}"
    else
        echo "拉取私有仓库镜像失败，请检查镜像名称或标签是否正确。"
        exit 1
    fi
}
docker_push() {
    echo "请输入要搜索的公共镜像名称："
    read -r IMAGE_NAME

    # 搜索镜像并显示结果
    echo "搜索镜像中..."
    docker search "$IMAGE_NAME" | awk 'NR==1 {print $0; next} {print NR-1 ") " $0}'

    # 存储镜像名称到一个数组中，用于后续拉取操作
    echo "========================================================="
    mapfile -t IMAGES < <(docker search "$IMAGE_NAME" | awk 'NR>1 {print $1}')
    if [ ${#IMAGES[@]} -eq 0 ]; then
        echo "未找到任何相关镜像。"
        exit 1
    fi

    echo "请输入要拉取的镜像编号："
    read -r IMAGE_INDEX
    if ! [[ "$IMAGE_INDEX" =~ ^[0-9]+$ ]] || [ "$IMAGE_INDEX" -lt 1 ] || [ "$IMAGE_INDEX" -gt ${#IMAGES[@]} ]; then
        echo "输入的编号无效。"
        exit 1
    fi
    SELECTED_IMAGE="${IMAGES[$IMAGE_INDEX - 1]}"
    echo "您选择的镜像为：$SELECTED_IMAGE"

    # 获取并选择镜像标签
    echo "正在获取镜像的标签列表..."
    TAGS_JSON=$(curl -s "https://hub.docker.com/v2/repositories/library/${SELECTED_IMAGE}/tags/?page_size=20")
    mapfile -t TAGS < <(echo "$TAGS_JSON" | jq -r '.results[].name' | awk '{print NR ") " $0}')

    if [ ${#TAGS[@]} -eq 0 ]; then
        echo "未找到任何相关标签。"
        exit 1
    fi

    echo "以下是可用的镜像标签（展示前20个结果）："
    for tag in "${TAGS[@]}"; do
        echo "$tag"
    done
    echo"============================================================="
    echo "请输入要拉取的镜像标签编号。如果列表中没有您想要的标签，请输入tag:<tagname>（例如tag:latest）："
    read -r TAG_INPUT

    # 初始化变量SELECTED_TAG
    SELECTED_TAG=""

    # 检查用户输入的是否以"tag:"开头
    if [[ "$TAG_INPUT" =~ ^tag:(.+) ]]; then
        # 用户指定了标签名，直接提取
        SELECTED_TAG="${BASH_REMATCH[1]}"
    else
        # 尝试按编号处理
        TAG_INDEX="$TAG_INPUT"
        if [[ "$TAG_INDEX" =~ ^[0-9]+$ ]] && [ "$TAG_INDEX" -gt 0 ] && [ "$TAG_INDEX" -le ${#TAGS[@]} ]; then
            SELECTED_TAG=$(echo "${TAGS[$TAG_INDEX - 1]}" | sed 's/^[0-9]*) //')
        else
            echo "输入无效。请使用有效的编号或者tag:<tagname>格式指定标签。"
            exit 1
        fi
    fi

    # 继续之前的拉取镜像操作
    FULL_IMAGE_NAME="$SELECTED_IMAGE:$SELECTED_TAG"
    echo "正在拉取公共镜像 ${FULL_IMAGE_NAME}..."
    if docker pull "$FULL_IMAGE_NAME"; then
        echo "公共镜像拉取成功。"
    else
        echo "拉取公共镜像失败，请检查镜像名称或标签是否正确。"
        exit 1
    fi
    echo "========================================================="
    echo "请输入私有仓库地址,默认为docker.hcegcorp.com"
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}

    echo "正在标记镜像并推送到私有仓库..."
    if docker tag "$FULL_IMAGE_NAME" "$REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"; then
        echo "镜像标记成功。"
    else
        echo "标记镜像失败，请检查以下可能的原因："
        echo "1. 输入的镜像名称或标签错误。"
        echo "2. 无法连接到私有仓库。"
        echo "请根据上述提示检查您的输入或网络连接，然后重试。"
        exit 1
    fi
    echo "正在推送镜像到私有仓库"
    echo "========================================================="
    echo "docker命令为:docker push $REGISTRY/$SELECTED_IMAGE:SELECTED_TAG"
    if ! docker push "$REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"; then
        echo "推送镜像失败，请检查以下可能的原因："
        echo "1. 输入的镜像名称或标签错误。"
        echo "2. 无法连接到私有仓库。"
        echo "3. 没有权限推送镜像到私有仓库。"
        echo "请根据上述提示检查您的输入、网络连接或权限，然后重试。"
        exit 1
    fi
    echo "镜像推送成功。"
    echo "是否删除镜像,请输入yes/y/enter或no/n:"
    read -r DELETE_IMAGE
    echo "=========================================================="
    echo "docker命令为:docker rmi $FULL_IMAGE_NAME"
    if [[ $DELETE_IMAGE == "yes" || $DELETE_IMAGE == "y" || $DELETE_IMAGE == "" ]]; then
        echo "正在删除本地镜像..."
        if docker rmi "$FULL_IMAGE_NAME"; then
            echo "镜像 $FULL_IMAGE_NAME 已从本地删除。"
        else
            echo "镜像 $FULL_IMAGE_NAME 删除失败，可能已被删除或不存在。"
        fi
    else
        echo "保留本地镜像。"
    fi
    # 然后尝试删除推送到私有仓库后的镜像标记
    if docker rmi "$REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"; then
        echo "========================================================="
        echo "docker命令为:docker rmi $REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"
        echo "镜像 $REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG 已从本地删除。"
    else
        echo "========================================================="
        echo "docker命令为:docker rmi $REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"
        echo "镜像 $REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG 删除失败，可能已被删除或不存在。"
    fi
        echo "保留本地镜像。"
    #询问是否修改daemon.json,并重启docker,这样会加速拉取镜像
    echo "是否修改daemon,并重启docker,这样会添加私有仓库,加速拉取镜像,请输入yes/y/enter或no/n:"
    read -r DAEMON_ALTER
    if [[ $DAEMON_ALTER == "yes" || $DAEMON_ALTER == "y" || $DAEMON_ALTER == "" ]]; then
        alter_daemon
    else
        echo "保留daemon.json。"
    fi
    echo "脚本执行完成。"
    echo "从私有仓库拉取镜像的命令为："
    echo "docker pull $REGISTRY/$SELECTED_IMAGE:SELECTED_TAG"
}
alter_daemon() {
    echo "请输入私有仓库地址（默认为docker.hcegcorp.com）："
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}

    DAEMON_JSON_PATH="/etc/docker/daemon.json"

    # 确保daemon.json文件存在，如果不存在，则创建
    if [ ! -f "$DAEMON_JSON_PATH" ]; then
        echo "{}" > "$DAEMON_JSON_PATH"
    fi

    # 检查私有仓库地址是否已存在于registry-mirrors中
    if jq -e --arg registry "https://$REGISTRY" '.["registry-mirrors"] | index($registry)' "$DAEMON_JSON_PATH" > /dev/null; then
        echo "私有仓库地址已存在于daemon.json中，无需重复添加。"
    else
        # 如果文件已经存在,先备份
        cp "$DAEMON_JSON_PATH" "$DAEMON_JSON_PATH.bak"
        # 使用jq添加私有仓库地址到registry-mirrors数组的开头，如果文件已存在
        TEMP_FILE=$(mktemp)
        jq --arg registry "https://$REGISTRY" '.["registry-mirrors"] += [$registry]' "$DAEMON_JSON_PATH" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DAEMON_JSON_PATH"
        echo "私有仓库地址已添加到daemon.json中。"

        # 重启Docker服务以应用更改
        echo "正在重启Docker服务..."
        sudo systemctl restart docker

        # 检查Docker服务状态
        if systemctl is-active --quiet docker; then
            echo "Docker服务已成功重启。"
        else
            echo "Docker服务重启失败，请检查daemon.json的配置或查看Docker服务的日志获取详细信息。"
        fi
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

    echo "正在标记镜像并推送到私有仓库..."
    docker tag "$SELECTED_IMAGE" "$FULL_TAG"

    echo "正在推送镜像到私有仓库..."
    if docker push "$FULL_TAG"; then
        echo "镜像成功推送到私有仓库：$FULL_TAG"
        # 列出远端私有仓库镜像列表
        echo "========================================================="
        echo "远端私有仓库列表:"
        # 注意：这里的命令描述可能会引起混淆，因为实际上我们使用的是curl命令而不是docker命令。
        # 因此，我建议直接输出结果而不是先输出命令描述。
        curl -s -X GET "https://$REGISTRY/v2/_catalog" | jq -r '.repositories[]'

    else
        echo "推送镜像失败，请检查网络连接或私有仓库权限。"
        exit 1
    fi
    #  从本地镜像列表中选择镜像推送到私有仓库后,删除本地打了私有仓库标签的镜像
    echo "是否删除镜像,请输入yes/y/enter或no/n:"
    read -r DELETE_IMAGE
    echo "========================================================="
    echo "docker命令为:docker rmi $FULL_TAG"
    if [[ $DELETE_IMAGE == "yes" || $DELETE_IMAGE == "y" || $DELETE_IMAGE == "" ]]; then
        echo "正在删除本地镜像..."
        if docker rmi "$FULL_TAG"; then
            echo "镜像 $FULL_TAG 已从本地删除。"
        else
            echo "镜像 $FULL_TAG 删除失败，可能已被删除或不存在。"
        fi
    else
        echo "保留本地镜像。"
    fi
}
# 交互式选择操作
PS3="请选择操作："
options=("搜索并推送公共镜像到私有仓库" "从私有仓库拉取镜像" "推送本地镜像到私有仓库" "修改daemon.json并重启Docker" "恢复daemon.json并重启Docker" "退出")
select opt in "${options[@]}"; do
    case $opt in
        "搜索并推送公共镜像到私有仓库")
            docker_push
            break
            ;;
        "从私有仓库拉取镜像")
            search_private_image
            break
            ;;
        "推送本地镜像到私有仓库")
            push_local_images
            break
            ;;
        "修改daemon.json并重启Docker")
            alter_daemon
            break
            ;;
        "恢复daemon.json并重启Docker")
            undone_alternation
            break
            ;;
        "退出")
            break
            ;;
        *) echo "无效的选项 $REPLY" ;;
    esac
done
