#!/bin/bash
clear
COLOR_GREEN='\033[32m'  # 绿色
COLOR_RED='\033[31m'  # 红色
COLOR_BLUE='\033[34m'  # 蓝色
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;32m🚀 欢迎使用 OHMYZSH配置美化脚本\e[0m"
echo -e "\e[1;33m👤 作者: saul\e[0m"
echo -e "\e[1;33m📧 邮箱: sau1@maranth@gmail.com\e[0m"
echo -e "\e[1;35m🔖 version 1.1\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;36m厌倦了单调的bash?本脚本将帮助您添加zsh,美化power10k主题,添加插件。\e[0m"
echo -e "\e${COLOR_BLUE}请按照提示输入相关信息，然后脚本将自动完成后续操作。\e[0m"
echo -e "\e${COLOR_RED}注意:此脚本只在debian和ubuntu上测试过"
echo -e "\e${COLOR_RED}https://github.com/sau1g0dman/scripts-for-linux\e[0m"
echo -e "\e[1;34m================================================================\e[0m"

install_basic_tools() {
    echo ""
    echo -e "\e${COLOR_GREEN}=========================[[开始更新系统和安装必要工具]]========================\e[0m"
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
    elif [ -f /etc/redhat-release ]; then
        sudo yum update
        sudo yum install -y curl vim zsh htop git tmux exa bat fd-find thefuck
    else
        echo ""
        echo -e "\e${COLOR_RED}=========================不支持的系统。=========================\e[0m"
        exit 1
    fi
    if [ -f /usr/bin/git ]; then
        echo -e "${COLOR_GREEN}git 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装git=========================\e[0m"
        sudo apt-get install -y git
        echo ""
        echo -e "\e${COLOR_GREEN}=========================git安装完成=========================\e[0m"
        sleep 1
    fi
    if [ -f /usr/bin/curl ]; then
        echo -e "\e${COLOR_GREEN}curl 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装curl.=========================\e[0m"
        sudo apt-get install -y curl
        echo ""
        echo -e "\e${COLOR_GREEN}=========================curl安装完成=========================\e[0m"
    fi
    if [ -f /usr/bin/vim ]; then
        echo -e "\e${COLOR_GREEN}vim 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装vim=========================\e[0m"
        sudo apt-get install -y vim
        echo ""
        echo -e "\e${COLOR_GREEN}=========================vim安装完成=========================\e[0m"
    fi
    if [ -f /usr/bin/zsh ]; then
        echo -e "\e${COLOR_GREEN}zsh 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装zsh=========================\e[0m"
        sudo apt-get install -y zsh
        echo ""
        echo -e "\e${COLOR_GREEN}=========================zsh安装完成=========================\e[0m"
    fi
    if [ -f /usr/bin/htop ]; then
        echo -e "\e${COLOR_GREEN}htop 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装htop=========================\e[0m"
        sudo apt-get install -y htop
        echo ""
        echo -e "\e${COLOR_GREEN}=========================htop安装完成=========================\e[0m"
    fi
    if [ -f /usr/bin/tmux ]; then
        echo -e "\e${COLOR_GREEN}tmux 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装tmux=========================\e[0m"
        sudo apt-get install -y tmux
    fi
    if [ -f /usr/bin/bat ]; then
        echo -e "\e${COLOR_GREEN}bat 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装bat=========================\e[0m"
        sudo apt-get install -y bat
    fi
    if [ -f /usr/bin/fdfind ]; then
        echo -e "\e${COLOR_GREEN}fdfind 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装fd-find=========================\e[0m"
        sudo apt-get install -y fd-find
    fi
    if [ -f /usr/bin/exa ]; then
        echo -e "\e${COLOR_GREEN}exa 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装exa=========================\e[0m"
        sudo apt-get install -y exa
        echo ""
        echo -e "\e${COLOR_GREEN}=========================exa安装完成=========================\e[0m"
    fi
    if [ -f /usr/local/bin/thefuck ]; then
        echo -e "\e${COLOR_GREEN}thefuck 已经安装在系统中。${COLOR_RESET}"
    else
        echo ""
        echo -e "\e${COLOR_GREEN}=========================正在安装thefuck=========================\e[0m"
        sudo apt-get install -y thefuck
        echo ""
        echo -e "\e${COLOR_GREEN}===========================thefuck安装完成=========================\e[0m"
    fi
    echo ""
    echo -e "\e${COLOR_GREEN}=========================正在安装riggrep=========================\e[0m"
    if ! command -v rg &> /dev/null; then
        curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
        sudo dpkg -i ripgrep_13.0.0_amd64.deb
        echo ""
        echo -e "\e${COLOR_GREEN}=========================完成安装riggrep=========================\e[0m"
    fi
    # 检查lazygit是否已安装
    if ! command -v lazygit &> /dev/null; then
        echo ""
        echo -e "\e${COLOR_GREEN}=====================正在安装lazygit==============================\e[0m"
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        # 清理下载的文件
        rm lazygit.tar.gz lazygit
        echo -e "\e${COLOR_GREEN}===========================lazygit安装完成=========================\e[0m"
    else
        echo -e "\e${COLOR_GREEN}lazygit 已经安装。${COLOR_RESET}"
    fi
    echo ""
    echo -e "\e${COLOR_GREEN}=========================正在安装net-tools=========================\e[0m"
    sudo apt install net-tools -y
    echo ""
    echo -e "\e${COLOR_GREEN}=========================net-tools已经安装=========================\e[0m"
    echo ""
    echo -e "\e[1;36m=========================基础工具安装完成=========================\e[0m"
    sleep 1
    clear
}
change_default_shell() {
    echo ""
    echo -e "\e[1;36m=========================正在自动更改默认Shell为zsh=========================\e[0m"
    ZSH_PATH=$(which zsh)
    chsh -s "$ZSH_PATH"
    echo "默认Shell更改完成。"
    echo ""
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
    sleep 1
}
install_oh_my_zsh() {
    echo ""
    echo -e "\e[1;36m=========================安装Oh My Zsh（原版）=========================\e[0m"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo ""
    echo -e "\e${COLOR_GREEN}=========================Oh My Zsh安装完成========================\e[0m"
        sleep 1
}


install_zsh_plugins() {
    echo ""
    echo -e "\e[1;36m=========================安装Zsh插件=========================\e[0m"
    
    # 智能检测 Oh My Zsh 安装位置
    local zsh_install_dir=""
    local zsh_custom_dir=""
    
    # 优先级1: 通过 $ZSH 环境变量检测
    if [[ -n "$ZSH" && -d "$ZSH" ]]; then
        zsh_install_dir="$ZSH"
        echo -e "\e[1;33m• 通过 \$ZSH 变量检测到 Oh My Zsh 安装在: ${zsh_install_dir}\e[0m"
    # 优先级2: 检查常见的系统级安装位置
    elif [[ -d "/usr/share/oh-my-zsh" ]]; then
        zsh_install_dir="/usr/share/oh-my-zsh"
        echo -e "\e[1;33m• 检测到系统级 Oh My Zsh 安装在: ${zsh_install_dir}\e[0m"
    # 优先级3: 检查常见的用户级安装位置
    elif [[ -d "$HOME/.oh-my-zsh" ]]; then
        zsh_install_dir="$HOME/.oh-my-zsh"
        echo -e "\e[1;33m• 检测到用户级 Oh My Zsh 安装在: ${zsh_install_dir}\e[0m"
    else
        echo -e "\e[1;31m✗ 未找到 Oh My Zsh 安装！请先安装 Oh My Zsh。\e[0m"
        return 1
    fi
    
    # 确定自定义目录路径
    if [[ -n "$ZSH_CUSTOM" && -d "$ZSH_CUSTOM" ]]; then
        zsh_custom_dir="$ZSH_CUSTOM"
        echo -e "\e[1;33m• 使用用户定义的自定义目录: ${zsh_custom_dir}\e[0m"
    else
        zsh_custom_dir="${zsh_install_dir}/custom"
        echo -e "\e[1;33m• 使用默认自定义目录: ${zsh_custom_dir}\e[0m"
    fi
    
    # 创建插件目录（如果不存在）
    local plugins_dir="${zsh_custom_dir}/plugins"
    mkdir -p "$plugins_dir" || {
        echo -e "\e[1;31m✗ 无法创建插件目录！请检查权限。\e[0m"
        return 1
    }
    
    # 定义要安装的插件列表
    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "MichaelAquilina/zsh-you-should-use"
    )
     local themes=(
        "romkatv/powerlevel10k"
    )
    
    # 安装插件
    for plugin in "${plugins[@]}"; do
         # 特殊处理 zsh-you-should-use 插件名
    local plugin_name=""
    if [[ "$plugin" == "MichaelAquilina/zsh-you-should-use" ]]; then
        plugin_name="you-should-use"  # 手动指定正确的插件目录名
    else
        plugin_name="${plugin##*/}"  # 其他插件自动提取仓库名
    fi


        local plugin_dir="${plugins_dir}/${plugin_name}"
        if [[ -d "$plugin_dir" ]]; then
            echo -e "\e[1;32m✓ ${plugin_name} 已安装\e[0m"
            continue
        fi
        echo -e "\e[1;34m安装插件 ${plugin_name}...\e[0m"
        if git clone --depth=1 "https://github.com/${plugin}" "$plugin_dir"; then
            echo -e "\e[1;32m✓ ${plugin_name} 安装成功\e[0m"
        else
            echo -e "\e[1;31m✗ ${plugin_name} 安装失败\e[0m"
            rm -rf "$plugin_dir"
        fi
    done
    
# 安装主题
for theme in "${themes[@]}"; do
    local theme_name="${theme##*/}"
    local theme_dir="${zsh_custom_dir}/themes/${theme_name}"
    if [[ -d "$theme_dir" ]]; then
        echo -e "\e[1;32m✓ ${theme_name} 主题已安装\e[0m"
        continue
    fi
    echo -e "\e[1;34m安装主题 ${theme_name}...\e[0m"
    if git clone --depth=1 "https://github.com/${theme}" "$theme_dir"; then
        # 添加复制配置文件功能（仅针对 powerlevel10k）
        if [[ "${theme_name}" == "powerlevel10k" ]]; then
            local config_file="${theme_dir}/config/p10k-rainbow.zsh"
            local dest_file="$HOME/.p10k.zsh"
            if [[ -f "$config_file" ]]; then
                echo -e "\e[1;34m复制 Powerlevel10k 配置文件到 ~/.p10k.zsh...\e[0m"
                cp -vf "$config_file" "$dest_file" &> /dev/null
                if [[ $? -eq 0 ]]; then
                    echo -e "\e[1;32m✓ 配置文件复制完成\e[0m"
                else
                    echo -e "\e[1;31m✗ 配置文件复制失败\e[0m"
                fi
            else
                echo -e "\e[1;31m✗ 未找到 Powerlevel10k 配置文件 ($config_file)\e[0m"
            fi
            # 修改 .zshrc 主题配置（可选，可根据需求保留或移除）
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
        fi
        echo -e "\e[1;32m✓ ${theme_name} 安装成功\e[0m"
    else
        echo -e "\e[1;31m✗ ${theme_name} 安装失败\e[0m"
        rm -rf "$theme_dir"
    fi
done
    
    # 安装 zoxide（目录跳转工具）
    echo -e "\e[1;34m安装 zoxide...\e[0m"
    if ! command -v zoxide &> /dev/null; then
        if curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
            echo -e "\e[1;32m✓ zoxide 安装成功\e[0m"
        else
            echo -e "\e[1;31m✗ zoxide 安装失败\e[0m"
        fi
    else
        echo -e "\e[1;32m✓ zoxide 已安装\e[0m"
    fi
    
    # 安装 fzf（模糊查找工具）
    echo -e "\e[1;34m安装 fzf...\e[0m"
    if [[ ! -d "$HOME/.fzf" ]]; then
        if git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf" --quiet; then
            "$HOME/.fzf/install" --all --no-update-rc --quiet &> /dev/null
            echo -e "\e[1;32m✓ fzf 安装成功\e[0m"
        else
            echo -e "\e[1;31m✗ fzf 安装失败\e[0m"
        fi
    else
        echo -e "\e[1;32m✓ fzf 已安装\e[0m"
    fi
    
    # 安装 fzf-git.sh（Git 集成工具）
    echo -e "\e[1;34m安装 fzf-git.sh...\e[0m"
    if [[ ! -d "$HOME/fzf-git.sh" ]]; then
        if git clone https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh" --quiet; then
            echo -e "\e[1;32m✓ fzf-git.sh 安装成功\e[0m"
        else
            echo -e "\e[1;31m✗ fzf-git.sh 安装失败\e[0m"
        fi
    else
        echo -e "\e[1;32m✓ fzf-git.sh 已安装\e[0m"
    fi
    
    echo ""
    echo -e "\e[1;32m=========================Zsh插件安装完成=========================\e[0m"
    sleep 1
}
install_oh_my_tmux() {
    echo -e "\e[1;36m=========================安装 oh-my-tmux=========================\e[0m"
    git clone https://github.com/gpakosz/.tmux.git
    # shellcheck disable=SC2226
    ln -s -f .tmux/.tmux.conf
    cp .tmux/.tmux.conf.local .
    echo -e "\e${COLOR_GREEN}=========================moh-my-tmux安装完成========================\e[0m"
        sleep 1

}
apply_zshrc_changes() {
    echo -e "\e[1;36m=========================应用 .zshrc 配置更改=========================\e[0m"
    CONFIG_LINE='export LC_ALL=en_US.UTF-8'
    COMMENT="# 设置环境变量 LC_ALL 为 en_US.UTF-8"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================LC_ALL环境变量设置为en_US.UTF-8.=========================\e[0m"
        sleep 1
    else
        echo -e "\e${COLOR_GREEN}=========================LC_ALL环境变量已设置为en_US.UTF-8.=========================\e[0m"
    fi
    declare -a new_plugins=("extract" "systemadmin" "zsh-interactive-cd" "systemd" "sudo" "docker" "ubuntu" "man" "command-not-found" "common-aliases" "aliases" "docker-compose" "git" "zsh-autosuggestions" "zsh-syntax-highlighting" "tmux" "zoxide" "you-should-use")
    if grep -q "^plugins=(" ~/.zshrc; then
        for plugin in "${new_plugins[@]}"; do
            if ! grep -q "plugins=(.*$plugin" ~/.zshrc; then
                sed -i "/^plugins=(/ s/)$/ $plugin)/" ~/.zshrc
                echo -e "\e${COLOR_GREEN}=========================插件 $plugin 已添加。=========================\e[0m"
            else
                echo -e "\e${COLOR_GREEN}=========================插件 $plugin 已存在，跳过。=========================\e[0m"
            fi
        done
    else
        echo "# 设置插件配置" >> ~/.zshrc
        printf "plugins=(" >> ~/.zshrc
        printf "%s " "${new_plugins[@]}" >> ~/.zshrc
        printf ")\n" >> ~/.zshrc
        echo "已创建新的插件配置。"
    fi
    CONFIG_LINE='export ZOXIDE_CMD_OVERRIDE=z'
    COMMENT="# 设置 ZOXIDE_CMD_OVERRIDE"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已设置 ZOXIDE_CMD_OVERRIDE========================\e[0m"
            sleep 1
    else
        echo "ZOXIDE_CMD_OVERRIDE已设置,不需要重新设置。"
    fi
    if ! grep -q 'export ZOXIDE_CMD_OVERRIDE=z' ~/.zshrc; then
        echo 'export ZOXIDE_CMD_OVERRIDE=z' >> ~/.zshrc
        echo "已设置 ZOXIDE_CMD_OVERRIDE。"
    fi
    CONFIG_LINE='eval "$(zoxide init zsh)"'
    COMMENT="# 初始化 zoxide"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已初始化 zoxide。========================\e[0m"
            sleep 1
    else
        echo -e "\e${COLOR_GREEN}=========================zoxide已初始化,不需要重新设置。========================\e[0m"
    fi
    CONFIG_LINE='export PATH="$PATH:$HOME/.local/bin"'
    COMMENT="# 更新 PATH 环境变量"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        sed -i "1i $COMMENT\n$CONFIG_LINE" ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================已将 PATH 环境变量更新添加到 ~/.zshrc 的最上方。========================\e[0m"
            sleep 1
    else
        echo "PATH 环境变量更新已存在于 ~/.zshrc 中，无需重复添加。"
    fi
    CONFIG_LINE='export ZSH_AUTOSUGGEST_STRATEGY=(history completion)'
    COMMENT="# 设置自动建议策略"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已设置 ZSH_AUTOSUGGEST_STRATEGY========================\e[0m"
            sleep 1
    else
        echo "ZSH_AUTOSUGGEST_STRATEGY已设置,不需要重新设置。"
    fi
    CONFIG_LINE='POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true'
    COMMENT="# 禁用 Powerlevel9k 配置向导"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================已禁用 Powerlevel9k 配置向导========================\e[0m"
            sleep 1
    else
        echo "Powerlevel9k 配置向导已禁用,不需要重新设置。"
    fi
    CONFIG_LINE="zstyle ':omz:update' mode auto"
    COMMENT="# =========================设置 Oh My Zsh 自动更新========================="
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已设置 Oh My Zsh 自动更新========================\e[0m"
            sleep 1
    else
        echo "Oh My Zsh 自动更新已设置,不需要重新设置。"
    fi
    CONFIG_LINE='[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
    COMMENT="# =========================检查并源自定义 p10k 配置========================="
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "=========================已添加 Powerlevel10k 配置文件检查。========================="
    else
        echo "=========================Powerlevel10k 配置文件检查已添加,不需要重新设置。========================="
    fi
    if ! grep -q 'copy-prev-shell-word' ~/.zshrc; then
        echo 'copy-prev-shell-word() {' >> ~/.zshrc
        echo '  local last_word=$(fc -ln -1 | awk '"'"'{print $NF}'"'"')' >> ~/.zshrc
        echo '  LBUFFER+=$last_word' >> ~/.zshrc
        echo '}' >> ~/.zshrc
        echo 'zle -N copy-prev-shell-word' >> ~/.zshrc
        echo 'bindkey "^[m" copy-prev-shell-word' >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已添加 bindkey '^[m' copy-prev-shell-word]========================\e[0m"
            sleep 1
    fi
    script_content="# 检查是否存在有效的 SSH_AUTH_SOCK 连接
        touch ~/.ssh-agent-ohmyzsh
        if [ ! -S \"\${SSH_AUTH_SOCK}\" ]; then
            # 尝试从 ~/.ssh-agent-ohmyzsh 加载 ssh-agent 配置
            if [ -f ~/.ssh-agent-ohmyzsh ]; then
                eval \"\$(cat ~/.ssh-agent-ohmyzsh)\"
            fi
        fi
        # 再次检查是否存在有效的 SSH_AUTH_SOCK 连接
        if [ ! -S \"\${SSH_AUTH_SOCK}\" ]; then
            # 如果没有有效的连接，启动一个新的 ssh-agent 并保存配置
            ssh-agent -t 12h > ~/.ssh-agent-ohmyzsh
            eval \"\$(cat ~/.ssh-agent-ohmyzsh)\"
            ssh-add ~/.ssh/* &>/dev/null
        fi"

    # 检查 ~/.zshrc 中是否已存在相同的脚本内容
    if grep -qF -- "$script_content" ~/.zshrc; then
        echo -e "\e${COLOR_GREEN}=========================SSH agent 脚本已存在于 ~/.zshrc 中。=========================\e[0m"
    else
        echo "$script_content" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================SSH agent 脚本已添加到 ~/.zshrc。=========================\e[0m"
    fi
    echo ""
    echo -e "\e[1;36m=========================安装vim-for-server=========================\e[0m"
    curl https://raw.githubusercontent.com/wklken/vim-for-server/master/vimrc > ~/.vimrc
    echo -e "\e${COLOR_GREEN}=========================vim-for-server安装完毕========================\e[0m"
        sleep 1
       echo ""
    echo -e "\e[1;36m=========================安装fzf=========================\e[0m"
    printf 'y\ny\ny\n' | ~/.fzf/install
    echo ""
    echo -e "\e${COLOR_GREEN}=========================fzf安装完毕========================\e[0m"
        sleep 1
    # 检查 batcat 是否已安装并位于预期的位置
    echo ""
    echo -e "\e[1;36m=========================配置bat和fd=========================\e[0m"
    if [ -f /usr/bin/batcat ]; then
        # 如果 batcat 已安装，检查是否存在 ~/.local/bin 目录
        if [ -d ~/.local/bin ]; then
            # 如果目录存在，创建 bat 的符号链接
            ln -sf /usr/bin/batcat ~/.local/bin/bat
            ln -sf /usr/bin/fdfind ~/.local/bin/fd
            echo ""
            echo -e "\e${COLOR_GREEN}=========================bat,和fd 已配置=========================\e[0m"
            sleep 1
        else
            # 如果目录不存在，创建目录并创建 bat 的符号链接
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
            ln -sf /usr/bin/fdfind ~/.local/bin/fd
            echo ""
            echo -e "\e${COLOR_GREEN}=========================bat,和fd 已配置=========================\e[0m"
        fi
    else
        # 如果 batcat 未安装，输出错误消息
        echo ""
        echo -e "\e${COLOR_RED}=========================bat未安装=========================\e[0m"
    fi
    # 删除掉 /root/.oh-my-zsh/plugins/common-aliases/common-aliases.plugin.zsh文件的
    # (( $+commands[fd] )) || alias fd='find . -type d -name'
    file_path="/root/.oh-my-zsh/plugins/common-aliases/common-aliases.plugin.zsh"
        # 检查文件是否存在
    if [[ -f "$file_path" ]]; then
        # 使用 sed 命令来注释掉特定的 fd 别名行
        sed -i '/commands\[fd/d' "$file_path"
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已禁用 $file_path 中的 fd 别名。=========================\e[0m"
    else
        echo ""
        echo -e "\e${COLOR_RED}=========================未找到文件: $file_path=========================\e[0m"
    fi
    config_text='# ================fd-fzf-bat===============
    fg="#CBE0F0"
    bg="#011628"
    bg_highlight="#143652"
    purple="#B388FF"
    blue="#06BCE4"
    cyan="#2CF9ED"
    export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan} --preview '\''bat --color=always --style=numbers --line-range=:500 {}'\''"
    export FZF_DEFAULT_COMMAND="fd --hidden  --strip-cwd-prefix --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_OPTS="--preview '\''exa --tree --color=always {} | head -200'\''"
    export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
    _fzf_compgen_path() {
        fd --hidden --exclude .git . "$1"
    }
    _fzf_compgen_dir() {
        fd --type=d --hidden --exclude .git . "$1"
    }
    _fzf_comprun() {
    local command=$1
    shift

    case "$command" in
        cd)           fzf --preview '\''exa --tree --color=always {} | head -200'\'' "$@" ;;
        export|unset) fzf --preview "eval '\''echo \\\$'\''{}"         "$@" ;;
        ssh)          fzf --preview '\''dig {}'\''                   "$@" ;;
        *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
    esac
    }
    eval $(thefuck --alias)
    eval $(thefuck --alias fk)
    ENABLE_CORRECTION="true"
    source ~/fzf-git.sh/fzf-git.sh
    # ================fd-fzf-bat===============
    '

    # 检查配置是否已存在
    if ! grep -q "fd-fzf-bat" ~/.zshrc; then
        # 插入配置
        echo "$config_text" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}========================fzf-fd-bat合体技能已经配置成功========================e[0m"
    else
        echo ""
        echo "=========================fzf-fd-bat合体技能已经配置成功,不用重复添加========================="
    fi
    #在.zshrc设置快捷alias
    ALIAS='
    # ================alias===============
    alias ls="exa -a --color=always --long --icons"
    alias tree="exa --tree --color=always --long --icons"
    alias cat="bat"
    alias cd="z"
    #clear
    alias c="clear"
    alias cl="clear"
    #ping
    alias pg="ping google.com -c 5"
    alias cg="curl -v google.com"
    alias pb="ping baidu.com -c 5"
    alias cb="curl -v baidu.com"
    alias ping="ping -c 5"
    #Exit Command
    alias :q="exit"
    alias ext="exit"
    alias xt="exit"
    alias by="exit"
    alias bye="exit"
    alias die="exit"
    alias quit="exit"
    # Launch Simple HTTP Server
    alias serve="python -m SimpleHTTPServer"
    # Parenting changing perms on /
    alias chown="chown --preserve-root"
    alias chmod="chmod --preserve-root"
    alias chgrp="chgrp --preserve-root"
    # Install & Update utilties
    alias sai="sudo apt install -y"
    alias sau="sudo apt update -y"
    alias update="sudo apt update -y"
    #Show open ports
    alias ports="sudo ss -tulanp"
    alias tu="df -hl --total G total"
    alias us="du -ch G total"
    alias vi="nvim"
    alias myip="ip addr show G inet G -v inet6"
    alias fdu="function _fdu() { find "$1" -type f -exec du -h {} + | sort -rh | head -n 20; }; _fdu"
    # ================alias===============
    '
    if ! grep -q "ALIAS" ~/.zshrc; then
        echo "$ALIAS" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================一大波alias快捷键已添加到~/.zshrc。=========================\e[0m"
    else
        echo -e "\e${COLOR_GREEN}=========================快捷键已存在于~/.zshrc。=========================\e[0m"
    fi

    echo -e "\e[1;36m=========================.zshrc 配置更改完成。=========================\e[0m"
    echo -e "\e[1;36m=========================请输入ZSH启动终端以应用更改。=========================\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[well done]]========================\e[0m"
        sleep 1
}
start_zsh() {
    echo ""
    echo -e "\e[1;36m=========================启动zsh...=========================\e[0m"
    exec zsh
}
PS3=$(echo -e "\e[1;36m=========================请选择操作: =========================\e[0m")

options=(
    $(echo -e "\e[1;32m全部自动安装\e[0m")
    $(echo -e "\e[1;34m️安装基础工具\e[0m")
    $(echo -e "\e[1;34m更改默认Shell为zsh\e[0m")
    $(echo -e "\e[1;34m安装OhMyZsh\e[0m")
    $(echo -e "\e[1;34m安装oh-my-tmux\e[0m")
    $(echo -e "\e[1;33m安装Zsh插件\e[0m")
    $(echo -e "\e[1;33m应用.zshrc配置更改\e[0m")
    $(echo -e "\e[1;32m启动zsh\e[0m")
    $(echo -e "\e[1;31m退出\e[0m")
)

COLUMNS=1
select opt in "${options[@]}"; do
    case $opt in
        *"全部自动安装"*)
            install_basic_tools
            change_default_shell
            install_oh_my_zsh
            install_oh_my_tmux
            install_zsh_plugins
            apply_zshrc_changes
            start_zsh
            break
            ;;
        *"安装基础工具"*)
            install_basic_tools
            ;;
        *"更改默认Shell为zsh"*)
            change_default_shell
            ;;
        *"安装OhMyZsh"*)
            install_oh_my_zsh
            ;;
        *"安装oh-my-tmux"*)
            install_oh_my_tmux
            ;;
        *"安装Zsh插件"*)
            install_zsh_plugins
            ;;
        *"应用.zshrc配置更改"*)
            apply_zshrc_changes
            ;;
        *"启动zsh"*)
            start_zsh
            ;;
        *"退出"*)
            break
            ;;
        *) echo -e "\e[1;31m无效操作 $REPLY\e[0m" ;;
    esac
done
