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
    # 判断是否已经安装,如果已经安装则不再安装,否则安装,echo返回信息
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
    # 清理屏幕 使得菜单显示在屏幕顶部
    clear
}


change_default_shell() {
    echo "正在自动更改默认Shell为zsh..."
    ZSH_PATH=$(which zsh)
    chsh -s "$ZSH_PATH"
    echo "默认Shell更改完成。"
}

install_oh_my_zsh() {
    echo "安装Oh My Zsh（国内镜像源）..."
    curl -fsSL https://gitee.com/Devkings/oh_my_zsh_install/raw/master/install.sh > install_oh_my_zsh.sh
    sed -i "/read opt/c\\opt='y'" install_oh_my_zsh.sh
    sh install_oh_my_zsh.sh
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
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    echo "Zsh插件安装完成。"
}

apply_zshrc_changes() {
    echo "应用 .zshrc 配置更改..."

    # LC_ALL 设置
    if ! grep -q 'export LC_ALL=en_US.UTF-8' ~/.zshrc; then
        echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshrc
        echo "已设置 LC_ALL 环境变量为 en_US.UTF-8。"
    fi

    # 插件配置
    if ! grep -q 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting tmux zoxide)' ~/.zshrc; then
        sed -i '/^plugins=(git)$/c\plugins=(git zsh-autosuggestions zsh-syntax-highlighting tmux zoxide)' ~/.zshrc
        echo "已更新插件配置。"
    fi

    # ZOXIDE_CMD_OVERRIDE
    if ! grep -q 'export ZOXIDE_CMD_OVERRIDE=z' ~/.zshrc; then
        echo 'export ZOXIDE_CMD_OVERRIDE=z' >> ~/.zshrc
        echo "已设置 ZOXIDE_CMD_OVERRIDE。"
    fi

    # zoxide init
    if ! grep -q 'eval "$(zoxide init zsh)"' ~/.zshrc; then
        echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
        echo "已初始化 zoxide。"
    fi

    # PATH 更新
    if ! grep -q 'export PATH="$PATH:$HOME/.local/bin"' ~/.zshrc; then
        echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
        echo "已更新 PATH 环境变量。"
    fi

    # 自动建议策略
    if ! grep -q 'export ZSH_AUTOSUGGEST_STRATEGY=(history completion)' ~/.zshrc; then
        echo 'export ZSH_AUTOSUGGEST_STRATEGY=(history completion)' >> ~/.zshrc
        echo "已设置 ZSH_AUTOSUGGEST_STRATEGY。"
    fi

    # 禁用 Powerlevel9k 配置向导
    if ! grep -q 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' ~/.zshrc; then
        echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >>  ~/.zshrc
        echo "已禁用 Powerlevel9k 配置向导。"
    fi

    # 自动更新设置
    if ! grep -q "zstyle ':omz:update' mode auto" ~/.zshrc; then
        echo "zstyle ':omz:update' mode auto" >>  ~/.zshrc
        echo "已设置 Oh My Zsh 自动更新。"
    fi

    # 检查并源自定义 p10k 配置
    if ! grep -q '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' ~/.zshrc; then
        echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >>  ~/.zshrc
        echo "已添加 Powerlevel10k 配置文件检查。"
    fi

    echo "脚本执行完成。"
}



start_zsh() {
    echo "启动zsh..."
    exec zsh
}

PS3='请选择操作: '
options=("全部自动安装" "安装基础工具"  "更改默认Shell为zsh" "安装Oh My Zsh" "安装Powerlevel10k主题" "下载Powerlevel10k配置文件" "安装Zsh插件" "应用.zshrc配置更改" "启动zsh" "退出")
select opt in "${options[@]}"
do
    case $opt in
        "全部自动安装")
            install_basic_tools
            change_default_shell
            install_oh_my_zsh
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
        *) echo "无效操作 $REPLY";;
    esac
done

