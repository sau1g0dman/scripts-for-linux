#!/bin/bash

echo "开始更新系统和安装必要工具..."
sudo apt-get update
sudo apt-get install -y curl vim zsh htop git
echo "基础工具安装完成。"

echo "正在自动更改默认Shell为zsh..."
ZSH_PATH=$(which zsh)
chsh -s "$ZSH_PATH"
echo "默认Shell更改完成。"
echo "安装Oh My Zsh（国内镜像源）..."
sh -c "$(curl -fsSL https://gitee.com/Devkings/oh_my_zsh_install/raw/master/install.sh)"
echo "Oh My Zsh安装完成。"

echo "安装Powerlevel10k主题..."
git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
sed -i '/ZSH_THEME="robbyrussell"/c\ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
echo "Powerlevel10k主题安装完成。"

echo "下载Powerlevel10k配置文件..."
curl -L https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-rainbow.zsh -o ~/.p10k.zsh
echo "Powerlevel10k配置文件下载完成。"

echo "安装Zsh插件..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode
sed -i '/^plugins=(git)$/c\plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)' ~/.zshrc
echo "Zsh插件安装完成。"

echo "应用.zshrc配置更改..."
echo 'export ZSH_AUTOSUGGEST_STRATEGY=(history completion)' >> ~/.zshrc
echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >>  ~/.zshrc
echo 'zstyle ':omz:update' mode auto' >>  ~/.zshrc
echo "脚本执行完成，启动zsh..."
exec zsh
