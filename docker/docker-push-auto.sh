#!/usr/bin/env bash
# 检查是否安装了Docker
COLOR_GREEN='\033[32m'  # 绿色
COLOR_RED='\033[31m'  # 红色
COLOR_BLUE='\033[34m'  # 蓝色
if ! command -v docker &> /dev/null; then
    echo -e "\e${COLOR_RED}错误: 未找到Docker，请先安装Docker。是否安装docker? 请输入yes/y/enter或no/n:\e[0m"
    read -r INSTALL_DOCKER
    if [[ $INSTALL_DOCKER == "yes" || $INSTALL_DOCKER == "y" || $INSTALL_DOCKER == "" ]]; then
        echo -e "\e${COLOR_GREEN}正在安装Docker...\e[0m"
        bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh)
        echo -e "\e${COLOR_GREEN}正在安装lazydocker...\e[0m"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    else
        echo -e "\e${COLOR_RED}未安装Docker。请先安装Docker。\e[0m"
        exit 1
    fi
fi
# daemon.json 的路径
    DAEMON_JSON_PATH="/etc/docker/daemon.json"
# 启动脚本后清空屏幕
clear
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;32m🚀 欢迎使用 Docker 镜像推送脚本\e[0m"
echo -e "\e[1;33m👤 作者: saul\e[0m"
echo -e "\e[1;33m📧 邮箱: sau1@maranth@gmail.com\e[0m"
echo -e "\e[1;35m🔖 version 1.1\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;36m本脚本将帮助您搜索、拉取、标记并推送公共Docker镜像到私有仓库 DockerRegistry。\e[0m"
echo -e "\e[1;36m请按照提示输入相关信息，然后脚本将自动完成后续操作。\e[0m"
echo -e "\e[1;34m================================================================\e[0m"

# 检测jq是否安装，如果没有安装，则尝试安装

        if ! command -v jq > /dev/null; then
    echo -e "\e${COLOR_BLUE}jq未安装。正在为您安装jq...\e[0m"
            if command -v apt > /dev/null; then
                sudo apt update &> /dev/null
                sudo apt install -y jq &> /dev/null
    elif         command -v yum > /dev/null; then
                sudo yum install -y jq &> /dev/null
    else
        echo -e "\e${COLOR_RED}未知的包管理器。请手动安装jq。\e[0m"
                exit 1
    fi
fi

#TODO
docker_push_container() {
    echo -e "\e${COLOR_BLUE}列出本地容器列表...\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    CONTAINERS=$(docker ps --format "{{.ID}}: {{.Names}}")
    if [ -z "$CONTAINERS" ]; then
        echo -e "\e${COLOR_RED}未找到任何正在运行的容器。\e[0m"
        exit 1
    fi
    echo -e "\e${COLOR_BLUE}以下是正在运行的容器列表：\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo "$CONTAINERS" | awk '{print NR ") " $0}'
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}请输入要提交为新镜像的容器编号：\e[0m"
    read -r CONTAINER_INDEX
    if ! [[ "$CONTAINER_INDEX" =~ ^[0-9]+$ ]] || [ "$CONTAINER_INDEX" -lt 1 ] || [ "$CONTAINER_INDEX" -gt $(echo "$CONTAINERS" | wc -l) ]; then
        echo -e "\e${COLOR_RED}输入的编号无效。\e[0m"
        exit 1
    fi
    CONTAINER_ID=$(echo "$CONTAINERS" | sed -n "${CONTAINER_INDEX}p" | awk '{print $1}')
    CONTAINER_NAME=$(echo "$CONTAINERS" | sed -n "${CONTAINER_INDEX}p" | awk '{print $3}')
    echo -e "\e${COLOR_GREEN}您选择的容器为：$CONTAINER_NAME\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}请输入新镜像的名称：\e[0m"
    read -r IMAGE_NAME
    echo -e "\e${COLOR_BLUE}请输入新镜像的标签：\e[0m"
    read -r IMAGE_TAG
    NEW_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_GREEN}正在提交容器 $CONTAINER_NAME 为新镜像 $NEW_IMAGE_NAME...\e[0m"
}

# 搜索私有仓库的镜像
search_private_image() {
    echo -e "\e${COLOR_BLUE}请输入私有仓库地址，默认为docker.hcegcorp.com：\e[0m"
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}

    # 获取私有仓库镜像列表，并存储在数组中
    echo -e "\e${COLOR_GREEN}私有仓库列表最近推送前20,并在行的最前端打上编号,从1开始\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    IFS=$'\n' read -r -d '' -a REPOSITORIES < <(curl -s -X GET "https://$REGISTRY/v2/_catalog" | jq -r '.repositories[]' && printf '\0')

    for i in "${!REPOSITORIES[@]}"; do
        echo -e "\e${COLOR_GREEN}$((i + 1))) ${REPOSITORIES[$i]}\e[0m"
    done
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"

    echo -e "\e${COLOR_BLUE}请输入镜像名称或者编号：\e[0m"

    read -r INPUT

    # 检测输入是编号还是名称
    if [[ "$INPUT" =~ ^[0-9]+$ ]] && [ "$INPUT" -ge 1 ] && [ "$INPUT" -le ${#REPOSITORIES[@]} ]; then
        IMAGE_NAME="${REPOSITORIES[$INPUT - 1]}"
    else
        IMAGE_NAME="$INPUT"
    fi
    echo -e "\e${COLOR_BLUE}正在获取镜像的标签列表"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    TAGS=$(curl -s -X GET "https://$REGISTRY/v2/${IMAGE_NAME}/tags/list" | jq -r '.tags[]')

    if [[ "$TAGS" == "null" ]] || [ -z "$TAGS" ]; then
        echo "该镜像没有找到标签或者获取标签失败。"
        exit 1
    fi

    #    echo "$TAGS" | awk '{print NR ") " $0}'
    echo -e "\e${COLOR_BLUE}以下是可用的镜像标签（展示前20个结果）：\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    IFS=$'\n' read -r -d '' -a TAGS < <(echo "$TAGS" | awk '{print NR ") " $0}' && printf '\0')
    for tag in "${TAGS[@]}"; do
        echo -e "\e${COLOR_GREEN}$tag\e[0m"
    done
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}请输入要拉取的镜像标签编号：按下enter,自动选择第一项\e[0m"
    read -r TAG_INDEX
    TAG_INDEX=${TAG_INDEX:-1}
    SELECTED_TAG=$(echo "${TAGS[$TAG_INDEX - 1]}" | sed 's/^[0-9]*) //')
    if [ -z "$SELECTED_TAG" ]; then
        echo -e "\e${COLOR_RED}输入的编号无效。\e[0m"
        exit 1
    fi

    FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$SELECTED_TAG"

    echo -e "\e${COLOR_GREEN}---[OK]---正在拉取私有仓库镜像 ${FULL_IMAGE_NAME}\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"

    if docker pull "$FULL_IMAGE_NAME"; then
        echo -e "\e${COLOR_GREEN}私有仓库镜像拉取成功。\e[0m"
        echo -e  "\e${COLOR_BLUE}=========================================================\e[0m"
        echo -e "\e${COLOR_BLUE}本地镜像的列表:\e[0m"
        IFS=$'\n' read -r -d '' -a IMAGES < <(docker images --format "{{.Repository}}:{{.Tag}}" && printf '\0')
        for i in "${!IMAGES[@]}"; do
            echo -e "\e${COLOR_GREEN}$((i + 1))) ${IMAGES[$i]}\e[0m"
        done
        echo -e "\e${COLOR_GREEN}---[OK]---从私有仓库拉取镜像到本地操作完成。\e[0m"
    else
        echo -e "\e${COLOR_RED}---[ERROR]---拉取私有仓库镜像失败，请检查镜像名称或标签是否正确。\e[0m"
        exit 1
    fi
}

docker_push() {
    echo -e "\e${COLOR_BLUE}请输入要搜索的公共镜像名称：\e[0m"
    read -r IMAGE_NAME

    # 搜索镜像并显示结果
    echo -e "\e${COLOR_GREEN}正在搜索公共镜像\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}以下是搜索到的镜像列表：\e[0m"
    docker search "$IMAGE_NAME" | awk 'NR==1 {print $0; next} {print NR-1 ") " $0}'
    # 存储镜像名称到一个数组中，用于后续拉取操作
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    mapfile -t IMAGES < <(docker search "$IMAGE_NAME" | awk 'NR>1 {print $1}')
    if [ ${#IMAGES[@]} -eq 0 ]; then
        echo -e "\e${COLOR_RED}未找到任何相关镜像。\e[0m"
        exit 1
    fi
    echo -e "\e${COLOR_BLUE}请输入要推送的本地镜像编号:"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    read -r IMAGE_INDEX
    if ! [[ "$IMAGE_INDEX" =~ ^[0-9]+$ ]] || [ "$IMAGE_INDEX" -lt 1 ] || [ "$IMAGE_INDEX" -gt ${#IMAGES[@]} ]; then
        echo -e "\e${COLOR_RED}输入的编号无效。\e[0m"
        exit 1
    fi
    SELECTED_IMAGE="${IMAGES[$IMAGE_INDEX - 1]}"
    echo -e "\e${COLOR_GREEN}您选择的镜像为：$SELECTED_IMAGE\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"

    # 获取并选择镜像标签
    echo -e "\e${COLOR_BLUE}正在获取镜像的标签列表:\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    TAGS_JSON=$(curl -s "https://hub.docker.com/v2/repositories/library/${SELECTED_IMAGE}/tags/?page_size=20")
    mapfile -t TAGS < <(echo "$TAGS_JSON" | jq -r '.results[].name' | awk '{print NR ") " $0}')

    if [ ${#TAGS[@]} -eq 0 ]; then
        echo -e "\e${COLOR_RED}未找到任何相关标签。\e[0m"
        exit 1
    fi
    echo -e "\e${COLOR_GREEN}以下是可用的镜像标签（展示前20个结果）:\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    for tag in "${TAGS[@]}"; do
        echo -e "\e${COLOR_GREEN}$tag\e[0m"
    done
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}请输入要拉取的镜像标签编号。如果列表中没有您想要的标签，请输入tag:<tagname>（例如tag:latest）,按下回车自动填入tag:latest：\e[0m"
    read -r TAG_INPUT
    TAG_INPUT=${TAG_INPUT:-tag:latest}

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
            echo -e "\e${COLOR_RED}输入无效。请使用有效的编号或者tag:<tagname>格式指定标签。\e[0m"
            exit 1
        fi
    fi

    # 继续之前的拉取镜像操作
    FULL_IMAGE_NAME="$SELECTED_IMAGE:$SELECTED_TAG"
    echo -e "\e${COLOR_GREEN}正在拉取公共镜像 ${FULL_IMAGE_NAME}...\e[0m"
    if docker pull "$FULL_IMAGE_NAME"; then
        echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
        echo -e "\e${COLOR_GREEN}公共镜像拉取成功。\e[0m"
    else
        echo -e "\e${COLOR_RED}---[ERROR]---拉取公共镜像失败，请检查镜像名称或标签是否正确。\e[0m"
        exit 1
    fi
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}请输入私有仓库地址,默认为docker.hcegcorp.com\e[0m"
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}

    echo -e "\e${COLOR_BLUE}请输入要推送的镜像名称：\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    if docker tag "$FULL_IMAGE_NAME" "$REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"; then
        echo -e "\e${COLOR_GREEN}镜像标记成功。\e[0m"
    else
        echo -e "\e${COLOR_RED}标记镜像失败，请检查以下可能的原因：\e[0m"
        echo "1. 输入的镜像名称或标签错误。"
        echo "2. 无法连接到私有仓库。"
        echo "请根据上述提示检查您的输入或网络连接，然后重试。"
        exit 1
    fi
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}docker命令为:docker images | grep $REGISTRY/$SELECTED_IMAGE\e[0m"
    echo -e "\e${COLOR_GREEN}正在推送镜像到私有仓库:\e[0m"
    docker images | grep "$REGISTRY/$SELECTED_IMAGE/$SELECTED_TAG"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo "docker命令为:docker push $REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"
    if ! docker push "$REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"; then
        echo -e "\e${COLOR_RED}推送镜像失败，请检查以下可能的原因：\e[0m"
        echo "1. 输入的镜像名称或标签错误。"
        echo "2. 无法连接到私有仓库。"
        echo "3. 没有权限推送镜像到私有仓库。"
        echo "请根据上述提示检查您的输入、网络连接或权限，然后重试。"
        exit 1
    fi
    echo -e "\e${COLOR_GREEN}镜像推送成功。\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}删除镜像的docker命令为:docker rmi $REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG\e[0m"

    echo -e "\e${COLOR_BLUE}是否删除镜像,请输入yes/y/enter或no/n:\e[0m"
    read -r DELETE_IMAGE
    echo "=========================================================="
    if [[ $DELETE_IMAGE == "yes" || $DELETE_IMAGE == "y" || $DELETE_IMAGE == "" ]]; then
        echo -e "\e${COLOR_GREEN}正在删除本地镜像...\e[0m"
        if docker rmi "$FULL_IMAGE_NAME"; then
            echo -e "\e${COLOR_GREEN}镜像 $FULL_IMAGE_NAME 已从本地删除。\e[0m"
        else
            echo -e "\e${COLOR_RED}镜像 $FULL_IMAGE_NAME 删除失败，可能已被删除或不存在。\e[0m"
        fi
    else
        echo -e "\e${COLOR_GREEN}保留本地镜像。\e[0m"
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
    echo "docker命令为:docker pull $REGISTRY/$SELECTED_IMAGE:$SELECTED_TAG"
}
# 修改daemon.json,并重启docker
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
        # 使用jq将私有仓库地址添加到registry-mirrors数组的开头
        TEMP_FILE=$(mktemp)
        jq --arg registry "https://$REGISTRY" 'if .["registry-mirrors"] then .["registry-mirrors"] = [$registry] + .["registry-mirrors"] else .["registry-mirrors"] = [$registry] end' "$DAEMON_JSON_PATH" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DAEMON_JSON_PATH"
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
    echo -e "\e${COLOR_BLUE}正在获取本地镜像列表...\e[0m"
    readarray -t IMAGES < <(docker images --format "{{.Repository}}:{{.Tag}}")
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"

    if [ ${#IMAGES[@]} -eq 0 ]; then
        echo -e "\e${COLOR_RED}未找到任何本地镜像。\e[0m"
        exit 1
    fi

    echo -e "\e${COLOR_BLUE}以下是本地镜像列表：\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    for i in "${!IMAGES[@]}"; do
        echo -e "\e${COLOR_GREEN}$((i + 1))) ${IMAGES[$i]}\e[0m"
    done
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}请输入要推送的本地镜像编号：\e[0m"
    read -r IMAGE_INDEX
    if ! [[ "$IMAGE_INDEX" =~ ^[0-9]+$ ]] || [ "$IMAGE_INDEX" -lt 1 ] || [ "$IMAGE_INDEX" -gt ${#IMAGES[@]} ]; then
        echo -e "\e${COLOR_RED}输入的编号无效。\e[0m"
        exit 1
    fi

    # 用户输入的是基于1的索引，需要转换为基于0的索引
    SELECTED_IMAGE=${IMAGES[$IMAGE_INDEX - 1]}
    echo -e "\e${COLOR_GREEN}您选择的镜像为：$SELECTED_IMAGE\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}请输入私有仓库地址，默认为docker.hcegcorp.com：\e[0m"
    read -r REGISTRY
    REGISTRY=${REGISTRY:-docker.hcegcorp.com}
    # 提取镜像名和标签，移除任何存在的仓库地址
    IFS='/' read -ra ADDR <<< "$SELECTED_IMAGE"
    CLEAN_IMAGE_NAME="${ADDR[-1]}"

    FULL_TAG="$REGISTRY/$CLEAN_IMAGE_NAME"

    echo -e  "\e${COLOR_GREEN}正在标记镜像并推送到私有仓库...\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    docker tag "$SELECTED_IMAGE" "$FULL_TAG"

    echo -e  "\e${COLOR_GREEN}正在推送镜像到私有仓库...\e[0m"
    echo -e "\e${COLOR_GREEN}docker命令为:docker push $FULL_TAG\e[0m"
    if docker push "$FULL_TAG"; then
        echo -e "\e${COLOR_GREEN}镜像成功推送到私有仓库：$FULL_TAG\e[0m"
        echo -e "\e${COLOR_BLUE}远端私有仓库列表:\e[0m"
        echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
        IFS=$'\n' read -r -d '' -a REPOSITORIES < <(curl -s -X GET "https://$REGISTRY/v2/_catalog" | jq -r '.repositories[]' && printf '\0')
        for i in "${!REPOSITORIES[@]}"; do
            echo -e "\e${COLOR_GREEN}$((i + 1))) ${REPOSITORIES[$i]}\e[0m"
        done
        echo -e "\e${COLOR_BLUE}=========================================================\e[0m"

    else
        echo -e "\e${COLOR_RED}推送镜像失败，请检查以下可能的原因：\e[0m"
        exit 1
    fi
    #  从本地镜像列表中选择镜像推送到私有仓库后,删除本地打了私有仓库标签的镜像
    echo -e "\e${COLOR_BLUE}是否删除镜像,请输入yes/y/enter或no/n:\e[0m"
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
PS3=$(echo -e "\e[1;36m请选择操作：\e[0m")

options=(
    $(echo -e "\e[1;32m搜索并推送公共镜像到私有仓库\e[0m")
    $(echo -e "\e[1;32m从私有仓库拉取镜像\e[0m")
    $(echo -e "\e[1;32m推送本地镜像到私有仓库\e[0m")
    $(echo -e "\e[1;32m列出本地容器并推送到私有仓库\e[0m")
    $(echo -e "\e[1;33m修改daemon.json并重启Docker\e[0m")
    $(echo -e "\e[1;33m恢复daemon.json并重启Docker\e[0m")
    $(echo -e "\e[1;31m退出\e[0m")
)

COLUMNS=1  # 使选项列表单列显示，每项单独一行
select opt in "${options[@]}"; do
    case $opt in
        *公共镜像*)
            docker_push
            break
            ;;
        *拉取镜像*)
            search_private_image
            break
            ;;
        *本地镜像*)
            push_local_images
            break
            ;;
        *本地容器*)
            docker_push_container
            break
            ;;
        *修改daemon.json*)
            alter_daemon
            break
            ;;
        *恢复daemon.json*)
            undone_alternation
            break
            ;;
        *退出*)
            break
            ;;
        *) echo -e "\e[1;31m无效的选项 $REPLY\e[0m" ;;
    esac
done

echo -e "\e[1;34m=========================================================\e[0m"
