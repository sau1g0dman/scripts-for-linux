#!/bin/bash
clear
COLOR_GREEN='\033[32m'  # 绿色
COLOR_RED='\033[31m'  # 红色
COLOR_BLUE='\033[34m'  # 蓝色
echo -e "\e${COLOR_BLUE}================================================================"
echo -e "\e${COLOR_GREEN}🚀 欢迎使用 自动安装nvim&&astronvim自动配置\e[0m"
echo -e "\e${COLOR_GREEN}👤 作者: saul\e[0m"
echo -e "\e${COLOR_GREEN}📧 邮箱: sau1amaranth@gmail.com\e[0m"
echo -e "\e${COLOR_GREEN}🔖 version 1.0\e[0m"
echo -e "\e${COLOR_GREEN}本脚本将帮助您自动安装nvim,并自动配置astronvim插件。\e[0m"
echo -e "\e${COLOR_BLUE}================================================================"

# 安装nvim
install_nvim() {
    echo -e "\e${COLOR_GREEN}正在安装nvim...\e[0m"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    sudo apt install python3.12-venv unzip npm -y
    EXPORT_PATH='export PATH="$PATH:/opt/nvim-linux64/bin"'
    if ! grep -qF -- "$EXPORT_PATH" ~/.zshrc; then
        echo "$EXPORT_PATH" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}已将nvim添加到环境变量。\e[0m"
    else
        echo -e "\e${COLOR_RED}nvim已添加到环境变量,不需要重复添加。\e[0m"
    fi
    echo -e "\e${COLOR_GREEN}nvim已安装。\e[0m"
    echo -e "\e${COLOR_GREEN}=====================正在安装lazygit==============================\e[0m"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    # 清理下载的文件
    rm lazygit.tar.gz lazygit
    echo -e "\e${COLOR_GREEN}===========================lazygit安装完成=========================\e[0m"
    echo -e "\e${COLOR_GREEN}===========================[[OK]]=======================================\e[0m"
    sleep 1
}
#安装ultra vimrc
install_ultra_vimrc() {
    echo -e "\e${COLOR_GREEN}正在安装ultra vimrc...\e[0m"
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
    echo -e "\e${COLOR_GREEN}ultra vimrc已安装。\e[0m"
    echo -e "\e${COLOR_GREEN}===========================[[OK]]=======================================\e[0m"
    sleep 1
}

# 安装 cc gcc clang zig
install_cc_gcc_clang_zig() {
    echo -e "\e${COLOR_GREEN}正在安装cc gcc clang zig...\e[0m"
    sudo apt install build-essential -y
    echo -e "\e${COLOR_GREEN}cc gcc clang zig已安装。\e[0m"
    echo -e "\e${COLOR_GREEN}===========================[[OK]]=======================================\e[0m"
    sleep 1
}

# 安装astronvim
install_astronvim() {
    echo -e "\e${COLOR_GREEN}正在安装astronvim...\e[0m"
    mv ~/.config/nvim ~/.config/nvim.bak
    mv ~/.local/share/nvim ~/.local/share/nvim.bak
    mv ~/.local/state/nvim ~/.local/state/nvim.bak
    mv ~/.cache/nvim ~/.cache/nvim.bak
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
    echo -e "\e${COLOR_GREEN}astronvim已安装。\e[0m"
    echo -e "\e${COLOR_GREEN}正在重新加载zsh配置文件...\e[0m"
    # shellcheck disable=SC1090
    sleep 1
    echo -e "\e${COLOR_GREEN}zsh配置文件已重新加载。\e[0m"
    echo -e "\e${COLOR_GREEN}===========================[[OK]]=======================================\e[0m"
    sleep 1
    zsh
}
# 安装lazyvim
install_lazyvim() {
    echo -e "\e${COLOR_GREEN}正在安装lazyvim...\e[0m"
    # required
    mv ~/.config/nvim{,.bak}
    # optional but recommended
    mv ~/.local/share/nvim{,.bak}
    mv ~/.local/state/nvim{,.bak}
    mv ~/.cache/nvim{,.bak}
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
    echo -e "\e${COLOR_GREEN}lazyvim已安装。\e[0m"
    echo ""

    echo -e "\e${COLOR_GREEN}===========================[[OK]]=======================================\e[0m"
    sleep 1
    zsh
}

# 卸载 astronvim
uninstall_astronvim() {
    echo -e "\e${COLOR_GREEN}正在卸载astronvim...\e[0m"
    mv ~/.config/nvim ~/.config/nvim.bak
    mv ~/.local/share/nvim ~/.local/share/nvim.bak
    mv ~/.local/state/nvim ~/.local/state/nvim.bak
    mv ~/.cache/nvim ~/.cache/nvim.bak
    echo -e "\e${COLOR_GREEN}astronvim已卸载。\e[0m"
    echo -e "\e${COLOR_GREEN}===========================[[OK]]=======================================\e[0m"
    sleep 1
}

# clone astronvim 官方模版
clone_astronvim() {
    echo -e "\e${COLOR_GREEN}正在clone astronvim官方模版...\e[0m"
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
    echo -e "\e${COLOR_GREEN}astronvim官方模版已clone。\e[0m"
    echo -e "\e${COLOR_GREEN}===========================[[OK]]=======================================\e[0m"
}
#安装NvChad
install_NvChad() {
    echo -e "\e${COLOR_GREEN}正在安装NvChad...\e[0m"
    git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
    echo -e "\e${COLOR_GREEN}NvChad。\e[0m"
}

PS3=$(echo -e "\e${COLOR_GREEN}请选择操作:\e[0m")
options=(

    $(echo -e "\e${COLOR_GREEN}自动安装Nvim\e[0m")
    $(echo -e "\e${COLOR_GREEN}自动安装NvChad\e[0m")
    $(echo -e "\e${COLOR_GREEN}自动安装astroNvim\e[0m")
    $(echo -e "\e${COLOR_GREEN}自动安装lazyVim\e[0m")
    $(echo -e "\e${COLOR_GREEN}克隆astronvim官方模版\e[0m")
    $(echo -e "\e${COLOR_GREEN}卸载astro/lazynvim/NvChad\e[0m")
    $(echo -e "\e${COLOR_GREEN}安装ultraVimrc\e[0m")
    $(echo -e "\e${COLOR_RED}退出\e[0m")
)
COLUMNS=1
select opt in "${options[@]}"; do
    case $opt in
        *"自动安装Nvim"*)
            install_nvim
            install_cc_gcc_clang_zig
            break
            ;;
        *"自动安装NvChad"*)
            install_nvim
            install_cc_gcc_clang_zig
            install_NvChad
            break
            ;;
        *"自动安装astroNvim"*)
            install_nvim
            install_cc_gcc_clang_zig
            install_astronvim
            break
            ;;
        *"自动安装lazyVim"*)
            install_nvim
            install_cc_gcc_clang_zig
            install_lazyvim
            break
            ;;
        *"克隆astronvim官方模版"*)
            clone_astronvim
            break
            ;;
        *"卸载astro/lazynvim/NvChad"*)
            uninstall_astronvim
            break
            ;;
        *"安装ultraVimrc"*)
            install_ultra_vimrc
            break
            ;;
        *"退出"*)
            break
            ;;
        *)
            echo -e "\e${COLOR_RED}无效选项\e[0m"
            ;;
    esac
done
