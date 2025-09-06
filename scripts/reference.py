#!/usr/bin/env python3

"""
参考脚本 - Python版本
作者: saul
版本: 1.0
描述: 包含完整的安装流程的参考实现
"""

import os
import sys
import subprocess
import time
import urllib.request
import json
from pathlib import Path

# 添加scripts目录到Python路径
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

try:
    from common import *
except ImportError:
    print("错误：无法导入common模块")
    print("请确保common.py文件存在于scripts目录中")
    sys.exit(1)

# =============================================================================
# 基础工具安装
# =============================================================================

def install_basic_tools():
    """安装基础工具"""
    log_info("开始安装基础工具...")
    
    # 基础工具列表
    basic_tools = [
        "git",           # 分布式版本控制工具
        "curl",          # 网络请求工具
        "vim",           # 文本编辑器
        "zsh",           # 增强Shell
        "htop",          # 进程监控
        "btop",          # 现代化系统监控
        "tmux",          # 终端复用器
        "exa",           # 现代化ls工具
        "bat",           # 带语法高亮的cat
        "fd-find",       # 快速查找文件
        "thefuck",       # 自动纠正命令错误
        "net-tools",     # 网络工具
        "nmap",          # 网络扫描工具
        "tshark",        # 网络分析工具
        "mtr",           # 网络诊断工具
        "netcat",        # 网络工具
        "traceroute",    # 路由跟踪
        "ncdu"           # 磁盘使用分析工具
    ]
    
    # 增强工具列表
    enhance_tools = [
        "ripgrep",       # 高级搜索工具
        "lazygit",       # Git可视化工具
        "fzf",           # 模糊查找工具
        "zoxide"         # 目录跳转工具
    ]
    
    try:
        # 更新包列表
        execute_command("apt update", "更新包列表")
        
        # 安装基础工具
        log_info("安装基础工具包...")
        for tool in basic_tools:
            try:
                execute_command(f"apt install -y {tool}", f"安装{tool}")
                log_info(f"✓ {tool} 安装成功")
            except Exception as e:
                log_warn(f"✗ {tool} 安装失败: {e}")
        
        # 安装增强工具
        log_info("安装增强工具...")
        
        # 安装ripgrep（使用固定版本）
        install_ripgrep()
        
        # 安装lazygit
        install_lazygit()
        
        # 安装fzf
        install_fzf()
        
        # 安装zoxide
        install_zoxide()
        
        log_info("基础工具安装完成")
        return True
    except Exception as e:
        log_error(f"基础工具安装失败: {e}")
        return False

def install_ripgrep():
    """安装ripgrep"""
    try:
        subprocess.run(['rg', '--version'], check=True, capture_output=True)
        log_info("ripgrep 已安装")
        return
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    log_info("安装 ripgrep（固定版本 14.1.0）...")
    
    try:
        # 下载deb包
        deb_file = "ripgrep_14.1.0-1_amd64.deb"
        deb_url = f"https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/{deb_file}"
        
        urllib.request.urlretrieve(deb_url, f"/tmp/{deb_file}")
        
        # 安装deb包
        execute_command(f"dpkg -i /tmp/{deb_file}", "安装ripgrep")
        
        # 清理下载文件
        os.remove(f"/tmp/{deb_file}")
        
        log_info("✓ ripgrep 安装成功")
    except Exception as e:
        log_warn(f"✗ ripgrep 安装失败: {e}")

def install_lazygit():
    """安装lazygit"""
    try:
        subprocess.run(['lazygit', '--version'], check=True, capture_output=True)
        log_info("lazygit 已安装")
        return
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    log_info("安装 lazygit...")
    
    try:
        # 使用官方安装脚本
        install_cmd = "curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep browser_download_url | grep Linux_x86_64 | cut -d '\"' -f 4 | wget -qi - -O /tmp/lazygit.tar.gz && tar xf /tmp/lazygit.tar.gz -C /tmp && sudo install /tmp/lazygit /usr/local/bin"
        subprocess.run(install_cmd, shell=True, check=True)
        
        log_info("✓ lazygit 安装成功")
    except Exception as e:
        log_warn(f"✗ lazygit 安装失败: {e}")

def install_fzf():
    """安装fzf"""
    try:
        subprocess.run(['fzf', '--version'], check=True, capture_output=True)
        log_info("fzf 已安装")
        return
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    log_info("安装 fzf...")
    
    try:
        # 克隆fzf仓库
        fzf_dir = Path.home() / '.fzf'
        if fzf_dir.exists():
            shutil.rmtree(fzf_dir)
        
        execute_command(f"git clone --depth 1 https://github.com/junegunn/fzf.git {fzf_dir}", "克隆fzf")
        
        # 安装fzf
        install_script = fzf_dir / 'install'
        subprocess.run([str(install_script), '--all'], check=True)
        
        log_info("✓ fzf 安装成功")
    except Exception as e:
        log_warn(f"✗ fzf 安装失败: {e}")

def install_zoxide():
    """安装zoxide"""
    try:
        subprocess.run(['zoxide', '--version'], check=True, capture_output=True)
        log_info("zoxide 已安装")
        return
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    log_info("安装 zoxide...")
    
    try:
        # 使用官方安装脚本
        install_cmd = "curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash"
        subprocess.run(install_cmd, shell=True, check=True)
        
        log_info("✓ zoxide 安装成功")
    except Exception as e:
        log_warn(f"✗ zoxide 安装失败: {e}")

# =============================================================================
# NTP时间同步
# =============================================================================

def sync_ntp_time():
    """同步NTP时间"""
    log_info("开始NTP时间同步...")
    
    ntp_servers = [
        "ntp1.aliyun.com",
        "ntp2.aliyun.com",
        "time1.aliyun.com",
        "cn.pool.ntp.org"
    ]
    
    try:
        # 安装ntpdate
        execute_command("apt install -y ntpdate", "安装ntpdate")
        
        # 尝试同步时间
        for server in ntp_servers:
            try:
                execute_command(f"ntpdate -s {server}", f"同步时间到{server}")
                log_info(f"✓ 时间同步成功: {server}")
                break
            except Exception:
                continue
        else:
            log_warn("所有NTP服务器同步失败")
            return False
        
        # 显示当前时间
        result = subprocess.run(['date'], capture_output=True, text=True, check=True)
        log_info(f"当前时间: {result.stdout.strip()}")
        
        return True
    except Exception as e:
        log_error(f"NTP时间同步失败: {e}")
        return False

# =============================================================================
# Shell环境配置
# =============================================================================

def change_default_shell():
    """更改默认Shell为ZSH"""
    log_info("更改默认Shell为ZSH...")
    
    try:
        current_user = os.getenv('SUDO_USER') or os.getenv('USER')
        if not current_user:
            log_error("无法获取当前用户名")
            return False
        
        # 检查zsh是否安装
        subprocess.run(['which', 'zsh'], check=True, capture_output=True)
        
        # 更改默认shell
        execute_command(f"chsh -s $(which zsh) {current_user}", "更改默认Shell")
        
        log_info("✓ 默认Shell已更改为ZSH")
        return True
    except subprocess.CalledProcessError:
        log_error("ZSH未安装或更改Shell失败")
        return False
    except Exception as e:
        log_error(f"更改默认Shell失败: {e}")
        return False

def install_oh_my_zsh():
    """安装Oh My Zsh"""
    log_info("安装Oh My Zsh...")
    
    oh_my_zsh_dir = Path.home() / '.oh-my-zsh'
    if oh_my_zsh_dir.exists():
        log_info("Oh My Zsh 已安装")
        return True
    
    try:
        # 使用国内镜像安装
        install_cmd = 'REMOTE=https://gitee.com/mirrors/oh-my-zsh.git BRANCH=master sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"'
        
        # 设置环境变量
        env = os.environ.copy()
        env['RUNZSH'] = 'no'  # 安装后不自动启动zsh
        
        subprocess.run(install_cmd, shell=True, env=env, check=True)
        
        log_info("✓ Oh My Zsh 安装成功")
        return True
    except Exception as e:
        log_error(f"Oh My Zsh 安装失败: {e}")
        return False

def install_zsh_plugins():
    """安装ZSH插件"""
    log_info("安装ZSH插件...")
    
    oh_my_zsh_dir = Path.home() / '.oh-my-zsh'
    if not oh_my_zsh_dir.exists():
        log_error("Oh My Zsh 未安装")
        return False
    
    plugins_dir = oh_my_zsh_dir / 'custom' / 'plugins'
    plugins_dir.mkdir(parents=True, exist_ok=True)
    
    # 插件列表
    plugins = {
        'zsh-autosuggestions': 'https://gitee.com/phpxxo/zsh-autosuggestions.git',
        'zsh-syntax-highlighting': 'https://gitee.com/Annihilater/zsh-syntax-highlighting.git',
        'you-should-use': 'https://github.com/MichaelAquilina/zsh-you-should-use.git'
    }
    
    try:
        for plugin_name, repo_url in plugins.items():
            plugin_dir = plugins_dir / plugin_name
            
            if plugin_dir.exists():
                log_info(f"{plugin_name} 已安装")
                continue
            
            execute_command(f"git clone {repo_url} {plugin_dir}", f"安装{plugin_name}")
            log_info(f"✓ {plugin_name} 安装成功")
        
        # 安装Powerlevel10k主题
        themes_dir = oh_my_zsh_dir / 'custom' / 'themes'
        themes_dir.mkdir(parents=True, exist_ok=True)
        
        p10k_dir = themes_dir / 'powerlevel10k'
        if not p10k_dir.exists():
            execute_command(f"git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git {p10k_dir}", "安装Powerlevel10k主题")
            log_info("✓ Powerlevel10k 主题安装成功")
        
        return True
    except Exception as e:
        log_error(f"ZSH插件安装失败: {e}")
        return False

def apply_zshrc_changes():
    """应用.zshrc配置更改"""
    log_info("配置.zshrc文件...")
    
    zshrc_path = Path.home() / '.zshrc'
    
    # 备份原配置
    if zshrc_path.exists():
        backup_path = zshrc_path.with_suffix(f'.backup.{get_timestamp()}')
        shutil.copy2(zshrc_path, backup_path)
        log_info(f"已备份原配置: {backup_path}")
    
    # 创建新配置
    zshrc_content = '''# Oh My Zsh配置
export ZSH="$HOME/.oh-my-zsh"

# 主题设置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件配置
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    you-should-use
)

# 加载Oh My Zsh
source $ZSH/oh-my-zsh.sh

# 用户配置
export EDITOR='vim'
export LANG=en_US.UTF-8

# 别名设置
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# fzf配置
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide配置
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Powerlevel10k配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
'''
    
    try:
        with open(zshrc_path, 'w') as f:
            f.write(zshrc_content)
        
        log_info("✓ .zshrc 配置完成")
        return True
    except Exception as e:
        log_error(f".zshrc 配置失败: {e}")
        return False

def start_zsh():
    """启动ZSH"""
    log_info("配置完成！")
    log_info("请重新登录或运行以下命令启动ZSH:")
    log_info("exec zsh")
    
    if interactive_ask_confirmation("是否现在启动ZSH？", True):
        try:
            os.execvp('zsh', ['zsh'])
        except Exception as e:
            log_error(f"启动ZSH失败: {e}")
            return False
    
    return True

# =============================================================================
# 主菜单
# =============================================================================

def show_main_menu():
    """显示主菜单"""
    options = [
        "🚀 一键安装（推荐）",
        "⏰ 同步NTP服务器",
        "📦 安装基础工具",
        "🐚 更改默认Shell",
        "🎨 安装Oh My Zsh",
        "🔌 安装ZSH插件",
        "⚙️  应用配置更改",
        "▶️  启动ZSH",
        "❌ 退出脚本"
    ]
    
    print("\n" + "="*50)
    print("请选择要执行的操作:")
    print("="*50)
    
    for i, option in enumerate(options, 1):
        print(f"{i}. {option}")
    
    print("="*50)

def main():
    """主函数"""
    try:
        # 显示脚本信息
        show_header("参考安装脚本", "1.0", "包含完整安装流程的参考实现")
        
        while True:
            show_main_menu()
            
            try:
                choice = input("请输入选择（1-9）: ").strip()
                
                if choice == "1":
                    # 一键安装
                    log_info("开始一键安装...")
                    steps = [
                        ("同步NTP时间", sync_ntp_time),
                        ("安装基础工具", install_basic_tools),
                        ("更改默认Shell", change_default_shell),
                        ("安装Oh My Zsh", install_oh_my_zsh),
                        ("安装ZSH插件", install_zsh_plugins),
                        ("应用配置更改", apply_zshrc_changes),
                        ("启动ZSH", start_zsh)
                    ]
                    
                    for step_name, step_func in steps:
                        log_info(f"执行步骤: {step_name}")
                        if not step_func():
                            log_error(f"步骤失败: {step_name}")
                            break
                    else:
                        log_info("一键安装完成！")
                    break
                    
                elif choice == "2":
                    sync_ntp_time()
                elif choice == "3":
                    install_basic_tools()
                elif choice == "4":
                    change_default_shell()
                elif choice == "5":
                    install_oh_my_zsh()
                elif choice == "6":
                    install_zsh_plugins()
                elif choice == "7":
                    apply_zshrc_changes()
                elif choice == "8":
                    start_zsh()
                elif choice == "9":
                    log_info("退出脚本...")
                    break
                else:
                    log_warn("请输入有效选项（1-9）")
                    continue
                
                input("\n按任意键返回菜单...")
                
            except KeyboardInterrupt:
                log_info("\n用户中断操作")
                break
            except Exception as e:
                log_error(f"操作执行失败: {e}")
                input("按任意键继续...")
        
    except Exception as e:
        log_error(f"程序执行过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
