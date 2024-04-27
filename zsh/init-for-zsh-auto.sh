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
echo -e "\e[1;36m本脚本将帮助您添加zsh,美化power10k主题,添加插件。\e[0m"
echo -e "\e${COLOR_BLUE}请按照提示输入相关信息，然后脚本将自动完成后续操作。\e[0m"
echo -e "\e[1;34m================================================================\e[0m"

install_basic_tools() {
    if [ -f /etc/debian_version ]; then
        #        echo "开始更新系统和安装必要工具..."
        echo -e "\e[1;36m开始更新系统和安装必要工具...\e[0m"
        sudo apt-get update
        sudo apt-get install -y curl vim zsh htop git tmux
    elif [ -f /etc/redhat-release ]; then
        sudo yum update
        sudo yum install -y curl vim zsh htop git tmux
    else
        echo -e "\e${COLOR_RED}不支持的系统。\e[0m"
        exit 1
    fi
    if [ -f /usr/bin/git ]; then
        echo -e "\e${COLOR_GREEN}git已经安装\e[0m"
    else
        sudo apt-get install -y git
    fi
    if [ -f /usr/bin/curl ]; then
        echo -e "\e${COLOR_GREEN}curl已经安装\e[0m"
    else
        sudo apt-get install -y curl
    fi
    if [ -f /usr/bin/vim ]; then
        echo -e "\e${COLOR_GREEN}vim已经安装\e[0m"
    else
        sudo apt-get install -y vim
    fi
    if [ -f /usr/bin/zsh ]; then
        echo -e "\e${COLOR_GREEN}zsh已经安装\e[0m"
    else
        sudo apt-get install -y zsh
    fi
    if [ -f /usr/bin/htop ]; then
        echo -e "\e${COLOR_GREEN}htop已经安装\e[0m"
    else
        sudo apt-get install -y htop
    fi
    if [ -f /usr/bin/tmux ]; then
        echo -e "\e${COLOR_GREEN}tmux已经安装\e[0m"
    else
        sudo apt-get install -y tmux
    fi
    if [ -f /usr/bin/bat ]; then
        echo -e "\e${COLOR_GREEN}bat已经安装\e[0m"
    else
        sudo apt-get install -y bat
    fi
    if [ -f /usr/bin/fdfind ]; then
        echo -e "\e${COLOR_GREEN}fd-find已经安装\e[0m"
    else
        sudo apt-get install -y fd-find
    fi
    if [ -f /usr/bin/exa ]; then
        echo -e "\e${COLOR_GREEN}exa已经安装\e[0m"
    else
        sudo apt-get install -y exa
    fi
    if [ -f /usr/local/bin/thefuck ]; then
        echo e "\e${COLOR_GREEN}thefuck已经安装\e[0m"
    else
        sudo apt-get install -y thefuck
    fi
    sudo apt install net-tools -y
    echo -e "\e${COLOR_GREEN}net-tools已经安装\e[0m"
    echo -e "\e[1;36m基础工具安装完成。\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
    sleep 1
    clear
}
change_default_shell() {
    echo -e "\e[1;36m正在自动更改默认Shell为zsh...\e[0m"
    ZSH_PATH=$(which zsh)
    chsh -s "$ZSH_PATH"
    echo "默认Shell更改完成。"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
    sleep 1
}
install_oh_my_zsh() {
    echo "安装Oh My Zsh（原版）..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo -e "\e[1;36mOh My Zsh安装完成。\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
        sleep 1
}
install_powerlevel10k() {
    echo -e "\e[1;36m安装Powerlevel10k主题...\e[0m"
    git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    sed -i '/ZSH_THEME="robbyrussell"/c\ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
    echo -e "\e[1;36mPowerlevel10k主题安装完成。\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
        sleep 1
}
download_p10k_config() {
    echo -e "\e[1;36m下载Powerlevel10k配置文件...\e[0m"
    curl -L https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-rainbow.zsh -o ~/.p10k.zsh
    echo -e "\e[1;36mPowerlevel10k配置文件下载完成。\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
    sleep 1
}
install_zsh_plugins() {
    echo -e "\e[1;36m安装Zsh插件...\e[0m"
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/you-should-use
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    git clone https://github.com/junegunn/fzf-git.sh.git
    echo -e "\e[1;36mZsh插件安装完成。\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
        sleep 1

}
install_oh_my_tmux() {
    echo -e "\e[1;36m安装 oh-my-tmux...\e[0m"
    git clone https://github.com/gpakosz/.tmux.git
    # shellcheck disable=SC2226
    ln -s -f .tmux/.tmux.conf
    cp .tmux/.tmux.conf.local .
    echo -e "\e[1;36moh-my-tmux安装完成。\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
        sleep 1

}
apply_zshrc_changes() {
    echo "应用 .zshrc 配置更改..."
    CONFIG_LINE='export LC_ALL=en_US.UTF-8'
    COMMENT="# 设置环境变量 LC_ALL 为 en_US.UTF-8"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "LC_ALL环境变量设置为en_US.UTF-8."
    else
        echo "LC_ALL环境变量已设置为en_US.UTF-8."
    fi
    declare -a new_plugins=("extract" "systemadmin" "zsh-interactive-cd" "systemd" "sudo" "docker" "ubuntu" "man" "command-not-found" "common-aliases" "aliases" "docker-compose" "git" "zsh-autosuggestions" "zsh-syntax-highlighting" "tmux" "zoxide" "you-should-use")
    if grep -q "^plugins=(" ~/.zshrc; then
        for plugin in "${new_plugins[@]}"; do
            if ! grep -q "plugins=(.*$plugin" ~/.zshrc; then
                sed -i "/^plugins=(/ s/)$/ $plugin)/" ~/.zshrc
                echo "插件 $plugin 已添加。"
            else
                echo "插件 $plugin 已存在，跳过。"
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
        echo "已设置 ZOXIDE_CMD_OVERRIDE。"
        echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
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
        echo "已初始化 zoxide。"
        echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
            sleep 1
    else
        echo "zoxide已初始化,不需要重新设置。"
    fi
    CONFIG_LINE='export PATH="$PATH:$HOME/.local/bin"'
    COMMENT="# 更新 PATH 环境变量"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        sed -i "1i $COMMENT\n$CONFIG_LINE" ~/.zshrc
        echo "已将 PATH 环境变量更新添加到 ~/.zshrc 的最上方。"
    else
        echo "PATH 环境变量更新已存在于 ~/.zshrc 中，无需重复添加。"
    fi
    CONFIG_LINE='export ZSH_AUTOSUGGEST_STRATEGY=(history completion)'
    COMMENT="# 设置自动建议策略"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "已设置 ZSH_AUTOSUGGEST_STRATEGY。"
        echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
            sleep 1
    else
        echo "ZSH_AUTOSUGGEST_STRATEGY已设置,不需要重新设置。"
    fi
    CONFIG_LINE='POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true'
    COMMENT="# 禁用 Powerlevel9k 配置向导"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "已禁用 Powerlevel9k 配置向导。"
    else
        echo "Powerlevel9k 配置向导已禁用,不需要重新设置。"
    fi
    CONFIG_LINE='DISABLE_AUTO_UPDATE="true"'
    COMMENT="# 设置 Oh My Zsh 自动更新"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "已设置 Oh My Zsh 自动更新。"
        echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
            sleep 1
    else
        echo "Oh My Zsh 自动更新已设置,不需要重新设置。"
    fi
    CONFIG_LINE='[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
    COMMENT="# 检查并源自定义 p10k 配置"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "已添加 Powerlevel10k 配置文件检查。"
    else
        echo "Powerlevel10k 配置文件检查已添加,不需要重新设置。"
    fi
    if ! grep -q 'copy-prev-shell-word' ~/.zshrc; then
        echo 'copy-prev-shell-word() {' >> ~/.zshrc
        echo '  local last_word=$(fc -ln -1 | awk '"'"'{print $NF}'"'"')' >> ~/.zshrc
        echo '  LBUFFER+=$last_word' >> ~/.zshrc
        echo '}' >> ~/.zshrc
        echo 'zle -N copy-prev-shell-word' >> ~/.zshrc
        echo 'bindkey "^[m" copy-prev-shell-word' >> ~/.zshrc
        echo "已添加 bindkey '^[m' copy-prev-shell-word"
        echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
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
        echo "SSH agent 脚本已存在于 ~/.zshrc 中。"
    else
        echo "$script_content" >> ~/.zshrc
        echo "SSH agent 脚本已添加到 ~/.zshrc。"
    fi
    echo "安装vim-for-server..."
    curl https://raw.githubusercontent.com/wklken/vim-for-server/master/vimrc > ~/.vimrc
    echo "vim-for-server安装完成。"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
        sleep 1
    echo "安装fzf"
    ~/.fzf/install
    echo "安装fzf完成"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
        sleep 1
    # 检查 batcat 是否已安装并位于预期的位置
    if [ -f /usr/bin/batcat ]; then
        # 如果 batcat 已安装，检查是否存在 ~/.local/bin 目录
        if [ -d ~/.local/bin ]; then
            # 如果目录存在，创建 bat 的符号链接
            ln -sf /usr/bin/batcat ~/.local/bin/bat
            ln -sf /usr/bin/fdfind ~/.local/bin/fd
            echo -e "\e${COLOR_GREEN}bat 已配置\e[0m"
            echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
                sleep 1
        else
            # 如果目录不存在，创建目录并创建 bat 的符号链接
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
            ln -sf /usr/bin/fdfind ~/.local/bin/fd
            echo -e "\e${COLOR_GREEN}bat,和fd 已配置\e[0m"
        fi
    else
        # 如果 batcat 未安装，输出错误消息
        echo -e "\e${COLOR_RED}bat 未安装\e[0m"
    fi
    # 删除掉 /root/.oh-my-zsh/plugins/common-aliases/common-aliases.plugin.zsh文件的
    # (( $+commands[fd] )) || alias fd='find . -type d -name'
    file_path="/root/.oh-my-zsh/plugins/common-aliases/common-aliases.plugin.zsh"
        # 检查文件是否存在
    if [[ -f "$file_path" ]]; then
        # 使用 sed 命令来注释掉特定的 fd 别名行
        sed -i '/(( $+commands[fd] )) || alias fd=/s/^/#/' "$file_path"
        echo "fd alias has been disabled in $file_path."
    else
        echo "File not found: $file_path"
    fi
    #==========================
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
        echo "Configuration added to ~/.zshrc."
    else
        echo "Configuration already exists in ~/.zshrc."
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
    alias sai="sudo apt install"
    alias sau="sudo apt update"
    alias update="sudo apt update"
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
        echo -e "\e${COLOR_GREEN}一大波alias快捷键已添加到~/.zshrc。\e[0m"
    else
        echo -e "\e${COLOR_GREEN}快捷键已存在于~/.zshrc。\e[0m"
    fi

    echo -e "\e[1;36m.zshrc 配置更改完成。\e[0m"
    echo -e "\e[1;36m请输入ZSH启动终端以应用更改。\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
        sleep 1
}
start_zsh() {
    echo "启动zsh..."
    exec zsh
}
PS3=$(echo -e "\e[1;36m请选择操作: \e[0m")

options=(
    $(echo -e "\e[1;32m🚀全部自动安装\e[0m")
    $(echo -e "\e[1;34m🛠️安装基础工具\e[0m")
    $(echo -e "\e[1;34m🔧更改默认Shell为zsh\e[0m")
    $(echo -e "\e[1;34m🎉安装OhMyZsh\e[0m")
    $(echo -e "\e[1;34m🔨安装oh-my-tmux\e[0m")
    $(echo -e "\e[1;35m🌟安装Powerlevel10k主题\e[0m")
    $(echo -e "\e[1;35m⬇️下载Powerlevel10k配置文件\e[0m")
    $(echo -e "\e[1;33m🔌安装Zsh插件\e[0m")
    $(echo -e "\e[1;33m📝应用.zshrc配置更改\e[0m")
    $(echo -e "\e[1;32m🚀启动zsh\e[0m")
    $(echo -e "\e[1;31m🚪退出\e[0m")
)

echo -e "\e[1;34m=========================================================\e[0m"
COLUMNS=1
select opt in "${options[@]}"; do
    case $opt in
        *"全部自动安装"*)
            install_basic_tools
            change_default_shell
            install_oh_my_zsh
            install_oh_my_tmux
            install_powerlevel10k
            download_p10k_config
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
        *"安装Powerlevel10k主题"*)
            install_powerlevel10k
            ;;
        *"下载Powerlevel10k配置文件"*)
            download_p10k_config
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
echo -e "\e[1;34m=========================================================\e[0m"
