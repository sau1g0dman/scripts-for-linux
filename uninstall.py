#!/usr/bin/env python3

"""
Ubuntu服务器环境卸载脚本 - Python版本
作者: saul
版本: 1.0
描述: 卸载通过scripts-for-linux安装的组件，恢复系统默认配置
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# 添加scripts目录到Python路径
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir / "scripts"))

try:
    from common import *
except ImportError:
    print("错误：无法导入common模块")
    print("请确保common.py文件存在于scripts目录中")
    sys.exit(1)

# =============================================================================
# 卸载函数
# =============================================================================

def show_header():
    """显示脚本头部信息"""
    os.system('clear')
    print(f"{BLUE}================================================================{RESET}")
    print(f"{BLUE}Ubuntu服务器环境卸载脚本{RESET}")
    print(f"{BLUE}版本: 1.0{RESET}")
    print(f"{BLUE}作者: saul{RESET}")
    print(f"{BLUE}================================================================{RESET}")
    print()
    print(f"{YELLOW} 警告：此脚本将卸载通过scripts-for-linux安装的组件{RESET}")
    print(f"{YELLOW}请确保您已经备份了重要的配置文件{RESET}")
    print()

def uninstall_zsh_environment():
    """卸载ZSH环境"""
    log_info("开始卸载ZSH环境...")
    
    try:
        # 恢复默认shell为bash
        current_user = os.getenv('SUDO_USER') or os.getenv('USER')
        if current_user:
            try:
                subprocess.run(['chsh', '-s', '/bin/bash', current_user], check=True)
                log_info("已将默认shell恢复为bash")
            except subprocess.CalledProcessError as e:
                log_warn(f"恢复默认shell失败: {e}")
        
        # 备份并删除ZSH配置文件
        home_dir = Path.home()
        zsh_files = [
            home_dir / '.zshrc',
            home_dir / '.p10k.zsh',
            home_dir / '.oh-my-zsh'
        ]
        
        timestamp = get_timestamp()
        for zsh_file in zsh_files:
            if zsh_file.exists():
                backup_path = zsh_file.with_suffix(f'.uninstall_backup.{timestamp}')
                try:
                    if zsh_file.is_dir():
                        shutil.move(str(zsh_file), str(backup_path))
                    else:
                        shutil.copy2(zsh_file, backup_path)
                        zsh_file.unlink()
                    log_info(f"已备份并删除: {zsh_file}")
                except Exception as e:
                    log_warn(f"处理文件失败 {zsh_file}: {e}")
        
        # 删除ZSH相关的缓存目录
        cache_dirs = [
            home_dir / '.cache' / 'p10k-instant-prompt-*.zsh',
            home_dir / '.cache' / 'zsh'
        ]
        
        for cache_dir in cache_dirs:
            if cache_dir.exists():
                try:
                    if cache_dir.is_dir():
                        shutil.rmtree(cache_dir)
                    else:
                        cache_dir.unlink()
                    log_info(f"已删除缓存: {cache_dir}")
                except Exception as e:
                    log_warn(f"删除缓存失败 {cache_dir}: {e}")
        
        log_info("ZSH环境卸载完成")
        return True
    except Exception as e:
        log_error(f"ZSH环境卸载失败: {e}")
        return False

def uninstall_development_tools():
    """卸载开发工具"""
    log_info("开始卸载开发工具...")
    
    try:
        # 备份并删除Neovim配置
        home_dir = Path.home()
        nvim_dirs = [
            home_dir / '.config' / 'nvim',
            home_dir / '.local' / 'share' / 'nvim',
            home_dir / '.cache' / 'nvim'
        ]
        
        timestamp = get_timestamp()
        for nvim_dir in nvim_dirs:
            if nvim_dir.exists():
                backup_path = nvim_dir.with_suffix(f'.uninstall_backup.{timestamp}')
                try:
                    shutil.move(str(nvim_dir), str(backup_path))
                    log_info(f"已备份并删除: {nvim_dir}")
                except Exception as e:
                    log_warn(f"处理目录失败 {nvim_dir}: {e}")
        
        # 删除LazyGit配置
        lazygit_config = home_dir / '.config' / 'lazygit'
        if lazygit_config.exists():
            try:
                backup_path = lazygit_config.with_suffix(f'.uninstall_backup.{timestamp}')
                shutil.move(str(lazygit_config), str(backup_path))
                log_info(f"已备份并删除LazyGit配置: {lazygit_config}")
            except Exception as e:
                log_warn(f"删除LazyGit配置失败: {e}")
        
        log_info("开发工具卸载完成")
        return True
    except Exception as e:
        log_error(f"开发工具卸载失败: {e}")
        return False

def uninstall_docker_environment():
    """卸载Docker环境"""
    log_info("开始卸载Docker环境...")
    
    try:
        # 停止所有Docker容器
        try:
            result = subprocess.run(['docker', 'ps', '-q'], 
                                  capture_output=True, text=True, check=True)
            if result.stdout.strip():
                log_info("停止所有运行中的Docker容器...")
                subprocess.run(['docker', 'stop'] + result.stdout.strip().split(), 
                              check=True, capture_output=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        # 删除所有Docker容器
        try:
            result = subprocess.run(['docker', 'ps', '-aq'], 
                                  capture_output=True, text=True, check=True)
            if result.stdout.strip():
                log_info("删除所有Docker容器...")
                subprocess.run(['docker', 'rm'] + result.stdout.strip().split(), 
                              check=True, capture_output=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        # 删除所有Docker镜像
        try:
            result = subprocess.run(['docker', 'images', '-q'], 
                                  capture_output=True, text=True, check=True)
            if result.stdout.strip():
                log_info("删除所有Docker镜像...")
                subprocess.run(['docker', 'rmi', '-f'] + result.stdout.strip().split(), 
                              check=True, capture_output=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        # 停止Docker服务
        try:
            subprocess.run(['systemctl', 'stop', 'docker'], check=True, capture_output=True)
            subprocess.run(['systemctl', 'disable', 'docker'], check=True, capture_output=True)
            log_info("Docker服务已停止并禁用")
        except subprocess.CalledProcessError as e:
            log_warn(f"停止Docker服务失败: {e}")
        
        # 删除Docker数据目录
        docker_dirs = [
            Path('/var/lib/docker'),
            Path('/var/lib/containerd')
        ]
        
        for docker_dir in docker_dirs:
            if docker_dir.exists():
                try:
                    shutil.rmtree(docker_dir)
                    log_info(f"已删除Docker数据目录: {docker_dir}")
                except Exception as e:
                    log_warn(f"删除Docker数据目录失败 {docker_dir}: {e}")
        
        log_info("Docker环境卸载完成")
        return True
    except Exception as e:
        log_error(f"Docker环境卸载失败: {e}")
        return False

def clean_system_configurations():
    """清理系统配置"""
    log_info("开始清理系统配置...")
    
    try:
        # 恢复SSH配置
        ssh_config = Path('/etc/ssh/sshd_config')
        ssh_backups = list(ssh_config.parent.glob('sshd_config.backup.*'))
        
        if ssh_backups:
            # 使用最新的备份
            latest_backup = max(ssh_backups, key=lambda p: p.stat().st_mtime)
            try:
                shutil.copy2(latest_backup, ssh_config)
                log_info(f"已恢复SSH配置从: {latest_backup}")
                
                # 重启SSH服务
                subprocess.run(['systemctl', 'restart', 'ssh'], check=True, capture_output=True)
                log_info("SSH服务已重启")
            except Exception as e:
                log_warn(f"恢复SSH配置失败: {e}")
        
        # 恢复时间同步配置
        timesyncd_conf = Path('/etc/systemd/timesyncd.conf')
        timesyncd_backups = list(timesyncd_conf.parent.glob('timesyncd.conf.backup.*'))
        
        if timesyncd_backups:
            latest_backup = max(timesyncd_backups, key=lambda p: p.stat().st_mtime)
            try:
                shutil.copy2(latest_backup, timesyncd_conf)
                log_info(f"已恢复时间同步配置从: {latest_backup}")
                
                # 重启时间同步服务
                subprocess.run(['systemctl', 'restart', 'systemd-timesyncd'], 
                              check=True, capture_output=True)
                log_info("时间同步服务已重启")
            except Exception as e:
                log_warn(f"恢复时间同步配置失败: {e}")
        
        log_info("系统配置清理完成")
        return True
    except Exception as e:
        log_error(f"系统配置清理失败: {e}")
        return False

def remove_installed_packages():
    """删除安装的软件包"""
    if not interactive_ask_confirmation("是否删除通过脚本安装的软件包？", False):
        return True
    
    log_info("开始删除安装的软件包...")
    
    # 可能安装的软件包列表
    packages_to_remove = [
        'zsh', 'oh-my-zsh', 'neovim', 'lazygit', 'ripgrep', 'fd-find',
        'docker.io', 'docker-compose', 'ntpdate', 'openssh-server'
    ]
    
    try:
        for package in packages_to_remove:
            try:
                # 检查包是否已安装
                result = subprocess.run(['dpkg', '-l', package], 
                                      capture_output=True, text=True)
                if result.returncode == 0 and 'ii' in result.stdout:
                    log_info(f"删除软件包: {package}")
                    subprocess.run(['apt', 'remove', '-y', package], 
                                  check=True, capture_output=True)
            except subprocess.CalledProcessError:
                # 包可能未安装，忽略错误
                pass
        
        # 清理不需要的依赖
        try:
            subprocess.run(['apt', 'autoremove', '-y'], check=True, capture_output=True)
            log_info("已清理不需要的依赖包")
        except subprocess.CalledProcessError as e:
            log_warn(f"清理依赖包失败: {e}")
        
        log_info("软件包删除完成")
        return True
    except Exception as e:
        log_error(f"软件包删除失败: {e}")
        return False

def main():
    """主函数"""
    try:
        # 显示头部信息
        show_header()
        
        # 检查root权限
        if os.getuid() != 0:
            log_error("此脚本需要root权限运行")
            log_info("请使用: sudo python3 uninstall.py")
            sys.exit(1)
        
        # 最终确认
        if not interactive_ask_confirmation("确定要卸载scripts-for-linux安装的所有组件吗？", False):
            log_info("用户取消卸载")
            return
        
        log_info("开始卸载scripts-for-linux组件...")
        
        # 卸载各个组件
        components = [
            ("ZSH环境", uninstall_zsh_environment),
            ("开发工具", uninstall_development_tools),
            ("Docker环境", uninstall_docker_environment),
            ("系统配置", clean_system_configurations),
            ("软件包", remove_installed_packages)
        ]
        
        failed_components = []
        for component_name, uninstall_func in components:
            if interactive_ask_confirmation(f"是否卸载{component_name}？", True):
                if not uninstall_func():
                    failed_components.append(component_name)
        
        # 显示卸载结果
        if failed_components:
            log_warn(f"以下组件卸载失败: {', '.join(failed_components)}")
            log_warn("请手动检查并清理相关配置")
        else:
            log_info("所有组件卸载完成！")
        
        log_info("卸载脚本执行完成")
        log_info("建议重新登录以确保所有更改生效")
        
    except KeyboardInterrupt:
        log_info("\n用户中断卸载")
        sys.exit(1)
    except Exception as e:
        log_error(f"卸载过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
