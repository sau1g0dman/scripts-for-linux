#!/bin/bash

# =============================================================================
# Ubuntu服务器环境卸载脚本
# 作者: saul
# 版本: 1.0
# 描述: 卸载通过scripts-for-linux安装的组件，恢复系统默认配置
# =============================================================================

set -euo pipefail

# =============================================================================
# 颜色定义
# =============================================================================
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly CYAN='\033[36m'
readonly RESET='\033[0m'

# =============================================================================
# 日志函数
# =============================================================================
log_info() {
    echo -e "${GREEN}[INFO]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# =============================================================================
# 工具函数
# =============================================================================

# 显示脚本头部信息
show_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}🗑️ Ubuntu服务器环境卸载脚本${RESET}"
    echo -e "${BLUE}版本: 1.0${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${YELLOW}⚠️ 警告：此脚本将卸载通过scripts-for-linux安装的组件${RESET}"
    echo -e "${YELLOW}请确保您已经备份了重要的配置文件${RESET}"
    echo
}

# 询问用户确认
ask_confirmation() {
    local message=$1
    local default=${2:-"n"}
    
    while true; do
        if [ "$default" = "y" ]; then
            read -p "$message [Y/n]: " choice
            choice=${choice:-y}
        else
            read -p "$message [y/N]: " choice
            choice=${choice:-n}
        fi
        
        case $choice in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo "请输入 y 或 n"
                ;;
        esac
    done
}

# =============================================================================
# 卸载函数
# =============================================================================

# 卸载ZSH环境
uninstall_zsh() {
    log_info "开始卸载ZSH环境..."
    
    # 恢复默认Shell
    if [ "$SHELL" != "/bin/bash" ]; then
        log_info "恢复默认Shell为bash..."
        chsh -s /bin/bash
    fi
    
    # 备份并删除ZSH配置
    if [ -f ~/.zshrc ]; then
        log_info "备份.zshrc文件..."
        mv ~/.zshrc ~/.zshrc.uninstall.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 删除Oh My Zsh
    if [ -d ~/.oh-my-zsh ]; then
        log_info "删除Oh My Zsh..."
        rm -rf ~/.oh-my-zsh
    fi
    
    # 删除Powerlevel10k配置
    if [ -f ~/.p10k.zsh ]; then
        log_info "备份Powerlevel10k配置..."
        mv ~/.p10k.zsh ~/.p10k.zsh.uninstall.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 可选：卸载ZSH包
    if ask_confirmation "是否完全卸载ZSH软件包？" "n"; then
        sudo apt remove --purge -y zsh
        sudo apt autoremove -y
    fi
    
    log_info "ZSH环境卸载完成"
}

# 卸载Neovim环境
uninstall_neovim() {
    log_info "开始卸载Neovim环境..."
    
    # 备份Neovim配置
    if [ -d ~/.config/nvim ]; then
        log_info "备份Neovim配置..."
        mv ~/.config/nvim ~/.config/nvim.uninstall.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 删除Neovim数据
    if [ -d ~/.local/share/nvim ]; then
        log_info "删除Neovim数据..."
        rm -rf ~/.local/share/nvim
    fi
    
    # 删除Neovim缓存
    if [ -d ~/.cache/nvim ]; then
        log_info "删除Neovim缓存..."
        rm -rf ~/.cache/nvim
    fi
    
    # 可选：卸载Neovim和相关工具
    if ask_confirmation "是否卸载Neovim和相关工具？" "n"; then
        sudo apt remove --purge -y neovim ripgrep fd-find
        
        # 卸载LazyGit
        if command -v lazygit >/dev/null 2>&1; then
            sudo rm -f /usr/local/bin/lazygit
        fi
    fi
    
    log_info "Neovim环境卸载完成"
}

# 恢复SSH配置
restore_ssh_config() {
    log_info "开始恢复SSH配置..."
    
    # 查找SSH配置备份
    local backup_files=($(ls /etc/ssh/sshd_config.backup.* 2>/dev/null | sort -r))
    
    if [ ${#backup_files[@]} -gt 0 ]; then
        local latest_backup="${backup_files[0]}"
        log_info "找到SSH配置备份: $latest_backup"
        
        if ask_confirmation "是否恢复SSH配置？" "y"; then
            sudo cp "$latest_backup" /etc/ssh/sshd_config
            sudo systemctl restart ssh
            log_info "SSH配置已恢复"
        fi
    else
        log_warn "未找到SSH配置备份文件"
    fi
}

# 恢复软件源配置
restore_apt_sources() {
    log_info "开始恢复软件源配置..."
    
    # 查找sources.list备份
    local backup_files=($(ls /etc/apt/sources.list.backup.* 2>/dev/null | sort -r))
    
    if [ ${#backup_files[@]} -gt 0 ]; then
        local latest_backup="${backup_files[0]}"
        log_info "找到软件源备份: $latest_backup"
        
        if ask_confirmation "是否恢复原始软件源配置？" "y"; then
            sudo cp "$latest_backup" /etc/apt/sources.list
            sudo apt update
            log_info "软件源配置已恢复"
        fi
    else
        log_warn "未找到软件源备份文件"
    fi
}

# 卸载Docker环境
uninstall_docker() {
    log_info "开始卸载Docker环境..."
    
    if ask_confirmation "是否卸载Docker？这将删除所有容器和镜像！" "n"; then
        # 停止所有容器
        if command -v docker >/dev/null 2>&1; then
            log_info "停止所有Docker容器..."
            docker stop $(docker ps -aq) 2>/dev/null || true
            docker rm $(docker ps -aq) 2>/dev/null || true
            docker rmi $(docker images -q) 2>/dev/null || true
        fi
        
        # 卸载Docker
        sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo apt autoremove -y
        
        # 删除Docker数据
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo rm -rf /etc/docker
        
        # 删除Docker组
        sudo groupdel docker 2>/dev/null || true
        
        # 卸载LazyDocker
        if command -v lazydocker >/dev/null 2>&1; then
            sudo rm -f /usr/local/bin/lazydocker
        fi
        
        log_info "Docker环境卸载完成"
    fi
}

# 清理用户配置
cleanup_user_configs() {
    log_info "清理用户配置文件..."
    
    # 清理Git配置（可选）
    if [ -f ~/.gitconfig ] && ask_confirmation "是否清理Git配置？" "n"; then
        mv ~/.gitconfig ~/.gitconfig.uninstall.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 清理SSH配置（可选）
    if [ -d ~/.ssh ] && ask_confirmation "是否备份SSH配置？" "y"; then
        cp -r ~/.ssh ~/.ssh.uninstall.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 清理字体
    if [ -d ~/.local/share/fonts ] && ask_confirmation "是否清理安装的字体？" "n"; then
        rm -rf ~/.local/share/fonts/*Nerd*
        fc-cache -fv
    fi
}

# =============================================================================
# 主卸载流程
# =============================================================================

# 显示卸载菜单
show_uninstall_menu() {
    echo
    echo -e "${BLUE}请选择要卸载的组件：${RESET}"
    echo
    echo "1. 🐚 ZSH环境（ZSH、Oh My Zsh、主题插件）"
    echo "2. 📝 Neovim环境（Neovim、LazyVim、插件）"
    echo "3. 🔐 恢复SSH配置"
    echo "4. 📦 恢复软件源配置"
    echo "5. 🐳 卸载Docker环境"
    echo "6. 🧹 清理用户配置"
    echo "7. 🗑️ 完全卸载（所有组件）"
    echo "0. 退出"
    echo
}

# 完全卸载
complete_uninstall() {
    log_warn "开始完全卸载所有组件..."
    
    uninstall_zsh
    uninstall_neovim
    restore_ssh_config
    restore_apt_sources
    uninstall_docker
    cleanup_user_configs
    
    log_info "完全卸载完成"
}

# 主卸载循环
main_uninstall() {
    while true; do
        show_uninstall_menu
        read -p "请选择 [0-7]: " choice
        
        case $choice in
            1)
                uninstall_zsh
                ;;
            2)
                uninstall_neovim
                ;;
            3)
                restore_ssh_config
                ;;
            4)
                restore_apt_sources
                ;;
            5)
                uninstall_docker
                ;;
            6)
                cleanup_user_configs
                ;;
            7)
                complete_uninstall
                ;;
            0)
                log_info "退出卸载程序"
                exit 0
                ;;
            *)
                log_warn "无效选择，请重新输入"
                continue
                ;;
        esac
        
        echo
        if ask_confirmation "是否继续卸载其他组件？" "n"; then
            continue
        else
            break
        fi
    done
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    # 显示头部信息
    show_header
    
    # 最终确认
    if ! ask_confirmation "确定要继续卸载吗？" "n"; then
        log_info "用户取消卸载"
        exit 0
    fi
    
    # 开始卸载
    main_uninstall
    
    # 显示完成信息
    echo
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${GREEN}✅ 卸载完成！${RESET}"
    echo -e "${GREEN}================================================================${RESET}"
    echo
    echo -e "${CYAN}建议重新登录以使所有更改生效${RESET}"
    echo
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
