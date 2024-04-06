#!/usr/bin/env bash


# 处理命令行参数
for arg in "$@"; do
    case $arg in
        --help)
            show_help
            exit 0
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        *)
            OTHER_ARGUMENTS+=("$1")
            shift
            ;;
    esac
done

# 检查是否安装了Docker
if ! command -v docker &> /dev/null; then
    echo "错误: 未找到Docker，请先安装Docker。"
    exit 1
fi
#==============================================================
# 交互式输入公共镜像名称和标签
echo "请输入要搜索的公共镜像名称："
read -r IMAGE_NAME

echo "搜索镜像中..."
# 使用 docker search 并通过 awk 在每一行前添加行号
docker search "$IMAGE_NAME" | awk 'NR==1 {print $0; next} {print NR-1 ") " $0}'

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
if ! docker tag "$FULL_IMAGE_NAME" "$REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG"; then
    echo "标记镜像失败，请检查以下可能的原因："
    echo "1. 输入的镜像名称或标签错误。"
    echo "2. 无法连接到私有仓库。"
    echo "请根据上述提示检查您的输入或网络连接，然后重试。"
    exit 1
fi
echo "镜像标记成功。"
echo "正在推送镜像到私有仓库..."
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
        echo "镜像 $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG 已从本地删除。"
    else
        # 如果镜像已经被删除，或者不存在，则会执行这里
        echo "镜像 $REGISTRY/$SELECTED_IMAGE:$IMAGE_TAG 删除失败，可能已被删除或不存在。"
    fi
else
    echo "保留本地镜像。"
fi

echo "脚本执行完成。"
