#!/bin/bash

# =============================================================================
# ZSH 插件和工具安装脚本
# 作者: saul
# 版本: 2.0
# 描述: 安装和配置ZSH插件、额外工具和优化配置的专用脚本
# 功能: 插件安装、工具配置、智能配置管理、依赖处理
# =============================================================================

set -e  # 使用较温和的错误处理

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
readonly ZSH_PLUGINS_VERSION="2.0"
readonly ZSH_INSTALL_MODE=${ZSH_INSTALL_MODE:-"interactive"}  # interactive/auto/minimal

# 安装路径配置
readonly ZSH_INSTALL_DIR=${ZSH_INSTALL_DIR:-"$HOME"}
readonly OMZ_DIR="$ZSH_INSTALL_DIR/.oh-my-zsh"
readonly ZSH_CUSTOM_DIR="$OMZ_DIR/custom"
readonly ZSH_PLUGINS_DIR="$ZSH_CUSTOM_DIR/plugins"

# 插件配置
readonly ZSH_PLUGINS=(
    "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
    "you-should-use:https://github.com/MichaelAquilina/zsh-you-should-use"
)

# 完整插件列表（用于.zshrc配置）
readonly COMPLETE_PLUGINS="git extract systemadmin zsh-interactive-cd systemd sudo docker ubuntu man command-not-found common-aliases docker-compose zsh-autosuggestions zsh-syntax-highlighting tmux you-should-use"

# 额外工具配置
readonly TMUX_CONFIG_REPO="https://github.com/gpakosz/.tmux.git"

# 状态管理
declare -g PLUGINS_INSTALL_STATE=""
declare -g ROLLBACK_ACTIONS=()
declare -g INSTALL_LOG_FILE="/opt/zsh-plugins-install-$(date +%Y%m%d-%H%M%S).log"
readonly ZSH_BACKUP_DIR="$HOME/.zsh-plugins-backup-$(date +%Y%m%d-%H%M%S)"

# =============================================================================
# 状态管理和回滚功能
# =============================================================================

# 设置安装状态
# 参数: $1 - 状态名称
set_install_state() {
    local state="$1"
    PLUGINS_INSTALL_STATE="$state"
    log_debug "插件安装状态更新: $state"
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
# 前置条件检查
# =============================================================================

# 检查ZSH核心环境是否已安装
check_zsh_core_installed() {
    log_info "检查ZSH核心环境..."

    # 检查ZSH是否安装
    if ! command -v zsh >/dev/null 2>&1; then
        log_error "ZSH未安装，请先运行 zsh-core-install.sh"
        return 1
    fi

    # 检查Oh My Zsh是否安装
    if [ ! -d "$OMZ_DIR" ] || [ ! -f "$OMZ_DIR/oh-my-zsh.sh" ]; then
        log_error "Oh My Zsh未安装，请先运行 zsh-core-install.sh"
        return 1
    fi

    # 检查.zshrc是否存在
    if [ ! -f "$HOME/.zshrc" ]; then
        log_error ".zshrc配置文件不存在，请先运行 zsh-core-install.sh"
        return 1
    fi

    # 检查Powerlevel10k主题
    local theme_dir="$ZSH_CUSTOM_DIR/themes/powerlevel10k"
    if [ ! -d "$theme_dir" ]; then
        log_warn "Powerlevel10k主题未安装，建议先运行 zsh-core-install.sh"
    fi

    log_info "ZSH核心环境检查通过"
    return 0
}

# 检查系统依赖
check_system_dependencies() {
    log_info "检查系统依赖..."

    local required_commands=("git" "curl" "zsh")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_error "缺少必需命令: ${missing_commands[*]}"
        log_error "请先安装这些命令或运行 zsh-core-install.sh"
        return 1
    fi

    # 检查网络连接
    if ! curl -fsSL --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1; then
        log_error "网络连接失败，无法下载插件"
        return 1
    fi

    log_info "系统依赖检查通过"
    return 0
}

# =============================================================================
# 错误处理
# =============================================================================

# 错误处理函数
# 参数: $1 - 错误行号, $2 - 错误代码
handle_error() {
    local line_no=${1:-"未知"}
    local error_code=${2:-1}

    log_error "脚本在第 $line_no 行发生错误 (退出码: $error_code)"
    log_error "当前安装状态: ${PLUGINS_INSTALL_STATE:-"未知"}"

    # 执行回滚
    execute_rollback

    log_error "ZSH插件安装失败，已执行回滚操作"
    exit $error_code
}

# 初始化环境
init_environment() {
    # 设置调试级别
    export LOG_LEVEL=${LOG_LEVEL:-1}  # 默认INFO级别

    # 调用common.sh的基础初始化
    detect_os
    detect_arch
    check_root

    # 设置错误处理
    trap 'handle_error $LINENO $?' ERR

    # 创建必要的目录
    mkdir -p "$(dirname "$INSTALL_LOG_FILE")"
    mkdir -p "$ZSH_PLUGINS_DIR"

    log_debug "ZSH插件安装脚本初始化完成"
    log_debug "安装日志: $INSTALL_LOG_FILE"
    log_debug "备份目录: $ZSH_BACKUP_DIR"
    log_info "权限模式: $([ -z "$SUDO" ] && echo "root" || echo "sudo")"
}

# =============================================================================
# ZSH 插件安装功能
# =============================================================================

# 安装单个ZSH插件
# 参数: $1 - 插件名称, $2 - 插件仓库URL
install_single_plugin() {
    local plugin_name="$1"
    local plugin_repo="$2"
    local plugin_dir="$ZSH_PLUGINS_DIR/$plugin_name"

    log_info "安装插件: $plugin_name"

    # 检查插件是否已安装
    if [ -d "$plugin_dir" ] && [ -n "$(ls -A "$plugin_dir" 2>/dev/null)" ]; then
        log_info "插件 $plugin_name 已安装，跳过"
        return 0
    fi

    # 克隆插件仓库
    log_info "克隆插件仓库: $plugin_repo"
    if git clone --depth=1 "$plugin_repo.git" "$plugin_dir" 2>/dev/null; then
        add_rollback_action "rm -rf '$plugin_dir'"
        log_info "插件 $plugin_name 安装成功"
        return 0
    else
        log_error "插件 $plugin_name 安装失败"
        return 1
    fi
}

# 安装所有ZSH插件
install_zsh_plugins() {
    log_info "安装ZSH插件..."
    set_install_state "INSTALLING_PLUGINS"

    local failed_plugins=()
    local success_count=0
    local total_plugins=${#ZSH_PLUGINS[@]}

    # 确保插件目录存在
    mkdir -p "$ZSH_PLUGINS_DIR"

    # 安装每个插件
    for plugin_info in "${ZSH_PLUGINS[@]}"; do
        IFS=':' read -r plugin_name plugin_repo <<< "$plugin_info"

        if install_single_plugin "$plugin_name" "$plugin_repo"; then
            success_count=$((success_count + 1))
        else
            failed_plugins+=("$plugin_name")
        fi
    done

    # 检查安装结果
    if [ ${#failed_plugins[@]} -gt 0 ]; then
        log_warn "以下插件安装失败："
        for failed_plugin in "${failed_plugins[@]}"; do
            log_warn "  • $failed_plugin"
        done
    fi

    log_info "插件安装完成: 成功 $success_count/$total_plugins"

    # 如果有插件安装成功，返回成功
    if [ $success_count -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# 验证插件安装
verify_plugins_installation() {
    log_info "验证插件安装..."

    local verified_count=0
    local total_plugins=${#ZSH_PLUGINS[@]}

    for plugin_info in "${ZSH_PLUGINS[@]}"; do
        IFS=':' read -r plugin_name plugin_repo <<< "$plugin_info"
        local plugin_dir="$ZSH_PLUGINS_DIR/$plugin_name"

        if [ -d "$plugin_dir" ] && [ -n "$(ls -A "$plugin_dir" 2>/dev/null)" ]; then
            log_debug "插件验证通过: $plugin_name"
            verified_count=$((verified_count + 1))
        else
            log_debug "插件验证失败: $plugin_name"
        fi
    done

    log_info "插件验证结果: $verified_count/$total_plugins"
    return 0
}

# =============================================================================
# 额外工具安装功能
# =============================================================================



# 安装和配置tmux
install_tmux_config() {
    log_info "安装和配置tmux..."
    set_install_state "INSTALLING_TMUX"

    # 检查tmux是否已安装
    if ! command -v tmux >/dev/null 2>&1; then
        log_info "tmux未安装，尝试安装..."
        if ! install_package "tmux"; then
            log_warn "tmux安装失败，跳过配置"
            return 1
        fi
    fi

    # 安装.tmux配置
    local tmux_config_dir="$HOME/.tmux"
    if [ ! -d "$tmux_config_dir" ]; then
        log_info "克隆.tmux配置..."
        if git clone --depth=1 "$TMUX_CONFIG_REPO" "$tmux_config_dir" 2>/dev/null; then
            log_info ".tmux配置克隆成功"
            add_rollback_action "rm -rf '$tmux_config_dir'"

            # 创建符号链接
            if ln -sf "$tmux_config_dir/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null; then
                log_info "创建.tmux.conf符号链接成功"
                add_rollback_action "rm -f '$HOME/.tmux.conf'"
            else
                log_warn "创建.tmux.conf符号链接失败"
            fi

            # 复制本地配置文件
            if cp "$tmux_config_dir/.tmux.conf.local" "$HOME/.tmux.conf.local" 2>/dev/null; then
                log_info "复制.tmux.conf.local成功"
                add_rollback_action "rm -f '$HOME/.tmux.conf.local'"
            else
                log_warn "复制.tmux.conf.local失败"
            fi

            return 0
        else
            log_warn ".tmux配置安装失败"
            return 1
        fi
    else
        log_info ".tmux配置已存在，跳过"
        return 0
    fi
}

# =============================================================================
# 智能配置管理功能
# =============================================================================

# 智能插件配置管理
# 参数: $1 - .zshrc文件路径
smart_plugin_config_management() {
    local zshrc_file="$1"
    local temp_file=$(mktemp)

    log_info "智能插件配置管理..."

    # 备份原配置
    create_backup "$zshrc_file"

    # 复制原配置
    cp "$zshrc_file" "$temp_file"

    # 检查是否存在 plugins=() 配置行
    if grep -q "^plugins=" "$temp_file"; then
        log_info "发现现有插件配置，进行智能合并..."

        # 提取现有插件列表
        local current_line=$(grep "^plugins=" "$temp_file")
        log_debug "当前插件配置行: $current_line"

        # 提取括号内的插件列表
        local current_plugins=$(echo "$current_line" | sed 's/^plugins=(//' | sed 's/)$//' | tr -s ' ' | sed 's/^ *//;s/ *$//')
        log_debug "当前插件列表: $current_plugins"

        # 将现有插件转换为数组
        local existing_array=()
        if [ -n "$current_plugins" ]; then
            IFS=' ' read -ra existing_array <<< "$current_plugins"
        fi

        # 将完整插件列表转换为数组
        local complete_array=()
        IFS=' ' read -ra complete_array <<< "$COMPLETE_PLUGINS"

        # 合并插件列表，避免重复
        local merged_plugins=()
        local plugin_exists

        # 先添加现有插件
        for plugin in "${existing_array[@]}"; do
            [ -n "$plugin" ] && merged_plugins+=("$plugin")
        done

        # 添加新插件（如果不存在）
        for new_plugin in "${complete_array[@]}"; do
            plugin_exists=false
            for existing_plugin in "${merged_plugins[@]}"; do
                if [ "$existing_plugin" = "$new_plugin" ]; then
                    plugin_exists=true
                    break
                fi
            done

            if [ "$plugin_exists" = false ]; then
                merged_plugins+=("$new_plugin")
                log_debug "添加新插件: $new_plugin"
            fi
        done

        # 生成新的插件配置行
        local new_plugins_line="plugins=(${merged_plugins[*]})"
        log_debug "新插件配置行: $new_plugins_line"

        # 替换插件配置行
        sed -i "s/^plugins=.*/$new_plugins_line/" "$temp_file"
        log_info "插件配置已更新，包含 ${#merged_plugins[@]} 个插件"

    else
        log_info "未找到插件配置，创建新的插件配置..."

        # 在 Oh My Zsh 源之前添加插件配置
        if grep -q "source.*oh-my-zsh.sh" "$temp_file"; then
            sed -i "/source.*oh-my-zsh.sh/i\\plugins=($COMPLETE_PLUGINS)" "$temp_file"
            log_info "已添加完整插件配置"
        else
            # 如果没有找到 source 行，在文件开头添加
            sed -i "1i\\plugins=($COMPLETE_PLUGINS)" "$temp_file"
            log_info "已在文件开头添加插件配置"
        fi
    fi

    # 应用更改
    mv "$temp_file" "$zshrc_file"
    return 0
}

# 确保Powerlevel10k配置
# 参数: $1 - .zshrc文件路径
ensure_p10k_config() {
    local zshrc_file="$1"
    local temp_file=$(mktemp)

    log_info "确保Powerlevel10k配置..."

    # 复制原配置
    cp "$zshrc_file" "$temp_file"

    # 检查是否已有p10k.zsh源配置
    if ! grep -q "\[.*-f.*\.p10k\.zsh.*\].*source.*\.p10k\.zsh" "$temp_file"; then
        log_info "添加Powerlevel10k配置源..."

        # 在文件末尾添加p10k配置
        cat >> "$temp_file" << 'EOF'

# Powerlevel10k 配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
        log_info "已添加Powerlevel10k配置源"
    else
        log_info "Powerlevel10k配置源已存在"
    fi

    # 应用更改
    mv "$temp_file" "$zshrc_file"
    return 0
}

# 添加增强配置
# 参数: $1 - .zshrc文件路径
add_enhanced_config() {
    local zshrc_file="$1"
    local temp_file=$(mktemp)

    log_info "添加增强配置..."

    # 复制原配置
    cp "$zshrc_file" "$temp_file"

    # 检查是否已有增强配置
    if ! grep -q "# Enhanced configurations" "$temp_file"; then
        cat >> "$temp_file" << 'EOF'

# =============================================================================
# Enhanced configurations added by zsh-plugins-install.sh
# =============================================================================

# 现代化工具别名
command -v bat >/dev/null && alias cat='bat --style=plain'
command -v fd >/dev/null && alias find='fd'
command -v eza >/dev/null && alias ls='eza --color=always --group-directories-first'



# 插件特定配置
# you-should-use 插件配置
export YSU_MESSAGE_POSITION="after"
export YSU_HARDCORE=1

# zsh-autosuggestions 插件配置
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

EOF
        log_info "已添加增强配置"
    else
        log_info "增强配置已存在"
    fi

    # 应用更改
    mv "$temp_file" "$zshrc_file"
    return 0
}

# 更新.zshrc配置文件
update_zshrc_config() {
    log_info "更新.zshrc配置文件..."
    set_install_state "UPDATING_CONFIG"

    local zshrc_file="$HOME/.zshrc"

    # 检查文件是否存在
    if [ ! -f "$zshrc_file" ]; then
        log_error ".zshrc文件不存在，请先运行 zsh-core-install.sh"
        return 1
    fi

    # 应用智能插件配置管理
    smart_plugin_config_management "$zshrc_file"

    # 确保Powerlevel10k配置
    ensure_p10k_config "$zshrc_file"

    # 添加增强配置
    add_enhanced_config "$zshrc_file"

    log_info ".zshrc配置文件更新完成"
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

    # 检查插件配置是否存在
    if grep -q "plugins=.*zsh-autosuggestions.*zsh-syntax-highlighting" "$zshrc_file"; then
        log_info "插件配置验证通过"
    else
        log_warn "插件配置可能不完整"
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
    echo -e "${BLUE}ZSH插件和工具安装脚本${RESET}"
    echo -e "${BLUE}版本: $ZSH_PLUGINS_VERSION${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    echo -e "${CYAN}本脚本将安装和配置ZSH插件和工具：${RESET}"
    echo -e "${CYAN}• ZSH插件: zsh-autosuggestions, zsh-syntax-highlighting, you-should-use${RESET}"
    echo -e "${CYAN}• 额外工具: tmux配置${RESET}"
    echo -e "${CYAN}• 智能配置管理和优化${RESET}"
    echo
    echo -e "${YELLOW}前置要求：需要先运行 zsh-core-install.sh 安装核心环境${RESET}"
    echo
}

# 显示安装总结
show_installation_summary() {
    local status="$1"

    echo
    echo -e "${CYAN}================================================================${RESET}"

    case "$status" in
        "success")
            echo -e "${GREEN}🎉 ZSH插件和工具安装成功！${RESET}"
            echo
            echo -e "${CYAN}已安装的组件：${RESET}"

            # 检查插件安装状态
            local installed_plugins=()
            for plugin_info in "${ZSH_PLUGINS[@]}"; do
                IFS=':' read -r plugin_name plugin_repo <<< "$plugin_info"
                local plugin_dir="$ZSH_PLUGINS_DIR/$plugin_name"
                if [ -d "$plugin_dir" ]; then
                    installed_plugins+=("$plugin_name")
                fi
            done

            echo -e "  ✅ ZSH插件: ${installed_plugins[*]}"
            echo -e "  ✅ tmux配置: $([ -f "$HOME/.tmux.conf" ] && echo '已配置' || echo '未配置')"
            echo -e "  ✅ 智能配置: 已更新"
            echo
            echo -e "${YELLOW}下一步操作：${RESET}"
            echo -e "  1. 运行 ${CYAN}chsh -s \$(which zsh)${RESET} 设置为默认shell"
            echo -e "  2. 重新登录或运行 ${CYAN}zsh${RESET} 开始使用"
            echo -e "  3. 首次启动时配置 Powerlevel10k 主题"
            ;;
        "failed")
            echo -e "${RED}❌ ZSH插件和工具安装失败${RESET}"
            echo
            echo -e "${YELLOW}故障排除建议：${RESET}"
            echo -e "  • 确保已运行 zsh-core-install.sh 安装核心环境"
            echo -e "  • 检查网络连接是否正常"
            echo -e "  • 确保有足够的磁盘空间"
            echo -e "  • 查看安装日志: ${CYAN}$INSTALL_LOG_FILE${RESET}"
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

    # 检查前置条件
    log_info "检查前置条件..."
    if ! check_zsh_core_installed || ! check_system_dependencies; then
        log_error "前置条件检查失败"
        show_installation_summary "failed"
        exit 1
    fi

    # 询问用户确认
    if [ "$ZSH_INSTALL_MODE" = "interactive" ]; then
        echo -e "是否继续安装ZSH插件和工具？ [Y/n]: " | tr -d '\n'
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

    log_info "开始ZSH插件和工具安装..."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始安装" >> "$INSTALL_LOG_FILE"

    # 执行安装步骤
    local install_success=true

    # 步骤1: 安装ZSH插件
    log_info "步骤1: 安装ZSH插件..."
    if ! install_zsh_plugins; then
        log_warn "部分ZSH插件安装失败，但不影响主要功能"
        # 插件安装失败不应该阻止整个流程
    fi
    verify_plugins_installation

    # 步骤2: 安装额外工具
    log_info "步骤2: 安装额外工具..."

    # 安装tmux配置
    log_info "2.1 安装tmux配置..."
    install_tmux_config

    # 步骤3: 更新配置文件
    log_info "步骤3: 更新配置文件..."
    if ! update_zshrc_config || ! verify_zshrc_config; then
        log_error "配置文件更新失败"
        install_success=false
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
