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
echo -e "\e[1;32m🚀 欢迎使用 Harbor 镜像推送脚本\e[0m"
echo -e "\e[1;33m👤 作者: saul\e[0m"
echo -e "\e[1;33m📧 邮箱: sau1@maranth@gmail.com\e[0m"
echo -e "\e[1;35m🔖 version 1.1\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;36m本脚本将帮助您搜索、拉取、标记并推送公共Docker镜像到私有仓库 Harbor。\e[0m"
echo -e "\e[1;36m请按照提示输入相关信息，然后脚本将自动完成后续操作。\e[0m"
echo -e "\e[1;34m================================================================\e[0m"

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

    echo -e "\e${COLOR_BLUE}请输入私有仓库地址（默认为harbor.hcegcorp.com）：\e[0m"
    read -r REGISTRY
    REGISTRY=${REGISTRY:-harbor.hcegcorp.com}
    echo "========================================================="
    echo "curl的命令为:curl -s -k https://$REGISTRY/api/v2.0/projects"
    echo -e "\e${COLOR_BLUE}列出所有项目,并在每个项目前面编号\e[0m"
    PROJECTS_JSON=$(curl -s -k "https://$REGISTRY/api/v2.0/projects")

    # 使用jq将项目名称提取出来，然后生成带顺序编号的列表
    PROJECTS=$(echo "$PROJECTS_JSON" | jq -r '.[] | "\(.name)"')
    IFS=$'\n' read -rd '' -a PROJECTS_ARRAY <<< "$PROJECTS"

    # 输出项目列表和编号
    for i in "${!PROJECTS_ARRAY[@]}"; do
        echo -e "$COLOR_GREEN$((i + 1))) ${PROJECTS_ARRAY[i]}\e[0m"
    done

    echo -e "\e${COLOR_BLUE}请输入要存放镜像的项目的编号,默认为1：\e[0m"
    read -r PROJECT_ID
    PROJECT_ID=${PROJECT_ID:-1} # 设置默认选项

    # 根据输入的编号选取项目，确保编号是有效的
    SELECTED_PROJECT_NAME="${PROJECTS_ARRAY[$PROJECT_ID - 1]}"

    if [ -z "$SELECTED_PROJECT_NAME" ]; then
        echo -e "\e${COLOR_RED}选择无效，请重试。\e[0m"
        exit 1
    fi

    echo -e "\e${COLOR_BLUE}您选择的项目名称为：$SELECTED_PROJECT_NAME\e[0m"
    echo "========================================================="
    echo "curl的命令为:curl -s -k https://$REGISTRY/api/v2.0/repositories?project_id=$SELECTED_PROJECT_ID | jq -r '.[].name'"
    REPOSITORIES_JSON=$(curl -s -k "https://$REGISTRY/api/v2.0/repositories?project_id=$SELECTED_PROJECT_ID")
    REPOSITORIES=$(echo "$REPOSITORIES_JSON" | jq -r '.[].name')
    if [ -z "$REPOSITORIES" ]; then
        echo "项目 '$SELECTED_PROJECT_NAME' 下没有找到任何镜像。"
        exit 1
    fi

    echo -e "\e${COLOR_BLUE}项目 '$SELECTED_PROJECT_NAME' 下的镜像列表：\e[0m"
    IFS=$'\n' read -rd '' -a REPOSITORIES_ARRAY <<< "$REPOSITORIES"
    #结果用绿色字体显示
    for i in "${!REPOSITORIES_ARRAY[@]}"; do
        echo -e "$COLOR_GREEN$((i + 1))) ${REPOSITORIES_ARRAY[$i]}\e[0m"
    done
    echo -e "\e${COLOR_BLUE}请输入要下载的镜像编号,默认为1：\e[0m"
    read -r SELECTIED_IMAGE_INDEX
    SELECTED_REPOSITORY="${REPOSITORIES_ARRAY[$SELECTIED_IMAGE_INDEX - 1]}"
    if [ -z "$SELECTED_REPOSITORY" ]; then
        echo -e "\e${COLOR_RED}选择无效，请重试。\e[0m"
        exit 1
    fi

    #    echo "您选择的镜像为：$SELECTED_REPOSITORY"
    echo -e "\e${COLOR_BLUE}您选择的镜像为：$SELECTED_REPOSITORY\e[0m"
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    #分离项目和镜像
    IFS='/' read -ra ADDR <<< "$SELECTED_REPOSITORY"
    CLEAN_IMAGE_NAME="${ADDR[-1]}"
    echo -e "\e${COLOR_BLUE}正在获取项目 '$SELECTED_PROJECT_NAME' 下 '$CLEAN_IMAGE_NAME' 的所有标签...\e[0m"
    # 确保 URL 的正确性，只使用镜像名称
    TAGS_JSON=$(curl -s -k "https://$REGISTRY/api/v2.0/projects/$SELECTED_PROJECT_NAME/repositories/$CLEAN_IMAGE_NAME/artifacts" | jq -r '.[].tags[]?.name')

    # 显示用于调试的 curl 命令
    echo "curl的命令是: curl -s -k \"https://$REGISTRY/api/v2.0/projects/$SELECTED_PROJECT_NAME/repositories/$CLEAN_IMAGE_NAME/artifacts\" | jq -r '.[] | .tags[]?.name'"

    if [ -z "$TAGS_JSON" ]; then
        echo -e "\e${COLOR_RED}未找到任何标签。\e[0m"
        exit 1
    fi

    echo -e "\e${COLOR_BLUE}以下是可用的镜像标签：\e[0m"
    IFS=$'\n' read -rd '' -a TAGS_ARRAY <<< "$TAGS_JSON"
    for i in "${!TAGS_ARRAY[@]}"; do
        echo -e "$COLOR_GREEN$((i + 1))) ${TAGS_ARRAY[$i]}\e[0m"
    done
    echo -e "\e${COLOR_BLUE}请输入要拉取的镜像标签编号，或直接输入标签名称（如latest）,默认为latest标签：\e[0m"
    read -r TAG_INDEX
    TAG_INDEX=${TAG_INDEX:-latest}
    if [[ "$TAG_INDEX" =~ ^[0-9]+$ ]] && [ "$TAG_INDEX" -gt 0 ] && [ "$TAG_INDEX" -le ${#TAGS_ARRAY[@]} ]; then
        SELECTED_TAG="${TAGS_ARRAY[$TAG_INDEX - 1]}"
    else
        SELECTED_TAG="$TAG_INDEX"
    fi
    echo -e "\e${COLOR_GREEN}您选择的镜像标签为：$SELECTED_TAG\e[0m"
    echo "========================================================="
    echo -e "\e${COLOR_BLUE}正在拉取镜像...\e[0m"
    if docker pull "$REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG"; then
        echo -e "\e${COLOR_GREEN}镜像拉取成功。\e[0m"
    else
        echo -e "\e${COLOR_RED}拉取镜像失败，请检查镜像名称或标签是否正确。\e[0m"
        echo -e "\e${COLOR_RED}拉取的命令为:docker pull $REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG\e[0m"
        exit 1
    fi
    echo -e "\e${COLOR_BLUE}=========================================================\e[0m"
    echo -e "\e${COLOR_BLUE}docker pull $REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG\e[0m"
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
    echo "============================================================="
    echo "请输入要拉取的镜像标签编号。如果列表中没有您想要的标签，请输入tag:<tagname>（例如tag:latest）,按下回车自动填入tag:latest："
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
    echo "请输入私有仓库地址,默认为harbor.hcegcorp.com"
    read -r REGISTRY
    REGISTRY=${REGISTRY:-harbor.hcegcorp.com}
    echo "========================================================="
    echo "列出所有项目,并在每个项目前面编号,请输入项目编号："
    echo "curl的命令为:curl -s -k https://$REGISTRY/api/v2.0/projects"
    PROJECTS_JSON=$(curl -s -k "https://$REGISTRY/api/v2.0/projects")
    # 将项目ID和名称合并为单个字符串，例如 "1) library"
    PROJECTS=$(echo "$PROJECTS_JSON" | jq -r '.[] | "\(.project_id)) \(.name)"')
    IFS=$'\n' read -rd '' -a PROJECTS_ARRAY <<< "$PROJECTS"
    for i in "${!PROJECTS_ARRAY[@]}"; do
        echo "${PROJECTS_ARRAY[$i]}"
    done
    echo "请输入要存放镜像的项目的编号"
    read -r PROJECT_ID
    SELECTED_PROJECT_ID=$(echo "${PROJECTS_ARRAY[$PROJECT_ID - 1]}" | awk '{print $1}' | sed 's/)//')
    if [ -z "$SELECTED_PROJECT_ID" ]; then
        echo "选择无效，请重试。"
        exit 1
    fi
    echo "您选择的项目名称为：$SELECTED_PROJECT_NAME"
    #通过PROJECT_ID获取项目名称
    SELECTED_PROJECT_NAME=$(echo "${PROJECTS_ARRAY[$PROJECT_ID - 1]}" | awk '{print $2}')
    echo "正在标记镜像并推送到私有仓库..."
    if docker tag "$FULL_IMAGE_NAME" "$REGISTRY/$SELECTED_PROJECT_NAME/$SELECTED_IMAGE:$SELECTED_TAG"; then
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
    echo "docker命令为:docker push $REGISTRY/$SELECTED_PROJECT_ID/$SELECTED_IMAGE:$SELECTED_TAG"
    if ! docker push "$REGISTRY/$SELECTED_PROJECT_NAME/$SELECTED_IMAGE:$SELECTED_TAG"; then
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
    if docker rmi "$REGISTRY/$SELECTED_PROJECT_ID/$SELECTED_IMAGE:$SELECTED_TAG"; then
        echo "========================================================="
        echo "docker命令为:docker rmi $REGISTRY/$SELECTED_PROJECT_ID/$SELECTED_IMAGE:$SELECTED_TAG"
        echo "镜像 $REGISTRY/$SELECTED_PROJECT_ID/$SELECTED_IMAGE:$SELECTED_TAG 已从本地删除。"
    else
        echo "========================================================="
        echo "docker命令为:docker rmi $REGISTRY/$SELECTED_PROJECT_ID/$SELECTED_IMAGE:$SELECTED_TAG"
        echo "镜像 $REGISTRY/$SELECTED_PROJECT_ID/$SELECTED_IMAGE:$SELECTED_TAG 删除失败，可能已被删除或不存在。"
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
    echo "docker命令为:docker pull $REGISTRY/$SELECTED_PROJECT_ID/$SELECTED_IMAGE:$SELECTED_TAG"
}
# 修改daemon.json,并重启docker
alter_daemon() {
    echo "请输入私有仓库地址（默认为harbor.hcegcorp.com）："
    read -r REGISTRY
    REGISTRY=${REGISTRY:-harbor.hcegcorp.com}

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
    echo "正在获取本地镜像列表..."
    readarray -t LOCALIMAGES < <(docker images --format "{{.Repository}}:{{.Tag}}")
    if [ ${#LOCALIMAGES[@]} -eq 0 ]; then
        echo "未找到任何本地镜像。"
        exit 1
    fi
    echo "========================================================="
    echo "一下是本地镜像列表:"
    for i in "${!LOCALIMAGES[@]}"; do
        echo "$((i + 1))) ${LOCALIMAGES[$i]}"
    done
    echo "========================================================="
    echo "请输入要推送的本地镜像编号:"
    read -r LOCALIMAGESINDEX
    if ! [[ "$LOCALIMAGESINDEX" =~ ^[0-9]+$ ]] || [ "$LOCALIMAGESINDEX" -lt 1 ] || [ "$LOCALIMAGESINDEX" -gt ${#LOCALIMAGES[@]} ]; then
        echo "输入的编号无效。"
        exit 1
    fi
    SELECTED_IMAGE="${LOCALIMAGES[$LOCALIMAGESINDEX - 1]}"
    echo -e "您选择推送的镜像为：\033[31m$SELECTED_IMAGE\033[0m"
    echo "请选择私有仓库的地址,默认为harbor.hcegcorp.com"
    read -r  REGISTRY
    REGISTRY=${REGISTRY:-harbor.hcegcorp.com}
    echo "========================================================="
    echo "列出所有项目,并在每个项目前面编号,请输入项目编号："
    echo "curl的命令为:curl -s -k https://$REGISTRY/api/v2.0/projects"
    PROJECTS_JSON=$(curl -s -k "https://$REGISTRY/api/v2.0/projects")
    # 使用jq处理JSON，创建一个项目名称的数组
    PROJECTS=($(echo "$PROJECTS_JSON" | jq -r '.[] | "\(.name)"'))
    # 显示项目列表及其编号
    for i in "${!PROJECTS[@]}"; do
        echo "$((i + 1))) ${PROJECTS[i]}"
    done
    echo "请输入要存放镜像的项目的编号，默认为1"
    read -r PROJECT_INDEX
    PROJECT_INDEX=${PROJECT_INDEX:-1} # 如果用户没有输入，使用默认值1
    SELECTED_PROJECT_NAME=${PROJECTS[$PROJECT_INDEX - 1]} # 根据索引获取项目名称

    # 验证是否成功获取项目名称
    if [ -z "$SELECTED_PROJECT_NAME" ]; then
        echo "选择无效，请重试。"
        exit 1
    fi

        echo -e "您选择的项目名称为：\033[31m$SELECTED_PROJECT_NAME\033[0m"
        echo "========================================================="
        echo "分离本地镜像和标签"
        # 分离镜像名称和标签
        IFS='/:' read -ra ADDR <<< "$SELECTED_IMAGE"
        # 从数组中提取最后一个元素，即包含镜像名称和标签的部分
        CLEAN_IMAGE_NAME="${ADDR[-2]}"
        SELECTED_TAG="${ADDR[-1]}"
        echo -e "分离后的镜像:标签为\033[31m$CLEAN_IMAGE_NAME:$SELECTED_TAG\033[0m"
        echo "========================================================="
        echo "正在标记镜像并推送到私有仓库..."
        if
        docker tag "$SELECTED_IMAGE" "$REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG"
        echo "docker tag $SELECTED_IMAGE $REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG"
    then
            echo "镜像标记成功。"
    else
            echo "标记镜像失败，请检查以下可能的原因："
            echo "1. 输入的镜像名称或标签错误。"
            echo "2. 无法连接到私有仓库。"
            echo "请根据上述提示检查您的输入或网络连接，然后重试。"
            exit 1
    fi
    echo "========================================================="
    echo "正在推送镜像到私有仓库"
    if ! docker push "$REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG"; then
        echo "推送镜像失败，请检查以下可能的原因："
        echo "1. 输入的镜像名称或标签错误。"
        echo "2. 无法连接到私有仓库。"
        echo "3. 没有权限推送镜像到私有仓库。"
        echo "请根据上述提示检查您的输入、网络连接或权限，然后重试。"
        exit 1
    fi
    echo "镜像推送成功。"
    echo "docker push $REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG"

    echo "远程仓库$REGISTRY的项目$SELECTED_PROJECT_NAME下的镜像列表如下:"
    echo "========================================================="
    curl -s -k "https://$REGISTRY/api/v2.0/repositories?project_id=$SELECTED_PROJECT_ID" | jq -r '.[].name'
    echo "========================================================="
    echo "curl的命令为:curl -s -k \"https://$REGISTRY/api/v2.0/repositories?project_id=$SELECTED_PROJECT_ID\" | jq -r '.[].name'"
    echo "========================================================="
    # 用彩色字体输出,完成推送本地镜像到私有仓库
    echo -e "您已经成功推送本地镜像\033[31m$SELECTED_IMAGE\033[0m到私有仓库\033[31m$REGISTRY/$SELECTED_PROJECT_NAME/$CLEAN_IMAGE_NAME:$SELECTED_TAG\033[0m"
    #返回到主菜单,让用户选择其他操作

}

# 交互式选择操作
PS3=$(echo -e "\e[1;36m请选择操作：\e[0m")

options=(
    $(echo -e "\e[1;32m搜索并推送公共镜像到私有仓库\e[0m")
    $(echo -e "\e[1;32m从私有仓库拉取镜像\e[0m")
    $(echo -e "\e[1;32m推送本地镜像到私有仓库\e[0m")
    $(echo -e "\e[1;33m修改daemon.json并重启Docker\e[0m")
    $(echo -e "\e[1;33m恢复daemon.json并重启Docker\e[0m")
    $(echo -e "\e[1;31m退出\e[0m")
)

COLUMNS=1
select opt in "${options[@]}"; do
    case $opt in
        *"搜索并推送公共镜像到私有仓库"*)
            docker_push
            break
            ;;
        *"从私有仓库拉取镜像"*)
            search_private_image
            break
            ;;
        *"推送本地镜像到私有仓库"*)
            push_local_images
            break
            ;;
        *"修改daemon.json并重启Docker"*)
            alter_daemon
            break
            ;;
        *"恢复daemon.json并重启Docker"*)
            undone_alternation
            break
            ;;
        *"退出"*)
            break
            ;;
        *) echo -e "\e[1;31m无效的选项 $REPLY\e[0m" ;;
    esac
done
echo -e "\e[1;34m=========================================================\e[0m"
