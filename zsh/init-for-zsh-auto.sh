#!/bin/bash

AUTO_INSTALL=false  # 默认为手动模式

if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用Bash运行此脚本（当前shell: $0）"
    exit 1
fi
# ========================
# 时间同步函数封装
# ========================
sync_ntp_time() {
# 定义sudo变量（提前获取root权限）
    if [ "$(id -u)" -ne 0 ]; then
        SUDO="sudo"
    else
        SUDO=""  # 确保root用户不使用sudo
    fi

# 定义颜色
RED=$(printf '\033[31m' 2>/dev/null || echo '')
GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
RESET=$(printf '\033[m' 2>/dev/null || echo '')

echo -e "${BLUE}================================================================${RESET}"
echo -e "${BLUE}🔧 系统初始化：时间同步配置${RESET}"
echo -e "${BLUE}================================================================${RESET}"

echo -e "${YELLOW}为什么需要时间同步？${RESET}"
echo -e "准确的系统时间是许多网络操作的基础，特别是："
echo -e "  1. TLS/SSL握手需要客户端和服务器时间同步（误差<5分钟）"
echo -e "  2. apt/yum包管理器验证软件包签名依赖正确时间"
echo -e "  3. 日志记录和审计系统依赖准确的时间戳"
echo -e "  4. 许多安全协议（如SSH、HTTPS）依赖时间同步"
echo -e "${YELLOW}--------------------------------------------${RESET}"

# 检查ntpdate是否已安装
echo -e "${YELLOW}ℹ 检查时间同步工具...${RESET}"
echo -e "${CYAN}  目的：确认系统是否已安装NTP客户端工具${RESET}"
echo -e "${CYAN}  为什么：NTP客户端用于从时间服务器同步系统时间${RESET}"

    if ! command -v ntpdate &> /dev/null && ! command -v ntp &> /dev/null; then
        echo -e "${YELLOW}ℹ ntpdate/ntp未安装，尝试直接安装...${RESET}"
        echo -e "${CYAN}  注意：若系统时间错误，可能导致安装失败，可手动设置时间后重试${RESET}"

        if [ -f /etc/debian_version ]; then
            # ✅ 跳过apt update，直接安装ntpdate（优先使用缓存的软件包列表）
            echo -e "${YELLOW}ℹ 尝试安装ntpdate（Debian系）...${RESET}"
            ${SUDO} apt install -y ntpdate || {
                echo "${RED}✖ ntpdate安装失败，尝试安装ntp包...${RESET}"
                ${SUDO} apt install -y ntp || {
                    echo "${RED}✖ 所有NTP工具安装失败${RESET}"
                    handle_install_failure  # 调用错误处理函数
                }
            }
        elif [ -f /etc/redhat-release ]; then
            echo -e "${YELLOW}ℹ 尝试安装ntpdate（RedHat系）...${RESET}"
            ${SUDO} yum install -y ntpdate || {
                echo "${RED}✖ ntpdate安装失败，尝试安装ntp包...${RESET}"
                ${SUDO} yum install -y ntp || {
                    echo "${RED}✖ 所有NTP工具安装失败${RESET}"
                    handle_install_failure  # 调用错误处理函数
                }
            }
        else
            echo "${RED}✖ 不支持的系统类型，无法安装NTP工具${RESET}"
            handle_install_failure
        fi
        echo -e "${GREEN}✔ NTP工具安装完成${RESET}"
    else
        echo -e "${GREEN}✔ NTP工具已安装${RESET}"
    fi

# 定义NTP服务器列表
echo -e "${YELLOW}ℹ 准备同步系统时间...${RESET}"
echo -e "${CYAN}  目的：将系统时间与可靠的NTP服务器同步${RESET}"
echo -e "${CYAN}  为什么：确保系统时间准确，为后续TLS握手和apt操作做准备${RESET}"

NTP_SERVERS=(
    "ntp1.aliyun.com"
    "ntp2.aliyun.com"
    "ntp3.aliyun.com"
    "ntp4.aliyun.com"
    "ntp5.aliyun.com"
    "ntp6.aliyun.com"
    "ntp7.aliyun.com"
    "time1.aliyun.com"  # 备用阿里云服务器
    "time2.aliyun.com"
    "ntp.aliyun.com"    # 阿里云主NTP服务器
    "cn.pool.ntp.org"   # 公共NTP池
    "ntp.ubuntu.com"    # Ubuntu官方NTP
    "time.google.com"   # Google NTP
    "time.cloudflare.com" # Cloudflare NTP
)

# 检测可用的NTP服务器（跳过ping，直接尝试同步）
echo -e "${BLUE}🔍 正在尝试同步NTP服务器...${RESET}"
echo -e "${CYAN}  操作：依次尝试连接多个NTP服务器进行时间同步${RESET}"
echo -e "${CYAN}  为什么：不同网络环境可能对某些NTP服务器有限制${RESET}"
SUCCESS=false

for server in "${NTP_SERVERS[@]}"; do
    echo -e "${YELLOW}尝试与 ${server} 同步...${RESET}"

    # 直接尝试NTP同步（尝试多种参数组合）
    SYNC_SUCCESS=false

    # 尝试带超时的同步
    echo -e "${CYAN}  尝试方法1: ntpdate -t 5 ${server}${RESET}"
    SYNC_RESULT=$(${SUDO} ntpdate -t 5 "$server" 2>&1)
    if [ $? -eq 0 ]; then
        SYNC_SUCCESS=true
    else
        # 尝试不带超时的同步
        echo -e "${CYAN}  尝试方法2: ntpdate ${server}${RESET}"
        SYNC_RESULT=$(${SUDO} ntpdate "$server" 2>&1)
        if [ $? -eq 0 ]; then
            SYNC_SUCCESS=true
        fi
    fi

    # 处理同步结果
    if $SYNC_SUCCESS; then
        echo -e "${GREEN}✔ 成功与 ${server} 同步时间：$(date)${RESET}"
        echo -e "${GREEN}✔ 系统时间已准确同步，可确保TLS握手和apt操作正常进行${RESET}"
        SUCCESS=true

    # 设置硬件时钟（确保重启后时间保持一致）
    echo -e "${YELLOW}ℹ 正在同步硬件时钟...${RESET}"
    echo -e "${CYAN}  目的：将系统时间写入BIOS，确保重启后时间保持准确${RESET}"
    if command -v hwclock &> /dev/null; then
        ${SUDO} hwclock --systohc
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ 已同步硬件时钟${RESET}"
        else
            echo -e "${RED}✖ 硬件时钟同步失败${RESET}"
            echo -e "${YELLOW}⚠ 系统重启后时间可能恢复到BIOS设置${RESET}"
        fi
    else
        echo -e "${YELLOW}⚠ 未找到hwclock工具，硬件时钟未同步${RESET}"
        echo -e "${YELLOW}   系统重启后可能需要重新同步时间${RESET}"
    fi

        break
    else
        echo -e "${RED}✖ 与 ${server} 同步失败：${SYNC_RESULT}${RESET}"
    fi
done

# 检查是否有可用服务器
if ! $SUCCESS; then
    echo "${RED}✖ 所有NTP服务器均同步失败，进行网络诊断...${RESET}"
    echo "${RED}✖ 时间同步失败可能导致TLS握手和apt操作出现问题${RESET}"

    # 网络诊断（不依赖ping）
    echo -e "${YELLOW}🌐 网络诊断信息：${RESET}"

    echo -e "${CYAN}  - 当前网络接口状态：${RESET}"
    ip -s link show up

    echo -e "${CYAN}  - 默认路由：${RESET}"
    ip route show default

    echo -e "${CYAN}  - DNS解析测试：${RESET}"
    echo -e "${YELLOW}  解析 ntp.aliyun.com...${RESET}"
    nslookup ntp.aliyun.com || echo -e "${RED}✖ DNS解析失败${RESET}"

    echo -e "${CYAN}  - NTP服务端口连通性测试：${RESET}"
    for server in "${NTP_SERVERS[@]:0:3}"; do  # 只测试前3个服务器以节省时间
        echo -e "${YELLOW}测试 ${server}:123 (UDP)...${RESET}"
        timeout 3 bash -c "echo > /dev/udp/$server/123" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ ${server}:123 端口可达${RESET}"
        else
            echo -e "${RED}✖ ${server}:123 端口不可达${RESET}"
        fi
    done

    echo -e "${RED}✖ 网络配置可能存在问题，请检查防火墙或联系网络管理员${RESET}"
    echo -e "${YELLOW}提示：您可以手动同步时间后继续：${RESET}"
    echo -e "${YELLOW}  1. 设置系统时间：sudo date -s \"YYYY-MM-DD HH:MM:SS\"${RESET}"
    echo -e "${YELLOW}  2. 继续执行脚本：bash init.sh${RESET}"
    #return 1
fi
# **新增提示：即使同步失败，仍继续后续操作**
if ! $SUCCESS; then
    echo -e "${YELLOW}⚠ 时间同步失败，将继续执行后续安装（可能影响部分功能）${RESET}"
fi
echo -e "${BLUE}================================================================${RESET}"
echo -e "${GREEN}✔ 时间同步完成，系统时间已准确设置${RESET}"
echo -e "${GREEN}✔ 现在可以安全地进行TLS握手和apt操作${RESET}"
echo -e "${BLUE}================================================================${RESET}"
return 0
}

# 新增：安装失败处理函数
handle_install_failure() {
    if [ "$AUTO_INSTALL" = "true" ]; then
        echo "${RED}✖ 自动模式：NTP工具安装失败，继续执行后续操作（存在风险）${RESET}"
        return 0  # 强制继续，允许风险操作
    else
        echo "${YELLOW}ℹ 建议操作：${RESET}"
        echo "${YELLOW}  1. 手动设置系统时间：sudo date -s \"YYYY-MM-DD HH:MM:SS\"${RESET}"
        echo "${YELLOW}  2. 更换软件源为HTTP（跳过HTTPS证书验证）${RESET}"
        echo "${YELLOW}  3. 重新运行脚本：bash $(basename "$0")${RESET}"
        read -p "${YELLOW}⚠ 是否跳过时间同步，继续执行后续操作？（y/Y继续，n/N终止）：${RESET}" -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    fi
}


set -uo pipefail  # 保证管道错误能被捕获

COLOR_GREEN='\033[32m'  # 绿色
COLOR_RED='\033[31m'  # 红色
COLOR_BLUE='\033[34m'  # 蓝色
RED=$(printf '\033[31m' 2>/dev/null || echo '')
GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
MAGENTA=$(printf '\033[35m' 2>/dev/null || echo '')
CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
RESET=$(printf '\033[m' 2>/dev/null || echo '')

# 检查root权限（非root用户自动使用sudo）
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
    echo "${YELLOW}提示：非root用户运行，将自动使用sudo${RESET}"
fi

# 通用执行函数（自动处理sudo）
run() {
    if [ -n "${SUDO:-}" ]; then
        ${SUDO} "$@"
    else
        "$@"
    fi
}

# ---------------------------
# 操作确认提示（统一逻辑）
# ---------------------------
confirm_with_list() {
    local title="$1"
    local -n items_array="$2"

    echo -e "\n${BLUE}${title}${RESET}"
    echo -e "${GREEN}• ${items_array[*]// /\\n• }${RESET}"  # 格式化列表显示
    # 自动模式下跳过确认，直接返回成功
    if [ "$AUTO_INSTALL" = "true" ]; then
        echo "${YELLOW}⚠ 自动安装模式：跳过确认，继续执行...${RESET}"
        return 0
    fi
    read -p "${YELLOW}⚠ 确认执行以上操作？继续请按(y/Y/回车)，取消按(n/N)：${RESET}" -n 1 -r
    echo
    case "$REPLY" in
        [yY]|'') return 0 ;;
        *)       echo "${RED}✖ 操作已取消${RESET}"; exit 1 ;;
    esac
}


echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;32m🚀 欢迎使用 OHMYZSH配置美化脚本\e[0m"
echo -e "\e[1;33m👤 作者: saul\e[0m"
echo -e "\e[1;33m📧 邮箱: sau1@maranth@gmail.com\e[0m"
echo -e "\e[1;35m🔖 version 1.1\e[0m"
echo -e "\e[1;34m================================================================\e[0m"
echo -e "\e[1;36m厌倦了单调的bash?本脚本将帮助您添加zsh,美化power10k主题,添加插件。\e[0m"
echo -e "\e${COLOR_BLUE}请按照提示输入相关信息，然后脚本将自动完成后续操作。\e[0m"
echo -e "\e${COLOR_RED}注意:此脚本只在debian和ubuntu上测试过"
echo -e "\e${COLOR_RED}https://github.com/sau1g0dman/scripts-for-linux\e[0m"
echo -e "\e[1;34m================================================================\e[0m"

install_basic_tools() {
    clear
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${GREEN}🚀 基础工具安装脚本（支持Debian/RedHat）${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${CYAN}ℹ 检测到当前系统：$(awk -F'=' '/^PRETTY_NAME=/ {print $2}' /etc/os-release | tr -d '"')${RESET}"
    echo -e "${YELLOW}⚠ 注意：将自动安装常用开发工具${RESET}"
    echo -e "${BLUE}================================================================${RESET}"


    # ---------------------------
    # 定义安装列表（含依赖关系）
    # ---------------------------
    local tools=(
        "git"                # 分布式版本控制工具
        "curl"               # 网络请求工具
        "vim"                # 文本编辑器
        "zsh"                # 增强Shell
        "htop"               # 进程监控
        "btop"
        "tmux"               # 终端复用器
        "exa"                # 现代化ls工具
        "bat"                # 带语法高亮的cat
        "fd-find"            # 快速查找文件（替代find）
        "thefuck"            # 自动纠正命令错误
        "net-tools"          # 网络工具（ifconfig等）
        "nmap"
        "tshark"
        "mtr"
        "netcat"
        "traceroute"
        "ncdu"               # 磁盘使用分析工具，ncdu提供交互式界面
    )

    local enhance_tools=(
        "ripgrep"            # 高级搜索工具
        "lazygit"            # Git可视化工具
        "oh-my-tmux"         # tmux配置管理
        "fzf"                # 模糊查找工具
        "zoxide"             # 目录跳转工具
        "fzf-git.sh"         # Git集成搜索工具
    )

    # 修正：使用正确的变量名 "tools" 而不是 "base_tools"
    local all_tools=("${tools[@]}" "${enhance_tools[@]}")

    # 显示完整安装列表并确认
    confirm_with_list "以下工具将被安装：" all_tools


    # ---------------------------
    # 系统兼容性检测
    # ---------------------------
    if [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
        PKG_MANAGER="apt-get"
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="redhat"
        PKG_MANAGER="yum"
    else
        echo "${RED}✖ 不支持的系统类型${RESET}"
        exit 1
    fi
    # ---------------------------
    # 统一更新命令
    # ---------------------------
    echo "${BLUE}🔄 正在更新系统包列表${RESET}"
    run ${PKG_MANAGER} update -y

    # ---------------------------
    # 安装基础工具
    # ---------------------------
    echo -e "\n${BLUE}开始安装基础工具（共 ${#tools[@]} 项）：${RESET}"
    for tool in "${tools[@]}"; do
        echo -e "${CYAN}───> 检查 ${tool}...${RESET}"
        if [ -x "$(command -v ${tool})" ]; then
            echo -e "${GREEN}✔ 已安装（版本：$( ${tool} --version | head -n1 )）${RESET}"

        else
            echo -e "${YELLOW}ℹ 开始安装 ${tool}...${RESET}"
            case ${OS_TYPE} in
                "debian") run ${PKG_MANAGER} install -y ${tool} ;;
                "redhat") run ${PKG_MANAGER} install -y ${tool} ;;
            esac
            if [ $? -eq 0 ]; then
                echo "${GREEN}✔ 安装完成${RESET}"

            else
                echo "${RED}✖ 安装失败（跳过）${RESET}"

            fi
        fi
    done

    # 安装 ripgrep（固定版本+友好提示）
    echo -e "\n${BLUE}安装增强工具：${RESET}"
    local optional_tools=("ripgrep" "lazygit" "oh-my-tmux" "fzf" "zoxide" "fzf-git.sh")
    echo -e "${CYAN}───> 安装 ripgrep（固定版本 14.1.0）${RESET}"

    # ---------------------------
    # 安装 ripgrep（修改错误处理）
    # ---------------------------
if ! command -v rg &> /dev/null; then
    DEB_FILE="ripgrep_14.1.0-1_amd64.deb"
    echo "${YELLOW}ℹ 下载固定版本 ${DEB_FILE}...${RESET}"

    # 临时禁用 set -e 避免下载失败时退出
    set +e
    curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/${DEB_FILE}"
    DOWNLOAD_STATUS=$?
    set -e

    if [ ${DOWNLOAD_STATUS} -ne 0 ]; then
        echo "${RED}✖ 下载失败，请检查网络连接或手动安装：https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/${DEB_FILE}${RESET}"
    else
        echo "${YELLOW}ℹ 开始安装 ${DEB_FILE}...${RESET}"
        # 临时禁用 set -e 处理 dpkg 可能的依赖问题
        set +e
        run dpkg -i "$DEB_FILE"
        INSTALL_STATUS=$?
        run apt-get install -f -y  # 自动修复依赖
        set -e

        if [ ${INSTALL_STATUS} -eq 0 ]; then
            echo "${GREEN}✔ ripgrep 14.1.0 安装完成${RESET}"
        else
            echo "${RED}✖ 安装失败，请手动执行：sudo dpkg -i ${DEB_FILE} && sudo apt-get install -f${RESET}"
        fi
        rm "$DEB_FILE"
    fi
else
    echo "${GREEN}✔ ripgrep 已安装（版本：$(rg --version)）${RESET}"
fi

    # 安装 lazygit（修改错误处理）
    echo "${BLUE}[🔧] 安装 lazygit（Git可视化工具）${RESET}"
    if ! command -v lazygit &> /dev/null; then
        LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit && run install lazygit /usr/local/bin && rm -rf lazygit* || echo "${RED}✖ lazygit 安装失败${RESET}"
        [ -x "$(command -v lazygit)" ] && echo "${GREEN}✔ lazygit 安装完成（版本：${LAZYGIT_VERSION}）${RESET}"
    else
        echo "${GREEN}✔ lazygit 已安装（版本：$(lazygit --version)）${RESET}"
    fi

    # ---------------------------
    # 新增：集成 oh-my-tmux 安装
    # ---------------------------
    echo "${BLUE}[🔧] 安装 oh-my-tmux（终端复用工具配置）${RESET}"
    if [ ! -d "$HOME/.tmux" ]; then
        echo "${YELLOW}ℹ 开始安装 oh-my-tmux${RESET}"
        git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux" --quiet || {
            echo "${RED}✖ oh-my-tmux 仓库克隆失败${RESET}"
        }
        # 创建符号链接（注意：需处理用户原有 .tmux.conf）
        if [ -f "$HOME/.tmux.conf" ]; then
            mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
            echo "${YELLOW}⚠ 检测到旧的 .tmux.conf，已备份为 .tmux.conf.bak${RESET}"
        fi
        ln -s -f "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf" || {
            echo "${RED}✖ 创建符号链接失败${RESET}"
        }
        cp "$HOME/.tmux/.tmux.conf.local" "$HOME/" || {
            echo "${RED}✖ 复制配置文件失败${RESET}"
        }
        echo "${GREEN}✔ oh-my-tmux 安装完成${RESET}"
    else
        echo "${GREEN}✔ oh-my-tmux 已安装${RESET}"
    fi

    # ---------------------------
    # 新增：安装 fzf（模糊查找工具）
    # ---------------------------
echo "${BLUE}[🔧] 安装 fzf（模糊查找工具）${RESET}"
if [[ ! -d "$HOME/.fzf" ]]; then
    echo "${YELLOW}ℹ 开始安装 fzf${RESET}"
    local install_success=false  # 初始化安装状态为失败

    # 1. 克隆仓库（确保目录存在）
    if ! git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf" --quiet; then
        echo "${RED}✖ fzf 仓库克隆失败${RESET}"
    else
        echo "${YELLOW}ℹ fzf 仓库克隆完成，开始执行安装脚本${RESET}"
        cd "$HOME/.fzf" || {
            echo "${RED}✖ 无法进入 fzf 目录${RESET}"
            return
        }

        # 2. 赋予安装脚本执行权限（确保可执行）
        chmod +x install  # 显式添加执行权限

        # 3. 执行安装脚本（指定完整路径，避免环境变量问题）
        if ./install --all --no-update-rc --quiet; then
            echo "${GREEN}✔ fzf 安装脚本执行成功${RESET}"
            install_success=true
        else
            echo "${RED}✖ fzf 安装脚本执行失败（可能缺少依赖）${RESET}"
            echo "${YELLOW}ℹ 提示：尝试手动执行 '~/.fzf/install' 查看详细错误${RESET}"
        fi
    fi

    # 4. 清理临时文件（可选）
    cd - >/dev/null 2>&1

    # 5. 根据安装状态输出结果
    if $install_success; then
        echo "${GREEN}✔ fzf 安装完成${RESET}"
    else
        echo "${RED}✖ fzf 安装失败${RESET}"
    fi
else
    echo "${GREEN}✔ fzf 已安装${RESET}"
fi

    # ---------------------------
    # 新增：安装 zoxide（目录跳转工具）
    # ---------------------------
    echo "${BLUE}[🔧] 安装 zoxide（目录跳转工具）${RESET}"
    if ! command -v zoxide &> /dev/null; then
        echo "${YELLOW}ℹ 开始安装 zoxide${RESET}"
        curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || {
            echo "${RED}✖ zoxide 安装脚本执行失败${RESET}"
        }
        echo "${GREEN}✔ zoxide 安装完成${RESET}"
    else
        echo "${GREEN}✔ zoxide 已安装${RESET}"
    fi

    # ---------------------------
    # 新增：安装 fzf-git.sh（Git 集成工具
    # ---------------------------
    echo "${BLUE}[🔧] 安装 fzf-git.sh（Git 可视化搜索工具）${RESET}"
    if [[ ! -d "$HOME/fzf-git.sh" ]]; then
        echo "${YELLOW}ℹ 开始克隆 fzf-git.sh 仓库${RESET}"
        git clone https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh" --quiet || {
            echo "${RED}✖ fzf-git.sh 仓库克隆失败${RESET}"
        }
        echo "${GREEN}✔ fzf-git.sh 安装完成${RESET}"
    else
        echo "${GREEN}✔ fzf-git.sh 已安装${RESET}"
    fi

    echo -e "\n${BLUE}──────────────────────────────────────────────────────────────${RESET}"
    echo -e "${CYAN}推荐操作：${RESET}"
    echo -e "  ${GREEN}1. 执行 'zsh' 切换到Zsh终端${RESET}"
    echo -e "  ${GREEN}2. 尝试运行 'exa --tree' 查看目录结构${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    sleep 3  # 延长停留时间方便查看
    sleep 2
}

change_default_shell() {
    echo ""
    echo -e "\e[1;36m=========================正在自动更改默认Shell为zsh=========================\e[0m"
    ZSH_PATH=$(which zsh)
    chsh -s "$ZSH_PATH"
    echo "默认Shell更改完成。"
    echo ""
    echo -e "\e${COLOR_GREEN}=========================[[OK]]========================\e[0m"
    sleep 1
}
install_oh_my_zsh() {
    echo ""
    echo -e "\e[1;36m=========================安装Oh My Zsh（原版）=========================\e[0m"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo ""
    echo -e "\e${COLOR_GREEN}=========================Oh My Zsh安装完成========================\e[0m"
        sleep 1
}


install_zsh_plugins() {
    echo ""
    echo -e "\e[1;36m=========================安装Zsh插件=========================\e[0m"

    # 智能检测 Oh My Zsh 安装位置
    local zsh_install_dir=""
    local zsh_custom_dir=""

    # 优先级1: 通过 $ZSH 环境变量检测
    # ✅ 修复：使用 ${ZSH:-} 避免未定义变量错误
    if [[ -n "${ZSH:-}" && -d "$ZSH" ]]; then
        zsh_install_dir="$ZSH"
        echo -e "\e[1;33m• 通过 \$ZSH 变量检测到 Oh My Zsh 安装在: ${zsh_install_dir}\e[0m"
    elif [[ -d "/usr/share/oh-my-zsh" ]]; then
        zsh_install_dir="/usr/share/oh-my-zsh"
        echo -e "\e[1;33m• 检测到系统级 Oh My Zsh 安装在: ${zsh_install_dir}\e[0m"
    elif [[ -d "$HOME/.oh-my-zsh" ]]; then
        zsh_install_dir="$HOME/.oh-my-zsh"
        echo -e "\e[1;33m• 检测到用户级 Oh My Zsh 安装在: ${zsh_install_dir}\e[0m"
    else
        echo -e "\e[1;31m✗ 未找到 Oh My Zsh 安装！请先安装 Oh My Zsh。\e[0m"
        return 1
    fi


    # 确定自定义目录路径
    if [[ -n "${ZSH_CUSTOM:-}" && -d "$ZSH_CUSTOM" ]]; then
        zsh_custom_dir="$ZSH_CUSTOM"
        echo -e "\e[1;33m• 使用用户定义的自定义目录: ${zsh_custom_dir}\e[0m"
    else
        zsh_custom_dir="${zsh_install_dir}/custom"
        echo -e "\e[1;33m• 使用默认自定义目录: ${zsh_custom_dir}\e[0m"
    fi

    # 创建插件目录（如果不存在）
    local plugins_dir="${zsh_custom_dir}/plugins"
    mkdir -p "$plugins_dir" || {
        echo -e "\e[1;31m✗ 无法创建插件目录！请检查权限。\e[0m"
        return 1
    }

    # 定义要安装的插件列表
    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "MichaelAquilina/zsh-you-should-use"
    )
     local themes=(
        "romkatv/powerlevel10k"
    )

    # 安装插件
    for plugin in "${plugins[@]}"; do
         # 特殊处理 zsh-you-should-use 插件名
    local plugin_name=""
    if [[ "$plugin" == "MichaelAquilina/zsh-you-should-use" ]]; then
        plugin_name="you-should-use"  # 手动指定正确的插件目录名
    else
        plugin_name="${plugin##*/}"  # 其他插件自动提取仓库名
    fi


        local plugin_dir="${plugins_dir}/${plugin_name}"
        if [[ -d "$plugin_dir" ]]; then
            echo -e "\e[1;32m✓ ${plugin_name} 已安装\e[0m"
            continue
        fi
        echo -e "\e[1;34m安装插件 ${plugin_name}...\e[0m"
        if git clone --depth=1 "https://github.com/${plugin}" "$plugin_dir"; then
            echo -e "\e[1;32m✓ ${plugin_name} 安装成功\e[0m"
        else
            echo -e "\e[1;31m✗ ${plugin_name} 安装失败\e[0m"
            rm -rf "$plugin_dir"
        fi
    done

    # 安装主题
    for theme in "${themes[@]}"; do
        local theme_name="${theme##*/}"
        local theme_dir="${zsh_custom_dir}/themes/${theme_name}"
        if [[ -d "$theme_dir" ]]; then
            echo -e "\e[1;32m✓ ${theme_name} 主题已安装\e[0m"
            continue
        fi
        echo -e "\e[1;34m安装主题 ${theme_name}...\e[0m"
        if git clone --depth=1 "https://github.com/${theme}" "$theme_dir"; then
            # 添加复制配置文件功能（仅针对 powerlevel10k）
            if [[ "${theme_name}" == "powerlevel10k" ]]; then
                local config_file="${theme_dir}/config/p10k-rainbow.zsh"
                local dest_file="$HOME/.p10k.zsh"
                if [[ -f "$config_file" ]]; then
                    echo -e "\e[1;34m复制 Powerlevel10k 配置文件到 ~/.p10k.zsh...\e[0m"
                    cp -vf "$config_file" "$dest_file" &> /dev/null
                    if [[ $? -eq 0 ]]; then
                        echo -e "\e[1;32m✓ 配置文件复制完成\e[0m"
                    else
                        echo -e "\e[1;31m✗ 配置文件复制失败\e[0m"
                    fi
                else
                    echo -e "\e[1;31m✗ 未找到 Powerlevel10k 配置文件 ($config_file)\e[0m"
                fi
                # 修改 .zshrc 主题配置（可选，可根据需求保留或移除）
                sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
            fi
            echo -e "\e[1;32m✓ ${theme_name} 安装成功\e[0m"
        else
            echo -e "\e[1;31m✗ ${theme_name} 安装失败\e[0m"
            rm -rf "$theme_dir"
        fi
    done


    echo ""
    echo -e "\e[1;32m=========================Zsh插件安装完成=========================\e[0m"
    sleep 1
}
install_oh_my_tmux() {
    echo -e "\e[1;36m=========================安装 oh-my-tmux=========================\e[0m"
    git clone https://github.com/gpakosz/.tmux.git
    # shellcheck disable=SC2226
    ln -s -f .tmux/.tmux.conf
    cp .tmux/.tmux.conf.local .
    echo -e "\e${COLOR_GREEN}=========================moh-my-tmux安装完成========================\e[0m"
        sleep 1

}
apply_zshrc_changes() {
    echo -e "\e[1;36m=========================应用 .zshrc 配置更改=========================\e[0m"
    CONFIG_LINE='export LC_ALL=en_US.UTF-8'
    COMMENT="# 设置环境变量 LC_ALL 为 en_US.UTF-8"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================LC_ALL环境变量设置为en_US.UTF-8.=========================\e[0m"
        sleep 1
    else
        echo -e "\e${COLOR_GREEN}=========================LC_ALL环境变量已设置为en_US.UTF-8.=========================\e[0m"
    fi
    declare -a new_plugins=("extract" "systemadmin" "zsh-interactive-cd" "systemd" "sudo" "docker" "ubuntu" "man" "command-not-found" "common-aliases" "aliases" "docker-compose" "git" "zsh-autosuggestions" "zsh-syntax-highlighting" "tmux" "zoxide" "you-should-use")
    if grep -q "^plugins=(" ~/.zshrc; then
        for plugin in "${new_plugins[@]}"; do
            if ! grep -q "plugins=(.*$plugin" ~/.zshrc; then
                sed -i "/^plugins=(/ s/)$/ $plugin)/" ~/.zshrc
                echo -e "\e${COLOR_GREEN}=========================插件 $plugin 已添加。=========================\e[0m"
            else
                echo -e "\e${COLOR_GREEN}=========================插件 $plugin 已存在，跳过。=========================\e[0m"
            fi
        done
    else
        echo "# 设置插件配置" >> ~/.zshrc
        printf "plugins=(" >> ~/.zshrc
        printf "%s " "${new_plugins[@]}" >> ~/.zshrc
        printf ")\n" >> ~/.zshrc
        echo "已创建新的插件配置。"
    fi
    CONFIG_LINE='export ZOXIDE_CMD_OVERRIDE=z'
    COMMENT="# 设置 ZOXIDE_CMD_OVERRIDE"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已设置 ZOXIDE_CMD_OVERRIDE========================\e[0m"
            sleep 1
    else
        echo "ZOXIDE_CMD_OVERRIDE已设置,不需要重新设置。"
    fi
    if ! grep -q 'export ZOXIDE_CMD_OVERRIDE=z' ~/.zshrc; then
        echo 'export ZOXIDE_CMD_OVERRIDE=z' >> ~/.zshrc
        echo "已设置 ZOXIDE_CMD_OVERRIDE。"
    fi
    CONFIG_LINE='eval "$(zoxide init zsh)"'
    COMMENT="# 初始化 zoxide"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已初始化 zoxide。========================\e[0m"
            sleep 1
    else
        echo -e "\e${COLOR_GREEN}=========================zoxide已初始化,不需要重新设置。========================\e[0m"
    fi
    CONFIG_LINE='export PATH="$PATH:$HOME/.local/bin"'
    COMMENT="# 更新 PATH 环境变量"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        sed -i "1i $COMMENT\n$CONFIG_LINE" ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================已将 PATH 环境变量更新添加到 ~/.zshrc 的最上方。========================\e[0m"
            sleep 1
    else
        echo "PATH 环境变量更新已存在于 ~/.zshrc 中，无需重复添加。"
    fi
    CONFIG_LINE='export ZSH_AUTOSUGGEST_STRATEGY=(history completion)'
    COMMENT="# 设置自动建议策略"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已设置 ZSH_AUTOSUGGEST_STRATEGY========================\e[0m"
            sleep 1
    else
        echo "ZSH_AUTOSUGGEST_STRATEGY已设置,不需要重新设置。"
    fi
    CONFIG_LINE='POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true'
    COMMENT="# 禁用 Powerlevel9k 配置向导"
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================已禁用 Powerlevel9k 配置向导========================\e[0m"
            sleep 1
    else
        echo "Powerlevel9k 配置向导已禁用,不需要重新设置。"
    fi
    CONFIG_LINE="zstyle ':omz:update' mode auto"
    COMMENT="# =========================设置 Oh My Zsh 自动更新========================="
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已设置 Oh My Zsh 自动更新========================\e[0m"
            sleep 1
    else
        echo "Oh My Zsh 自动更新已设置,不需要重新设置。"
    fi
    CONFIG_LINE='[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
    COMMENT="# =========================检查并源自定义 p10k 配置========================="
    if ! grep -qF -- "$CONFIG_LINE" ~/.zshrc; then
        echo "$COMMENT" >> ~/.zshrc
        echo "$CONFIG_LINE" >> ~/.zshrc
        echo "=========================已添加 Powerlevel10k 配置文件检查。========================="
    else
        echo "=========================Powerlevel10k 配置文件检查已添加,不需要重新设置。========================="
    fi
    if ! grep -q 'copy-prev-shell-word' ~/.zshrc; then
        echo 'copy-prev-shell-word() {' >> ~/.zshrc
        echo '  local last_word=$(fc -ln -1 | awk '"'"'{print $NF}'"'"')' >> ~/.zshrc
        echo '  LBUFFER+=$last_word' >> ~/.zshrc
        echo '}' >> ~/.zshrc
        echo 'zle -N copy-prev-shell-word' >> ~/.zshrc
        echo 'bindkey "^[m" copy-prev-shell-word' >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已添加 bindkey '^[m' copy-prev-shell-word]========================\e[0m"
            sleep 1
    fi
    script_content="# 检查是否存在有效的 SSH_AUTH_SOCK 连接
        touch ~/.ssh-agent-ohmyzsh
        if [ ! -S \"\${SSH_AUTH_SOCK}\" ]; then
            # 尝试从 ~/.ssh-agent-ohmyzsh 加载 ssh-agent 配置
            if [ -f ~/.ssh-agent-ohmyzsh ]; then
                eval \"\$(cat ~/.ssh-agent-ohmyzsh)\"
            fi
        fi
        # 再次检查是否存在有效的 SSH_AUTH_SOCK 连接
        if [ ! -S \"\${SSH_AUTH_SOCK}\" ]; then
            # 如果没有有效的连接，启动一个新的 ssh-agent 并保存配置
            ssh-agent -t 12h > ~/.ssh-agent-ohmyzsh
            eval \"\$(cat ~/.ssh-agent-ohmyzsh)\"
            ssh-add ~/.ssh/* &>/dev/null
        fi"

    # 检查 ~/.zshrc 中是否已存在相同的脚本内容
    if grep -qF -- "$script_content" ~/.zshrc; then
        echo -e "\e${COLOR_GREEN}=========================SSH agent 脚本已存在于 ~/.zshrc 中。=========================\e[0m"
    else
        echo "$script_content" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================SSH agent 脚本已添加到 ~/.zshrc。=========================\e[0m"
    fi
    echo ""
    echo -e "\e[1;36m=========================安装vim-for-server=========================\e[0m"
    curl https://raw.githubusercontent.com/wklken/vim-for-server/master/vimrc > ~/.vimrc
    echo -e "\e${COLOR_GREEN}=========================vim-for-server安装完毕========================\e[0m"
        sleep 1
       echo ""
    echo -e "\e[1;36m=========================安装fzf=========================\e[0m"
    printf 'y\ny\ny\n' | ~/.fzf/install
    echo ""
    echo -e "\e${COLOR_GREEN}=========================fzf安装完毕========================\e[0m"
        sleep 1
    # 检查 batcat 是否已安装并位于预期的位置
    echo ""
    echo -e "\e[1;36m=========================配置bat和fd=========================\e[0m"
    if [ -f /usr/bin/batcat ]; then
        # 如果 batcat 已安装，检查是否存在 ~/.local/bin 目录
        if [ -d ~/.local/bin ]; then
            # 如果目录存在，创建 bat 的符号链接
            ln -sf /usr/bin/batcat ~/.local/bin/bat
            ln -sf /usr/bin/fdfind ~/.local/bin/fd
            echo ""
            echo -e "\e${COLOR_GREEN}=========================bat,和fd 已配置=========================\e[0m"
            sleep 1
        else
            # 如果目录不存在，创建目录并创建 bat 的符号链接
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
            ln -sf /usr/bin/fdfind ~/.local/bin/fd
            echo ""
            echo -e "\e${COLOR_GREEN}=========================bat,和fd 已配置=========================\e[0m"
        fi
    else
        # 如果 batcat 未安装，输出错误消息
        echo ""
        echo -e "\e${COLOR_RED}=========================bat未安装=========================\e[0m"
    fi
    # 删除掉 /root/.oh-my-zsh/plugins/common-aliases/common-aliases.plugin.zsh文件的
    # (( $+commands[fd] )) || alias fd='find . -type d -name'
    file_path="/root/.oh-my-zsh/plugins/common-aliases/common-aliases.plugin.zsh"
        # 检查文件是否存在
    if [[ -f "$file_path" ]]; then
        # 使用 sed 命令来注释掉特定的 fd 别名行
        sed -i '/commands\[fd/d' "$file_path"
        echo ""
        echo -e "\e${COLOR_GREEN}=========================已禁用 $file_path 中的 fd 别名。=========================\e[0m"
    else
        echo ""
        echo -e "\e${COLOR_RED}=========================未找到文件: $file_path=========================\e[0m"
    fi
    config_text='# ================fd-fzf-bat===============
    fg="#CBE0F0"
    bg="#011628"
    bg_highlight="#143652"
    purple="#B388FF"
    blue="#06BCE4"
    cyan="#2CF9ED"
    export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan} --preview '\''bat --color=always --style=numbers --line-range=:500 {}'\''"
    export FZF_DEFAULT_COMMAND="fd --hidden  --strip-cwd-prefix --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_OPTS="--preview '\''exa --tree --color=always {} | head -200'\''"
    export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
    _fzf_compgen_path() {
        fd --hidden --exclude .git . "$1"
    }
    _fzf_compgen_dir() {
        fd --type=d --hidden --exclude .git . "$1"
    }
    _fzf_comprun() {
    local command=$1
    shift

    case "$command" in
        cd)           fzf --preview '\''exa --tree --color=always {} | head -200'\'' "$@" ;;
        export|unset) fzf --preview "eval '\''echo \\\$'\''{}"         "$@" ;;
        ssh)          fzf --preview '\''dig {}'\''                   "$@" ;;
        *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
    esac
    }
    eval $(thefuck --alias)
    eval $(thefuck --alias fk)
    ENABLE_CORRECTION="true"
    source ~/fzf-git.sh/fzf-git.sh
    # ================fd-fzf-bat===============
    '

    # 检查配置是否已存在
    if ! grep -q "fd-fzf-bat" ~/.zshrc; then
        # 插入配置
        echo "$config_text" >> ~/.zshrc
        echo ""
        echo -e "\e${COLOR_GREEN}========================fzf-fd-bat合体技能已经配置成功========================e[0m"
    else
        echo ""
        echo "=========================fzf-fd-bat合体技能已经配置成功,不用重复添加========================="
    fi
    #在.zshrc设置快捷alias
    ALIAS='
    # ================alias===============
    alias ls="exa -a --color=always --long --icons"
    alias tree="exa --tree --color=always --long --icons"
    alias cat="bat"
    alias cd="z"
    #clear
    alias c="clear"
    alias cl="clear"
    #ping
    alias pg="ping google.com -c 5"
    alias cg="curl -v google.com"
    alias pb="ping baidu.com -c 5"
    alias cb="curl -v https://baidu.com"
    alias ping="ping -c 5"
    #Exit Command
    alias :q="exit"
    alias ext="exit"
    alias xt="exit"
    alias by="exit"
    alias bye="exit"
    alias die="exit"
    alias quit="exit"
    # Launch Simple HTTP Server
    alias serve="python -m SimpleHTTPServer"
    # Parenting changing perms on /
    alias chown="chown --preserve-root"
    alias chmod="chmod --preserve-root"
    alias chgrp="chgrp --preserve-root"
    # Install & Update utilties
    alias sai="sudo apt install -y"
    alias sau="sudo apt update -y"
    alias update="sudo apt update -y"
    #Show open ports
    alias ports="sudo ss -tulanp"
    alias tu="df -hl --total G total"
    alias us="du -ch G total"
    alias vi="nvim"
    alias myip="ip addr show G inet G -v inet6"
    alias fdu="function _fdu() { find "$1" -type f -exec du -h {} + | sort -rh | head -n 20; }; _fdu"
    # ================alias===============
    '
    if ! grep -q "ALIAS" ~/.zshrc; then
        echo "$ALIAS" >> ~/.zshrc
        echo -e "\e${COLOR_GREEN}=========================一大波alias快捷键已添加到~/.zshrc。=========================\e[0m"
    else
        echo -e "\e${COLOR_GREEN}=========================快捷键已存在于~/.zshrc。=========================\e[0m"
    fi

    echo -e "\e[1;36m=========================.zshrc 配置更改完成。=========================\e[0m"
    echo -e "\e[1;36m=========================请输入ZSH启动终端以应用更改。=========================\e[0m"
    echo -e "\e${COLOR_GREEN}=========================[[well done]]========================\e[0m"
        sleep 1
}
start_zsh() {
    echo ""
    echo -e "\e[1;36m=========================启动zsh...=========================\e[0m"
    exec zsh
}
# 菜单选项优化（更清晰的分组）
PS3=$(echo -e "\n${BLUE}请选择操作（方向键选择，回车确认）：${RESET}")
options=(
    " ${GREEN}全部自动安装（推荐）${RESET}"
    " ${CYAN}同步NTP服务器${RESET}"
    " ${CYAN}分步安装 - 基础工具${RESET}"
    " ${CYAN}分步安装 - 切换Zsh Shell${RESET}"
    " ${CYAN}分步安装 - 安装Oh My Zsh${RESET}"
    " ${CYAN}分步安装 - 安装Zsh插件${RESET}"
    " ${CYAN}应用配置更改${RESET}"
    " ${GREEN}启动Zsh终端${RESET}"
    " ${RED}退出脚本${RESET}"
)

COLUMNS=1
select opt in "${options[@]}"; do
    case $REPLY in
        1)  AUTO_INSTALL=true  # 启用自动模式
            sync_ntp_time && install_basic_tools && change_default_shell && install_oh_my_zsh && install_zsh_plugins && apply_zshrc_changes && start_zsh; break ;;
        2)  # 同步NTP服务器
                sync_ntp_time
                read -p "${YELLOW}按任意键返回菜单...${RESET}" -n 1 -r
                echo
                ;;

        3)  install_basic_tools; break ;;
        4)  change_default_shell; break ;;
        5)  install_oh_my_zsh; break ;;
        6)  install_zsh_plugins; break ;;
        7)  apply_zshrc_changes; break ;;
        8)  start_zsh; break ;;
        9)  echo "${RED}退出脚本...${RESET}"; break ;;
        *)  echo "${YELLOW}请输入有效选项（1-9）${RESET}"; continue ;;
    esac
done
