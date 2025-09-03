#!/bin/bash

# =============================================================================
# ZSH环境安装配置脚本
# 作者: saul
# 版本: 1.0
# 描述: 自动安装和配置ZSH、Oh My Zsh、插件和主题，支持Ubuntu 20-22 x64/ARM64
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# =============================================================================
# 配置变量
# =============================================================================

# 安装模式
AUTO_INSTALL=${AUTO_INSTALL:-false}

# Oh My Zsh配置
readonly OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# 插件配置
readonly ZSH_PLUGINS=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "zsh-completions"
)

# =============================================================================
# ZSH安装函数
# =============================================================================

# 检查ZSH是否已安装
check_zsh_installed() {
    if command -v zsh >/dev/null 2>&1; then
        log_info "ZSH已安装: $(zsh --version)"
        return 0
    else
        log_info "ZSH未安装"
        return 1
    fi
}

# 安装ZSH
install_zsh() {
    log_info "开始安装ZSH..."
    
    # 更新包管理器
    update_package_manager
    
    # 安装ZSH和相关工具
    local packages=(
        "zsh"
        "git"
        "curl"
        "wget"
        "unzip"
        "fontconfig"
    )
    
    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            log_error "安装 $package 失败"
            return 1
        fi
    done
    
    log_info "ZSH安装完成"
    return 0
}

# 安装Oh My Zsh
install_oh_my_zsh() {
    log_info "开始安装Oh My Zsh..."
    
    # 检查是否已安装
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Oh My Zsh已安装"
        return 0
    fi
    
    # 下载并安装Oh My Zsh
    if curl -fsSL "$OMZ_INSTALL_URL" | sh; then
        log_info "Oh My Zsh安装完成"
    else
        log_error "Oh My Zsh安装失败"
        return 1
    fi
    
    return 0
}

# 安装ZSH插件
install_zsh_plugins() {
    log_info "开始安装ZSH插件..."
    
    local plugin_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    # 创建插件目录
    mkdir -p "$plugin_dir"
    
    # 安装zsh-autosuggestions
    if [ ! -d "$plugin_dir/zsh-autosuggestions" ]; then
        log_info "安装zsh-autosuggestions插件..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions"
    fi
    
    # 安装zsh-syntax-highlighting
    if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
        log_info "安装zsh-syntax-highlighting插件..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/zsh-syntax-highlighting"
    fi
    
    # 安装zsh-completions
    if [ ! -d "$plugin_dir/zsh-completions" ]; then
        log_info "安装zsh-completions插件..."
        git clone https://github.com/zsh-users/zsh-completions "$plugin_dir/zsh-completions"
    fi
    
    log_info "ZSH插件安装完成"
    return 0
}

# 安装Powerlevel10k主题
install_powerlevel10k() {
    log_info "开始安装Powerlevel10k主题..."
    
    local theme_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    
    if [ ! -d "$theme_dir" ]; then
        log_info "下载Powerlevel10k主题..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
    else
        log_info "Powerlevel10k主题已安装"
    fi
    
    return 0
}

# 配置.zshrc文件
configure_zshrc() {
    log_info "配置.zshrc文件..."
    
    local zshrc_file="$HOME/.zshrc"
    
    # 备份原始.zshrc
    if [ -f "$zshrc_file" ]; then
        cp "$zshrc_file" "$zshrc_file.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 生成新的.zshrc配置
    cat << 'EOF' > "$zshrc_file"
# ZSH配置文件 - 自动生成

# Oh My Zsh配置
export ZSH="$HOME/.oh-my-zsh"

# 主题设置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件配置
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    sudo
    extract
    z
)

# 加载Oh My Zsh
source $ZSH/oh-my-zsh.sh

# 用户配置
export LANG=en_US.UTF-8
export EDITOR='vim'

# 别名设置
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# 历史记录配置
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# 自动补全配置
autoload -U compinit
compinit

# Powerlevel10k即时提示
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 加载Powerlevel10k配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

    log_info ".zshrc配置完成"
    return 0
}

# 设置ZSH为默认Shell
set_default_shell() {
    local zsh_path
    zsh_path=$(which zsh)
    
    if [ -z "$zsh_path" ]; then
        log_error "未找到ZSH可执行文件"
        return 1
    fi
    
    log_info "设置ZSH为默认Shell..."
    
    # 检查当前Shell
    if [ "$SHELL" = "$zsh_path" ]; then
        log_info "ZSH已经是默认Shell"
        return 0
    fi
    
    # 确保ZSH在/etc/shells中
    if ! grep -q "$zsh_path" /etc/shells; then
        echo "$zsh_path" | $SUDO tee -a /etc/shells
    fi
    
    # 更改默认Shell
    if chsh -s "$zsh_path"; then
        log_info "默认Shell已设置为ZSH"
        log_info "请重新登录或运行 'exec zsh' 来使用ZSH"
    else
        log_error "设置默认Shell失败"
        return 1
    fi
    
    return 0
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    # 初始化环境
    init_environment
    
    # 显示脚本信息
    show_header "ZSH环境安装配置脚本" "1.0" "自动安装和配置ZSH、Oh My Zsh、插件和主题"
    
    # 检查网络连接
    if ! check_network; then
        log_error "网络连接失败，无法下载ZSH组件"
        exit 1
    fi
    
    # 同步系统时间（调用独立的时间同步脚本）
    if [ -f "$SCRIPT_DIR/../system/time-sync.sh" ]; then
        log_info "同步系统时间..."
        bash "$SCRIPT_DIR/../system/time-sync.sh"
    fi
    
    # 检查并安装ZSH
    if ! check_zsh_installed; then
        if ! install_zsh; then
            log_error "ZSH安装失败"
            exit 1
        fi
    fi
    
    # 安装Oh My Zsh
    if ! install_oh_my_zsh; then
        log_error "Oh My Zsh安装失败"
        exit 1
    fi
    
    # 安装插件
    if ! install_zsh_plugins; then
        log_error "ZSH插件安装失败"
        exit 1
    fi
    
    # 安装主题
    if ! install_powerlevel10k; then
        log_error "Powerlevel10k主题安装失败"
        exit 1
    fi
    
    # 配置.zshrc
    if ! configure_zshrc; then
        log_error ".zshrc配置失败"
        exit 1
    fi
    
    # 设置默认Shell
    if ask_confirmation "是否将ZSH设置为默认Shell？" "y"; then
        set_default_shell
    fi
    
    # 显示完成信息
    show_footer
    
    log_info "ZSH环境配置完成！"
    log_info "建议运行 'p10k configure' 来配置Powerlevel10k主题"
    log_info "或者重新登录以使用新的ZSH环境"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
