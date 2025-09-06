#!/bin/bash

# =============================================================================
# Ubuntu/Debian服务器安装脚本 - 菜单入口
# 作者: saul
# 版本: 2.0
# 描述: 模块化安装脚本的菜单入口，支持Ubuntu 20-24和Debian 10-12 x64/ARM64
# 功能: 提供交互式菜单，调用独立的安装脚本模块，无自动安装行为
# =============================================================================

set -euo pipefail

# =============================================================================
# 导入通用函数库
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || {
    echo "错误：无法确定脚本目录"
    exit 1
}

# 检查并加载 common.sh
if [ -f "$SCRIPT_DIR/scripts/common.sh" ]; then
    source "$SCRIPT_DIR/scripts/common.sh"
else
    echo "错误：找不到 common.sh 文件"
    echo "请确保在项目根目录中运行此脚本"
    exit 1
fi



# =============================================================================
# 配置变量
# =============================================================================
readonly INSTALL_DIR="$HOME/.scripts-for-linux"

# =============================================================================
# 日志函数 (安全版本，兼容颜色变量未定义的情况)
# =============================================================================
log_info() {
    local cyan_color="${CYAN:-}"
    local reset_color="${RESET:-}"
    echo -e "${cyan_color}[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1${reset_color}"
}

log_warn() {
    local yellow_color="${YELLOW:-}"
    local reset_color="${RESET:-}"
    echo -e "${yellow_color}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${reset_color}"
}

log_error() {
    local red_color="${RED:-}"
    local reset_color="${RESET:-}"
    echo -e "${red_color}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${reset_color}"
}

log_debug() {
    local blue_color="${BLUE:-}"
    local reset_color="${RESET:-}"
    echo -e "${blue_color}[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $1${reset_color}"
}

# =============================================================================
# 脚本验证函数
# =============================================================================

# 验证本地脚本目录
verify_local_scripts() {
    local scripts_dir="$SCRIPT_DIR/scripts"

    if [ ! -d "$scripts_dir" ]; then
        log_error "脚本目录不存在: $scripts_dir"
        log_error "请确保在正确的项目根目录中运行此脚本"
        return 1
    fi

    # 检查关键脚本文件
    local required_files=(
        "$scripts_dir/common.sh"
        "$scripts_dir/system/time-sync.sh"
        "$scripts_dir/shell/zsh-core-install.sh"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "缺少必需文件: $file"
            return 1
        fi
    done

    log_info "本地脚本验证通过"
    return 0
}

# =============================================================================
# 工具函数
# =============================================================================

# 显示脚本头部信息
show_header() {
    clear
    # 安全地使用颜色变量，如果未定义则使用空字符串
    local blue_color="${BLUE:-}"
    local cyan_color="${CYAN:-}"
    local yellow_color="${YELLOW:-}"
    local reset_color="${RESET:-}"

    echo -e "${blue_color}================================================================${reset_color}"
    echo -e "${blue_color}Ubuntu/Debian服务器安装脚本 - 菜单入口${reset_color}"
    echo -e "${blue_color}版本: 2.0${reset_color}"
    echo -e "${blue_color}作者: saul${reset_color}"
    echo -e "${blue_color}邮箱: sau1amaranth@gmail.com${reset_color}"
    echo -e "${blue_color}================================================================${reset_color}"
    echo
    echo -e "${cyan_color}本脚本提供模块化的安装选项菜单${reset_color}"
    echo -e "${cyan_color}支持Ubuntu 20-24和Debian 10-12，x64和ARM64架构${reset_color}"
    echo
    echo -e "${yellow_color}📋 使用方法：${reset_color}"
    echo -e "${yellow_color}   1. git clone https://github.com/sau1g0dman/scripts-for-linux.git${reset_color}"
    echo -e "${yellow_color}   2. cd scripts-for-linux${reset_color}"
    echo -e "${yellow_color}   3. bash install.sh${reset_color}"
    echo
    echo -e "${yellow_color}⚠️  注意：本脚本不会自动安装任何软件${reset_color}"
    echo -e "${yellow_color}   所有安装操作都需要您的明确选择和确认${reset_color}"
    echo
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."

    # 检查操作系统
    if [ ! -f /etc/os-release ]; then
        log_error "无法检测操作系统版本"
        exit 1
    fi

    . /etc/os-release

    case "$ID" in
        ubuntu)
            case "$VERSION_ID" in
                "20.04"|"22.04"|"22.10"|"24.04")
                    log_info "检测到支持的Ubuntu版本: $VERSION_ID"
                    ;;
                *)
                    log_warn "检测到Ubuntu版本: $VERSION_ID，可能不完全兼容"
                    ;;
            esac
            ;;
        debian)
            case "$VERSION_ID" in
                "10"|"11"|"12")
                    log_info "检测到支持的Debian版本: $VERSION_ID"
                    ;;
                *)
                    log_warn "检测到Debian版本: $VERSION_ID，可能不完全兼容"
                    ;;
            esac
            ;;
        *)
            log_error "不支持的操作系统: $ID"
            log_error "本脚本仅支持Ubuntu 20-24和Debian 10-12"
            exit 1
            ;;
    esac

    # 检查架构
    local arch=$(uname -m)
    case "$arch" in
        x86_64|aarch64|armv7l)
            log_info "检测到支持的架构: $arch"
            ;;
        *)
            log_warn "检测到架构: $arch，可能不完全兼容"
            ;;
    esac

    # 检查网络连接
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl未安装，正在安装..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y curl
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y curl
        else
            log_error "无法自动安装curl，请手动安装后重试"
            exit 1
        fi
    fi

    if ! curl -sSL -I --connect-timeout 5 --max-time 10 https://github.com/robots.txt >/dev/null 2>&1; then
        log_warn "网络连接失败，无法访问GitHub"
        log_warn "某些功能可能无法正常工作，建议检查网络连接"

        # 使用标准化的交互式确认
        if interactive_ask_confirmation "网络连接失败，是否继续安装？" "false"; then
            log_info "用户选择继续安装"
        else
            log_info "用户选择退出安装"
            exit 1
        fi
    fi

    log_info "系统要求检查通过"
}



# 创建安装选项菜单数组
create_install_menu_options() {
    INSTALL_MENU_OPTIONS=(
        "常用软件安装 - 14个基础工具包（curl, git, vim, htop等）"
        "系统配置 - 时间同步配置"
        "ZSH环境 - ZSH、Oh My Zsh、主题插件"
        "开发工具 - Neovim、LazyVim、Git工具"
        "安全配置 - SSH配置、密钥管理"
        "Docker环境 - Docker、Docker Compose、管理工具"
        "软件源管理 - 系统软件源、Docker源、镜像加速器"
        "全部安装 - 逐个确认安装所有组件（推荐）"
        "自定义安装 - 与全部安装相同，逐个选择组件"
        "退出 - 退出安装程序"
    )
}

# 执行本地脚本
execute_local_script() {
    local script_path=$1
    local script_name=$2
    local script_file="$SCRIPT_DIR/scripts/$script_path"

    log_info "开始执行: $script_name"
    log_debug "脚本路径: $script_file"

    # 检查脚本文件是否存在
    if [ ! -f "$script_file" ]; then
        log_error "脚本文件不存在: $script_file"
        return 1
    fi

    # 检查脚本是否可执行
    if [ ! -r "$script_file" ]; then
        log_error "脚本文件不可读: $script_file"
        return 1
    fi

    # 设置详细日志级别
    export LOG_LEVEL=0  # 启用DEBUG级别日志

    # 执行本地脚本
    log_info "执行本地脚本..."

    # 临时禁用错误处理，手动处理退出码
    set +e
    (
        # 在子shell中执行脚本，避免exit语句影响主脚本
        bash "$script_file"
    )
    local exit_code=$?
    set -e

    if [ $exit_code -eq 0 ]; then
        log_info "$script_name 执行成功"
        return 0
    else
        log_error "$script_name 执行失败 (退出码: $exit_code)"
        log_error "请检查上述错误信息以了解失败原因"
        return $exit_code
    fi
}

# 向后兼容的别名函数
execute_remote_script() {
    execute_local_script "$@"
}

# =============================================================================
# 模块化安装函数 - 调用独立脚本
# =============================================================================

# 安装常用软件（调用独立脚本）
install_common_software() {
    execute_local_script "software/common-software-install.sh" "常用软件安装"
}



# 安装系统配置
install_system_config() {
    execute_local_script "system/time-sync.sh" "时间同步配置"
}

# 安装ZSH环境
install_zsh_environment() {
    log_info "开始安装ZSH环境..."

    local arch=$(uname -m)
    local install_success=true

    case "$arch" in
        aarch64|armv7l)
            log_info "检测到ARM架构，使用ARM专用脚本"
            execute_local_script "shell/zsh-arm.sh" "ARM版ZSH环境"
            ;;
        *)
            log_info "检测到x86_64架构，使用模块化安装脚本"

            # 步骤1: 安装ZSH核心环境
            log_info "步骤1: 安装ZSH核心环境..."
            if ! execute_local_script "shell/zsh-core-install.sh" "ZSH核心环境"; then
                log_error "ZSH核心环境安装失败"
                install_success=false
            fi

            # 步骤2: 安装ZSH插件和工具
            if [ "$install_success" = true ]; then
                log_info "步骤2: 安装ZSH插件和工具..."
                if ! execute_local_script "shell/zsh-plugins-install.sh" "ZSH插件和工具"; then
                    log_warn "ZSH插件安装失败，但核心环境已安装"
                    # 插件安装失败不影响核心功能
                fi
            fi
            ;;
    esac

    # 验证安装结果
    if [ "$install_success" = true ]; then
        # 验证ZSH是否真正安装成功
        if command -v zsh >/dev/null 2>&1; then
            log_info "ZSH环境安装完成并验证成功"
            log_info "   ZSH版本: $(zsh --version 2>/dev/null || echo '已安装')"
            return 0
        else
            log_error "ZSH环境安装脚本执行成功，但ZSH命令不可用"
            return 1
        fi
    else
        log_error "ZSH环境安装失败"
        return 1
    fi
}

# 安装开发工具
install_development_tools() {
    execute_local_script "development/nvim-setup.sh" "Neovim开发环境"
}

# 安装安全配置
install_security_config() {
    execute_local_script "security/ssh-config.sh" "SSH安全配置"

    if interactive_ask_confirmation "是否配置SSH密钥？" "false"; then
        execute_local_script "security/ssh-keygen.sh" "SSH密钥配置"
    fi
}

# 安装Docker环境
install_docker_environment() {
    execute_local_script "containers/docker-install.sh" "Docker环境"
}

# 创建软件源管理菜单数组
create_mirrors_menu_options() {
    MIRRORS_MENU_OPTIONS=(
        "更换系统软件源 - GNU/Linux 系统软件源优化"
        "Docker安装与换源 - 安装Docker并配置国内源"
        "Docker镜像加速器 - 仅更换Docker镜像加速器"
        "全部执行 - 执行上述所有操作"
        "返回主菜单 - 返回主安装菜单"
    )
}

# 更换系统软件源
change_system_mirrors() {
    log_info "使用第三方优化脚本: https://linuxmirrors.cn/main.sh"
    bash <(curl -sSL https://linuxmirrors.cn/main.sh) 2>/dev/null
}

# Docker安装与换源
install_docker_with_mirrors() {
    log_info "使用第三方优化脚本: https://linuxmirrors.cn/docker.sh"
    bash <(curl -sSL https://linuxmirrors.cn/docker.sh) 2>/dev/null
}

# Docker镜像加速器配置
configure_docker_registry() {
    log_info "使用第三方优化脚本: https://linuxmirrors.cn/docker.sh --only-registry"
    bash <(curl -sSL https://linuxmirrors.cn/docker.sh) --only-registry 2>/dev/null
}

# 软件源管理主函数
manage_mirrors() {
    # 创建菜单选项
    create_mirrors_menu_options

    while true; do
        echo
        echo -e "${BLUE}================================================================${RESET}"
        echo -e "${BLUE}软件源管理选项${RESET}"
        echo -e "${BLUE}================================================================${RESET}"
        echo

        # 使用键盘导航菜单选择
        select_menu "MIRRORS_MENU_OPTIONS" "请选择软件源管理操作：" 0  # 默认选择第一项

        local selected_index=$MENU_SELECT_INDEX

        case $selected_index in
            0)  # 更换系统软件源
                change_system_mirrors
                ;;
            1)  # Docker安装与换源
                install_docker_with_mirrors
                ;;
            2)  # Docker镜像加速器
                configure_docker_registry
                ;;
            3)  # 全部执行
                log_info "执行全部软件源管理操作..."
                echo
                change_system_mirrors
                echo
                install_docker_with_mirrors
                echo
                configure_docker_registry
                ;;
            4)  # 返回主菜单
                log_info "返回主菜单"
                return 0
                ;;
            *)
                log_warn "无效选择，请重新选择"
                continue
                ;;
        esac

        echo
        if interactive_ask_confirmation "是否继续其他软件源管理操作？" "false"; then
            continue
        else
            log_info "返回主菜单"
            return 0
        fi
    done
}

# 全部安装（逐个确认）
install_all() {
    log_info "全部安装模式 - 将逐个确认每个组件的安装"
    echo
    echo -e "${YELLOW}注意：全部安装模式会逐个询问每个组件，您可以选择跳过不需要的组件${RESET}"
    echo

    if interactive_ask_confirmation "是否安装常用软件？" "true"; then
        install_common_software
    fi

    if interactive_ask_confirmation "是否安装系统配置？" "true"; then
        install_system_config
    fi

    if interactive_ask_confirmation "是否安装ZSH环境？" "true"; then
        install_zsh_environment
    fi

    if interactive_ask_confirmation "是否安装开发工具？" "false"; then
        install_development_tools
    fi

    if interactive_ask_confirmation "是否安装安全配置？" "true"; then
        install_security_config
    fi

    if interactive_ask_confirmation "是否安装Docker环境？" "false"; then
        install_docker_environment
    fi

    if interactive_ask_confirmation "是否进行软件源管理？" "false"; then
        manage_mirrors
    fi

    log_info "全部安装流程完成"
}

# 自定义安装（与全部安装相同，保持向后兼容）
custom_install() {
    install_all
}

# 主安装流程
main_install() {
    # 创建菜单选项
    create_install_menu_options

    while true; do
        echo
        echo -e "${BLUE}================================================================${RESET}"
        echo -e "${BLUE}Ubuntu/Debian服务器安装脚本 - 主菜单${RESET}"
        echo -e "${BLUE}================================================================${RESET}"
        echo

        # 使用键盘导航菜单选择
        select_menu "INSTALL_MENU_OPTIONS" "请选择要安装的组件：" 7  # 默认选择"全部安装"

        local selected_index=$MENU_SELECT_INDEX

        case $selected_index in
            0)  # 常用软件安装
                install_common_software
                ;;
            1)  # 系统配置
                install_system_config
                ;;
            2)  # ZSH环境
                install_zsh_environment
                ;;
            3)  # 开发工具
                install_development_tools
                ;;
            4)  # 安全配置
                install_security_config
                ;;
            5)  # Docker环境
                install_docker_environment
                ;;
            6)  # 软件源管理
                manage_mirrors
                ;;
            7)  # 全部安装
                install_all
                ;;
            8)  # 自定义安装
                custom_install
                ;;
            9)  # 退出
                log_info "退出安装程序"
                exit 0
                ;;
            *)
                log_warn "无效选择，请重新选择"
                continue
                ;;
        esac

        # 安装完成后询问是否继续
        echo
        if interactive_ask_confirmation "是否返回主菜单继续其他操作？" "true"; then
            continue
        else
            log_info "安装程序结束"
            break
        fi
    done
}


# 显示完成信息
show_completion() {
    echo
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${GREEN}安装完成！${RESET}"
    echo -e "${GREEN}================================================================${RESET}"
    echo
    echo -e "${CYAN}后续步骤：${RESET}"
    echo "1. 重新登录以使配置生效"
    echo "2. 运行 'exec zsh' 切换到ZSH（如果安装了ZSH）"
    echo "3. 运行 'p10k configure' 配置Powerlevel10k主题"
    echo "4. 查看项目文档了解更多功能"
    echo
    echo -e "${CYAN}项目地址：${RESET}https://github.com/sau1g0dman/scripts-for-linux"
    echo -e "${CYAN}问题反馈：${RESET}sau1amaranth@gmail.com"
    echo
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    # 显示头部信息
    show_header

    # 检查系统要求
    check_system_requirements

    # 验证本地脚本
    if ! verify_local_scripts; then
        log_error "本地脚本验证失败，安装终止"
        log_error "请确保在项目根目录中运行此脚本"
        exit 1
    fi

    # 使用标准化的交互式确认
    if interactive_ask_confirmation "是否继续安装？" "true"; then
        log_info "用户确认继续安装"
    else
        log_info "用户取消安装"
        exit 0
    fi

    # 开始安装
    main_install

    # 显示完成信息
    show_completion
}

# 脚本入口点
# 安全检查 BASH_SOURCE 是否存在，兼容 curl | bash 执行方式
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
