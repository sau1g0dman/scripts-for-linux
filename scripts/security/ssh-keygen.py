#!/usr/bin/env python3

"""
SSH密钥生成和配置脚本 - Python版本
作者: saul
版本: 1.0
描述: 自动生成SSH密钥并配置到远程服务器
"""

import os
import sys
import subprocess
import socket
import getpass
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
# SSH密钥生成函数
# =============================================================================

def generate_ssh_key():
    """生成SSH密钥"""
    log_info("开始生成SSH密钥...")
    
    # 获取密钥名称
    print("请输入RSA密钥的名称：")
    print("默认键入enter为id_rsa")
    print("如果不是，请输入RSA密钥的名称：")
    key_name = input().strip() or "id_rsa"
    
    # 获取注释信息
    default_comment = f"{os.getenv('USER')}@{socket.gethostname()}"
    print(f"请输入密钥的注释（例如你的邮箱），默认为{default_comment}：")
    comment = input().strip() or default_comment
    
    # SSH目录路径
    ssh_dir = Path.home() / ".ssh"
    ssh_dir.mkdir(mode=0o700, exist_ok=True)
    
    key_path = ssh_dir / key_name
    
    # 检查密钥是否已存在
    if key_path.exists():
        if not interactive_ask_confirmation(f"密钥文件 {key_path} 已存在，是否覆盖？", False):
            log_info("取消密钥生成")
            return None
    
    try:
        # 生成SSH密钥
        cmd = [
            'ssh-keygen',
            '-t', 'rsa',
            '-b', '4096',
            '-C', comment,
            '-f', str(key_path),
            '-N', ''  # 空密码，如果需要密码可以修改
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        log_info(f"密钥已生成，文件保存在 {key_path}")
        log_info(f"公钥文件: {key_path}.pub")
        
        return str(key_path)
    except subprocess.CalledProcessError as e:
        log_error(f"密钥生成失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return None

def list_ssh_keys():
    """列出现有的SSH密钥"""
    ssh_dir = Path.home() / ".ssh"
    if not ssh_dir.exists():
        log_warn("SSH目录不存在")
        return []
    
    # 查找私钥文件（通常没有扩展名或以id_开头）
    private_keys = []
    for file_path in ssh_dir.iterdir():
        if file_path.is_file() and not file_path.name.endswith('.pub'):
            # 检查是否是SSH私钥
            try:
                with open(file_path, 'r') as f:
                    first_line = f.readline().strip()
                    if 'PRIVATE KEY' in first_line:
                        private_keys.append(file_path)
            except Exception:
                continue
    
    return private_keys

def select_ssh_key():
    """选择SSH密钥"""
    keys = list_ssh_keys()
    
    if not keys:
        log_info("未找到现有的SSH密钥")
        if interactive_ask_confirmation("是否生成新的SSH密钥？", True):
            return generate_ssh_key()
        else:
            return None
    
    print("\n找到以下SSH密钥:")
    for i, key_path in enumerate(keys, 1):
        print(f"{i}. {key_path.name}")
    
    print(f"{len(keys) + 1}. 生成新密钥")
    
    while True:
        try:
            choice = input(f"请选择密钥 (1-{len(keys) + 1}): ").strip()
            choice_num = int(choice)
            
            if 1 <= choice_num <= len(keys):
                selected_key = keys[choice_num - 1]
                log_info(f"已选择密钥: {selected_key}")
                return str(selected_key)
            elif choice_num == len(keys) + 1:
                return generate_ssh_key()
            else:
                log_warn(f"请输入有效的选择 (1-{len(keys) + 1})")
        except ValueError:
            log_warn("请输入有效的数字")

def install_sshpass():
    """安装sshpass工具"""
    try:
        subprocess.run(['sshpass', '-V'], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        log_info("安装sshpass工具...")
        try:
            execute_command("apt install -y sshpass", "安装sshpass")
            return True
        except Exception as e:
            log_error(f"sshpass安装失败: {e}")
            return False

def add_ssh_key_to_server(key_path):
    """添加SSH密钥到服务器"""
    if not key_path:
        log_error("未选择有效的密钥文件")
        return False
    
    key_path = Path(key_path)
    pub_key_path = key_path.with_suffix('.pub')
    
    if not pub_key_path.exists():
        log_error(f"公钥文件不存在: {pub_key_path}")
        return False
    
    # 获取服务器信息
    print("请输入服务器IP地址：")
    server_ip = input().strip()
    if not server_ip:
        log_error("服务器IP地址不能为空")
        return False
    
    print("请输入服务器用户名：")
    username = input().strip()
    if not username:
        log_error("用户名不能为空")
        return False
    
    print("请输入服务器密码：")
    password = getpass.getpass()
    if not password:
        log_error("密码不能为空")
        return False
    
    # 安装sshpass
    if not install_sshpass():
        log_error("无法安装sshpass，无法自动配置密钥")
        return False
    
    try:
        # 读取公钥内容
        with open(pub_key_path, 'r') as f:
            public_key = f.read().strip()
        
        # 使用ssh-copy-id添加公钥到服务器
        log_info(f"添加公钥到服务器 {server_ip}...")
        
        cmd = [
            'sshpass', '-p', password,
            'ssh-copy-id',
            '-o', 'StrictHostKeyChecking=no',
            '-i', str(pub_key_path),
            f'{username}@{server_ip}'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        log_info("公钥添加成功！")
        
        # 测试SSH连接
        if interactive_ask_confirmation("是否测试SSH密钥连接？", True):
            test_ssh_connection(key_path, username, server_ip)
        
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"添加公钥失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False
    except Exception as e:
        log_error(f"操作过程中发生错误: {e}")
        return False

def test_ssh_connection(key_path, username, server_ip):
    """测试SSH连接"""
    log_info("测试SSH密钥连接...")
    
    try:
        cmd = [
            'ssh',
            '-i', str(key_path),
            '-o', 'StrictHostKeyChecking=no',
            '-o', 'ConnectTimeout=10',
            f'{username}@{server_ip}',
            'echo "SSH密钥连接测试成功！"'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        log_info("SSH密钥连接测试成功！")
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"SSH连接测试失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False

def show_public_key(key_path):
    """显示公钥内容"""
    if not key_path:
        return
    
    pub_key_path = Path(key_path).with_suffix('.pub')
    if not pub_key_path.exists():
        log_warn(f"公钥文件不存在: {pub_key_path}")
        return
    
    try:
        with open(pub_key_path, 'r') as f:
            public_key = f.read().strip()
        
        print("\n" + "="*60)
        print("公钥内容:")
        print("="*60)
        print(public_key)
        print("="*60)
        print(f"公钥文件路径: {pub_key_path}")
        print("="*60)
    except Exception as e:
        log_error(f"读取公钥文件失败: {e}")

def main():
    """主函数"""
    try:
        # 显示脚本信息
        show_header("SSH密钥生成和配置脚本", "1.0", "自动生成SSH密钥并配置到远程服务器")
        
        print("本脚本将帮助您配合ssh-agent添加root密码登录,自动生成sshkey,并将公钥添加到指定服务器。")
        print("请按照提示输入相关信息，然后脚本将自动完成后续操作。")
        print()
        
        # 选择或生成SSH密钥
        key_path = select_ssh_key()
        if not key_path:
            log_info("未选择密钥，退出程序")
            return
        
        # 显示公钥内容
        show_public_key(key_path)
        
        # 询问是否添加到服务器
        if interactive_ask_confirmation("是否将公钥添加到远程服务器？", True):
            add_ssh_key_to_server(key_path)
        
        log_info("SSH密钥配置完成！")
        
    except KeyboardInterrupt:
        log_info("\n用户中断操作")
    except Exception as e:
        log_error(f"程序执行过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
