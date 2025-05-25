#!/bin/sh
set -euo pipefail

# 定义颜色变量（兼容老旧终端，无颜色时静默）
RED=$(printf '\033[31m' 2>/dev/null || echo '')
GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
RESET=$(printf '\033[m' 2>/dev/null || echo '')

# 检查root权限
if [ "$(id -u)" -ne 0 ]; then
    echo "${YELLOW}警告：非root用户运行，可能需要手动处理权限问题${RESET}"
fi

# ---------------------------
# 一、系统更新与依赖安装
# ---------------------------
echo "${BLUE}[1/7] 系统更新与依赖安装${RESET}"
echo "${BLUE}• 更新软件包列表...${RESET}"
opkg update || {
    echo "${RED}✖ 失败：更新软件包列表失败！请检查网络连接或OpenWrt配置${RESET}"
    exit 1
}
echo "${GREEN}✔ 成功：软件包列表更新完成${RESET}"

echo "${BLUE}• 安装Zsh、Git、Vim...${RESET}"
opkg install zsh git git-http vim-full vim-runtime || {
    echo "${RED}✖ 失败：依赖安装失败！请检查软件源是否支持当前架构${RESET}"
    exit 1
}
# 备份Vim配置（带时间戳避免覆盖）
cp -n ~/.vimrc ~/.vimrc.bak."$(date +%Y%m%d%H%M%S)" 2>/dev/null
# 应用服务器优化版Vim配置
curl -fsSL https://raw.githubusercontent.com/wklken/vim-for-server/master/vimrc > ~/.vimrc
echo "${GREEN}✔ 成功：工具安装及Vim配置完成${RESET}"

# ---------------------------
# 二、清理旧版Oh My Zsh目录
# ---------------------------
echo "${BLUE}[2/7] 清理旧版Oh My Zsh目录${RESET}"
OH_MY_ZSH_DIR=~/.oh-my-zsh
if [ -d "$OH_MY_ZSH_DIR" ]; then
    echo "${YELLOW}ℹ 提示：检测到旧版目录，正在清理...${RESET}"
    rm -rf "$OH_MY_ZSH_DIR"
    echo "${GREEN}✔ 成功：旧目录清理完成${RESET}"
else
    echo "${GREEN}✔ 跳过：未检测到旧版Oh My Zsh目录${RESET}"
fi

# ---------------------------
# 三、安装 Oh My Zsh（自动应答）
# ---------------------------
echo "${BLUE}[3/7] 安装Oh My Zsh${RESET}"
echo "${BLUE}• 下载并运行安装脚本...${RESET}"
# 自动应答：不备份现有.zshrc（n=不备份，y=备份）
echo "n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
    echo "${RED}✖ 失败：Oh My Zsh安装失败！请检查网络连接${RESET}"
    exit 1
}
echo "${GREEN}✔ 成功：Oh My Zsh安装完成${RESET}"

# ---------------------------
# 四、安装 Powerlevel10k 主题
# ---------------------------
echo "${BLUE}[4/7] 安装Powerlevel10k主题${RESET}"
POWERLEVEL10K_DIR=~/powerlevel10k
if [ -d "$POWERLEVEL10K_DIR" ]; then
    echo "${YELLOW}ℹ 提示：Powerlevel10k已存在，跳过克隆${RESET}"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$POWERLEVEL10K_DIR" || {
        echo "${RED}✖ 失败：Powerlevel10k克隆失败！请检查Git连接${RESET}"
        exit 1
    }
    echo "${GREEN}✔ 成功：Powerlevel10k克隆完成${RESET}"
fi

# 添加主题及禁用向导（避免首次启动弹窗）
echo "source ${POWERLEVEL10K_DIR}/powerlevel10k.zsh-theme" >> ~/.zshrc
CONFIG_LINE='POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD=true'
CONFIG_LINE2='[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
if ! grep -qF "$CONFIG_LINE" ~/.zshrc; then
    echo -e "${YELLOW}ℹ 提示：已禁用Powerlevel10k初始化向导（如需手动配置，可删除此配置后运行 p10k configure）${RESET}"
    echo "$CONFIG_LINE" >> ~/.zshrc
    echo "$CONFIG_LINE2" >> ~/.zshrc
fi

# 复制官方示例配置（仅仓库存在时生效）
if [ -f "${POWERLEVEL10K_DIR}/config/p10k-rainbow.zsh" ]; then
    cp "${POWERLEVEL10K_DIR}/config/p10k-rainbow.zsh" ~/.p10k.zsh
    echo "${GREEN}✔ 成功：示例配置已复制到 ~/.p10k.zsh${RESET}"
else
    echo "${YELLOW}ℹ 提示：未找到官方示例配置，首次启动Zsh时会自动生成默认配置${RESET}"
fi

# ---------------------------
# 五、安装 zsh-autosuggestions 插件
# ---------------------------
echo "${BLUE}[5/7] 安装自动建议插件${RESET}"
AUTOSUGGESTIONS_DIR=~/.zsh/zsh-autosuggestions
mkdir -p ~/.zsh  # 确保插件目录存在
if [ -d "$AUTOSUGGESTIONS_DIR" ]; then
    echo "${YELLOW}ℹ 提示：插件已存在，跳过克隆${RESET}"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGESTIONS_DIR" || {
        echo "${RED}✖ 失败：插件克隆失败！${RESET}"
        exit 1
    }
    echo "${GREEN}✔ 成功：插件安装完成${RESET}"
fi
echo "source ${AUTOSUGGESTIONS_DIR}/zsh-autosuggestions.zsh" >> ~/.zshrc  # 加载插件

# ---------------------------
# 六、安装语法高亮插件（需最后加载）
# ---------------------------
echo "${BLUE}[6/8] 安装语法高亮插件${RESET}"
SYNTAX_HIGHLIGHTING_DIR=~/.zsh/zsh-syntax-highlighting
if [ -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
    echo "${YELLOW}ℹ 提示：插件已存在，跳过克隆${RESET}"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR" || {
        echo "${RED}✖ 失败：插件克隆失败！${RESET}"
        exit 1
    }
    echo "${GREEN}✔ 成功：插件安装完成${RESET}"
fi
# 确保语法高亮在所有插件后加载（关键！）
echo "# 语法高亮插件（必须最后加载）" >> ~/.zshrc
echo "source ${SYNTAX_HIGHLIGHTING_DIR}/zsh-syntax-highlighting.zsh" >> ~/.zshrc

# ---------------------------
# 七、.zshrc 插件配置补全（核心逻辑）
# ---------------------------
echo "${BLUE}[7/8] 配置.zshrc 插件列表${RESET}"
ZSHRC=~/.zshrc
# 固定插件列表（不合并现有，直接替换）
TARGET_PLUGINS="git command-not-found common-aliases docker docker-compose extract git man sudo systemadmin systemd ubuntu zsh-interactive-cd"
NEW_PLUGIN_LINE="plugins=(${TARGET_PLUGINS})"

# 1. 备份.zshrc
cp -n "$ZSHRC" "$ZSHRC.bak"
echo "${YELLOW}ℹ 提示：已备份.zshrc 到 ${ZSHRC}.bak${RESET}"

# 2. 检测现有plugins配置
echo "${YELLOW}ℹ 提示：正在检测现有插件配置...${RESET}"
if grep -qE '^plugins=\([^)]*\)' "$ZSHRC"; then
    echo "${YELLOW}ℹ 提示：检测到现有插件配置，将替换为固定列表${RESET}"

    # 使用sed精确替换plugins=()行（保留行首可能的空格）
    sed -i "s/^plugins=.*/${NEW_PLUGIN_LINE}/" "$ZSHRC" || {
        echo "${RED}✖ 失败：更新插件配置失败！${RESET}"
        exit 1
    }
else
    echo "${YELLOW}ℹ 提示：未检测到插件配置，创建新配置${RESET}"

    # 在oh-my-zsh源之后插入（若存在）
    if grep -q 'source ~/.oh-my-zsh/oh-my-zsh.sh' "$ZSHRC"; then
        sed -i '/source ~/.oh-my-zsh/oh-my-zsh.sh/a\'"${NEW_PLUGIN_LINE}" "$ZSHRC" || {
            echo "${RED}✖ 失败：插入配置失败！${RESET}"
            exit 1
        }
    else
        # 否则追加到文件末尾
        echo "${NEW_PLUGIN_LINE}" >> "$ZSHRC" || {
            echo "${RED}✖ 失败：追加配置失败！${RESET}"
            exit 1
        }
    fi
fi

echo "${GREEN}✔ 成功：.zshrc 插件配置更新完成${RESET}"
echo "${YELLOW}ℹ 提示：当前插件列表：${TARGET_PLUGINS}${RESET}"

# ---------------------------
# 八、完成提示（保持不变）...
# ---------------------------
echo "${BLUE}[8/8] 安装完成！${RESET}"
echo -e "${GREEN}🎉 所有步骤已完成，Zsh及相关工具已安装就绪！${RESET}"

echo -e "${YELLOW}ℹ 注意：当前默认Shell未修改，以下是使用说明：${RESET}"
echo "  1. **临时启动Zsh**（退出后回到原Shell）："
echo "     ${BLUE}zsh${RESET}"
echo "     输入 ${YELLOW}exit${RESET} 可回到原Shell"

echo "  2. **长期使用Zsh（需root权限，适合OpenWrt）**："
echo "     ① 备份系统文件："
echo "        ${BLUE}cp -n /etc/passwd /etc/passwd.bak${RESET}"
echo "     ② 修改默认Shell（根据你的原Shell--cat /etc/shells--替换路径，例如原Shell为/bin/bash）："
echo "        ${BLUE}sed -i '' \"s@:/bin/bash@\$(which zsh)@g\" /etc/passwd${RESET}"
echo "     ③ 重启SSH服务："
echo "        ${BLUE}/etc/init.d/dropbear restart${RESET}"
echo "     ④ 验证：重新登录后执行 ${BLUE}echo \$SHELL${RESET} 应显示Zsh路径"

echo -e "\n${YELLOW}ℹ 其他提示：${RESET}"
echo "  • 主题配置：~/.p10k.zsh（已预设官方彩虹主题，首次启动Zsh时生效）"
echo "  • Zsh配置：~/.zshrc（包含Oh My Zsh、插件和主题加载逻辑，可自行编辑）"
echo "  • 终端乱码解决："
echo "     ① 下载 ${BLUE}Nerd Fonts${RESET} 字体（推荐：MesloLGS NF）"
echo "     ② 在终端设置中选择已安装的Nerd Fonts字体"
echo "  • 插件位置：~/.zsh/（自动建议和语法高亮插件已安装）"
