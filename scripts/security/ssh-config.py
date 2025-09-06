#!/usr/bin/env python3

"""
SSH配置脚本 - Python版本
作者: saul
版本: 1.0
描述: 安全的SSH服务器配置，支持Ubuntu/Debian系统
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path
import re

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
# 系统检测
# =============================================================================

def check_system_compatibility():
    """检查系统兼容性"""
    if not Path("/etc/os-release").exists():
        log_error("未找到系统标识文件 /etc/os-release")
        return False

    os_name, os_version = detect_os()
    os_name_lower = os_name.lower()

    # 检查是否为支持的系统
    supported_systems = ['ubuntu', 'debian']
    is_supported = any(sys_name in os_name_lower for sys_name in supported_systems)

    if not is_supported:
        log_error(f"仅支持Ubuntu/Debian系统（当前系统：{os_name} {os_version}）")
        return False

    log_info(f"系统兼容性检查通过: {os_name} {os_version}")
    return True

# =============================================================================
# SSH服务管理
# =============================================================================

def install_ssh_server():
    """安装SSH服务器"""
    log_info("检查SSH服务器安装状态...")

    try:
        # 检查是否已安装
        result = subprocess.run(['dpkg', '-l', 'openssh-server'],
                              capture_output=True, text=True)
        if result.returncode == 0 and 'ii' in result.stdout:
            log_info("SSH服务器已安装")
            return True
    except subprocess.CalledProcessError:
        pass

    log_info("安装SSH服务器...")
    try:
        execute_command("apt update", "更新包列表")
        execute_command("apt install -y openssh-server", "安装SSH服务器")
        log_info("SSH服务器安装完成")
        return True
    except Exception as e:
        log_error(f"SSH服务器安装失败: {e}")
        return False

def backup_ssh_config():
    """备份SSH配置文件"""
    ssh_config_path = Path("/etc/ssh/sshd_config")
    if not ssh_config_path.exists():
        log_warn("SSH配置文件不存在")
        return False

    timestamp = get_timestamp()
    backup_path = ssh_config_path.with_suffix(f".backup.{timestamp}")

    try:
        shutil.copy2(ssh_config_path, backup_path)
        log_info(f"SSH配置已备份到: {backup_path}")
        return True
    except Exception as e:
        log_error(f"备份SSH配置失败: {e}")
        return False

def configure_ssh_security():
    """配置SSH安全设置"""
    log_info("配置SSH安全设置...")

    ssh_config_path = Path("/etc/ssh/sshd_config")

    # 安全配置项
    security_configs = {
        'Port': '22',
        'Protocol': '2',
        'PermitRootLogin': 'yes',
        'PasswordAuthentication': 'yes',
        'PubkeyAuthentication': 'yes',
        'AuthorizedKeysFile': '.ssh/authorized_keys',
        'PermitEmptyPasswords': 'no',
        'ChallengeResponseAuthentication': 'no',
        'UsePAM': 'yes',
        'X11Forwarding': 'no',
        'PrintMotd': 'no',
        'AcceptEnv': 'LANG LC_*',
        'Subsystem': 'sftp /usr/lib/openssh/sftp-server',
        'MaxAuthTries': '3',
        'ClientAliveInterval': '300',
        'ClientAliveCountMax': '2',
        'LoginGraceTime': '60',
        'MaxStartups': '10:30:100',
        'AllowAgentForwarding': 'yes',  # SSH代理转发支持
        'AllowUsers': '',  # 将在后面设置
    }

    try:
        # 读取现有配置
        with open(ssh_config_path, 'r') as f:
            lines = f.readlines()

        # 第一步：移除所有要更新的配置项的现有行
        filtered_lines = []
        for line in lines:
            stripped_line = line.strip()

            # 保留注释和空行
            if not stripped_line or stripped_line.startswith('#'):
                filtered_lines.append(line)
                continue

            # 解析配置项
            parts = stripped_line.split(None, 1)
            if len(parts) >= 1:
                key = parts[0]
                # 如果这个配置项在我们的安全配置中，跳过它（稍后会添加新的）
                if key in security_configs:
                    log_debug(f"移除现有配置项: {stripped_line}")
                    continue
                else:
                    # 保留不在我们配置列表中的其他配置项
                    filtered_lines.append(line)
            else:
                filtered_lines.append(line)

        # 第二步：添加我们的安全配置项
        config_lines = []
        config_lines.append("\n# SSH Security Configuration - Auto-generated\n")

        for key, value in security_configs.items():
            if key == 'AllowUsers':
                # 特殊处理AllowUsers配置
                current_user = os.getenv('SUDO_USER') or os.getenv('USER')
                if current_user and current_user != 'root':
                    config_lines.append(f"AllowUsers {current_user}\n")
                    log_info(f"配置AllowUsers: {current_user}")
            elif value:  # 只添加有值的配置项
                config_lines.append(f"{key} {value}\n")
                log_debug(f"配置{key}: {value}")

        # 第三步：合并配置
        new_lines = filtered_lines + config_lines

        # 写入新配置
        with open(ssh_config_path, 'w') as f:
            f.writelines(new_lines)

        log_success("SSH安全配置完成")
        log_info("已配置的安全选项:")
        for key, value in security_configs.items():
            if key == 'AllowUsers':
                current_user = os.getenv('SUDO_USER') or os.getenv('USER')
                if current_user and current_user != 'root':
                    log_info(f"  - {key}: {current_user}")
            elif value:
                log_info(f"  - {key}: {value}")

        return True
    except Exception as e:
        log_error(f"SSH安全配置失败: {e}")
        return False

def configure_ssh_client_agent_forwarding():
    """配置SSH客户端代理转发"""
    log_info("配置SSH客户端代理转发...")

    ssh_client_config_path = Path.home() / ".ssh" / "config"
    ssh_dir = Path.home() / ".ssh"

    # 确保.ssh目录存在
    ssh_dir.mkdir(mode=0o700, exist_ok=True)

    # SSH客户端配置内容
    agent_forwarding_config = """# SSH Agent Forwarding Configuration
Host *
    ForwardAgent yes
    AddKeysToAgent yes
    IdentitiesOnly no
    ServerAliveInterval 60
    ServerAliveCountMax 3

"""

    try:
        # 检查是否已存在配置
        if ssh_client_config_path.exists():
            with open(ssh_client_config_path, 'r') as f:
                existing_content = f.read()

            if "ForwardAgent yes" in existing_content:
                log_info("SSH代理转发配置已存在")
                return True

            # 在现有配置前添加代理转发配置
            with open(ssh_client_config_path, 'w') as f:
                f.write(agent_forwarding_config + existing_content)
        else:
            # 创建新的配置文件
            with open(ssh_client_config_path, 'w') as f:
                f.write(agent_forwarding_config)

        # 设置正确的权限
        ssh_client_config_path.chmod(0o600)

        log_success("SSH客户端代理转发配置完成")
        return True

    except Exception as e:
        log_error(f"配置SSH客户端代理转发失败: {e}")
        return False

def restart_ssh_service():
    """重启SSH服务"""
    log_info("重启SSH服务...")

    try:
        # 测试配置文件语法
        result = subprocess.run(['sshd', '-t'],
                              capture_output=True, text=True)
        if result.returncode != 0:
            log_error("SSH配置文件语法错误:")
            log_error(result.stderr)
            return False

        # 重启服务
        execute_command("systemctl restart ssh", "重启SSH服务")
        execute_command("systemctl enable ssh", "启用SSH服务")

        # 检查服务状态
        result = subprocess.run(['systemctl', 'is-active', 'ssh'],
                              capture_output=True, text=True)
        if result.stdout.strip() == 'active':
            log_info("SSH服务运行正常")
            return True
        else:
            log_error("SSH服务启动失败")
            return False
    except Exception as e:
        log_error(f"重启SSH服务失败: {e}")
        return False

def show_ssh_status():
    """显示SSH状态信息"""
    print(f"\n{GREEN}{'='*70}")
    print(f" SSH服务状态信息")
    print(f"{'='*70}{RESET}")
    print()

    try:
        # 服务状态
        print(f"{CYAN}服务状态：{RESET}")
        print(f"{BLUE}{'─'*70}{RESET}")
        result = subprocess.run(['systemctl', 'status', 'ssh', '--no-pager'],
                              capture_output=True, text=True)
        print(result.stdout)

        # 监听端口
        result = subprocess.run(['ss', '-tlnp', '| grep :22'],
                              shell=True, capture_output=True, text=True)
        if result.stdout:
            print(f"\n{CYAN}SSH监听端口：{RESET}")
            print(f"{BLUE}{'─'*70}{RESET}")
            print(result.stdout)

        # 当前连接
        result = subprocess.run(['who'], capture_output=True, text=True)
        if result.stdout:
            print(f"\n{CYAN}当前SSH连接：{RESET}")
            print(f"{BLUE}{'─'*70}{RESET}")
            print(result.stdout)

        print(f"{GREEN}{'='*70}{RESET}")
        print()

    except Exception as e:
        log_warn(f"获取SSH状态信息失败: {e}")

def configure_firewall():
    """配置防火墙规则"""
    if not interactive_ask_confirmation("是否配置防火墙规则？", True):
        return True

    log_info("配置防火墙规则...")

    try:
        # 检查ufw是否安装
        result = subprocess.run(['which', 'ufw'], capture_output=True)
        if result.returncode != 0:
            log_info("安装ufw防火墙...")
            execute_command("apt install -y ufw", "安装ufw")

        # 配置防火墙规则
        execute_command("ufw --force reset", "重置防火墙规则")
        execute_command("ufw default deny incoming", "设置默认拒绝入站")
        execute_command("ufw default allow outgoing", "设置默认允许出站")
        execute_command("ufw allow ssh", "允许SSH连接")
        execute_command("ufw --force enable", "启用防火墙")

        log_info("防火墙配置完成")
        return True
    except Exception as e:
        log_error(f"防火墙配置失败: {e}")
        return False

def main():
    """主函数"""
    try:
        # 初始化环境
        init_environment()

        # 显示脚本信息
        show_header("SSH安全配置脚本", "1.0", "配置安全的SSH服务器")

        # 检查系统兼容性
        if not check_system_compatibility():
            sys.exit(1)

        # 检查root权限
        if os.getuid() != 0:
            log_error("此脚本需要root权限运行")
            log_info("请使用: sudo python3 ssh-config.py")
            sys.exit(1)

        # 安装SSH服务器
        if not install_ssh_server():
            log_error("SSH服务器安装失败")
            sys.exit(1)

        # 备份配置文件
        if not backup_ssh_config():
            log_warn("配置文件备份失败，继续执行...")

        # 配置SSH安全设置
        if not configure_ssh_security():
            log_error("SSH安全配置失败")
            sys.exit(1)

        # 重启SSH服务
        if not restart_ssh_service():
            log_error("SSH服务重启失败")
            sys.exit(1)

        # 配置SSH客户端代理转发
        if not configure_ssh_client_agent_forwarding():
            log_warn("SSH客户端代理转发配置失败，继续执行...")

        # 配置防火墙
        configure_firewall()

        # 显示状态信息
        show_ssh_status()

        # 显示完成信息
        print(f"\n{GREEN}{'='*70}")
        print(f" SSH安全配置完成！")
        print(f"{'='*70}{RESET}")
        print()
        print(f"{YELLOW}重要提醒：{RESET}")
        print(f"{BLUE}{'─'*70}{RESET}")
        print(f"  {GREEN}1.{RESET} root用户登录已被启用")
        print(f"  {GREEN}2.{RESET} 请确保当前用户可以正常SSH登录")
        print(f"  {GREEN}3.{RESET} 建议配置SSH密钥认证以提高安全性")
        print(f"  {GREEN}4.{RESET} SSH代理转发功能已配置")
        print(f"{BLUE}{'─'*70}{RESET}")
        print(f"{GREEN}感谢使用SSH安全配置脚本！{RESET}")
        print()

    except KeyboardInterrupt:
        log_info("\n用户中断配置")
        sys.exit(1)
    except Exception as e:
        log_error(f"配置过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
