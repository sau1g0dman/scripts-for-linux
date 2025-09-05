#!/bin/bash

# =============================================================================
# ZSH 核心环境安装脚本
# 作者: saul
# 版本: 2.0
# 描述: 安装 ZSH shell、Oh My Zsh 框架和 Powerlevel10k 主题的核心脚本
# 功能: 系统检查、基础软件安装、框架配置、主题安装
# =============================================================================

set -euo pipefail

# =============================================================================
# 脚本初始化和配置
# =============================================================================

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

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
# 全局配置变量
# =============================================================================

# 版本和模式配置
readonly ZSH_CORE_VERSION="2.0"
readonly ZSH_INSTALL_MODE=${ZSH_INSTALL_MODE:-"interactive"}  # interactive/auto/minimal

# 安装路径配置
readonly ZSH_INSTALL_DIR=${ZSH_INSTALL_DIR:-"$HOME"}
readonly OMZ_DIR="$ZSH_INSTALL_DIR/.oh-my-zsh"
readonly ZSH_CUSTOM_DIR="$OMZ_DIR/custom"
readonly ZSH_THEMES_DIR="$ZSH_CUSTOM_DIR/themes"

# 下载源配置
readonly OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
readonly P10K_THEME_REPO="romkatv/powerlevel10k"
readonly P10K_CONFIG_URL="https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-rainbow.zsh"

# 必需软件包列表
readonly REQUIRED_PACKAGES=(
    "zsh:ZSH Shell"
    "git:Git版本控制"
    "curl:网络下载工具"
    "wget:备用下载工具"
)

# 状态管理
declare -g ZSH_INSTALL_STATE=""
declare -g ROLLBACK_ACTIONS=()
declare -g INSTALL_LOG_FILE="/tmp/zsh-core-install-$(date +%Y%m%d-%H%M%S).log"
readonly ZSH_BACKUP_DIR="$HOME/.zsh-backup-$(date +%Y%m%d-%H%M%S)"

# =============================================================================
# 状态管理和回滚功能
# =============================================================================

# 设置安装状态
# 参数: $1 - 状态名称
set_install_state() {
    local state="$1"
    ZSH_INSTALL_STATE="$state"
    log_debug "安装状态更新: $state"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - STATE: $state" >> "$INSTALL_LOG_FILE"
}

# 添加回滚操作
# 参数: $1 - 回滚命令
add_rollback_action() {
    local action="$1"
    ROLLBACK_ACTIONS+=("$action")
    log_debug "添加回滚操作: $action"
}

# 执行回滚操作
execute_rollback() {
    if [ ${#ROLLBACK_ACTIONS[@]} -eq 0 ]; then
        log_info "无需回滚操作"
        return 0
    fi

    log_warn "开始执行回滚操作..."
    local rollback_count=0

    # 逆序执行回滚操作
    for ((i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i--)); do
        local action="${ROLLBACK_ACTIONS[i]}"
        log_info "执行回滚: $action"

        if eval "$action" 2>/dev/null; then
            rollback_count=$((rollback_count + 1))
            log_debug "回滚成功: $action"
        else
            log_warn "回滚失败: $action"
        fi
    done

    log_info "回滚完成，执行了 $rollback_count 个操作"
    ROLLBACK_ACTIONS=()
}

# 创建备份
# 参数: $1 - 要备份的文件或目录路径
create_backup() {
    local file_path="$1"
    local backup_name="$(basename "$file_path")"

    if [ -f "$file_path" ] || [ -d "$file_path" ]; then
        log_info "备份文件: $file_path"
        mkdir -p "$ZSH_BACKUP_DIR"

        if cp -r "$file_path" "$ZSH_BACKUP_DIR/$backup_name" 2>/dev/null; then
            add_rollback_action "restore_backup '$file_path' '$ZSH_BACKUP_DIR/$backup_name'"
            log_debug "备份成功: $file_path -> $ZSH_BACKUP_DIR/$backup_name"
            return 0
        else
            log_warn "备份失败: $file_path"
            return 1
        fi
    fi
}

# 恢复备份
# 参数: $1 - 原始路径, $2 - 备份路径
restore_backup() {
    local original_path="$1"
    local backup_path="$2"

    if [ -f "$backup_path" ] || [ -d "$backup_path" ]; then
        rm -rf "$original_path" 2>/dev/null || true
        cp -r "$backup_path" "$original_path" 2>/dev/null || true
        log_debug "恢复备份: $backup_path -> $original_path"
    fi
}

# =============================================================================
# 系统环境检查功能
# =============================================================================

# 检查系统兼容性
check_system_compatibility() {
    log_info "检查系统兼容性..."
    set_install_state "CHECKING_SYSTEM"

    # 检查操作系统
    if [ ! -f /etc/os-release ]; then
        log_error "无法检测操作系统版本"
        return 1
    fi

    . /etc/os-release
    case "$ID" in
        ubuntu)
            case "$VERSION_ID" in
                "20.04"|"22.04"|"24.04")
                    log_info "支持的Ubuntu版本: $VERSION_ID"
                    ;;
                *)
                    log_warn "Ubuntu版本 $VERSION_ID 可能不完全兼容"
                    ;;
            esac
            ;;
        debian)
            log_info "检测到Debian系统: $VERSION_ID"
            ;;
        *)
            log_error "不支持的操作系统: $ID $VERSION_ID"
            log_error "本脚本仅支持Ubuntu 20-24和Debian 10-12"
            return 1
            ;;
    esac

    # 检查架构
    local arch=$(uname -m)
    case "$arch" in
        x86_64|aarch64|armv7l)
            log_info "支持的系统架构: $arch"
            ;;
        *)
            log_warn "系统架构 $arch 可能不完全兼容"
            ;;
    esac

    # 检查磁盘空间 (至少需要100MB)
    local available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 102400 ]; then
        log_error "磁盘空间不足，需要至少100MB空间"
        return 1
    fi

    log_info "系统兼容性检查通过"
    return 0
}

# 检查网络连接
check_network_connectivity() {
    log_info "检查网络连接..."

    local test_urls=(
        "github.com"
        "raw.githubusercontent.com"
    )

    for url in "${test_urls[@]}"; do
        if curl -fsSL --connect-timeout 5 --max-time 10 "https://$url" >/dev/null 2>&1; then
            log_info "网络连接正常: $url"
            return 0
        fi
    done

    log_error "网络连接失败，无法访问必需的服务"
    return 1
}

# 检查用户权限
check_user_permissions() {
    log_info "检查用户权限..."

    # 检查当前用户类型
    if [ "$(id -u)" -eq 0 ]; then
        log_info "检测到root用户，将以管理员权限安装"
    else
        log_info "检测到普通用户，将以用户权限安装"
    fi

    # 检查HOME目录权限
    if [ ! -w "$HOME" ]; then
        log_error "无法写入HOME目录: $HOME"
        return 1
    fi

    # 检查基本命令权限
    if ! touch "$HOME/.zsh-install-test" 2>/dev/null; then
        log_error "无法在HOME目录创建文件"
        return 1
    else
        rm -f "$HOME/.zsh-install-test" 2>/dev/null || true
    fi

    log_info "用户权限检查通过"
    return 0
}

# =============================================================================
# 错误处理
# =============================================================================

# 错误处理函数
# 参数: $1 - 错误行号, $2 - 错误代码
handle_error() {
    local line_no=$1
    local error_code=$2

    log_error "脚本在第 $line_no 行发生错误 (退出码: $error_code)"
    log_error "当前安装状态: $ZSH_INSTALL_STATE"

    # 执行回滚
    execute_rollback

    log_error "ZSH核心安装失败，已执行回滚操作"
    exit $error_code
}

# 初始化环境
init_environment() {
    # 设置错误处理
    trap 'handle_error $LINENO $?' ERR

    # 创建必要的目录
    mkdir -p "$(dirname "$INSTALL_LOG_FILE")"

    log_debug "ZSH核心安装脚本初始化完成"
    log_debug "安装日志: $INSTALL_LOG_FILE"
    log_debug "备份目录: $ZSH_BACKUP_DIR"
}

# =============================================================================
# 软件包安装功能
# =============================================================================

# 安装必需软件包
install_required_packages() {
    log_info "安装必需软件包..."
    set_install_state "INSTALLING_PACKAGES"

    # 更新包管理器
    log_info "更新软件包列表..."
    if ! update_package_manager; then
        log_error "包管理器更新失败"
        return 1
    fi

    local failed_packages=()
    local success_count=0
    local total_packages=${#REQUIRED_PACKAGES[@]}

    # 安装软件包
    for package_info in "${REQUIRED_PACKAGES[@]}"; do
        IFS=':' read -r package_name package_desc <<< "$package_info"

        log_info "安装: $package_desc ($package_name)"

        # 检查是否已安装
        if dpkg -l | grep -q "^ii  $package_name "; then
            log_info "$package_desc 已安装，跳过"
            success_count=$((success_count + 1))
            continue
        fi

        # 安装软件包
        if sudo apt install -y "$package_name" >/dev/null 2>&1; then
            log_info "$package_desc 安装成功"
            success_count=$((success_count + 1))
            add_rollback_action "sudo apt remove -y '$package_name' >/dev/null 2>&1 || true"
        else
            log_error "$package_desc 安装失败"
            failed_packages+=("$package_name:$package_desc")
        fi
    done

    # 检查安装结果
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_error "以下必需软件包安装失败："
        for failed_pkg in "${failed_packages[@]}"; do
            IFS=':' read -r pkg_name pkg_desc <<< "$failed_pkg"
            log_error "  • $pkg_desc ($pkg_name)"
        done
        return 1
    fi

    log_info "所有必需软件包安装成功 ($success_count/$total_packages)"
    return 0
}

# 验证ZSH安装
verify_zsh_installation() {
    log_info "验证ZSH安装..."

    # 检查ZSH命令是否可用
    if ! command -v zsh >/dev/null 2>&1; then
        log_error "ZSH命令不可用"
        return 1
    fi

    # 获取ZSH信息
    local zsh_version=$(zsh --version 2>/dev/null | head -1 || echo "版本信息不可用")
    local zsh_path=$(which zsh 2>/dev/null || echo "路径不可用")

    # 检查ZSH是否在有效shell列表中
    if ! grep -q "$(which zsh)" /etc/shells 2>/dev/null; then
        log_warn "ZSH未在 /etc/shells 中注册，尝试添加..."
        if echo "$(which zsh)" | sudo tee -a /etc/shells >/dev/null 2>&1; then
            log_info "ZSH已添加到有效shell列表"
            add_rollback_action "sudo sed -i '\|$(which zsh)|d' /etc/shells"
        else
            log_warn "无法添加ZSH到有效shell列表"
        fi
    fi

    # 测试ZSH基本功能
    if echo 'echo "ZSH test successful"' | zsh 2>/dev/null | grep -q "ZSH test successful"; then
        log_info "ZSH功能测试通过"
    else
        log_error "ZSH功能测试失败"
        return 1
    fi

    log_info "ZSH安装验证成功"
    log_info "版本: $zsh_version"
    log_info "路径: $zsh_path"

    return 0
}

# =============================================================================
# Oh My Zsh 框架安装
# =============================================================================

# 检查Oh My Zsh是否已安装
check_omz_installed() {
    if [ -d "$OMZ_DIR" ] && [ -f "$OMZ_DIR/oh-my-zsh.sh" ]; then
        log_info "Oh My Zsh已安装: $OMZ_DIR"
        return 0
    else
        return 1
    fi
}

# 安装Oh My Zsh框架
install_oh_my_zsh() {
    log_info "安装Oh My Zsh框架..."
    set_install_state "INSTALLING_OMZ"

    # 检查是否已安装
    if check_omz_installed; then
        log_info "Oh My Zsh已存在，跳过安装"
        return 0
    fi

    # 备份现有配置
    create_backup "$HOME/.zshrc"
    create_backup "$OMZ_DIR"

    # 设置环境变量避免交互
    export RUNZSH=no
    export CHSH=no
    export KEEP_ZSHRC=yes

    log_info "下载Oh My Zsh安装脚本..."

    # 下载并执行安装脚本
    local temp_script=$(mktemp)
    add_rollback_action "rm -f '$temp_script'"

    if curl -fsSL "$OMZ_INSTALL_URL" -o "$temp_script"; then
        log_info "安装脚本下载成功"

        # 执行安装
        if bash "$temp_script"; then
            add_rollback_action "rm -rf '$OMZ_DIR'"
            log_info "Oh My Zsh安装成功"
        else
            log_error "Oh My Zsh安装失败"
            rm -f "$temp_script"
            return 1
        fi
    else
        log_error "无法下载Oh My Zsh安装脚本"
        rm -f "$temp_script"
        return 1
    fi

    rm -f "$temp_script"

    # 验证安装
    if verify_omz_installation; then
        log_info "Oh My Zsh安装验证成功"
        return 0
    else
        log_error "Oh My Zsh安装验证失败"
        return 1
    fi
}

# 验证Oh My Zsh安装
verify_omz_installation() {
    log_info "验证Oh My Zsh安装..."

    # 检查核心文件
    local required_files=(
        "$OMZ_DIR/oh-my-zsh.sh"
        "$OMZ_DIR/lib"
        "$OMZ_DIR/plugins"
        "$OMZ_DIR/themes"
    )

    for file in "${required_files[@]}"; do
        if [ ! -e "$file" ]; then
            log_error "缺少必需文件: $file"
            return 1
        fi
    done

    # 检查目录结构
    mkdir -p "$ZSH_CUSTOM_DIR" "$ZSH_THEMES_DIR"
    add_rollback_action "rm -rf '$ZSH_CUSTOM_DIR'"

    # 测试Oh My Zsh加载
    if echo 'source ~/.oh-my-zsh/oh-my-zsh.sh && echo "OMZ test successful"' | zsh 2>/dev/null | grep -q "OMZ test successful"; then
        log_info "Oh My Zsh功能测试通过"
        return 0
    else
        log_error "Oh My Zsh功能测试失败"
        return 1
    fi
}

# =============================================================================
# Powerlevel10k 主题安装
# =============================================================================

# 安装Powerlevel10k主题
install_powerlevel10k_theme() {
    log_info "安装Powerlevel10k主题..."
    set_install_state "INSTALLING_THEME"

    local theme_dir="$ZSH_THEMES_DIR/powerlevel10k"

    # 检查主题是否已安装
    if [ -d "$theme_dir" ]; then
        log_info "Powerlevel10k主题已安装，跳过"
        return 0
    fi

    log_info "克隆Powerlevel10k主题仓库..."

    # 克隆主题仓库
    if git clone --depth=1 "https://github.com/$P10K_THEME_REPO.git" "$theme_dir" 2>/dev/null; then
        add_rollback_action "rm -rf '$theme_dir'"
        log_info "Powerlevel10k主题安装成功"

        # 下载rainbow主题配置
        download_p10k_config

        return 0
    else
        log_error "Powerlevel10k主题安装失败"
        return 1
    fi
}

# 下载Powerlevel10k配置文件
download_p10k_config() {
    log_info "下载Powerlevel10k配置文件..."

    local p10k_config_file="$HOME/.p10k.zsh"
    local p10k_backup_dir="$HOME/.oh-my-zsh/themes"

    # 创建备份目录
    mkdir -p "$p10k_backup_dir"

    # 备份现有配置（如果存在）
    if [ -f "$p10k_config_file" ]; then
        log_info "备份现有P10k配置..."
        cp "$p10k_config_file" "$p10k_config_file.backup-$(date +%Y%m%d-%H%M%S)"
    fi

    # 尝试下载rainbow配置
    log_info "下载Rainbow主题配置..."
    local temp_config=$(mktemp)

    if curl -fsSL --connect-timeout 10 --max-time 30 "$P10K_CONFIG_URL" -o "$temp_config" 2>/dev/null; then
        # 验证下载的文件
        if [ -s "$temp_config" ] && grep -q "powerlevel10k" "$temp_config" 2>/dev/null; then
            # 部署配置文件
            mv "$temp_config" "$p10k_config_file"
            chmod 644 "$p10k_config_file"

            # 保存备份到themes目录
            cp "$p10k_config_file" "$p10k_backup_dir/p10k-rainbow.zsh"

            log_info "Rainbow主题配置部署成功"
            add_rollback_action "rm -f '$p10k_config_file' '$p10k_backup_dir/p10k-rainbow.zsh'"
            return 0
        else
            log_error "下载的配置文件无效"
            rm -f "$temp_config"
            return 1
        fi
    else
        log_warn "无法下载Rainbow主题配置，将使用默认配置"
        rm -f "$temp_config"
        return 1
    fi
}

# 验证主题安装
verify_theme_installation() {
    log_info "验证主题安装..."

    local theme_dir="$ZSH_THEMES_DIR/powerlevel10k"
    local theme_file="$theme_dir/powerlevel10k.zsh-theme"

    if [ -f "$theme_file" ]; then
        log_info "主题文件验证通过: $theme_file"
        return 0
    else
        log_error "主题文件验证失败: $theme_file"
        return 1
    fi
}

# =============================================================================
# 基础配置文件生成
# =============================================================================

# 生成基础.zshrc配置文件
generate_basic_zshrc() {
    log_info "生成基础.zshrc配置文件..."
    set_install_state "CONFIGURING_ZSHRC"

    local zshrc_file="$HOME/.zshrc"

    # 备份现有配置
    create_backup "$zshrc_file"

    log_info "生成基础ZSH配置..."

    cat << 'EOF' > "$zshrc_file"
# =============================================================================
# ZSH核心配置文件 - 由zsh-core-install.sh自动生成
# =============================================================================

# Powerlevel10k即时提示（必须在最前面）
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh配置
export ZSH="$HOME/.oh-my-zsh"

# 主题配置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 基础插件配置（核心插件）
plugins=(git)

# 加载Oh My Zsh
source $ZSH/oh-my-zsh.sh

# =============================================================================
# 基础用户配置
# =============================================================================

# 历史配置
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# 自动补全配置
autoload -U compinit
compinit

# 基础别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# =============================================================================
# 环境变量
# =============================================================================

# 编辑器
export EDITOR='nano'
command -v vim >/dev/null && export EDITOR='vim'
command -v nvim >/dev/null && export EDITOR='nvim'

# 语言环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# =============================================================================
# Powerlevel10k 配置
# =============================================================================

# 加载Powerlevel10k配置（如果存在）
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

EOF

    add_rollback_action "restore_backup '$zshrc_file' '$ZSH_BACKUP_DIR/.zshrc'"
    log_info "基础.zshrc配置文件生成完成"
    return 0
}

# 验证配置文件
verify_zshrc_config() {
    log_info "验证ZSH配置文件..."

    local zshrc_file="$HOME/.zshrc"

    # 检查文件是否存在
    if [ ! -f "$zshrc_file" ]; then
        log_error ".zshrc文件不存在"
        return 1
    fi

    # 检查配置语法
    if zsh -n "$zshrc_file" 2>/dev/null; then
        log_info ".zshrc语法检查通过"
    else
        log_error ".zshrc语法检查失败"
        return 1
    fi

    # 测试配置加载
    if echo 'source ~/.zshrc && echo "Config test successful"' | zsh 2>/dev/null | grep -q "Config test successful"; then
        log_info ".zshrc配置加载测试通过"
        return 0
    else
        log_error ".zshrc配置加载测试失败"
        return 1
    fi
}

# =============================================================================
# 主安装流程
# =============================================================================

# 显示脚本头部信息
show_header() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}ZSH核心环境安装脚本${RESET}"
    echo -e "${BLUE}版本: $ZSH_CORE_VERSION${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将安装ZSH核心环境：${RESET}"
    echo -e "${CYAN}• ZSH Shell${RESET}"
    echo -e "${CYAN}• Oh My Zsh 框架${RESET}"
    echo -e "${CYAN}• Powerlevel10k 主题${RESET}"
    echo -e "${CYAN}• 基础配置文件${RESET}"
    echo
    echo -e "${YELLOW}注意：插件安装请使用 zsh-plugins-install.sh 脚本${RESET}"
    echo
}

# 显示安装总结
show_installation_summary() {
    local status="$1"

    echo
    echo -e "${CYAN}================================================================${RESET}"

    case "$status" in
        "success")
            echo -e "${GREEN}🎉 ZSH核心环境安装成功！${RESET}"
            echo
            echo -e "${CYAN}已安装的组件：${RESET}"
            echo -e "  ✅ ZSH Shell: $(zsh --version 2>/dev/null | head -1 || echo '已安装')"
            echo -e "  ✅ Oh My Zsh: $([ -d "$OMZ_DIR" ] && echo '已安装' || echo '未安装')"
            echo -e "  ✅ Powerlevel10k: $([ -d "$ZSH_THEMES_DIR/powerlevel10k" ] && echo '已安装' || echo '未安装')"
            echo -e "  ✅ 基础配置: $([ -f "$HOME/.zshrc" ] && echo '已生成' || echo '未生成')"
            echo
            echo -e "${YELLOW}下一步操作：${RESET}"
            echo -e "  1. 运行 ${CYAN}zsh-plugins-install.sh${RESET} 安装插件"
            echo -e "  2. 或者运行 ${CYAN}chsh -s \$(which zsh)${RESET} 设置为默认shell"
            echo -e "  3. 重新登录或运行 ${CYAN}zsh${RESET} 开始使用"
            ;;
        "failed")
            echo -e "${RED}❌ ZSH核心环境安装失败${RESET}"
            echo
            echo -e "${YELLOW}故障排除建议：${RESET}"
            echo -e "  • 检查网络连接是否正常"
            echo -e "  • 确保有足够的磁盘空间"
            echo -e "  • 查看安装日志: ${CYAN}$INSTALL_LOG_FILE${RESET}"
            echo -e "  • 检查系统兼容性"
            ;;
    esac

    echo -e "${CYAN}================================================================${RESET}"
    echo
}

# 主安装函数
main() {
    # 显示头部信息
    show_header

    # 初始化环境
    init_environment

    # 询问用户确认
    if [ "$ZSH_INSTALL_MODE" = "interactive" ]; then
        echo -e "是否继续安装ZSH核心环境？ [Y/n]: " | tr -d '\n'
        read -r choice
        choice=${choice:-y}
        case $choice in
            [Yy]|[Yy][Ee][Ss])
                log_info "用户确认继续安装"
                ;;
            *)
                log_info "用户取消安装"
                exit 0
                ;;
        esac
        echo
    fi

    log_info "开始ZSH核心环境安装..."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始安装" >> "$INSTALL_LOG_FILE"

    # 执行安装步骤
    local install_success=true

    # 步骤1: 系统检查
    log_info "步骤1: 系统环境检查..."
    if ! check_system_compatibility || ! check_network_connectivity || ! check_user_permissions; then
        log_error "系统环境检查失败"
        install_success=false
    fi

    # 步骤2: 安装必需软件包
    if [ "$install_success" = true ]; then
        log_info "步骤2: 安装必需软件包..."
        if ! install_required_packages || ! verify_zsh_installation; then
            log_error "软件包安装失败"
            install_success=false
        fi
    fi

    # 步骤3: 安装Oh My Zsh
    if [ "$install_success" = true ]; then
        log_info "步骤3: 安装Oh My Zsh框架..."
        if ! install_oh_my_zsh; then
            log_error "Oh My Zsh安装失败"
            install_success=false
        fi
    fi

    # 步骤4: 安装主题
    if [ "$install_success" = true ]; then
        log_info "步骤4: 安装Powerlevel10k主题..."
        if ! install_powerlevel10k_theme || ! verify_theme_installation; then
            log_error "主题安装失败"
            install_success=false
        fi
    fi

    # 步骤5: 生成配置文件
    if [ "$install_success" = true ]; then
        log_info "步骤5: 生成基础配置文件..."
        if ! generate_basic_zshrc || ! verify_zshrc_config; then
            log_error "配置文件生成失败"
            install_success=false
        fi
    fi

    # 显示安装结果
    if [ "$install_success" = true ]; then
        set_install_state "COMPLETED"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 安装成功" >> "$INSTALL_LOG_FILE"
        show_installation_summary "success"

        # 清理临时文件
        rm -f "$INSTALL_LOG_FILE" 2>/dev/null || true

        return 0
    else
        set_install_state "FAILED"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 安装失败" >> "$INSTALL_LOG_FILE"
        show_installation_summary "failed"

        # 执行回滚
        execute_rollback

        return 1
    fi
}

# =============================================================================
# 脚本入口点
# =============================================================================

# 检查是否被其他脚本调用
is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
