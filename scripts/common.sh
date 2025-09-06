#!/bin/bash

# =============================================================================
# 通用工具函数库
# 作者: saul
# 版本: 1.0
# 描述: 为Ubuntu 20-22服务器初始化脚本提供通用功能
# 支持平台: x64, ARM64
# =============================================================================

# 防重复加载保护
if [[ -n "${COMMON_SH_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
readonly COMMON_SH_LOADED=1

# 检查Bash版本
if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用Bash运行此脚本（当前shell: $0）"
    exit 1
fi

# =============================================================================
# 颜色定义
# =============================================================================
readonly RED=$(printf '\033[31m' 2>/dev/null || echo '')
readonly GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
readonly YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
readonly BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
readonly CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
readonly MAGENTA=$(printf '\033[35m' 2>/dev/null || echo '')
readonly GRAY=$(printf '\033[90m' 2>/dev/null || echo '')
readonly RESET=$(printf '\033[m' 2>/dev/null || echo '')

# =============================================================================
# 日志函数
# =============================================================================

# 日志级别
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

# 当前日志级别（默认INFO）
LOG_LEVEL=${LOG_LEVEL:-$LOG_INFO}



# 标准化日志函数（与install.sh格式一致）
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
    # 只在DEBUG级别时显示
    [ ${LOG_LEVEL:-1} -le $LOG_DEBUG ] && echo -e "${blue_color}[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $1${reset_color}"
}

# 执行命令并记录详细日志
execute_command() {
    local cmd="$1"
    local description="${2:-执行命令}"

    log_info "开始执行: $description"
    log_debug "命令: $cmd"

    # 创建临时文件存储输出
    local temp_output=$(mktemp)
    local temp_error=$(mktemp)

    # 执行命令并捕获输出
    if eval "$cmd" > "$temp_output" 2> "$temp_error"; then
        local exit_code=0
        log_info "[SUCCESS] $description - 成功完成"

        # 显示输出（如果有）
        if [ -s "$temp_output" ]; then
            log_debug "命令输出:"
            while IFS= read -r line; do
                log_debug "  $line"
            done < "$temp_output"
        fi
    else
        local exit_code=$?
        log_error "[ERROR] $description - 执行失败 (退出码: $exit_code)"

        # 显示错误输出
        if [ -s "$temp_error" ]; then
            log_error "错误信息:"
            while IFS= read -r line; do
                log_error "  $line"
            done < "$temp_error"
        fi

        # 显示标准输出（可能包含有用信息）
        if [ -s "$temp_output" ]; then
            log_warn "标准输出:"
            while IFS= read -r line; do
                log_warn "  $line"
            done < "$temp_output"
        fi
    fi

    # 清理临时文件
    rm -f "$temp_output" "$temp_error"

    return $exit_code
}

# 验证命令是否成功安装
verify_command() {
    local cmd="$1"
    local package_name="${2:-$cmd}"

    if command -v "$cmd" >/dev/null 2>&1; then
        local version=$(eval "$cmd --version 2>/dev/null | head -1" || echo "版本信息不可用")
        log_info "[SUCCESS] $package_name 验证成功: $version"
        return 0
    else
        log_error "[ERROR] $package_name 验证失败: 命令 '$cmd' 未找到"
        return 1
    fi
}

# =============================================================================
# 系统检测函数
# =============================================================================

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS=CentOS
        VER=$(cat /etc/redhat-release)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    log_debug "检测到操作系统: $OS $VER"
}

# 检测CPU架构
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="x64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            log_warn "未知的CPU架构: $ARCH"
            ;;
    esac

    log_debug "检测到CPU架构: $ARCH"
}

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
        log_debug "当前用户为root"
    else
        SUDO="sudo"
        log_debug "当前用户非root，将使用sudo"
    fi
}

# =============================================================================
# 网络检测函数
# =============================================================================

# 检查网络连接
check_network() {
    local test_urls=(
        "https://www.baidu.com"
        "https://www.google.com"
        "https://github.com"
    )

    log_info "检查网络连接..."

    for url in "${test_urls[@]}"; do
        if curl -fsSL --connect-timeout 5 --max-time 10 "$url" >/dev/null 2>&1; then
            log_info "网络连接正常 ($url)"
            return 0
        fi
    done

    log_error "网络连接失败，请检查网络设置"
    return 1
}

# 检查DNS解析
check_dns() {
    local test_domain="www.baidu.com"

    if nslookup "$test_domain" >/dev/null 2>&1; then
        log_info "DNS解析正常"
        return 0
    else
        log_error "DNS解析失败"
        return 1
    fi
}

# =============================================================================
# 包管理器函数
# =============================================================================

# 更新包管理器
update_package_manager() {
    log_info "[UPDATE] 开始更新包管理器..."

    if command -v apt >/dev/null 2>&1; then
        execute_command "$SUDO apt update" "更新APT包列表"
    elif command -v yum >/dev/null 2>&1; then
        execute_command "$SUDO yum update -y" "更新YUM包列表"
    elif command -v dnf >/dev/null 2>&1; then
        execute_command "$SUDO dnf update -y" "更新DNF包列表"
    elif command -v pacman >/dev/null 2>&1; then
        execute_command "$SUDO pacman -Sy" "更新Pacman包列表"
    else
        log_error "[ERROR] 未找到支持的包管理器"
        return 1
    fi

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_info "[SUCCESS] 包管理器更新完成"
    else
        log_error "[ERROR] 包管理器更新失败"
    fi
    return $exit_code
}

# 安装包
install_package() {
    local package=$1

    log_info "[INSTALL] 开始安装软件包: $package"

    # 首先检查包是否已安装
    if check_package_installed "$package"; then
        log_info "[SUCCESS] $package 已安装，跳过"
        return 0
    fi

    local install_cmd=""
    if command -v apt >/dev/null 2>&1; then
        install_cmd="$SUDO apt install -y $package"
    elif command -v yum >/dev/null 2>&1; then
        install_cmd="$SUDO yum install -y $package"
    elif command -v dnf >/dev/null 2>&1; then
        install_cmd="$SUDO dnf install -y $package"
    elif command -v pacman >/dev/null 2>&1; then
        install_cmd="$SUDO pacman -S --noconfirm $package"
    else
        log_error "[ERROR] 未找到支持的包管理器"
        return 1
    fi

    if execute_command "$install_cmd" "安装 $package"; then
        # 验证安装是否成功 - 使用多重验证策略
        if verify_package_installation "$package"; then
            log_info "[SUCCESS] $package 安装并验证成功"
            return 0
        else
            log_error "[ERROR] $package 安装后验证失败"
            return 1
        fi
    else
        log_error "[ERROR] $package 安装失败"
        return 1
    fi
}

# 验证软件包安装 - 使用多重策略
verify_package_installation() {
    local package=$1

    log_debug "开始验证软件包安装: $package"

    # 策略1: 检查对应的命令是否可用
    case "$package" in
        "git")
            if command -v git >/dev/null 2>&1; then
                log_debug "命令验证: git 命令可用"
                return 0
            fi
            ;;
        "curl")
            if command -v curl >/dev/null 2>&1; then
                log_debug "命令验证: curl 命令可用"
                return 0
            fi
            ;;
        "wget")
            if command -v wget >/dev/null 2>&1; then
                log_debug "命令验证: wget 命令可用"
                return 0
            fi
            ;;
        "zsh")
            if command -v zsh >/dev/null 2>&1; then
                log_debug "命令验证: zsh 命令可用"
                return 0
            fi
            ;;
        "unzip")
            if command -v unzip >/dev/null 2>&1; then
                log_debug "命令验证: unzip 命令可用"
                return 0
            fi
            ;;
        "fontconfig")
            # fontconfig 通常不提供直接命令，检查配置文件
            if [ -d "/etc/fonts" ] || [ -f "/usr/bin/fc-list" ]; then
                log_debug "文件验证: fontconfig 配置存在"
                return 0
            fi
            ;;
    esac

    # 策略2: 使用包管理器检查
    if check_package_installed "$package"; then
        log_debug "包管理器验证: $package 已安装"
        return 0
    fi

    # 策略3: 对于某些包，检查关键文件是否存在
    case "$package" in
        "fontconfig")
            if [ -f "/usr/bin/fc-cache" ] || [ -f "/usr/bin/fc-list" ]; then
                log_debug "文件验证: fontconfig 工具存在"
                return 0
            fi
            ;;
    esac

    log_debug "所有验证策略都失败: $package"
    return 1
}

# 检查包是否已安装
check_package_installed() {
    local package=$1

    log_debug "检查软件包安装状态: $package"

    if command -v apt >/dev/null 2>&1; then
        # 使用多种方法检查包是否已安装
        if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
            log_debug "dpkg检查: $package 已安装"
            return 0
        elif apt list --installed "$package" 2>/dev/null | grep -q "installed"; then
            log_debug "apt list检查: $package 已安装"
            return 0
        else
            log_debug "包管理器检查: $package 未安装"
            return 1
        fi
    elif command -v yum >/dev/null 2>&1; then
        if yum list installed "$package" >/dev/null 2>&1; then
            log_debug "yum检查: $package 已安装"
            return 0
        else
            log_debug "yum检查: $package 未安装"
            return 1
        fi
    elif command -v dnf >/dev/null 2>&1; then
        if dnf list installed "$package" >/dev/null 2>&1; then
            log_debug "dnf检查: $package 已安装"
            return 0
        else
            log_debug "dnf检查: $package 未安装"
            return 1
        fi
    elif command -v pacman >/dev/null 2>&1; then
        if pacman -Q "$package" >/dev/null 2>&1; then
            log_debug "pacman检查: $package 已安装"
            return 0
        else
            log_debug "pacman检查: $package 未安装"
            return 1
        fi
    else
        log_debug "未找到支持的包管理器"
        return 1
    fi
}

# =============================================================================
# 错误处理函数
# =============================================================================

# 错误处理
handle_error() {
    local exit_code=$?
    local line_number=$1

    log_error "脚本在第 $line_number 行发生错误，退出码: $exit_code"
    exit $exit_code
}

# 设置错误处理
set_error_handling() {
    set -eE  # 遇到错误立即退出，包括管道中的错误
    trap 'handle_error $LINENO' ERR
}

# =============================================================================
# 用户交互函数
# =============================================================================

# 检查是否支持高级交互式选择器
can_use_interactive_selection() {
    if command -v tput >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 高级交互式确认选择器（支持键盘左右键选择）
interactive_ask_confirmation() {
    local message="$1"
    local default="${2:-false}"  # true 或 false
    local selected=0
    local menu_height=3

    # 检查是否在交互式环境中
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        # 非交互式环境，直接返回默认值
        echo -e "$message"
        if [ "$default" = "true" ] || [ "$default" = "y" ]; then
            echo -e "${GREEN:-}▶ 是${RESET:-} (自动选择)"
            return 0
        else
            echo -e "${RED:-}▶ 否${RESET:-} (自动选择)"
            return 1
        fi
    fi

    # 根据默认值设置初始选择
    if [ "$default" = "true" ] || [ "$default" = "y" ]; then
        selected=0  # 默认选择"是"
    else
        selected=1  # 默认选择"否"
    fi

    # 内部函数定义
    local function_definitions='
    function clear_menu() {
        for ((i = 0; i < '"$menu_height"'; i++)); do
            tput cuu1 2>/dev/null
            tput el 2>/dev/null
        done
    }

    function cleanup() {
        clear_menu
        tput cnorm 2>/dev/null
        # 静默处理取消操作，不显示警告信息
        # 设置全局变量表示用户取消，而不是直接退出
        CONFIRMATION_RESULT=false
        return 130
    }

    function draw_menu() {
        echo -e "╭─ '"$message"'"
        echo -e "│"
        if [ "$1" -eq 0 ]; then
            echo -e "╰─ '"${BLUE}"'●'"${RESET}"' 是'"${CYAN}"' / ○ 否'"${RESET}"'"
        else
            echo -e "╰─ '"${CYAN}"'○ 是 / '"${RESET}${BLUE}"'●'"${RESET}"' 否"
        fi
    }

    function read_key() {
        # 检查是否在交互式环境中
        if [ ! -t 0 ]; then
            # 非交互式环境，返回回车键
            echo ""
            return 0
        fi

        IFS= read -rsn1 key
        if [[ $key == $'"'"'\x1b'"'"' ]]; then
            IFS= read -rsn2 key
            key="$key"
        fi
        echo "$key"
    }'

    # 执行交互式选择
    eval "$function_definitions"

    tput civis 2>/dev/null
    # 只在交互式环境中设置trap
    if [ -t 0 ] && [ -t 1 ]; then
        trap "cleanup" INT TERM
    fi
    draw_menu $selected

    while true; do
        key=$(read_key)
        case "$key" in
            "[D" | "a" | "A" | "h" | "H")  # 左箭头或 a/h 键
                if [ "$selected" -gt 0 ]; then
                    selected=$((selected - 1))
                    clear_menu
                    draw_menu $selected
                fi
                ;;
            "[C" | "d" | "D" | "l" | "L")  # 右箭头或 d/l 键
                if [ "$selected" -lt 1 ]; then
                    selected=$((selected + 1))
                    clear_menu
                    draw_menu $selected
                fi
                ;;
            "")  # 回车键
                clear_menu
                break
                ;;
            *) ;;
        esac
    done

    # 显示最终选择结果
    echo -e "╭─ $message"
    echo -e "│"
    if [ "$selected" -eq 0 ]; then
        echo -e "╰─ ${GREEN}●${RESET} ${GREEN}是${RESET}${CYAN} / ○ 否${RESET}"
        tput cnorm 2>/dev/null
        return 0
    else
        echo -e "╰─ ${CYAN}○ 是 / ${RESET}${GREEN}●${RESET} ${GREEN}否${RESET}"
        tput cnorm 2>/dev/null
        return 1
    fi
}





# 高级交互式菜单选择器（支持键盘上下键选择）
interactive_select_menu() {
    local options_array_name="$1"
    local message="$2"
    local default_index=${3:-0}

    # 全局变量存储选择结果
    MENU_SELECT_RESULT=""
    MENU_SELECT_INDEX=-1

    # 获取数组长度的安全方法
    local array_length
    eval "array_length=\${#${options_array_name}[@]}"

    local selected=$default_index
    local start=0
    local page_size=$(($(tput lines 2>/dev/null || echo 20) - 5))

    # 确保选择索引在有效范围内
    if [ $selected -ge $array_length ]; then
        selected=0
    fi
    if [ $selected -lt 0 ]; then
        selected=0
    fi

    # 内部函数定义
    local function_definitions='
    function clear_menu() {
        local with_header=${1:-true}
        local menu_height=$(('$array_length'))
        if [ $menu_height -gt '"$page_size"' ]; then
            menu_height='"$page_size"'
        fi

        # 如果包含标题，需要额外清理3行（标题+说明+空行）
        if [ "$with_header" = "true" ]; then
            menu_height=$((menu_height + 3))
        fi

        for ((i = 0; i < menu_height; i++)); do
            tput cuu1 2>/dev/null || echo -ne "\033[A"
            tput el 2>/dev/null || echo -ne "\033[K"
        done
    }

    function cleanup() {
        clear_menu true
        tput cnorm 2>/dev/null || echo -ne "\033[?25h"
        # 静默处理取消操作，不显示警告信息
        # 设置全局变量表示用户取消，而不是直接退出
        MENU_SELECT_INDEX=-1
        MENU_SELECT_RESULT=""
        return 130
    }

    function draw_menu() {
        local current_selected=$1
        local show_header=${2:-true}

        # 只在第一次显示时显示标题和说明
        if [ "$show_header" = "true" ]; then
            echo -e "'"$message"'"
            echo -e "${CYAN}💡 使用方法：↑↓ 键移动光标，Enter 键确认选择，Ctrl+C 退出${RESET}"
            echo
        fi

        local end=$((start + '"$page_size"' - 3))
        if [ $end -ge '$array_length' ]; then
            end=$(('$array_length' - 1))
        fi

        for ((i = start; i <= end; i++)); do
            local option_value
            eval "option_value=\"\${'"$options_array_name"'[$i]}\""
            if [ "$i" -eq "$current_selected" ]; then
                echo -e "  ${BLUE}▶ $option_value${RESET}"
            else
                echo -e "    $option_value"
            fi
        done

        # 显示分页信息
        if [ '$array_length' -gt '"$page_size"' ]; then
            echo -e "\n${CYAN}第 $((start + 1))-$((end + 1)) 项，共 '$array_length' 项${RESET}"
        fi
    }

    function read_key() {
        # 检查是否在交互式环境中
        if [ ! -t 0 ]; then
            # 非交互式环境，返回回车键
            echo ""
            return 0
        fi

        IFS= read -rsn1 key
        if [[ $key == $'"'"'\x1b'"'"' ]]; then
            IFS= read -rsn2 key
            key="$key"
        fi
        echo "$key"
    }'

    # 执行交互式选择
    eval "$function_definitions"

    tput civis 2>/dev/null || echo -ne "\033[?25l"
    # 只在交互式环境中设置trap
    if [ -t 0 ] && [ -t 1 ]; then
        trap "cleanup" INT TERM
    fi
    draw_menu $selected

    while true; do
        key=$(read_key)
        case "$key" in
            "[A" | "w" | "W" | "k" | "K")  # 上箭头或 w/k 键
                if [ "$selected" -gt 0 ]; then
                    selected=$((selected - 1))
                    if [ "$selected" -lt "$start" ]; then
                        start=$((start - 1))
                    fi
                    clear_menu false
                    draw_menu $selected false
                fi
                ;;
            "[B" | "s" | "S" | "j" | "J")  # 下箭头或 s/j 键
                if [ "$selected" -lt $((array_length - 1)) ]; then
                    selected=$((selected + 1))
                    if [ "$selected" -ge $((start + page_size - 3)) ]; then
                        start=$((start + 1))
                    fi
                    clear_menu false
                    draw_menu $selected false
                fi
                ;;
            "")  # 回车键
                clear_menu true
                break
                ;;
            *) ;;
        esac
    done

    # 检查是否被取消
    if [ "$MENU_SELECT_INDEX" -eq -1 ]; then
        tput cnorm 2>/dev/null || echo -ne "\033[?25h"
        return 130
    fi

    # 获取选中的选项值
    local selected_option
    eval "selected_option=\"\${${options_array_name}[$selected]}\""

    # 显示最终选择结果
    echo -e "$message"
    echo -e "${GREEN}▶ $selected_option${RESET}"
    echo

    # 设置返回值
    MENU_SELECT_RESULT="$selected_option"
    MENU_SELECT_INDEX=$selected

    tput cnorm 2>/dev/null || echo -ne "\033[?25h"
    return 0
}

# 标准化菜单选择函数 - 只使用高级交互模式
select_menu() {
    local options_array_name="$1"
    local message="$2"
    local default_index=${3:-0}

    # 检查是否在交互式环境中
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        # 非交互式环境，直接返回默认选择
        log_debug "非交互式环境，使用默认选择: $default_index"

        # 获取默认选项的值
        local default_option
        eval "default_option=\"\${${options_array_name}[$default_index]}\""

        # 设置返回值
        MENU_SELECT_RESULT="$default_option"
        MENU_SELECT_INDEX=$default_index

        echo -e "$message"
        echo -e "${GREEN:-}▶ $default_option${RESET:-} (自动选择)"
        echo

        return 0
    fi

    # 获取数组长度
    local array_length
    eval "array_length=\${#${options_array_name}[@]}"

    # 交互式环境，使用高级交互式菜单选择器
    log_debug "使用高级交互式菜单选择器"
    interactive_select_menu "$options_array_name" "$message" "$default_index"
}




# =============================================================================
# 初始化函数
# =============================================================================

# 初始化环境
init_environment() {
    # 设置错误处理
    set_error_handling

    # 检测系统信息
    detect_os
    detect_arch
    check_root

    log_info "环境初始化完成"
    log_info "操作系统: $OS $VER"
    log_info "CPU架构: $ARCH"
    log_info "权限模式: $([ -z "$SUDO" ] && echo "root" || echo "sudo")"
}

# =============================================================================
# 脚本信息显示
# =============================================================================

# 显示脚本头部信息
show_header() {
    local script_name=$1
    local script_version=${2:-"1.0"}
    local script_description=$3

    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE} $script_name${RESET}"
    echo -e "${BLUE}版本: $script_version${RESET}"
    echo -e "${BLUE}作者: saul${RESET}"
    echo -e "${BLUE}邮箱: sau1amaranth@gmail.com${RESET}"
    if [ -n "$script_description" ]; then
        echo -e "${BLUE}描述: $script_description${RESET}"
    fi
    echo -e "${BLUE}================================================================${RESET}"
}

# 显示脚本尾部信息
show_footer() {
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${GREEN} 脚本执行完成${RESET}"
    echo -e "${GREEN}================================================================${RESET}"
}
