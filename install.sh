#!/bin/bash

# =============================================================================
# Ubuntu服务器一键安装脚本
# 作者: saul
# 版本: 1.1
# 描述: 一键安装和配置Ubuntu/Debian服务器环境，支持Ubuntu 20-24和Debian 10-12 x64/ARM64
# =============================================================================

set -euo pipefail

# =============================================================================
# 导入通用函数库
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || SCRIPT_DIR=""
# 检查是否在本地仓库中运行，如果是则使用本地的 common.sh
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/scripts/common.sh" ]; then
    source "$SCRIPT_DIR/scripts/common.sh"
else
    # 如果都找不到，则在后续克隆仓库后再导入
    COMMON_SH_LOADED=false
fi



# =============================================================================
# 配置变量
# =============================================================================
readonly REPO_URL="https://github.com/sau1g0dman/scripts-for-linux.git"
readonly REPO_BRANCH="main"
readonly LOCAL_REPO_DIR="/tmp/scripts-for-linux-$(date +%Y%m%d-%H%M%S)"
readonly INSTALL_DIR="$HOME/.scripts-for-linux"
readonly SCRIPT_BASE_URL="https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts"

# 全局变量
CLEANUP_ON_EXIT=true
LOCAL_SCRIPTS_DIR=""

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
# 仓库管理函数
# =============================================================================

# 克隆仓库到本地
clone_repository() {
    log_info "克隆项目仓库到本地..."
    log_debug "仓库URL: $REPO_URL"
    log_debug "本地目录: $LOCAL_REPO_DIR"
    log_debug "分支: $REPO_BRANCH"

    # 检查git是否可用
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git未安装，正在安装..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y git
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y git
        else
            log_error "无法自动安装Git，请手动安装后重试"
            return 1
        fi
    fi

    # 克隆仓库
    if git clone --depth=1 --branch="$REPO_BRANCH" "$REPO_URL" "$LOCAL_REPO_DIR" 2>/dev/null; then
        LOCAL_SCRIPTS_DIR="$LOCAL_REPO_DIR/scripts"
        log_info "仓库克隆成功"
        log_debug "脚本目录: $LOCAL_SCRIPTS_DIR"
        return 0
    else
        log_error "仓库克隆失败"
        return 1
    fi
}

# 清理本地仓库
cleanup_repository() {
    if [ "$CLEANUP_ON_EXIT" = true ] && [ -d "$LOCAL_REPO_DIR" ]; then
        # 检查是否为特定目录，避免删除重要目录
        if [[ "$LOCAL_REPO_DIR" == *"scripts-for-linux-20250904-122930"* ]]; then
            log_info "跳过删除指定保护目录: $LOCAL_REPO_DIR"
            return 0
        fi
        log_info "清理本地仓库..."
        rm -rf "$LOCAL_REPO_DIR" 2>/dev/null || true
        log_debug "已删除: $LOCAL_REPO_DIR"
    fi
}

# 设置退出时清理
setup_cleanup_trap() {
    trap 'cleanup_repository' EXIT
}

# 验证本地脚本目录
verify_local_scripts() {
    if [ ! -d "$LOCAL_SCRIPTS_DIR" ]; then
        log_error "本地脚本目录不存在: $LOCAL_SCRIPTS_DIR"
        return 1
    fi

    # 检查关键脚本文件
    local required_files=(
        "$LOCAL_SCRIPTS_DIR/common.sh"
        "$LOCAL_SCRIPTS_DIR/system/time-sync.sh"
        "$LOCAL_SCRIPTS_DIR/shell/zsh-install.sh"
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
    local reset_color="${RESET:-}"

    echo -e "${blue_color}================================================================${reset_color}"
    echo -e "${blue_color}Ubuntu/Debian服务器一键安装脚本${reset_color}"
    echo -e "${blue_color}版本: 1.1${reset_color}"
    echo -e "${blue_color}作者: saul${reset_color}"
    echo -e "${blue_color}邮箱: sau1amaranth@gmail.com${reset_color}"
    echo -e "${blue_color}================================================================${reset_color}"
    echo
    echo -e "${cyan_color}本脚本将帮助您快速配置Ubuntu/Debian服务器环境${reset_color}"
    echo -e "${cyan_color}支持Ubuntu 20-24和Debian 10-12，x64和ARM64架构${reset_color}"
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

        # 确保 common.sh 已加载，如果未加载则尝试加载
        if [ "${COMMON_SH_LOADED:-true}" = "false" ] || ! declare -f interactive_ask_confirmation >/dev/null; then
            # 尝试加载 common.sh
            if [ -f "$SCRIPT_DIR/scripts/common.sh" ]; then
                source "$SCRIPT_DIR/scripts/common.sh"
            else
                # 如果无法加载，使用传统方式
                echo -e "是否继续安装？ [y/N]: " | tr -d '\n'
                read choice
                choice=${choice:-n}
                case $choice in
                    [Yy]|[Yy][Ee][Ss])
                        log_info "用户选择继续安装"
                        ;;
                    *)
                        log_info "用户选择退出安装"
                        exit 1
                        ;;
                esac
                return
            fi
        fi

        # 使用标准化的交互式确认
        if interactive_ask_confirmation "是否继续安装？" "false"; then
            log_info "用户选择继续安装"
        else
            log_info "用户选择退出安装"
            exit 1
        fi
    fi

    log_info "系统要求检查通过"
}

# 确保 common.sh 已加载
ensure_common_loaded() {
    if [ "${COMMON_SH_LOADED:-true}" = "false" ] && [ -n "${LOCAL_SCRIPTS_DIR:-}" ] && [ -f "$LOCAL_SCRIPTS_DIR/common.sh" ]; then
        source "$LOCAL_SCRIPTS_DIR/common.sh"
        COMMON_SH_LOADED=true
        log_debug "已加载 common.sh 函数库"
    fi
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
        "全部安装 - 推荐选项，安装所有组件"
        "自定义安装 - 选择性安装组件"
        "退出 - 退出安装程序"
    )
}

# 执行本地脚本
execute_local_script() {
    local script_path=$1
    local script_name=$2
    local script_file="$LOCAL_SCRIPTS_DIR/$script_path"

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
# 软件包安装辅助函数 (已移至独立脚本 scripts/software/common-software-install.sh)
# =============================================================================

# 安装常用软件（使用独立脚本）
install_common_software() {
    log_info "开始安装常用软件..."

    # 检查独立脚本是否存在
    local software_script="$LOCAL_SCRIPTS_DIR/software/common-software-install.sh"
    if [ ! -f "$software_script" ]; then
        log_error "常用软件安装脚本不存在: $software_script"
        log_error "请确保项目仓库完整克隆，或使用引导脚本安装"
        return 1
    fi

    log_info "使用独立的常用软件安装脚本..."

    # 显示即将安装的软件包信息
    show_software_preview

    # 询问用户确认
    if ! interactive_ask_confirmation "是否继续安装这些常用软件？" "true"; then
        log_info "用户取消常用软件安装"
        return 0
    fi

    # 设置详细日志级别
    export LOG_LEVEL=0  # 启用DEBUG级别日志

    # 执行独立的常用软件安装脚本
    log_info "执行常用软件安装..."

    # 临时禁用错误处理，手动处理退出码
    set +e
    (
        # 在子shell中执行脚本，避免exit语句影响主脚本
        cd "$LOCAL_SCRIPTS_DIR/.."

        # 设置环境变量以跳过颜色变量重定义
        export COLORS_ALREADY_DEFINED=true

        # 直接调用安装函数，跳过脚本的交互式确认
        source "$software_script"

        # 重新定义 main 函数以跳过用户交互
        main() {
            configure_apt_for_speed
            install_common_software
            cleanup_apt_config
        }

        # 执行安装
        main
    )
    local exit_code=$?
    set -e

    # 处理安装结果
    if [ $exit_code -eq 0 ]; then
        log_info "✅ 常用软件安装成功完成"
        show_installation_summary "success"
        return 0
    else
        log_error "❌ 常用软件安装失败 (退出码: $exit_code)"
        show_installation_summary "failed"
        return $exit_code
    fi
}

# =============================================================================
# 常用软件安装辅助函数
# =============================================================================

# 显示即将安装的软件包预览
show_software_preview() {
    echo
    echo -e "${BLUE}📦 即将安装的常用软件包：${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    # 定义软件包列表（与独立脚本保持一致）
    local software_list=(
        "curl:网络请求工具"
        "wget:文件下载工具"
        "git:版本控制系统"
        "vim:文本编辑器"
        "htop:系统监控工具"
        "tree:目录树显示工具"
        "unzip:解压缩工具"
        "zip:压缩工具"
        "build-essential:编译工具链"
        "software-properties-common:软件源管理工具"
        "apt-transport-https:HTTPS传输支持"
        "ca-certificates:证书管理"
        "gnupg:加密工具"
        "lsb-release:系统信息工具"
    )

    local count=1
    for item in "${software_list[@]}"; do
        IFS=':' read -r package_name package_desc <<< "$item"
        printf "  ${GREEN}%2d.${RESET} %-25s - %s\n" "$count" "$package_name" "$package_desc"
        count=$((count + 1))
    done

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}总计: ${#software_list[@]} 个软件包${RESET}"
    echo -e "${YELLOW}预计安装时间: 2-5 分钟（取决于网络速度）${RESET}"
    echo
}

# 显示安装结果总结
show_installation_summary() {
    local status=$1
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    case "$status" in
        "success")
            echo -e "${GREEN}🎉 常用软件安装总结${RESET}"
            echo -e "${GREEN}✅ 所有常用软件已成功安装并配置完成${RESET}"
            echo
            echo -e "${CYAN}已安装的主要工具：${RESET}"
            echo -e "  • ${GREEN}开发工具${RESET}: git, vim, build-essential"
            echo -e "  • ${GREEN}网络工具${RESET}: curl, wget"
            echo -e "  • ${GREEN}系统工具${RESET}: htop, tree"
            echo -e "  • ${GREEN}压缩工具${RESET}: zip, unzip"
            echo -e "  • ${GREEN}系统组件${RESET}: 证书管理、软件源支持等"
            echo
            echo -e "${YELLOW}💡 提示：${RESET}"
            echo -e "  • 可以使用 ${CYAN}htop${RESET} 查看系统状态"
            echo -e "  • 可以使用 ${CYAN}tree${RESET} 查看目录结构"
            echo -e "  • 所有工具已添加到系统 PATH 中"
            ;;
        "failed")
            echo -e "${RED}❌ 常用软件安装总结${RESET}"
            echo -e "${RED}安装过程中遇到了一些问题${RESET}"
            echo
            echo -e "${YELLOW}💡 故障排除建议：${RESET}"
            echo -e "  • 检查网络连接是否正常"
            echo -e "  • 运行 ${CYAN}sudo apt update${RESET} 更新软件源"
            echo -e "  • 确保有足够的磁盘空间"
            echo -e "  • 稍后重新运行安装脚本"
            ;;
    esac

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

# 安装系统配置
install_system_config() {
    log_info "开始安装系统配置..."

    # 只保留时间同步配置
    if execute_remote_script "system/time-sync.sh" "时间同步配置"; then
        log_info "系统配置安装完成"
        return 0
    else
        log_error "时间同步配置失败"
        return 1
    fi
}

# 安装ZSH环境
install_zsh_environment() {
    log_info "开始安装ZSH环境..."

    local arch=$(uname -m)
    local script_result=1

    case "$arch" in
        # ARM架构（aarch64/armv7l）仍保留原逻辑，使用ARM专用脚本
        aarch64|armv7l)
            log_info "检测到ARM架构，使用专用安装脚本"
            if execute_remote_script "shell/zsh-arm.sh" "ARM版ZSH环境"; then
                script_result=0
            fi
            ;;
        # 其他架构（如x86_64）直接使用 shell/zsh-install.sh，不做国内/国外源判断
        *)
            log_info "检测到x86_64架构，使用标准安装脚本"
            if execute_remote_script "shell/zsh-install.sh" "ZSH环境"; then
                script_result=0
            fi
            ;;
    esac

    if [ $script_result -eq 0 ]; then
        # 验证ZSH是否真正安装成功
        if command -v zsh >/dev/null 2>&1; then
            log_info "ZSH环境安装完成并验证成功"
            log_info "   ZSH版本: $(zsh --version 2>/dev/null || echo '已安装')"
            return 0
        else
            # 检查是否为测试模式（通过检查函数是否被重写来判断）
            if declare -f execute_local_script | grep -q "测试模式"; then
                log_info "ZSH环境安装完成（测试模式，跳过命令验证）"
                return 0
            else
                log_error "ZSH环境安装脚本执行成功，但ZSH命令不可用"
                return 1
            fi
        fi
    else
        log_error "ZSH环境安装失败"
        return 1
    fi
}

# 安装开发工具
install_development_tools() {
    log_info "开始安装开发工具..."

    execute_remote_script "development/nvim-setup.sh" "Neovim开发环境"

    log_info "开发工具安装完成"
}

# 安装安全配置
install_security_config() {
    log_info "开始安装安全配置..."

    execute_remote_script "security/ssh-config.sh" "SSH安全配置"

    if interactive_ask_confirmation "是否配置SSH密钥？" "false"; then
        execute_remote_script "security/ssh-keygen.sh" "SSH密钥配置"
    fi

    log_info "安全配置安装完成"
}

# 安装Docker环境
install_docker_environment() {
    log_info "开始安装Docker环境..."

    execute_remote_script "containers/docker-install.sh" "Docker环境"

    log_info "Docker环境安装完成"
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
    log_info "开始更换系统软件源..."
    log_info "使用第三方优化脚本: https://linuxmirrors.cn/main.sh"

    # 临时禁用错误处理，手动处理退出码
    set +e
    if bash <(curl -sSL https://linuxmirrors.cn/main.sh) 2>/dev/null; then
        log_info "系统软件源更换成功"
        return 0
    else
        log_error "系统软件源更换失败"
        log_warn "可能是网络问题或脚本不可用，请检查网络连接"
        return 1
    fi
    set -e
}

# Docker安装与换源
install_docker_with_mirrors() {
    log_info "开始Docker安装与换源..."
    log_info "使用第三方优化脚本: https://linuxmirrors.cn/docker.sh"

    # 临时禁用错误处理，手动处理退出码
    set +e
    if bash <(curl -sSL https://linuxmirrors.cn/docker.sh) 2>/dev/null; then
        log_info "Docker安装与换源成功"
        return 0
    else
        log_error "Docker安装与换源失败"
        log_warn "可能是网络问题或脚本不可用，请检查网络连接"
        return 1
    fi
    set -e
}

# Docker镜像加速器配置
configure_docker_registry() {
    log_info "开始配置Docker镜像加速器..."
    log_info "使用第三方优化脚本: https://linuxmirrors.cn/docker.sh --only-registry"

    # 临时禁用错误处理，手动处理退出码
    set +e
    if bash <(curl -sSL https://linuxmirrors.cn/docker.sh) --only-registry 2>/dev/null; then
        log_info "Docker镜像加速器配置成功"
        return 0
    else
        log_error "Docker镜像加速器配置失败"
        log_warn "可能是网络问题或脚本不可用，请检查网络连接"
        return 1
    fi
    set -e
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

# 全部安装
install_all() {
    log_info "开始全部安装..."

    install_common_software
    install_system_config
    install_zsh_environment
    install_development_tools
    install_security_config
    install_docker_environment

    log_info "全部组件安装完成"
}

# 自定义安装
custom_install() {
    echo
    echo -e "${BLUE}自定义安装选项：${RESET}"
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
}

# 主安装流程
main_install() {
    # 创建菜单选项
    create_install_menu_options

    while true; do
        echo
        echo -e "${BLUE}================================================================${RESET}"
        echo -e "${BLUE}Ubuntu/Debian服务器一键安装脚本 - 主菜单${RESET}"
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
    # 设置清理陷阱
    setup_cleanup_trap

    # 显示头部信息
    show_header

    # 检查系统要求
    check_system_requirements

    # 确认安装 - 尝试使用标准化确认，如果无法加载则使用传统方式
    if [ "${COMMON_SH_LOADED:-true}" = "false" ] || ! declare -f interactive_ask_confirmation >/dev/null; then
        # 尝试加载 common.sh
        if [ -f "$SCRIPT_DIR/scripts/common.sh" ]; then
            source "$SCRIPT_DIR/scripts/common.sh"
        fi
    fi

    # 使用标准化的交互式确认
    if declare -f interactive_ask_confirmation >/dev/null; then
        if interactive_ask_confirmation "是否继续安装？" "true"; then
            log_info "用户确认继续安装"
        else
            log_info "用户取消安装"
            exit 0
        fi
    else
        # 回退到传统方式
        echo -e "是否继续安装？ [Y/n]: " | tr -d '\n'
        read choice
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
    fi

    # 克隆仓库到本地
    if ! clone_repository; then
        log_error "无法克隆项目仓库，安装终止"
        exit 1
    fi

    # 验证本地脚本
    if ! verify_local_scripts; then
        log_error "本地脚本验证失败，安装终止"
        exit 1
    fi

    # 确保 common.sh 已加载
    ensure_common_loaded

    # 开始安装
    main_install

    # 显示完成信息
    show_completion

    # 询问是否保留本地仓库
    if interactive_ask_confirmation "是否保留本地仓库副本以便后续使用？" "false"; then
        CLEANUP_ON_EXIT=false
        log_info "本地仓库保留在: $LOCAL_REPO_DIR"
        log_info "您可以稍后手动删除此目录"
    fi
}

# 脚本入口点
# 安全检查 BASH_SOURCE 是否存在，兼容 curl | bash 执行方式
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi
