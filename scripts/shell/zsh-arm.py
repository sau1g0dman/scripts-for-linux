#!/usr/bin/env python3

"""
ZSH ARM版本安装脚本 - Python版本
作者: saul
版本: 1.0
描述: 专为ARM设备优化的ZSH安装脚本，支持OpenWrt、树莓派等ARM设备
"""

import os
import sys
import subprocess
import shutil
import urllib.request
from pathlib import Path

# 添加scripts目录到Python路径
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir.parent))

try:
    from common import *
except ImportError:
    print("错误：无法导入common模块")
    print("请确保common.py文件存在于scripts目录中")
    sys.exit(1)

# =============================================================================
# 颜色定义（兼容老旧终端）
# =============================================================================
try:
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    RESET = '\033[m'
except:
    RED = GREEN = YELLOW = BLUE = RESET = ''

# =============================================================================
# 系统检查函数
# =============================================================================

def check_root_permission():
    """检查root权限"""
    if os.getuid() != 0:
        print(f"{YELLOW}警告：非root用户运行，可能需要手动处理权限问题{RESET}")
        return False
    return True

def update_system():
    """系统更新与依赖安装"""
    print(f"{BLUE}[1/7] 系统更新与依赖安装{RESET}")
    print(f"{BLUE}• 更新软件包列表...{RESET}")
    
    try:
        subprocess.run(['opkg', 'update'], check=True, capture_output=True)
        print(f"{GREEN}✔ 成功：软件包列表更新完成{RESET}")
    except subprocess.CalledProcessError:
        print(f"{RED}✖ 失败：更新软件包列表失败！请检查网络连接或OpenWrt配置{RESET}")
        return False
    except FileNotFoundError:
        print(f"{RED}✖ 失败：未找到opkg包管理器，此脚本仅支持OpenWrt系统{RESET}")
        return False
    
    print(f"{BLUE}• 安装Zsh、Git、Vim...{RESET}")
    try:
        packages = ['zsh', 'git', 'git-http', 'vim-full', 'vim-runtime']
        subprocess.run(['opkg', 'install'] + packages, check=True, capture_output=True)
        
        # 备份Vim配置
        vimrc_path = Path.home() / '.vimrc'
        if vimrc_path.exists():
            timestamp = get_timestamp()
            backup_path = vimrc_path.with_suffix(f'.bak.{timestamp}')
            shutil.copy2(vimrc_path, backup_path)
        
        # 应用服务器优化版Vim配置
        vim_config_url = "https://raw.githubusercontent.com/wklken/vim-for-server/master/vimrc"
        try:
            urllib.request.urlretrieve(vim_config_url, vimrc_path)
        except Exception as e:
            print(f"{YELLOW}警告：Vim配置下载失败: {e}{RESET}")
        
        print(f"{GREEN}✔ 成功：工具安装及Vim配置完成{RESET}")
        return True
    except subprocess.CalledProcessError:
        print(f"{RED}✖ 失败：依赖安装失败！请检查软件源是否支持当前架构{RESET}")
        return False

def cleanup_old_oh_my_zsh():
    """清理旧版Oh My Zsh目录"""
    print(f"{BLUE}[2/7] 清理旧版Oh My Zsh目录{RESET}")
    
    oh_my_zsh_dir = Path.home() / '.oh-my-zsh'
    if oh_my_zsh_dir.exists():
        print(f"{YELLOW}ℹ 提示：检测到旧版目录，正在清理...{RESET}")
        try:
            shutil.rmtree(oh_my_zsh_dir)
            print(f"{GREEN}✔ 成功：旧目录清理完成{RESET}")
        except Exception as e:
            print(f"{RED}✖ 失败：清理旧目录失败: {e}{RESET}")
            return False
    else:
        print(f"{GREEN}✔ 跳过：未检测到旧版Oh My Zsh目录{RESET}")
    
    return True

def install_oh_my_zsh():
    """安装Oh My Zsh框架"""
    print(f"{BLUE}[3/7] 安装Oh My Zsh框架{RESET}")
    
    try:
        # 使用国内镜像源安装Oh My Zsh
        install_cmd = 'sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"'
        
        # 设置环境变量使用国内源
        env = os.environ.copy()
        env['REMOTE'] = 'https://gitee.com/mirrors/oh-my-zsh.git'
        env['BRANCH'] = 'master'
        
        result = subprocess.run(install_cmd, shell=True, env=env, 
                              capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            print(f"{GREEN}✔ 成功：Oh My Zsh框架安装完成{RESET}")
            return True
        else:
            print(f"{RED}✖ 失败：Oh My Zsh安装失败{RESET}")
            if result.stderr:
                print(f"{RED}错误详情: {result.stderr}{RESET}")
            return False
    except subprocess.TimeoutExpired:
        print(f"{RED}✖ 失败：Oh My Zsh安装超时{RESET}")
        return False
    except Exception as e:
        print(f"{RED}✖ 失败：Oh My Zsh安装过程中发生错误: {e}{RESET}")
        return False

def install_powerlevel10k():
    """安装Powerlevel10k主题"""
    print(f"{BLUE}[4/7] 安装Powerlevel10k主题{RESET}")
    
    oh_my_zsh_dir = Path.home() / '.oh-my-zsh'
    if not oh_my_zsh_dir.exists():
        print(f"{RED}✖ 失败：Oh My Zsh目录不存在{RESET}")
        return False
    
    themes_dir = oh_my_zsh_dir / 'custom' / 'themes'
    themes_dir.mkdir(parents=True, exist_ok=True)
    
    p10k_dir = themes_dir / 'powerlevel10k'
    
    try:
        # 克隆Powerlevel10k主题
        if p10k_dir.exists():
            shutil.rmtree(p10k_dir)
        
        git_cmd = [
            'git', 'clone', '--depth=1',
            'https://gitee.com/romkatv/powerlevel10k.git',
            str(p10k_dir)
        ]
        
        subprocess.run(git_cmd, check=True, capture_output=True, timeout=180)
        print(f"{GREEN}✔ 成功：Powerlevel10k主题安装完成{RESET}")
        return True
    except subprocess.TimeoutExpired:
        print(f"{RED}✖ 失败：Powerlevel10k主题下载超时{RESET}")
        return False
    except subprocess.CalledProcessError as e:
        print(f"{RED}✖ 失败：Powerlevel10k主题安装失败: {e}{RESET}")
        return False

def install_zsh_plugins():
    """安装ZSH插件"""
    print(f"{BLUE}[5/7] 安装ZSH插件{RESET}")
    
    oh_my_zsh_dir = Path.home() / '.oh-my-zsh'
    plugins_dir = oh_my_zsh_dir / 'custom' / 'plugins'
    plugins_dir.mkdir(parents=True, exist_ok=True)
    
    plugins = {
        'zsh-autosuggestions': 'https://gitee.com/phpxxo/zsh-autosuggestions.git',
        'zsh-syntax-highlighting': 'https://gitee.com/Annihilater/zsh-syntax-highlighting.git'
    }
    
    for plugin_name, repo_url in plugins.items():
        print(f"{BLUE}• 安装 {plugin_name}...{RESET}")
        plugin_dir = plugins_dir / plugin_name
        
        try:
            if plugin_dir.exists():
                shutil.rmtree(plugin_dir)
            
            git_cmd = ['git', 'clone', '--depth=1', repo_url, str(plugin_dir)]
            subprocess.run(git_cmd, check=True, capture_output=True, timeout=120)
            print(f"{GREEN}✔ 成功：{plugin_name} 安装完成{RESET}")
        except subprocess.TimeoutExpired:
            print(f"{RED}✖ 失败：{plugin_name} 下载超时{RESET}")
            return False
        except subprocess.CalledProcessError as e:
            print(f"{RED}✖ 失败：{plugin_name} 安装失败: {e}{RESET}")
            return False
    
    return True

def configure_zshrc():
    """配置.zshrc文件"""
    print(f"{BLUE}[6/7] 配置.zshrc文件{RESET}")
    
    zshrc_path = Path.home() / '.zshrc'
    
    # 备份原配置
    if zshrc_path.exists():
        timestamp = get_timestamp()
        backup_path = zshrc_path.with_suffix(f'.backup.{timestamp}')
        shutil.copy2(zshrc_path, backup_path)
        print(f"{GREEN}✔ 原配置已备份到: {backup_path}{RESET}")
    
    # 创建新的.zshrc配置
    zshrc_content = '''# Oh My Zsh配置
export ZSH="$HOME/.oh-my-zsh"

# 主题设置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件配置
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# 加载Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ARM设备优化设置
export HISTSIZE=1000
export SAVEHIST=1000
export HISTFILE=~/.zsh_history

# 别名设置
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# 如果存在Powerlevel10k配置文件，则加载
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
'''
    
    try:
        with open(zshrc_path, 'w') as f:
            f.write(zshrc_content)
        print(f"{GREEN}✔ 成功：.zshrc配置完成{RESET}")
        return True
    except Exception as e:
        print(f"{RED}✖ 失败：.zshrc配置失败: {e}{RESET}")
        return False

def change_default_shell():
    """更改默认Shell"""
    print(f"{BLUE}[7/7] 更改默认Shell{RESET}")
    
    try:
        # 检查zsh是否在/etc/shells中
        with open('/etc/shells', 'r') as f:
            shells = f.read()
        
        zsh_path = '/bin/zsh'
        if zsh_path not in shells:
            print(f"{YELLOW}ℹ 提示：添加zsh到/etc/shells{RESET}")
            with open('/etc/shells', 'a') as f:
                f.write(f'\n{zsh_path}\n')
        
        # 更改默认shell
        current_user = os.getenv('USER')
        if current_user:
            subprocess.run(['chsh', '-s', zsh_path, current_user], check=True)
            print(f"{GREEN}✔ 成功：默认Shell已更改为ZSH{RESET}")
        else:
            print(f"{YELLOW}ℹ 提示：请手动运行 'chsh -s /bin/zsh' 更改默认Shell{RESET}")
        
        return True
    except Exception as e:
        print(f"{RED}✖ 失败：更改默认Shell失败: {e}{RESET}")
        print(f"{YELLOW}ℹ 提示：请手动运行 'chsh -s /bin/zsh' 更改默认Shell{RESET}")
        return False

def main():
    """主函数"""
    try:
        print(f"{BLUE}ZSH ARM版本安装脚本{RESET}")
        print(f"{BLUE}专为ARM设备优化（OpenWrt、树莓派等）{RESET}")
        print("="*50)
        
        # 检查root权限
        check_root_permission()
        
        # 执行安装步骤
        steps = [
            ("系统更新与依赖安装", update_system),
            ("清理旧版Oh My Zsh", cleanup_old_oh_my_zsh),
            ("安装Oh My Zsh框架", install_oh_my_zsh),
            ("安装Powerlevel10k主题", install_powerlevel10k),
            ("安装ZSH插件", install_zsh_plugins),
            ("配置.zshrc文件", configure_zshrc),
            ("更改默认Shell", change_default_shell)
        ]
        
        for step_name, step_func in steps:
            if not step_func():
                print(f"{RED}✖ 安装失败：{step_name}{RESET}")
                sys.exit(1)
        
        print(f"\n{GREEN}🎉 ZSH ARM版本安装完成！{RESET}")
        print(f"{GREEN}请重新登录或运行 'zsh' 启动新的Shell环境{RESET}")
        print(f"{GREEN}首次启动时会自动配置Powerlevel10k主题{RESET}")
        
    except KeyboardInterrupt:
        print(f"\n{YELLOW}用户中断安装{RESET}")
        sys.exit(1)
    except Exception as e:
        print(f"{RED}安装过程中发生错误: {e}{RESET}")
        sys.exit(1)

if __name__ == "__main__":
    main()
