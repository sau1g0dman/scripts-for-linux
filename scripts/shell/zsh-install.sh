#!/bin/bash

# =============================================================================
# ZSH环境安装配置脚本
# 作者: saul
# 版本: 1.0
# 描述: 自动安装和配置ZSH、Oh My Zsh、插件和主题，支持Ubuntu 20-22 x64/ARM64
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否为远程执行（通过curl | bash）
if [[ -f "$SCRIPT_DIR/../common.sh" ]]; then
    # 本地执行
    source "$SCRIPT_DIR/../common.sh"
else
    # 远程执行，下载common.sh
    COMMON_SH_URL="https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/common.sh"
    if ! source <(curl -fsSL "$COMMON_SH_URL"); then
        echo "错误：无法加载通用函数库"
        exit 1
    fi
fi

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
    log_info "🔍 检查ZSH安装状态..."

    if command -v zsh >/dev/null 2>&1; then
        local zsh_version=$(zsh --version 2>/dev/null || echo "版本信息不可用")
        local zsh_path=$(which zsh 2>/dev/null || echo "路径不可用")
        log_info "✅ ZSH已安装"
        log_info "   版本: $zsh_version"
        log_info "   路径: $zsh_path"
        return 0
    else
        log_info "❌ ZSH未安装"
        return 1
    fi
}

# 安装ZSH
install_zsh() {
    log_info "🚀 开始安装ZSH和相关工具..."

    # 更新包管理器
    log_info "📋 第1步: 更新包管理器"
    if ! update_package_manager; then
        log_error "❌ 包管理器更新失败，无法继续安装"
        return 1
    fi

    # 安装ZSH和相关工具
    log_info "📦 第2步: 安装必需的软件包"
    local packages=(
        "zsh"
        "git"
        "curl"
        "wget"
        "unzip"
        "fontconfig"
    )

    local failed_packages=()
    local installed_count=0
    local total_packages=${#packages[@]}

    for package in "${packages[@]}"; do
        log_info "📦 正在安装 ($((installed_count + 1))/$total_packages): $package"

        if install_package "$package"; then
            ((installed_count++))
            log_info "✅ $package 安装成功 ($installed_count/$total_packages)"
        else
            log_error "❌ $package 安装失败"
            failed_packages+=("$package")
        fi
    done

    # 检查安装结果
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log_info "✅ 所有软件包安装成功 ($installed_count/$total_packages)"

        # 验证ZSH安装
        log_info "🔍 第3步: 验证ZSH安装"
        if verify_command "zsh" "ZSH"; then
            log_info "🎉 ZSH安装和验证完成"
            return 0
        else
            log_error "❌ ZSH安装后验证失败"
            return 1
        fi
    else
        log_error "❌ 以下软件包安装失败: ${failed_packages[*]}"
        log_error "❌ ZSH安装未完成，成功安装: $installed_count/$total_packages"
        return 1
    fi
}

# 安装Oh My Zsh
install_oh_my_zsh() {
    log_info "🎨 开始安装Oh My Zsh..."

    # 检查是否已安装
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "✅ Oh My Zsh已安装，跳过"
        return 0
    fi

    # 下载并安装Oh My Zsh
    log_info "📥 从官方仓库下载Oh My Zsh安装脚本..."
    log_debug "下载URL: $OMZ_INSTALL_URL"

    # 设置环境变量以避免交互式安装
    export RUNZSH=no
    export CHSH=no

    if execute_command "curl -fsSL '$OMZ_INSTALL_URL' | sh" "安装Oh My Zsh"; then
        # 验证安装
        if [ -d "$HOME/.oh-my-zsh" ]; then
            log_info "✅ Oh My Zsh安装成功"
            log_info "   安装路径: $HOME/.oh-my-zsh"
            return 0
        else
            log_error "❌ Oh My Zsh安装后验证失败：目录不存在"
            return 1
        fi
    else
        log_error "❌ Oh My Zsh安装失败"
        return 1
    fi
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

    log_info "🚀 开始ZSH环境安装流程..."
    log_info "📋 安装步骤概览:"
    log_info "   1️⃣  网络连接检查"
    log_info "   2️⃣  ZSH基础安装"
    log_info "   3️⃣  Oh My Zsh安装"
    log_info "   4️⃣  插件安装"
    log_info "   5️⃣  主题安装"
    log_info "   6️⃣  配置文件设置"
    log_info "   7️⃣  默认Shell设置"
    echo

    # 步骤1: 检查网络连接
    log_info "1️⃣  检查网络连接..."
    if ! check_network; then
        log_error "❌ 网络连接失败，无法下载ZSH组件"
        log_error "💡 请检查网络连接后重试"
        exit 1
    fi
    log_info "✅ 网络连接正常"
    echo

    # 步骤2: 检查并安装ZSH
    log_info "2️⃣  ZSH基础环境安装..."
    if ! check_zsh_installed; then
        if ! install_zsh; then
            log_error "❌ ZSH安装失败，无法继续"
            log_error "💡 请检查系统权限和网络连接"
            exit 1
        fi
    else
        log_info "✅ ZSH已安装，跳过基础安装"
    fi
    echo

    # 步骤3: 安装Oh My Zsh
    log_info "3️⃣  Oh My Zsh框架安装..."
    if ! install_oh_my_zsh; then
        log_error "❌ Oh My Zsh安装失败"
        log_error "💡 请检查网络连接和磁盘空间"
        exit 1
    fi
    echo

    # 步骤4: 安装插件
    log_info "4️⃣  ZSH插件安装..."
    if ! install_zsh_plugins; then
        log_error "❌ ZSH插件安装失败"
        log_error "💡 部分插件可能无法正常工作"
        # 插件安装失败不退出，继续后续步骤
    fi
    echo

    # 步骤5: 安装主题
    log_info "5️⃣  Powerlevel10k主题安装..."
    if ! install_powerlevel10k; then
        log_error "❌ Powerlevel10k主题安装失败"
        log_error "💡 将使用默认主题"
        # 主题安装失败不退出，继续后续步骤
    fi
    echo

    # 步骤6: 配置.zshrc
    log_info "6️⃣  配置ZSH配置文件..."
    if ! configure_zshrc; then
        log_error "❌ .zshrc配置失败"
        log_error "💡 可能需要手动配置ZSH"
        # 配置失败不退出，继续后续步骤
    fi
    echo

    # 步骤7: 设置默认Shell
    log_info "7️⃣  设置默认Shell..."
    if ask_confirmation "是否将ZSH设置为默认Shell？" "y"; then
        if set_default_shell; then
            log_info "✅ ZSH已设置为默认Shell"
        else
            log_warn "⚠️  默认Shell设置失败，可以稍后手动设置"
        fi
    else
        log_info "ℹ️  跳过默认Shell设置"
    fi
    echo

    # 最终验证
    log_info "🔍 最终验证安装结果..."
    local verification_passed=true

    # 验证ZSH
    if verify_command "zsh" "ZSH"; then
        log_info "✅ ZSH验证通过"
    else
        log_error "❌ ZSH验证失败"
        verification_passed=false
    fi

    # 验证Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "✅ Oh My Zsh验证通过"
    else
        log_error "❌ Oh My Zsh验证失败"
        verification_passed=false
    fi

    echo
    # 显示完成信息
    if [ "$verification_passed" = true ]; then
        log_info "🎉 ZSH环境安装完成！"
        log_info "📋 安装摘要:"
        log_info "   ✅ ZSH Shell: $(zsh --version 2>/dev/null || echo '已安装')"
        log_info "   ✅ Oh My Zsh: 已安装"
        log_info "   ✅ 插件: ${#ZSH_PLUGINS[@]} 个"
        log_info "   ✅ 主题: Powerlevel10k"
        echo
        log_info "🚀 后续步骤:"
        log_info "   1. 重新登录或运行: exec zsh"
        log_info "   2. 配置主题: p10k configure"
        log_info "   3. 享受强大的ZSH环境！"
    else
        log_warn "⚠️  ZSH环境安装部分完成，但存在一些问题"
        log_warn "💡 请检查上述错误信息并手动修复"
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
