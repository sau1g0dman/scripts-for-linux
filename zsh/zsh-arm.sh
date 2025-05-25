#!/bin/sh
set -euo pipefail

# 定义颜色变量
RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
BLUE=$(printf '\033[34m')
RESET=$(printf '\033[m')

# 检查root权限
if [ "$(id -u)" -ne 0 ]; then
    echo "${YELLOW}警告：非root用户运行，可能需要手动处理权限问题${RESET}"
fi

# ---------------------------
# 一、系统更新与依赖安装
# ---------------------------
echo "${BLUE}开始更新软件包列表...${RESET}"
opkg update || {
    echo "${RED}更新软件包列表失败！请检查网络连接或OpenWrt配置${RESET}"
    exit 1
}

echo "${BLUE}安装Zsh和Git,vim工具...${RESET}"
opkg install zsh git git-http vim-full vim-runtime || {
    echo "${RED}依赖安装失败！请检查软件源是否支持当前架构${RESET}"
    exit 1
}
cp ~/.vimrc ~/.vimrc_bak
curl https://raw.githubusercontent.com/wklken/vim-for-server/master/vimrc > ~/.vimrc
# ---------------------------
# 二、清理旧版Oh My Zsh目录（新增）
# ---------------------------
OH_MY_ZSH_DIR=~/.oh-my-zsh
if [ -d "$OH_MY_ZSH_DIR" ]; then
    echo "${YELLOW}检测到旧版Oh My Zsh目录，正在清理...${RESET}"
    rm -rf "$OH_MY_ZSH_DIR"
    echo "${GREEN}旧目录清理完成${RESET}"
fi

# ---------------------------
# 三、安装 Oh My Zsh（自动应答）
# ---------------------------
echo "${BLUE}下载并安装Oh My Zsh...${RESET}"
echo "n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/felix-fly/openwrt-ohmyzsh/master/install.sh)" || {
    echo "${RED}Oh My Zsh安装失败！请检查安装脚本链接是否有效${RESET}"
    exit 1
}

# ---------------------------
# 四、设置Zsh为默认Shell
# ---------------------------
echo "${BLUE}设置Zsh为默认Shell...${RESET}"
ZSH_PATH=$(which zsh)
if [ -z "$ZSH_PATH" ]; then
    echo "${RED}未找到Zsh路径！安装可能失败${RESET}"
    exit 1
fi

# 备份passwd文件并修改默认Shell
cp -n /etc/passwd /etc/passwd.bak
sed -i "s|/bin/ash|${ZSH_PATH}|g" /etc/passwd
echo "${GREEN}默认Shell已设置为：${ZSH_PATH}${RESET}"

# ---------------------------
# 五、安装 Powerlevel10k 主题
# ---------------------------
echo "${BLUE}安装Powerlevel10k主题...${RESET}"
POWERLEVEL10K_DIR=~/powerlevel10k
if [ -d "$POWERLEVEL10K_DIR" ]; then
    echo "${YELLOW}Powerlevel10k已存在，跳过克隆${RESET}"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$POWERLEVEL10K_DIR" || {
        echo "${RED}Powerlevel10k克隆失败！请检查Git连接${RESET}"
        exit 1
    }
fi

# 添加主题配置到.zshrc
echo "source ${POWERLEVEL10K_DIR}/powerlevel10k.zsh-theme" >> ~/.zshrc
echo "${GREEN}Powerlevel10k已配置，建议运行p10k configure进行初始化${RESET}"

# ---------------------------
# 六、安装 zsh-autosuggestions 插件
# ---------------------------
echo "${BLUE}安装zsh-autosuggestions插件...${RESET}"
AUTOSUGGESTIONS_DIR=~/.zsh/zsh-autosuggestions
mkdir -p ~/.zsh
if [ -d "$AUTOSUGGESTIONS_DIR" ]; then
    echo "${YELLOW}zsh-autosuggestions已存在，跳过克隆${RESET}"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGESTIONS_DIR" || {
        echo "${RED}zsh-autosuggestions克隆失败！${RESET}"
        exit 1
    }
fi

# 添加插件到.zshrc
echo "source ${AUTOSUGGESTIONS_DIR}/zsh-autosuggestions.zsh" >> ~/.zshrc
echo "${GREEN}自动建议插件已安装${RESET}"

# ---------------------------
# 七、安装 zsh-syntax-highlighting 插件
# ---------------------------
echo "${BLUE}安装zsh-syntax-highlighting插件...${RESET}"
SYNTAX_HIGHLIGHTING_DIR=~/.zsh/zsh-syntax-highlighting
if [ -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
    echo "${YELLOW}zsh-syntax-highlighting已存在，跳过克隆${RESET}"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR" || {
        echo "${RED}语法高亮插件克隆失败！${RESET}"
        exit 1
    }
fi

# 添加插件到.zshrc（需放在所有插件之后）
echo "source ${SYNTAX_HIGHLIGHTING_DIR}/zsh-syntax-highlighting.zsh" >> ~/.zshrc
echo "${GREEN}语法高亮插件已安装${RESET}"

# ---------------------------
# 八、完成提示
# ---------------------------
echo "${BLUE}==================== 安装完成 ====================${RESET}"
echo "${GREEN}请执行以下操作："
echo "1. 重启终端或运行 exec zsh 生效"
echo "2. 首次使用Powerlevel10k请运行 p10k configure 配置主题"
echo "3. 若遇到字体问题，请安装Nerd Fonts字体${RESET}"
echo "${BLUE}===============================================${RESET}"
