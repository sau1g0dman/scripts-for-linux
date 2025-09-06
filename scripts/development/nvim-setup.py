#!/usr/bin/env python3

"""
Neovim开发环境安装配置脚本 - Python版本
作者: saul
版本: 2.0
描述: 自动安装Neovim并配置各种开发环境（AstroNvim、LazyVim、NvChad等）
支持标准化交互式界面
"""

import os
import sys
import subprocess
import shutil
import json
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
# 配置变量
# =============================================================================

NEOVIM_APPIMAGE_URL = "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
NEOVIM_INSTALL_PATH = "/usr/local/bin/nvim"

# 配置选项
NVIM_CONFIGS = {
    "1": {
        "name": "AstroNvim",
        "description": "功能丰富的Neovim发行版，开箱即用",
        "repo": "https://github.com/AstroNvim/AstroNvim",
        "backup_suffix": "astronvim_backup"
    },
    "2": {
        "name": "LazyVim",
        "description": "基于lazy.nvim的现代化配置",
        "repo": "https://github.com/LazyVim/starter",
        "backup_suffix": "lazyvim_backup"
    },
    "3": {
        "name": "NvChad",
        "description": "美观且快速的Neovim配置",
        "repo": "https://github.com/NvChad/NvChad",
        "backup_suffix": "nvchad_backup"
    },
    "4": {
        "name": "自定义配置",
        "description": "基础Neovim安装，不包含预设配置",
        "repo": None,
        "backup_suffix": "custom_backup"
    }
}

# =============================================================================
# 错误处理
# =============================================================================

def handle_error(error_msg, line_number=None):
    """处理错误"""
    if line_number:
        log_error(f"脚本在第 {line_number} 行发生错误")
    log_error(error_msg)
    log_error("错误详情：")
    log_error(f"  - 当前工作目录: {os.getcwd()}")
    log_error(f"  - 当前用户: {os.getenv('USER', 'unknown')}")
    
    log_error("调试建议：")
    log_error("  1. 检查网络连接是否正常")
    log_error("  2. 确认有足够的磁盘空间")
    log_error("  3. 验证用户权限是否充足")
    log_error("  4. 查看系统日志获取更多信息")

# =============================================================================
# 系统检查函数
# =============================================================================

def check_system_requirements():
    """检查系统要求"""
    log_info("检查系统要求...")
    
    # 检查操作系统
    if not detect_os() in ['ubuntu', 'debian']:
        log_error("此脚本仅支持Ubuntu和Debian系统")
        return False
    
    # 检查网络连接
    if not check_network():
        log_error("网络连接失败，无法下载Neovim")
        return False
    
    # 检查磁盘空间（至少需要500MB）
    try:
        statvfs = os.statvfs('/')
        free_space = statvfs.f_frsize * statvfs.f_bavail
        if free_space < 500 * 1024 * 1024:  # 500MB
            log_warn("磁盘空间不足500MB，可能影响安装")
    except Exception as e:
        log_warn(f"无法检查磁盘空间: {e}")
    
    log_info("系统要求检查完成")
    return True

def install_dependencies():
    """安装依赖包"""
    log_info("安装必要的依赖包...")
    
    dependencies = [
        "curl", "git", "unzip", "tar", "gzip",
        "build-essential", "cmake", "gettext",
        "python3", "python3-pip", "nodejs", "npm"
    ]
    
    try:
        # 更新包列表
        execute_command("apt update", "更新包列表")
        
        # 安装依赖
        deps_str = " ".join(dependencies)
        execute_command(f"apt install -y {deps_str}", "安装依赖包")
        
        log_info("依赖包安装完成")
        return True
    except Exception as e:
        log_error(f"依赖包安装失败: {e}")
        return False

# =============================================================================
# Neovim安装函数
# =============================================================================

def check_neovim_installed():
    """检查Neovim是否已安装"""
    try:
        result = subprocess.run(['nvim', '--version'], 
                              capture_output=True, text=True, check=True)
        version_line = result.stdout.split('\n')[0]
        log_info(f"Neovim已安装: {version_line}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        log_info("Neovim未安装")
        return False

def install_neovim():
    """安装Neovim"""
    log_info("开始安装Neovim...")
    
    try:
        # 下载Neovim AppImage
        log_info("下载Neovim AppImage...")
        execute_command(f"curl -L {NEOVIM_APPIMAGE_URL} -o /tmp/nvim.appimage", "下载Neovim")
        
        # 设置执行权限
        execute_command("chmod +x /tmp/nvim.appimage", "设置执行权限")
        
        # 移动到系统路径
        execute_command(f"mv /tmp/nvim.appimage {NEOVIM_INSTALL_PATH}", "安装Neovim")
        
        # 验证安装
        result = subprocess.run(['nvim', '--version'], 
                              capture_output=True, text=True, check=True)
        version_line = result.stdout.split('\n')[0]
        log_info(f"Neovim安装成功: {version_line}")
        return True
    except Exception as e:
        log_error(f"Neovim安装失败: {e}")
        return False

# =============================================================================
# 配置管理函数
# =============================================================================

def backup_existing_config():
    """备份现有配置"""
    nvim_config_dir = Path.home() / ".config" / "nvim"
    nvim_data_dir = Path.home() / ".local" / "share" / "nvim"
    nvim_cache_dir = Path.home() / ".cache" / "nvim"
    
    timestamp = get_timestamp()
    
    for config_dir in [nvim_config_dir, nvim_data_dir, nvim_cache_dir]:
        if config_dir.exists():
            backup_dir = config_dir.with_suffix(f".backup.{timestamp}")
            try:
                shutil.move(str(config_dir), str(backup_dir))
                log_info(f"已备份: {config_dir} -> {backup_dir}")
            except Exception as e:
                log_warn(f"备份失败 {config_dir}: {e}")

def install_nvim_config(config_choice):
    """安装Neovim配置"""
    config = NVIM_CONFIGS.get(config_choice)
    if not config:
        log_error("无效的配置选择")
        return False
    
    log_info(f"安装 {config['name']} 配置...")
    
    if config['repo'] is None:
        log_info("选择自定义配置，跳过预设配置安装")
        return True
    
    try:
        nvim_config_dir = Path.home() / ".config" / "nvim"
        
        # 克隆配置仓库
        execute_command(f"git clone {config['repo']} {nvim_config_dir}", f"克隆{config['name']}配置")
        
        log_info(f"{config['name']} 配置安装完成")
        return True
    except Exception as e:
        log_error(f"{config['name']} 配置安装失败: {e}")
        return False

def install_additional_tools():
    """安装额外的开发工具"""
    log_info("安装额外的开发工具...")
    
    tools = {
        "ripgrep": "rg",
        "fd-find": "fd",
        "lazygit": "lazygit"
    }
    
    for package, command in tools.items():
        try:
            # 检查是否已安装
            subprocess.run([command, '--version'], 
                          capture_output=True, check=True)
            log_info(f"{package} 已安装")
        except (subprocess.CalledProcessError, FileNotFoundError):
            try:
                if package == "lazygit":
                    # LazyGit需要特殊安装方式
                    install_cmd = "curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep browser_download_url | grep Linux_x86_64 | cut -d '\"' -f 4 | wget -qi - -O /tmp/lazygit.tar.gz && tar xf /tmp/lazygit.tar.gz -C /tmp && sudo install /tmp/lazygit /usr/local/bin"
                    execute_command(install_cmd, f"安装{package}")
                else:
                    execute_command(f"apt install -y {package}", f"安装{package}")
                log_info(f"{package} 安装成功")
            except Exception as e:
                log_warn(f"{package} 安装失败: {e}")

# =============================================================================
# 交互式界面
# =============================================================================

def show_config_menu():
    """显示配置选择菜单"""
    print("\n" + "="*60)
    print("请选择Neovim配置:")
    print("="*60)
    
    for key, config in NVIM_CONFIGS.items():
        print(f"{key}. {config['name']}")
        print(f"   {config['description']}")
        print()
    
    while True:
        choice = input("请输入选择 (1-4): ").strip()
        if choice in NVIM_CONFIGS:
            return choice
        else:
            log_warn("请输入有效的选择 (1-4)")

def main():
    """主函数"""
    try:
        # 初始化环境
        init_environment()
        
        # 显示脚本信息
        show_header("Neovim开发环境安装配置脚本", "2.0", 
                   "自动安装Neovim并配置各种开发环境")
        
        # 检查系统要求
        if not check_system_requirements():
            log_error("系统要求检查失败")
            sys.exit(1)
        
        # 安装依赖
        if not install_dependencies():
            log_error("依赖安装失败")
            sys.exit(1)
        
        # 检查并安装Neovim
        if not check_neovim_installed():
            if not install_neovim():
                log_error("Neovim安装失败")
                sys.exit(1)
        
        # 备份现有配置
        if interactive_ask_confirmation("是否备份现有的Neovim配置？", True):
            backup_existing_config()
        
        # 选择配置
        config_choice = show_config_menu()
        
        # 安装选择的配置
        if not install_nvim_config(config_choice):
            log_error("Neovim配置安装失败")
            sys.exit(1)
        
        # 安装额外工具
        if interactive_ask_confirmation("是否安装额外的开发工具？", True):
            install_additional_tools()
        
        log_info("Neovim开发环境安装完成！")
        log_info("请运行 'nvim' 启动Neovim")
        
        if config_choice != "4":
            log_info("首次启动时，配置会自动下载和安装插件，请耐心等待")
        
    except KeyboardInterrupt:
        log_info("\n用户中断安装")
        sys.exit(1)
    except Exception as e:
        handle_error(f"安装过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
