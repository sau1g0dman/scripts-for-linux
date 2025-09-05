#!/bin/bash

# =============================================================================
# Neovim开发环境安装配置脚本
# 作者: saul
# 版本: 2.0
# 描述: 自动安装Neovim并配置各种开发环境（AstroNvim、LazyVim、NvChad等）
# 支持交互式确认选择器
# =============================================================================

set -euo pipefail

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
        echo "错误：无法加载通用函数库，使用内置函数"
        USE_BUILTIN_FUNCTIONS=true
    fi
fi

# 如果无法加载通用函数库，使用内置的颜色定义
if [[ "${USE_BUILTIN_FUNCTIONS:-false}" == "true" ]]; then
    readonly COLOR_GREEN='\033[32m'
    readonly COLOR_RED='\033[31m'
    readonly COLOR_BLUE='\033[34m'
    readonly COLOR_YELLOW='\033[33m'
    readonly COLOR_CYAN='\033[36m'
    readonly COLOR_RESET='\033[0m'
fi

# 内置日志函数（仅在无法加载通用函数库时使用）
if [[ "${USE_BUILTIN_FUNCTIONS:-false}" == "true" ]]; then
    log_info() {
        echo -e "${COLOR_CYAN}[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1${COLOR_RESET}"
    }

    log_warn() {
        echo -e "${COLOR_YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${COLOR_RESET}"
    }

    log_error() {
        echo -e "${COLOR_RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${COLOR_RESET}"
    }

    log_success() {
        echo -e "${COLOR_GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1${COLOR_RESET}"
    }

    # 内置确认函数
    ask_confirmation() {
        local message=$1
        local default=${2:-"n"}

        while true; do
            if [ "$default" = "y" ]; then
                echo -e "${COLOR_GREEN}$message [Y/n]: ${COLOR_RESET}" | tr -d '\n'
                read choice
                choice=${choice:-y}
            else
                echo -e "${COLOR_GREEN}$message [y/N]: ${COLOR_RESET}" | tr -d '\n'
                read choice
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
                    echo -e "${COLOR_YELLOW}请输入 y 或 n${COLOR_RESET}"
                    ;;
            esac
        done
    }
fi

# 错误处理函数
handle_error() {
    local line_number=$1
    local error_code=${2:-$?}

    # 只有在真正的错误情况下才处理（退出码非0）
    if [ $error_code -ne 0 ]; then
        log_error "脚本在第 $line_number 行发生错误 (退出码: $error_code)"
        log_error "错误详情："
        log_error "  - 行号: $line_number"
        log_error "  - 退出码: $error_code"
        log_error "  - 当前工作目录: $(pwd)"
        log_error "  - 当前用户: $(whoami)"
        log_error "请检查上述错误信息以了解失败原因"

        # 提供调试建议
        log_error "调试建议："
        log_error "  1. 检查网络连接是否正常"
        log_error "  2. 确认有足够的磁盘空间"
        log_error "  3. 验证用户权限是否充足"
        log_error "  4. 查看系统日志获取更多信息"

        exit $error_code
    else
        # 记录误触发的情况，但不输出错误信息
        log_debug "ERR trap triggered with exit code 0 at line $line_number - ignoring"
        return 0
    fi
}

# 设置错误处理
trap 'handle_error $LINENO $?' ERR



# 显示脚本头部信息
show_header() {
    clear
    echo -e "${COLOR_BLUE}================================================================${COLOR_RESET}"
    echo -e "${COLOR_GREEN} 欢迎使用 Neovim开发环境自动安装配置脚本${COLOR_RESET}"
    echo -e "${COLOR_GREEN} 作者: saul${COLOR_RESET}"
    echo -e "${COLOR_GREEN} 邮箱: sau1amaranth@gmail.com${COLOR_RESET}"
    echo -e "${COLOR_GREEN} 版本: 1.0${COLOR_RESET}"
    echo -e "${COLOR_GREEN} 本脚本将帮助您自动安装Neovim并配置各种开发环境${COLOR_RESET}"
    echo -e "${COLOR_BLUE}================================================================${COLOR_RESET}"
    echo
}

# 安装Neovim
install_nvim() {
    log_info "开始安装Neovim..."

    # 检查是否已安装
    if command -v nvim >/dev/null 2>&1; then
        log_info "Neovim已安装，版本: $(nvim --version | head -1)"
        if interactive_ask_confirmation "是否重新安装Neovim？" "false"; then
            log_info "继续重新安装Neovim..."
        else
            log_info "跳过Neovim安装"
            return 0
        fi
    fi

    # 下载Neovim
    log_info "下载Neovim最新版本..."
    if ! curl -fsSL -o nvim-linux64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz; then
        log_error "下载Neovim失败"
        return 1
    fi

    # 安装Neovim
    log_info "安装Neovim到/opt目录..."
    sudo rm -rf /opt/nvim /opt/nvim-linux64 2>/dev/null || true
    if ! sudo tar -C /opt -xzf nvim-linux64.tar.gz; then
        log_error "解压Neovim失败"
        rm -f nvim-linux64.tar.gz
        return 1
    fi
    rm -f nvim-linux64.tar.gz

    # 安装依赖包
    log_info "安装必要的依赖包..."
    local packages=("python3-venv" "unzip" "npm" "build-essential")
    for package in "${packages[@]}"; do
        if ! sudo apt install -y "$package"; then
            log_warn "安装 $package 失败，但继续安装过程"
        fi
    done

    # 添加到环境变量
    local nvim_path='export PATH="$PATH:/opt/nvim-linux64/bin"'
    local shell_files=("$HOME/.zshrc" "$HOME/.bashrc")

    for shell_file in "${shell_files[@]}"; do
        if [ -f "$shell_file" ]; then
            if ! grep -qF -- "$nvim_path" "$shell_file"; then
                echo "$nvim_path" >> "$shell_file"
                log_info "已将Neovim添加到 $shell_file"
            else
                log_info "Neovim路径已存在于 $shell_file"
            fi
        fi
    done

    # 验证安装
    export PATH="$PATH:/opt/nvim-linux64/bin"
    if command -v nvim >/dev/null 2>&1; then
        log_success "Neovim安装成功，版本: $(nvim --version | head -1)"
    else
        log_error "Neovim安装验证失败"
        return 1
    fi

    # 安装LazyGit
    install_lazygit
}

# 安装LazyGit
install_lazygit() {
    log_info "开始安装LazyGit..."

    # 检查是否已安装
    if command -v lazygit >/dev/null 2>&1; then
        log_info "LazyGit已安装，版本: $(lazygit --version | head -1)"
        return 0
    fi

    # 获取最新版本
    log_info "获取LazyGit最新版本信息..."
    local lazygit_version
    if ! lazygit_version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*'); then
        log_error "获取LazyGit版本信息失败"
        return 1
    fi

    log_info "下载LazyGit v$lazygit_version..."
    if ! curl -fsSL -o lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lazygit_version}_Linux_x86_64.tar.gz"; then
        log_error "下载LazyGit失败"
        return 1
    fi

    # 解压并安装
    if tar xf lazygit.tar.gz lazygit && sudo install lazygit /usr/local/bin; then
        log_success "LazyGit安装成功"
        rm -f lazygit.tar.gz lazygit
        return 0
    else
        log_error "LazyGit安装失败"
        rm -f lazygit.tar.gz lazygit
        return 1
    fi
}

# 注意：ask_confirmation 函数已移除，现在使用 common.sh 中的 interactive_ask_confirmation
# 安装Ultra Vimrc
install_ultra_vimrc() {
    log_info "开始安装Ultra Vimrc..."

    # 检查是否已安装
    if [ -d ~/.vim_runtime ]; then
        log_info "Ultra Vimrc已安装"
        if interactive_ask_confirmation "是否重新安装Ultra Vimrc？" "false"; then
            log_info "删除现有安装..."
            rm -rf ~/.vim_runtime
        else
            log_info "跳过Ultra Vimrc安装"
            return 0
        fi
    fi

    # 克隆仓库
    log_info "克隆Ultra Vimrc仓库..."
    if ! git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime; then
        log_error "克隆Ultra Vimrc仓库失败"
        return 1
    fi

    # 执行安装脚本
    log_info "执行Ultra Vimrc安装脚本..."
    if sh ~/.vim_runtime/install_awesome_vimrc.sh; then
        log_success "Ultra Vimrc安装成功"
        return 0
    else
        log_error "Ultra Vimrc安装失败"
        return 1
    fi
}

# 安装开发工具链
install_development_tools() {
    log_info "开始安装开发工具链..."

    local packages=("build-essential" "clang" "cmake" "pkg-config")
    local failed_packages=()

    for package in "${packages[@]}"; do
        log_info "安装 $package..."
        if sudo apt install -y "$package"; then
            log_success "$package 安装成功"
        else
            log_error "$package 安装失败"
            failed_packages+=("$package")
        fi
    done

    if [ ${#failed_packages[@]} -eq 0 ]; then
        log_success "所有开发工具安装成功"
        return 0
    else
        log_warn "以下工具安装失败: ${failed_packages[*]}"
        return 1
    fi
}

# 安装AstroNvim
install_astronvim() {
    log_info "开始安装AstroNvim..."

    # 备份现有配置
    backup_nvim_config "AstroNvim"

    # 克隆AstroNvim模板
    log_info "克隆AstroNvim模板..."
    if ! git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim; then
        log_error "克隆AstroNvim模板失败"
        restore_nvim_config
        return 1
    fi

    # 清理git信息
    rm -rf ~/.config/nvim/.git

    log_success "AstroNvim安装成功"
    log_info "请运行 'nvim' 来完成插件安装"
    return 0
}
# 安装LazyVim
install_lazyvim() {
    log_info "开始安装LazyVim..."

    # 备份现有配置
    backup_nvim_config "LazyVim"

    # 克隆LazyVim启动模板
    log_info "克隆LazyVim启动模板..."
    if ! git clone https://github.com/LazyVim/starter ~/.config/nvim; then
        log_error "克隆LazyVim模板失败"
        restore_nvim_config
        return 1
    fi

    # 清理git信息
    rm -rf ~/.config/nvim/.git

    log_success "LazyVim安装成功"
    log_info "请运行 'nvim' 来完成插件安装"
    return 0
}

# 备份Neovim配置
backup_nvim_config() {
    local config_name=${1:-"backup"}
    local timestamp=$(date +%Y%m%d_%H%M%S)

    log_info "备份现有Neovim配置..."

    # 备份配置目录
    [ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.${config_name}.${timestamp}.bak
    [ -d ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.${config_name}.${timestamp}.bak
    [ -d ~/.local/state/nvim ] && mv ~/.local/state/nvim ~/.local/state/nvim.${config_name}.${timestamp}.bak
    [ -d ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim.${config_name}.${timestamp}.bak

    log_info "配置备份完成，时间戳: $timestamp"
}

# 恢复Neovim配置
restore_nvim_config() {
    log_info "恢复Neovim配置..."

    # 查找最新的备份
    local latest_config=$(find ~/.config -maxdepth 1 -name "nvim.*.bak" -type d | sort | tail -1)
    local latest_share=$(find ~/.local/share -maxdepth 1 -name "nvim.*.bak" -type d | sort | tail -1)
    local latest_state=$(find ~/.local/state -maxdepth 1 -name "nvim.*.bak" -type d | sort | tail -1)
    local latest_cache=$(find ~/.cache -maxdepth 1 -name "nvim.*.bak" -type d | sort | tail -1)

    # 删除当前配置
    rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim

    # 恢复备份
    [ -n "$latest_config" ] && mv "$latest_config" ~/.config/nvim
    [ -n "$latest_share" ] && mv "$latest_share" ~/.local/share/nvim
    [ -n "$latest_state" ] && mv "$latest_state" ~/.local/state/nvim
    [ -n "$latest_cache" ] && mv "$latest_cache" ~/.cache/nvim

    log_info "配置恢复完成"
}

# 卸载Neovim配置
uninstall_nvim_configs() {
    log_info "开始卸载Neovim配置..."

    if interactive_ask_confirmation "是否备份现有配置？" "true"; then
        backup_nvim_config "uninstall"
    else
        log_warn "删除现有配置（不备份）..."
        rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
    fi

    log_success "Neovim配置卸载完成"
}

# 克隆AstroNvim官方模板
clone_astronvim_template() {
    log_info "开始克隆AstroNvim官方模板..."

    # 检查目标目录
    if [ -d ~/.config/nvim ]; then
        log_warn "检测到现有Neovim配置"
        if interactive_ask_confirmation "是否备份现有配置？" "true"; then
            backup_nvim_config "template"
        else
            rm -rf ~/.config/nvim
        fi
    fi

    # 克隆模板
    log_info "克隆AstroNvim模板..."
    if git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim; then
        rm -rf ~/.config/nvim/.git
        log_success "AstroNvim模板克隆成功"
        return 0
    else
        log_error "AstroNvim模板克隆失败"
        return 1
    fi
}

# 安装NvChad
install_nvchad() {
    log_info "开始安装NvChad..."

    # 备份现有配置
    backup_nvim_config "NvChad"

    # 克隆NvChad启动模板
    log_info "克隆NvChad启动模板..."
    if git clone https://github.com/NvChad/starter ~/.config/nvim; then
        rm -rf ~/.config/nvim/.git
        log_success "NvChad安装成功"
        log_info "请运行 'nvim' 来完成插件安装"
        return 0
    else
        log_error "NvChad安装失败"
        restore_nvim_config
        return 1
    fi
}

# 创建菜单选项数组
create_nvim_menu_options() {
    NVIM_MENU_OPTIONS=(
        "安装Neovim - 包含LazyGit和开发工具"
        "安装NvChad配置 - 现代化Neovim配置"
        "安装AstroNvim配置 - 功能丰富的配置方案"
        "安装LazyVim配置 - 轻量级配置方案"
        "克隆AstroNvim模板 - 官方配置模板"
        "卸载Neovim配置 - 清理所有配置文件"
        "安装Ultra Vimrc - 传统Vim配置"
        "退出 - 退出安装程序"
    )
}

# 主函数
main() {
    # 显示头部信息
    show_header

    # 检查系统要求
    log_info "检查系统要求..."
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git未安装，请先安装Git"
        exit 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl未安装，请先安装curl"
        exit 1
    fi

    # 创建菜单选项
    create_nvim_menu_options

    # 主循环
    while true; do
        echo
        echo -e "${COLOR_BLUE}================================================================${COLOR_RESET}"
        echo -e "${COLOR_BLUE}Neovim开发环境配置脚本${COLOR_RESET}"
        echo -e "${COLOR_BLUE}================================================================${COLOR_RESET}"
        echo

        # 使用键盘导航菜单选择
        select_menu "NVIM_MENU_OPTIONS" "请选择要执行的操作：" 0  # 默认选择第一项

        local selected_index=$MENU_SELECT_INDEX

        case $selected_index in
            0)  # 安装Neovim
                log_info "开始安装Neovim完整环境..."
                install_nvim && install_development_tools
                ;;
            1)  # 安装NvChad配置
                log_info "开始安装NvChad配置..."
                install_nvchad
                ;;
            2)  # 安装AstroNvim配置
                log_info "开始安装AstroNvim配置..."
                install_astronvim
                ;;
            3)  # 安装LazyVim配置
                log_info "开始安装LazyVim配置..."
                install_lazyvim
                ;;
            4)  # 克隆AstroNvim模板
                log_info "开始克隆AstroNvim官方模板..."
                clone_astronvim_template
                ;;
            5)  # 卸载Neovim配置
                log_info "开始卸载Neovim配置..."
                uninstall_nvim_configs
                ;;
            6)  # 安装Ultra Vimrc
                log_info "开始安装Ultra Vimrc..."
                install_ultra_vimrc
                ;;
            7)  # 退出
                log_info "退出程序"
                exit 0
                ;;
            *)
                log_warn "无效选择，请重新选择"
                continue
                ;;
        esac

        echo
        if interactive_ask_confirmation "是否继续其他操作？" "false"; then
            continue
        else
            log_info "程序结束"
            break
        fi
    done
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
