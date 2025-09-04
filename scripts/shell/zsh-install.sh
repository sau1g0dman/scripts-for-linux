#!/bin/bash

# =============================================================================
# ZSH环境安装配置脚本 - 模块化重构版本
# 作者: saul
# 版本: 2.0
# 描述: 模块化的ZSH环境安装脚本，支持自定义配置、完整验证和错误回滚
# 支持系统: Ubuntu 20-22 LTS (x64/ARM64)
# =============================================================================

set -euo pipefail  # 严格错误处理

# 导入通用函数库
# 安全获取脚本目录，兼容远程执行环境
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
# 配置管理模块
# =============================================================================

# 全局状态变量
declare -g ZSH_INSTALL_STATE=""
declare -g ROLLBACK_ACTIONS=()
declare -g INSTALL_LOG_FILE="/tmp/zsh-install-$(date +%Y%m%d-%H%M%S).log"

# 基础配置
readonly ZSH_CONFIG_VERSION="2.0"
readonly ZSH_INSTALL_MODE=${ZSH_INSTALL_MODE:-"interactive"}  # interactive/auto/minimal
readonly ZSH_BACKUP_DIR="$HOME/.zsh-backup-$(date +%Y%m%d-%H%M%S)"

# 安装路径配置
readonly ZSH_INSTALL_DIR=${ZSH_INSTALL_DIR:-"$HOME"}
readonly OMZ_DIR="$ZSH_INSTALL_DIR/.oh-my-zsh"
readonly ZSH_CUSTOM_DIR="$OMZ_DIR/custom"
readonly ZSH_PLUGINS_DIR="$ZSH_CUSTOM_DIR/plugins"
readonly ZSH_THEMES_DIR="$ZSH_CUSTOM_DIR/themes"

# 下载源配置
readonly OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com"

# 插件配置 - 支持用户自定义
ZSH_PLUGINS_LIST=${ZSH_PLUGINS_LIST:-"zsh-autosuggestions,zsh-syntax-highlighting,zsh-completions,zsh-history-substring-search"}
IFS=',' read -ra ZSH_PLUGINS <<< "$ZSH_PLUGINS_LIST"

# 主题配置
readonly ZSH_THEME=${ZSH_THEME:-"powerlevel10k"}
readonly ZSH_THEME_REPO="romkatv/powerlevel10k"

# 必需软件包列表
readonly REQUIRED_PACKAGES=(
    "zsh:ZSH Shell"
    "git:Git版本控制"
    "curl:网络下载工具"
    "wget:备用下载工具"
    "unzip:解压工具"
)

# 可选软件包列表
readonly OPTIONAL_PACKAGES=(
    "fd-find:现代化find替代品"
    "bat:现代化cat替代品"
    "exa:现代化ls替代品"
    "fzf:模糊搜索工具"
)

# =============================================================================
# 状态管理和回滚模块
# =============================================================================

# 设置安装状态
set_install_state() {
    local state="$1"
    ZSH_INSTALL_STATE="$state"
    log_debug "安装状态更新: $state"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - STATE: $state" >> "$INSTALL_LOG_FILE"
}

# 添加回滚操作
add_rollback_action() {
    local action="$1"
    ROLLBACK_ACTIONS+=("$action")
    log_debug "添加回滚操作: $action"
}

# 执行回滚
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
# 环境检查模块
# =============================================================================

# 检查系统兼容性
check_system_compatibility() {
    log_info "检查系统兼容性..."
    set_install_state "CHECKING_SYSTEM"

    # 检查操作系统
    if [ ! -f /etc/os-release ]; then
        log_error "[ERROR] 无法检测操作系统版本"
        return 1
    fi

    . /etc/os-release
    case "$ID" in
        ubuntu)
            case "$VERSION_ID" in
                "20.04"|"22.04"|"24.04")
                    log_info "[SUCCESS] 支持的Ubuntu版本: $VERSION_ID"
                    ;;
                *)
                    log_warn "[WARN] Ubuntu版本 $VERSION_ID 可能不完全兼容"
                    ;;
            esac
            ;;
        debian)
            log_info "[SUCCESS] 检测到Debian系统: $VERSION_ID"
            ;;
        *)
            log_error "[ERROR] 不支持的操作系统: $ID $VERSION_ID"
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
            log_warn " 系统架构 $arch 可能不完全兼容"
            ;;
    esac

    # 检查磁盘空间 (至少需要100MB)
    local available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 102400 ]; then
        log_error "[ERROR] 磁盘空间不足，需要至少100MB空间"
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

    log_error "[ERROR] 网络连接失败，无法访问必需的服务"
    return 1
}

# 检查用户权限
check_user_permissions() {
    log_info "检查用户权限..."

    # 检查当前用户类型（仅用于信息记录）
    if [ "$(id -u)" -eq 0 ]; then
        log_info "[INFO] 检测到root用户，将以管理员权限安装"
        log_debug "用户ID: $(id -u), 用户名: $(whoami)"
    else
        log_info "[INFO] 检测到普通用户，将以用户权限安装"
        log_debug "用户ID: $(id -u), 用户名: $(whoami)"
    fi

    # 检查HOME目录权限
    if [ ! -w "$HOME" ]; then
        log_error "[ERROR] 无法写入HOME目录: $HOME"
        log_error "请确保当前用户对HOME目录有写入权限"
        return 1
    fi

    # 检查基本命令权限
    if ! touch "$HOME/.zsh-install-test" 2>/dev/null; then
        log_error "[ERROR] 无法在HOME目录创建文件"
        log_error "请检查文件系统权限和磁盘空间"
        return 1
    else
        rm -f "$HOME/.zsh-install-test" 2>/dev/null || true
        log_debug "HOME目录写入权限验证通过"
    fi

    log_info "用户权限检查通过"
    return 0
}

# =============================================================================
#  基础安装模块
# =============================================================================

# 安装必需软件包
install_required_packages() {
    log_info "安装必需软件包..."
    set_install_state "INSTALLING_PACKAGES"

    # 更新包管理器
    if ! update_package_manager; then
        log_error "[ERROR] 包管理器更新失败"
        return 1
    fi

    local failed_packages=()
    local installed_count=0
    local total_packages=${#REQUIRED_PACKAGES[@]}

    for package_info in "${REQUIRED_PACKAGES[@]}"; do
        IFS=':' read -r package_name package_desc <<< "$package_info"

        log_info "安装 ($((installed_count + 1))/$total_packages): $package_desc"

        if install_package "$package_name"; then
            installed_count=$((installed_count + 1))
            log_info "$package_desc 安装成功"
            add_rollback_action "remove_package '$package_name'"
        else
            log_error "[ERROR] $package_desc 安装失败"
            failed_packages+=("$package_name")
        fi
    done

    # 检查关键包安装结果
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_error "[ERROR] 以下必需软件包安装失败: ${failed_packages[*]}"
        return 1
    fi

    log_info "所有必需软件包安装成功 ($installed_count/$total_packages)"
    return 0
}

# 安装可选软件包
install_optional_packages() {
    if [ "$ZSH_INSTALL_MODE" = "minimal" ]; then
        log_info "跳过可选软件包安装（最小化模式）"
        return 0
    fi

    log_info "安装可选软件包（增强功能）..."

    local installed_count=0
    local total_packages=${#OPTIONAL_PACKAGES[@]}

    for package_info in "${OPTIONAL_PACKAGES[@]}"; do
        IFS=':' read -r package_name package_desc <<< "$package_info"

        log_info "安装可选包 ($((installed_count + 1))/$total_packages): $package_desc"

        if install_package "$package_name"; then
            installed_count=$((installed_count + 1))
            log_info "$package_desc 安装成功"
            add_rollback_action "remove_package '$package_name'"
        else
            log_warn "$package_desc 安装失败（可选包，不影响主要功能）"
        fi
    done

    log_info "可选软件包安装完成 ($installed_count/$total_packages)"
    return 0
}

# 验证ZSH安装
verify_zsh_installation() {
    log_info "验证ZSH安装..."

    # 检查ZSH命令是否可用
    if ! command -v zsh >/dev/null 2>&1; then
        log_error "[ERROR] ZSH命令不可用"
        return 1
    fi

    # 获取ZSH信息
    local zsh_version=$(zsh --version 2>/dev/null | head -1 || echo "版本信息不可用")
    local zsh_path=$(which zsh 2>/dev/null || echo "路径不可用")

    # 检查ZSH是否在有效shell列表中
    if ! grep -q "$(which zsh)" /etc/shells 2>/dev/null; then
        log_warn " ZSH未在 /etc/shells 中注册，尝试添加..."
        if echo "$(which zsh)" | sudo tee -a /etc/shells >/dev/null 2>&1; then
            log_info "ZSH已添加到有效shell列表"
            add_rollback_action "remove_from_shells '$(which zsh)'"
        else
            log_warn " 无法添加ZSH到有效shell列表"
        fi
    fi

    # 测试ZSH基本功能
    if echo 'echo "ZSH test successful"' | zsh 2>/dev/null | grep -q "ZSH test successful"; then
        log_info "ZSH功能测试通过"
    else
        log_error "[ERROR] ZSH功能测试失败"
        return 1
    fi

    log_info "ZSH安装验证成功"
    log_info "版本: $zsh_version"
    log_info "路径: $zsh_path"

    return 0
}

# 移除软件包（回滚用）
remove_package() {
    local package="$1"
    log_debug "回滚：移除软件包 $package"

    if command -v apt >/dev/null 2>&1; then
        sudo apt remove -y "$package" >/dev/null 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        sudo yum remove -y "$package" >/dev/null 2>&1 || true
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf remove -y "$package" >/dev/null 2>&1 || true
    fi
}

# 从shells文件移除（回滚用）
remove_from_shells() {
    local shell_path="$1"
    log_debug "回滚：从/etc/shells移除 $shell_path"
    sudo sed -i "\|$shell_path|d" /etc/shells 2>/dev/null || true
}

# =============================================================================
#  Oh My Zsh框架模块
# =============================================================================

# 检查Oh My Zsh是否已安装
check_omz_installed() {
    if [ -d "$OMZ_DIR" ] && [ -f "$OMZ_DIR/oh-my-zsh.sh" ]; then
        log_info "Oh My Zsh已安装: $OMZ_DIR"
        return 0
    else
        log_info "[ERROR] Oh My Zsh未安装"
        return 1
    fi
}

# 安装Oh My Zsh
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
    log_debug "下载URL: $OMZ_INSTALL_URL"

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
            log_error "[ERROR] Oh My Zsh安装失败"
            rm -f "$temp_script"
            return 1
        fi
    else
        log_error "[ERROR] 无法下载Oh My Zsh安装脚本"
        rm -f "$temp_script"
        return 1
    fi

    rm -f "$temp_script"

    # 验证安装
    if verify_omz_installation; then
        log_info "Oh My Zsh安装验证成功"
        return 0
    else
        log_error "[ERROR] Oh My Zsh安装验证失败"
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
            log_error "[ERROR] 缺少必需文件: $file"
            return 1
        fi
    done

    # 检查目录结构
    mkdir -p "$ZSH_CUSTOM_DIR" "$ZSH_PLUGINS_DIR" "$ZSH_THEMES_DIR"
    add_rollback_action "rm -rf '$ZSH_CUSTOM_DIR'"

    # 测试Oh My Zsh加载
    if echo 'source ~/.oh-my-zsh/oh-my-zsh.sh && echo "OMZ test successful"' | zsh 2>/dev/null | grep -q "OMZ test successful"; then
        log_info "Oh My Zsh功能测试通过"
        return 0
    else
        log_error "[ERROR] Oh My Zsh功能测试失败"
        return 1
    fi
}

# =============================================================================
#  插件管理模块
# =============================================================================

# 获取插件信息
get_plugin_info() {
    local plugin_name="$1"

    case "$plugin_name" in
        "zsh-autosuggestions")
            echo "zsh-users/zsh-autosuggestions:自动建议插件"
            ;;
        "zsh-syntax-highlighting")
            echo "zsh-users/zsh-syntax-highlighting:语法高亮插件"
            ;;
        "zsh-completions")
            echo "zsh-users/zsh-completions:额外补全插件"
            ;;
        "zsh-history-substring-search")
            echo "zsh-users/zsh-history-substring-search:历史搜索插件"
            ;;
        *)
            echo "unknown/unknown:未知插件"
            ;;
    esac
}

# 安装单个插件
install_single_plugin() {
    local plugin_name="$1"
    local plugin_info=$(get_plugin_info "$plugin_name")
    IFS=':' read -r plugin_repo plugin_desc <<< "$plugin_info"

    if [ "$plugin_repo" = "unknown/unknown" ]; then
        log_warn " 跳过未知插件: $plugin_name"
        return 1
    fi

    local plugin_dir="$ZSH_PLUGINS_DIR/$plugin_name"

    # 检查插件是否已安装
    if [ -d "$plugin_dir" ]; then
        log_info "$plugin_desc 已安装，跳过"
        return 0
    fi

    log_info "安装插件: $plugin_desc"
    log_debug "仓库: $plugin_repo"
    log_debug "目标目录: $plugin_dir"

    # 克隆插件仓库
    if git clone "https://github.com/$plugin_repo.git" "$plugin_dir" 2>/dev/null; then
        add_rollback_action "rm -rf '$plugin_dir'"
        log_info "$plugin_desc 安装成功"
        return 0
    else
        log_error "[ERROR] $plugin_desc 安装失败"
        return 1
    fi
}

# 安装所有插件
install_zsh_plugins() {
    log_info "安装ZSH插件..."
    set_install_state "INSTALLING_PLUGINS"

    if [ ${#ZSH_PLUGINS[@]} -eq 0 ]; then
        log_info "无插件需要安装"
        return 0
    fi

    local installed_count=0
    local failed_count=0
    local total_plugins=${#ZSH_PLUGINS[@]}

    # 确保插件目录存在
    mkdir -p "$ZSH_PLUGINS_DIR"

    for plugin in "${ZSH_PLUGINS[@]}"; do
        # 跳过空插件名
        [ -z "$plugin" ] && continue

        log_info "安装插件 ($((installed_count + failed_count + 1))/$total_plugins): $plugin"

        if install_single_plugin "$plugin"; then
            installed_count=$((installed_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
    done

    log_info "插件安装完成: 成功 $installed_count 个，失败 $failed_count 个"

    # 验证插件安装
    if verify_plugins_installation; then
        log_info "插件验证成功"
        return 0
    else
        log_warn " 部分插件验证失败，但不影响主要功能"
        return 0  # 插件失败不应该阻止整个安装过程
    fi
}

# 验证插件安装
verify_plugins_installation() {
    log_info "验证插件安装..."

    local verified_count=0
    local total_plugins=${#ZSH_PLUGINS[@]}

    for plugin in "${ZSH_PLUGINS[@]}"; do
        [ -z "$plugin" ] && continue

        local plugin_dir="$ZSH_PLUGINS_DIR/$plugin"
        if [ -d "$plugin_dir" ] && [ -n "$(ls -A "$plugin_dir" 2>/dev/null)" ]; then
            log_debug "插件验证通过: $plugin"
            verified_count=$((verified_count + 1))
        else
            log_debug "[ERROR] 插件验证失败: $plugin"
        fi
    done

    log_info "插件验证结果: $verified_count/$total_plugins"
    return 0
}

# =============================================================================
#  主题管理模块
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
    log_debug "仓库: $ZSH_THEME_REPO"
    log_debug "目标目录: $theme_dir"

    # 克隆主题仓库
    if git clone --depth=1 "https://github.com/$ZSH_THEME_REPO.git" "$theme_dir" 2>/dev/null; then
        add_rollback_action "rm -rf '$theme_dir'"
        log_info "Powerlevel10k主题安装成功"
        return 0
    else
        log_error "[ERROR] Powerlevel10k主题安装失败"
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
        log_error "[ERROR] 主题文件验证失败: $theme_file"
        return 1
    fi
}

# 下载并配置rainbow主题
configure_rainbow_theme() {
    log_info "配置Powerlevel10k Rainbow主题..."

    local p10k_config_file="$HOME/.p10k.zsh"
    local p10k_backup_dir="$HOME/.oh-my-zsh/themes"
    local main_url="https://raw.githubusercontent.com/romkatv/powerlevel10k/refs/heads/master/config/p10k-rainbow.zsh"
    local backup_url="https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-rainbow.zsh"

    # 创建备份目录
    mkdir -p "$p10k_backup_dir"

    # 备份现有配置（如果存在）
    if [ -f "$p10k_config_file" ]; then
        log_info "备份现有P10k配置..."
        cp "$p10k_config_file" "$p10k_config_file.backup-$(date +%Y%m%d-%H%M%S)"
        add_rollback_action "restore_backup '$p10k_config_file' '$p10k_config_file.backup-$(date +%Y%m%d-%H%M%S)'"
    fi

    # 尝试下载rainbow配置
    log_info "下载Rainbow主题配置..."
    local download_success=false
    local temp_config=$(mktemp)

    # 尝试主URL
    if curl -fsSL --connect-timeout 10 --max-time 30 "$main_url" -o "$temp_config" 2>/dev/null; then
        log_info "从主URL下载成功"
        download_success=true
    elif curl -fsSL --connect-timeout 10 --max-time 30 "$backup_url" -o "$temp_config" 2>/dev/null; then
        log_info "从备用URL下载成功"
        download_success=true
    else
        log_warn "无法下载Rainbow主题配置，将使用默认配置"
        rm -f "$temp_config"
        return 1
    fi

    if [ "$download_success" = true ]; then
        # 验证下载的文件
        if [ -s "$temp_config" ] && grep -q "powerlevel10k" "$temp_config" 2>/dev/null; then
            # 部署配置文件
            mv "$temp_config" "$p10k_config_file"
            chmod 644 "$p10k_config_file"

            # 保存备份到themes目录
            cp "$p10k_config_file" "$p10k_backup_dir/p10k-rainbow.zsh"

            log_info "Rainbow主题配置部署成功"
            log_info "配置文件位置: $p10k_config_file"
            log_info "备份位置: $p10k_backup_dir/p10k-rainbow.zsh"

            add_rollback_action "rm -f '$p10k_config_file' '$p10k_backup_dir/p10k-rainbow.zsh'"
            return 0
        else
            log_error "下载的配置文件无效"
            rm -f "$temp_config"
            return 1
        fi
    fi

    return 1
}

# =============================================================================
#   配置文件管理模块
# =============================================================================

# 智能配置合并.zshrc
generate_zshrc_config() {
    log_info "配置ZSH环境文件..."
    set_install_state "CONFIGURING_ZSHRC"

    local zshrc_file="$HOME/.zshrc"
    local omz_generated_zshrc=false

    # 检查Oh My Zsh是否已生成.zshrc
    if [ -f "$zshrc_file" ] && grep -q "oh-my-zsh" "$zshrc_file" 2>/dev/null; then
        log_info "检测到Oh My Zsh已生成.zshrc配置，将进行智能合并..."
        omz_generated_zshrc=true
    else
        log_info "生成新的ZSH配置文件..."
        omz_generated_zshrc=false
    fi

    # 备份现有配置
    create_backup "$zshrc_file"

    if [ "$omz_generated_zshrc" = true ]; then
        # 智能合并模式：在现有配置基础上添加增强功能
        merge_zshrc_config "$zshrc_file"
    else
        # 全新生成模式
        generate_new_zshrc_config "$zshrc_file"
    fi

    add_rollback_action "restore_backup '$zshrc_file' '$ZSH_BACKUP_DIR/.zshrc'"
    log_info ".zshrc配置文件处理完成"
    return 0
}

# 合并现有.zshrc配置
merge_zshrc_config() {
    local zshrc_file="$1"
    local temp_file=$(mktemp)

    log_info "合并现有配置..."

    # 复制原配置
    cp "$zshrc_file" "$temp_file"

    # 确保使用powerlevel10k主题
    if ! grep -q "ZSH_THEME.*powerlevel10k" "$temp_file"; then
        log_info "更新主题为Powerlevel10k..."
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$temp_file"
    fi

    # 添加或更新插件配置
    if grep -q "^plugins=" "$temp_file"; then
        log_info "更新插件配置..."
        # 确保包含我们需要的插件
        local required_plugins="git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search"
        for plugin in $required_plugins; do
            if ! grep -q "$plugin" "$temp_file"; then
                sed -i "/^plugins=(/a\\  $plugin" "$temp_file"
            fi
        done
    fi

    # 添加增强配置（如果不存在）
    if ! grep -q "# Enhanced configurations" "$temp_file"; then
        cat >> "$temp_file" << 'EOF'

# =============================================================================
# Enhanced configurations added by zsh-install.sh
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

# 现代化命令别名
command -v exa >/dev/null && alias ls='exa --color=auto --group-directories-first'
command -v bat >/dev/null && alias cat='bat --style=plain'
command -v fd >/dev/null && alias find='fd'

# 语言环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

EOF
    fi

    # 应用合并后的配置
    mv "$temp_file" "$zshrc_file"
}

# 生成全新.zshrc配置
generate_new_zshrc_config() {
    local zshrc_file="$1"

# =============================================================================
# ZSH配置文件 - 由zsh-install.sh自动生成
# =============================================================================

# Oh My Zsh配置
export ZSH="$HOME/.oh-my-zsh"

# 主题配置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件配置
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    zsh-history-substring-search
)

# 加载Oh My Zsh
source $ZSH/oh-my-zsh.sh

# =============================================================================
# 用户自定义配置
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

# 别名配置
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# 如果安装了现代化工具，使用它们
command -v exa >/dev/null && alias ls='exa --color=auto --group-directories-first'
command -v bat >/dev/null && alias cat='bat --style=plain'
command -v fd >/dev/null && alias find='fd'

# Powerlevel10k即时提示
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 加载Powerlevel10k配置（如果存在）
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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

EOF
}

# 验证配置文件
verify_zshrc_config() {
    log_info "验证ZSH配置文件..."

    local zshrc_file="$HOME/.zshrc"

    # 检查文件是否存在
    if [ ! -f "$zshrc_file" ]; then
        log_error "[ERROR] .zshrc文件不存在"
        return 1
    fi

    # 检查配置语法
    if zsh -n "$zshrc_file" 2>/dev/null; then
        log_info ".zshrc语法检查通过"
    else
        log_error "[ERROR] .zshrc语法检查失败"
        return 1
    fi

    # 测试配置加载
    if echo 'source ~/.zshrc && echo "Config test successful"' | zsh 2>/dev/null | grep -q "Config test successful"; then
        log_info ".zshrc配置加载测试通过"
        return 0
    else
        log_error "[ERROR] .zshrc配置加载测试失败"
        return 1
    fi
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

# =============================================================================
#  主安装流程模块
# =============================================================================

main() {
    # 设置错误处理 - 使用更安全的方式
    set -eE  # 确保ERR trap能够被继承
    trap 'handle_error $LINENO' ERR

    # 初始化环境
    init_environment

    # 创建安装日志
    log_info "安装日志文件: $INSTALL_LOG_FILE"
    echo "ZSH安装开始 - $(date)" > "$INSTALL_LOG_FILE"

    # 显示脚本信息
    show_header "ZSH环境安装配置脚本" "$ZSH_CONFIG_VERSION" "模块化ZSH环境安装，支持自定义配置和完整验证"

    log_info "开始ZSH环境安装流程..."
    log_info "安装模式: $ZSH_INSTALL_MODE"
    log_info "安装步骤概览:"
    log_info "1. 系统兼容性检查"
    log_info "2. 网络连接检查"
    log_info "3. 用户权限检查"
    log_info "4. 基础软件包安装"
    log_info "5. Oh My Zsh框架安装"
    log_info "6. 插件安装"
    log_info "7. 主题安装"
    log_info "8. 配置文件生成"
    log_info "9. 最终验证"
    echo

    # 步骤1: 系统兼容性检查
    log_info "1. 系统兼容性检查..."
    if ! check_system_compatibility; then
        log_error "[ERROR] 系统兼容性检查失败"
        exit 1
    fi
    echo

    # 步骤2: 网络连接检查
    log_info "2. 网络连接检查..."
    if ! check_network_connectivity; then
        log_error "[ERROR] 网络连接检查失败"
        exit 1
    fi
    echo

    # 步骤3: 用户权限检查
    log_info "3. 用户权限检查..."
    if ! check_user_permissions; then
        log_error "[ERROR] 用户权限检查失败"
        exit 1
    fi
    echo

    # 步骤4: 基础软件包安装
    log_info "4. 基础软件包安装..."
    if ! install_required_packages; then
        log_error "[ERROR] 基础软件包安装失败，无法继续"
        execute_rollback
        exit 1
    fi

    # 验证ZSH安装
    if ! verify_zsh_installation; then
        log_error "[ERROR] ZSH安装验证失败，无法继续"
        execute_rollback
        exit 1
    fi

    # 安装可选软件包
    install_optional_packages
    echo

    # 步骤5: Oh My Zsh框架安装
    log_info "5. Oh My Zsh框架安装..."
    if ! install_oh_my_zsh; then
        log_error "[ERROR] Oh My Zsh安装失败"
        execute_rollback
        exit 1
    fi
    echo

    # 步骤6: 插件安装
    log_info "6. ZSH插件安装..."
    if ! install_zsh_plugins; then
        log_warn " 插件安装部分失败，但不影响主要功能"
    fi
    echo

    # 步骤7: 主题安装
    log_info "7. 主题安装..."
    if ! install_powerlevel10k_theme; then
        log_warn "主题安装失败，将使用默认主题"
    else
        # 主题安装成功后，配置rainbow主题
        log_info "配置Rainbow主题..."
        if configure_rainbow_theme; then
            log_info "Rainbow主题配置成功"
        else
            log_warn "Rainbow主题配置失败，将使用默认P10k配置"
        fi
    fi
    echo

    # 步骤8: 配置文件生成
    log_info "8. 配置文件生成..."
    if ! generate_zshrc_config; then
        log_error "[ERROR] 配置文件生成失败"
        execute_rollback
        exit 1
    fi

    if ! verify_zshrc_config; then
        log_warn " 配置文件验证失败，可能需要手动调整"
    fi
    echo

    # 步骤9: 最终验证
    log_info "9. 最终验证..."
    local verification_results=()
    local verification_passed=true

    # 验证ZSH
    if verify_zsh_installation; then
        verification_results+=(" ZSH Shell: $(zsh --version 2>/dev/null | head -1)")
    else
        verification_results+=("[ERROR] ZSH Shell: 验证失败")
        verification_passed=false
    fi

    # 验证Oh My Zsh
    if verify_omz_installation; then
        verification_results+=(" Oh My Zsh: 已安装并可用")
    else
        verification_results+=("[ERROR] Oh My Zsh: 验证失败")
        verification_passed=false
    fi

    # 验证插件
    if verify_plugins_installation; then
        verification_results+=(" 插件: ${#ZSH_PLUGINS[@]} 个已安装")
    else
        verification_results+=("  插件: 部分安装失败")
    fi

    # 验证主题
    if verify_theme_installation; then
        verification_results+=(" 主题: Powerlevel10k")
    else
        verification_results+=("  主题: 使用默认主题")
    fi

    # 验证配置文件
    if verify_zshrc_config; then
        verification_results+=(" 配置文件: .zshrc 已生成")
    else
        verification_results+=("  配置文件: 可能需要手动调整")
    fi

    echo
    # 显示安装结果
    if [ "$verification_passed" = true ]; then
        set_install_state "COMPLETED_SUCCESS"
        log_info "ZSH环境安装完成！"
        log_info "安装摘要:"
        for result in "${verification_results[@]}"; do
            log_info "$result"
        done
        echo
        log_info "后续步骤:"
        log_info "1. 重新登录或运行: exec zsh"
        log_info "2. 配置主题: p10k configure"
        log_info "3. 享受强大的ZSH环境！"
        echo
        log_info "安装日志已保存到: $INSTALL_LOG_FILE"

        # 询问是否设置为默认Shell
        if [ "$ZSH_INSTALL_MODE" = "interactive" ]; then
            if ask_confirmation "是否将ZSH设置为默认Shell？" "y"; then
                if set_default_shell; then
                    log_info "ZSH已设置为默认Shell"
                else
                    log_warn " 默认Shell设置失败，可以稍后手动设置: chsh -s $(which zsh)"
                fi
            fi
        fi

        return 0
    else
        set_install_state "COMPLETED_WITH_ERRORS"
        log_warn " ZSH环境安装部分完成，但存在一些问题"
        log_warn "� 安装结果:"
        for result in "${verification_results[@]}"; do
            log_warn "$result"
        done
        echo
        log_warn "� 请检查上述错误信息并手动修复"
        log_warn "详细日志: $INSTALL_LOG_FILE"

        return 1
    fi
}

# 错误处理函数
handle_error() {
    local line_number=$1
    local error_code=$?

    # 记录调试信息
    log_debug "handle_error called: line=$line_number, code=$error_code"

    # 只有在真正的错误情况下才处理（退出码非0）
    if [ $error_code -ne 0 ]; then
        log_error "[ERROR] 脚本在第 $line_number 行发生错误 (退出码: $error_code)"
        log_error "当前安装状态: $ZSH_INSTALL_STATE"

        # 执行回滚
        log_warn "开始执行回滚操作..."
        execute_rollback

        # 保存错误日志
        echo "ERROR at line $line_number (exit code: $error_code) - State: $ZSH_INSTALL_STATE" >> "$INSTALL_LOG_FILE"

        exit $error_code
    else
        # 记录误触发的情况
        log_debug "ERR trap triggered with exit code 0 at line $line_number - ignoring"
    fi
}

# 脚本入口点
# 安全检查 BASH_SOURCE 是否存在，兼容 curl | bash 执行方式
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
