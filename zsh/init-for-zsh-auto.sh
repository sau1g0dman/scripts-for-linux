#!/bin/bash
install_basic_tools() {
    echo "开始更新系统和安装必要工具..."
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y curl vim zsh htop git tmux
    elif [ -f /etc/redhat-release ]; then
        sudo yum update
        sudo yum install -y curl vim zsh htop git tmux
    else
        echo "不支持的系统。"
        exit 1
    fi
    if [ -f /usr/bin/git ]; then
        echo "git已经安装"
    else
        sudo apt-get install -y git
    fi
    if [ -f /usr/bin/curl ]; then
        echo "curl已经安装"
    else
        sudo apt-get install -y curl
    fi
    if [ -f /usr/bin/vim ]; then
        echo "vim已经安装"
    else
        sudo apt-get install -y vim
    fi
    if [ -f /usr/bin/zsh ]; then
        echo "zsh已经安装"
    else
        sudo apt-get install -y zsh
    fi
    if [ -f /usr/bin/htop ]; then
        echo "htop已经安装"
    else
        sudo apt-get install -y htop
    fi
    if [ -f /usr/bin/tmux ]; then
        echo "tmux已经安装"
    else
        sudo apt-get install -y tmux
    fi
    echo "基础工具安装完成。"
    clear
}
change_default_shell() {
    echo "正在自动更改默认Shell为zsh..."
    ZSH_PATH=$(which zsh)
    chsh -s "$ZSH_PATH"
    echo "默认Shell更改完成。"
}
install_oh_my_zsh() {
    echo "安装Oh My Zsh（原版）..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh安装完成。"
}
install_powerlevel10k() {
    echo "安装Powerlevel10k主题..."
    git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    sed -i '/ZSH_THEME="robbyrussell"/c\ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
    echo "Powerlevel10k主题安装完成。"
}
download_p10k_config() {
    echo "下载Powerlevel10k配置文件..."
    curl -L https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-rainbow.zsh -o ~/.p10k.zsh
    echo "Powerlevel10k配置文件下载完成。"
}
install_zsh_plugins() {
    echo "安装Zsh插件..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/you-should-use
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    echo "Zsh插件安装完成。"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
}
install_oh_my_tmux() {
    echo "安装 oh-my-tmux..."
    git clone https://github.com/gpakosz/.tmux.git
    # shellcheck disable=SC2226
    ln -s -f .tmux/.tmux.conf
    cp .tmux/.tmux.conf.local .
    echo "oh-my-tmux安装完成。"
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
        # shellcheck disable=SC2129
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
    CONFIG_LINE='zstyle ":omz:update" mode auto'
    COMMENT="# 设置 Oh My Zsh 自动更新"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "已设置 Oh My Zsh 自动更新。"
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
            ssh-agent -t 1h > ~/.ssh-agent-ohmyzsh
            eval \"\$(cat ~/.ssh-agent-ohmyzsh)\"
        fi
        ssh-add ~/.ssh/id_rsa*"


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
    echo "脚本执行完成。"
    echo "安装fzf"
    y | ~/.fzf/install
    echo "安装fzf完成"
}
start_zsh() {
    echo "启动zsh..."
    exec zsh
}
PS3='请选择操作: '
options=("全部自动安装" "安装基础工具" "更改默认Shell为zsh" "安装Oh My Zsh" "安装oh-my-tmux" "安装Powerlevel10k主题" "下载Powerlevel10k配置文件" "安装Zsh插件" "应用.zshrc配置更改" "启动zsh" "退出")
select opt in "${options[@]}"; do
    case $opt in
        "全部自动安装")
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
        "安装基础工具")
            install_basic_tools
            ;;
        "更改默认Shell为zsh")
            change_default_shell
            ;;
        "安装Oh My Zsh")
            install_oh_my_zsh
            ;;
        "安装oh-my-tmux")
            install_oh_my_tmux
            ;;
        "安装Powerlevel10k主题")
            install_powerlevel10k
            ;;
        "下载Powerlevel10k配置文件")
            download_p10k_config
            ;;
        "安装Zsh插件")
            install_zsh_plugins
            ;;
        "应用.zshrc配置更改")
            apply_zshrc_changes
            ;;
        "启动zsh")
            start_zsh
            ;;
        "退出")
            break
            ;;
        *) echo "无效操作 $REPLY" ;;
    esac
done
