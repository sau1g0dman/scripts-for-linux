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
except ImportError as e:
    print(f"错误：无法导入common模块: {e}")
    print("请确保common.py文件存在于scripts目录中")
    print(f"当前Python路径: {sys.path}")
    print(f"脚本目录: {script_dir}")
    sys.exit(1)

# 验证关键函数是否已导入
try:
    log_success("SSH密钥生成脚本初始化成功")
except NameError as e:
    print(f"错误：关键函数未正确导入: {e}")
    sys.exit(1)

# =============================================================================
# 输入处理函数
# =============================================================================

def safe_input(prompt: str, default: str = "") -> str:
    """安全的输入函数，处理各种输入异常"""
    try:
        if not sys.stdin.isatty():
            log_warn(f"非交互式环境，使用默认值: {default}")
            return default

        print(prompt, end="", flush=True)
        result = input().strip()
        return result if result else default

    except (EOFError, KeyboardInterrupt):
        log_info("\n用户取消输入")
        return default
    except Exception as e:
        log_error(f"输入异常: {e}")
        return default

def safe_password_input(prompt: str) -> str:
    """安全的密码输入函数"""
    try:
        if not sys.stdin.isatty():
            log_error("密码输入需要交互式终端")
            return ""

        print(prompt, end="", flush=True)
        password = getpass.getpass("")
        return password

    except (EOFError, KeyboardInterrupt):
        log_info("\n用户取消输入")
        return ""
    except Exception as e:
        log_error(f"密码输入异常: {e}")
        return ""

# =============================================================================
# SSH代理管理函数
# =============================================================================

def is_ssh_agent_running():
    """检查SSH代理是否正在运行"""
    ssh_auth_sock = os.environ.get('SSH_AUTH_SOCK')

    if not ssh_auth_sock:
        return False

    # 检查socket文件是否存在且有效
    try:
        sock_path = Path(ssh_auth_sock)
        if sock_path.exists() and sock_path.is_socket():
            # 尝试连接到socket以验证代理是否响应
            import socket as sock
            s = sock.socket(sock.AF_UNIX, sock.SOCK_STREAM)
            s.settimeout(1)
            s.connect(ssh_auth_sock)
            s.close()
            return True
    except (OSError, Exception):
        pass

    return False

def start_ssh_agent():
    """启动SSH代理"""
    try:
        # 启动ssh-agent，设置12小时超时
        result = subprocess.run(['ssh-agent', '-t', '12h'],
                              capture_output=True, text=True, check=True)

        # 解析并设置环境变量
        for line in result.stdout.split('\n'):
            if line.startswith('SSH_AUTH_SOCK='):
                os.environ['SSH_AUTH_SOCK'] = line.split('=', 1)[1].strip(';')
            elif line.startswith('SSH_AGENT_PID='):
                os.environ['SSH_AGENT_PID'] = line.split('=', 1)[1].strip(';')

        # 保存配置到文件
        config_path = Path.home() / ".ssh-agent-ohmyzsh"
        with open(config_path, 'w') as f:
            f.write(result.stdout)
        config_path.chmod(0o600)

        log_success("SSH代理启动成功")
        return True

    except subprocess.CalledProcessError as e:
        log_error(f"启动SSH代理失败: {e}")
        return False
    except Exception as e:
        log_error(f"SSH代理配置失败: {e}")
        return False

def add_key_to_ssh_agent(key_path):
    """将SSH密钥添加到代理"""
    try:
        result = subprocess.run(['ssh-add', str(key_path)],
                              capture_output=True, text=True, check=True)
        log_info(f"SSH密钥 {Path(key_path).name} 已添加到代理")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"添加SSH密钥到代理失败: {e}")
        return False
    except Exception as e:
        log_error(f"SSH代理操作异常: {e}")
        return False

def ensure_ssh_agent_and_add_key(key_path):
    """确保SSH代理运行并添加密钥"""
    # 检查代理是否运行
    if not is_ssh_agent_running():
        log_info("SSH代理未运行，启动新代理...")
        if not start_ssh_agent():
            return False

    # 添加密钥到代理
    return add_key_to_ssh_agent(key_path)

# =============================================================================
# SSH密钥生成函数
# =============================================================================

def get_host_info():
    """获取主机信息（主机名和IP地址）"""
    try:
        hostname = socket.gethostname()

        # 尝试获取主机IP地址
        try:
            # 连接到外部地址来获取本机IP
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.connect(("8.8.8.8", 80))
                ip = s.getsockname()[0]
        except Exception:
            # 如果无法获取外部IP，使用localhost
            ip = "127.0.0.1"

        return hostname, ip
    except Exception as e:
        log_warn(f"获取主机信息失败: {e}")
        return "unknown", "127.0.0.1"

def generate_ssh_key_with_host_info():
    """生成带主机信息的SSH密钥（类似shell版本的ssh-config.sh功能）"""
    log_info("生成SSH密钥对（含hostname和IP）...")

    # 获取主机信息
    hostname, ip = get_host_info()

    # 生成密钥名称（包含主机名和IP）
    key_name = f"id_rsa_{hostname}_{ip.replace('.', '_')}"

    # SSH目录路径
    ssh_dir = Path.home() / ".ssh"
    ssh_dir.mkdir(mode=0o700, exist_ok=True)

    key_path = ssh_dir / key_name

    log_info(f"将生成密钥对：{key_path}（无密码）")

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
            '-f', str(key_path),
            '-N', '',  # 无密码
            '-q'       # 静默模式
        ]

        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        log_success("SSH密钥对已生成")
        log_info(f"私钥路径：{key_path}")
        log_info(f"公钥路径：{key_path}.pub")

        # 自动添加密钥到SSH代理
        if ensure_ssh_agent_and_add_key(key_path):
            log_success("SSH密钥已自动添加到代理")
        else:
            log_warn("SSH密钥添加到代理失败，可以稍后手动添加")

        return str(key_path)
    except subprocess.CalledProcessError as e:
        log_error(f"SSH密钥生成失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return None

def generate_ssh_key():
    """生成标准SSH密钥（兼容原有功能）"""
    log_info("开始生成SSH密钥...")

    # 获取密钥配置
    print(f"\n{CYAN}=== SSH密钥配置 ==={RESET}")
    print(f"{CYAN}请输入RSA密钥的名称：{RESET}")
    print("默认键入enter为id_rsa")
    print("如果不是，请输入RSA密钥的名称：")

    key_name = safe_input("", "id_rsa")

    # 获取注释信息
    default_comment = f"{os.getenv('USER')}@{socket.gethostname()}"
    comment = safe_input(f"{CYAN}请输入密钥的注释（例如你的邮箱），默认为{default_comment}：{RESET}", default_comment)

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
        log_success(f"密钥已生成，文件保存在 {key_path}")
        log_info(f"公钥文件: {key_path}.pub")

        # 自动添加密钥到SSH代理
        if ensure_ssh_agent_and_add_key(key_path):
            log_success("SSH密钥已自动添加到代理")
        else:
            log_warn("SSH密钥添加到代理失败，可以稍后手动添加")

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

def add_ssh_key_to_server(key_path=None):
    """添加SSH密钥到服务器（增强版，符合shell版本功能）"""
    # 安装sshpass
    if not install_sshpass():
        log_error("无法安装sshpass，无法自动配置密钥")
        return False

    # 获取服务器信息
    print(f"\n{CYAN}=== 服务器配置信息 ==={RESET}")

    server_ip = safe_input(f"{CYAN}请输入服务器IP地址：{RESET}")
    if not server_ip:
        log_error("服务器IP地址不能为空")
        return False

    print(f"{GREEN}输入的IP为: {server_ip}{RESET}")

    port = safe_input(f"{CYAN}请输入服务器端口：(默认为22){RESET}", "22")
    print(f"{GREEN}输入的端口为: {port}{RESET}")

    username = safe_input(f"{CYAN}请输入服务器用户名：(默认为root){RESET}", "root")
    print(f"{GREEN}输入的用户名为: {username}{RESET}")

    password = safe_password_input(f"{CYAN}请输入服务器密码：{RESET}")
    if not password:
        log_error("密码不能为空")
        return False
    print(f"{GREEN}密码已输入。{RESET}")

    try:
        # 自动添加远程主机的SSH公钥到known_hosts以避免手动确认
        log_info("正在添加远程主机的SSH公钥到known_hosts...")
        ssh_keyscan_cmd = ['ssh-keyscan', '-H', '-p', port, server_ip]

        with open(Path.home() / ".ssh" / "known_hosts", 'a') as known_hosts:
            result = subprocess.run(ssh_keyscan_cmd, stdout=known_hosts, stderr=subprocess.DEVNULL)

        log_success("已添加远程主机的SSH公钥到known_hosts。")

        # 如果没有指定密钥路径，让用户选择
        if not key_path:
            key_path = select_ssh_key_for_server()
            if not key_path:
                log_error("未选择有效的密钥文件")
                return False

        key_path = Path(key_path)
        # 正确构造公钥路径，避免IP地址被截断
        # 始终使用字符串拼接，避免with_suffix()误将IP地址的数字部分当作后缀
        pub_key_path = Path(str(key_path) + '.pub')

        if not pub_key_path.exists():
            log_error(f"公钥文件不存在: {pub_key_path}")
            return False

        print(f"{GREEN}选择的公钥文件为: {pub_key_path.name}{RESET}")

        # 使用ssh-copy-id添加公钥到服务器
        cmd = [
            'sshpass', '-p', password,
            'ssh-copy-id',
            '-i', str(pub_key_path),
            '-p', port,
            f'{username}@{server_ip}'
        ]

        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        # 确保SSH代理运行并添加密钥
        if ensure_ssh_agent_and_add_key(key_path):
            log_success("SSH密钥已添加到代理，现在可以无密码连接服务器")
        else:
            log_warn("SSH密钥添加到代理失败，可能需要手动添加")

        log_success(f"公钥 {pub_key_path} 添加成功")
        log_success(f"现在您可以通过ssh {username}@{server_ip} -p {port}登录服务器。")

        return True

    except subprocess.CalledProcessError as e:
        print(f"sshpass的命令为: sshpass -p {password} ssh-copy-id -i {pub_key_path} -p {port} {username}@{server_ip}")
        log_error("公钥添加失败，请检查以下可能的原因：")
        print("1. 服务器IP地址或端口号输入错误。")
        print("2. 服务器用户名或密码错误。")
        print("3. 指定的公钥文件不存在。")
        print("4. ssh-copy-id命令未正确执行，可能是因为sshpass未安装，或远程服务器不允许密码认证。")
        print("请根据上述提示检查您的输入或配置，然后重试。")
        return False
    except Exception as e:
        log_error(f"操作过程中发生错误: {e}")
        return False

def select_ssh_key_for_server():
    """为服务器选择SSH密钥"""
    ssh_dir = Path.home() / ".ssh"

    if not ssh_dir.exists():
        log_error("SSH目录不存在")
        return None

    # 查找所有公钥文件
    pub_keys = list(ssh_dir.glob("*.pub"))

    if not pub_keys:
        log_error("未找到任何SSH公钥文件")
        return None

    log_info("以下是可用的公钥文件：")
    for i, pub_key in enumerate(pub_keys, 1):
        print(f"{i}. {pub_key.name}")

    while True:
        choice = safe_input(f"{CYAN}请选择要使用的公钥文件编号: {RESET}", "1")

        if not choice:
            # 如果没有输入，默认选择第一个
            choice = "1"

        try:
            index = int(choice) - 1
            if 0 <= index < len(pub_keys):
                selected_pub_key = pub_keys[index]
                # 返回对应的私钥路径
                private_key = selected_pub_key.with_suffix('')
                if private_key.exists():
                    return str(private_key)
                else:
                    log_error(f"对应的私钥文件不存在: {private_key}")
                    return None
            else:
                print("无效的选择，请重新输入")
        except ValueError:
            print("请输入有效的数字")
        except Exception as e:
            log_error(f"选择过程中发生错误: {e}")
            return None

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

    # 正确构造公钥路径，避免IP地址被截断
    key_path = Path(key_path)
    # 始终使用字符串拼接，避免with_suffix()误将IP地址的数字部分当作后缀
    pub_key_path = Path(str(key_path) + '.pub')

    if not pub_key_path.exists():
        log_warn(f"公钥文件不存在: {pub_key_path}")
        return

    try:
        with open(pub_key_path, 'r') as f:
            public_key = f.read().strip()

        print(f"\n{GREEN}{'='*70}")
        print(f" 生成的SSH公钥内容")
        print(f"{'='*70}{RESET}")
        print()
        print(f"{CYAN}{public_key}{RESET}")
        print()
        print(f"{BLUE}{'─'*70}{RESET}")
        print(f"{YELLOW}公钥文件路径:{RESET} {pub_key_path}")
        print(f"{BLUE}{'─'*70}{RESET}")
        print()
    except Exception as e:
        log_error(f"读取公钥文件失败: {e}")

def show_ssh_keygen_menu():
    """显示SSH密钥生成操作菜单"""
    print(f"{CYAN}本脚本将帮助您配合ssh-agent添加root密码登录,自动生成sshkey,并将公钥添加到指定服务器。{RESET}")
    print(f"{CYAN}请按照提示输入相关信息，然后脚本将自动完成后续操作。{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print()
    print(f"{YELLOW}功能说明：{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"  {GREEN}•{RESET} 生成标准SSH密钥对")
    print(f"  {GREEN}•{RESET} 生成带主机信息的SSH密钥对")
    print(f"  {GREEN}•{RESET} 自动添加公钥到远程服务器")
    print(f"  {GREEN}•{RESET} 支持SSH Agent集成")
    print(f"{BLUE}{'─'*70}{RESET}")
    print()

def main():
    """主函数"""
    try:
        # 检查是否为非交互式环境
        if not sys.stdin.isatty():
            log_warn("检测到非交互式环境，脚本将以非交互模式运行")
            log_info("如需交互式操作，请在终端中直接运行此脚本")
            return

        # 显示脚本信息
        show_header("SSH密钥生成和配置脚本", "1.0", "自动生成SSH密钥并配置到远程服务器")
        show_ssh_keygen_menu()

        # 菜单选项
        menu_options = [
            f"{GREEN}生成密钥{RESET}",
            f"{BLUE}添加公钥到服务器{RESET}",
            f"{YELLOW}生成带主机信息的密钥{RESET}",
            f"{RED}退出{RESET}"
        ]

        max_attempts = 10  # 防止无限循环的最大尝试次数
        attempt_count = 0

        while attempt_count < max_attempts:
            attempt_count += 1
            print()
            selection_index, selection_text = interactive_select_menu(
                menu_options,
                f"{CYAN}请选择操作：{RESET}",
                0
            )

            if selection_index == -1:  # 用户取消
                break

            operation_success = False

            if selection_index == 0:  # 生成密钥
                key_path = generate_ssh_key()
                if key_path:
                    log_success("密钥生成完成！")
                    # 显示公钥内容
                    show_public_key(key_path)
                    operation_success = True

            elif selection_index == 1:  # 添加公钥到服务器
                if add_ssh_key_to_server():
                    log_success("公钥添加完成！")
                    operation_success = True

            elif selection_index == 2:  # 生成带主机信息的密钥
                key_path = generate_ssh_key_with_host_info()
                if key_path:
                    log_success("带主机信息的密钥生成完成！")
                    # 显示公钥内容
                    show_public_key(key_path)
                    operation_success = True

            elif selection_index == 3:  # 退出
                break

            # 如果操作失败且连续失败多次，自动退出防止无限循环
            if not operation_success:
                if attempt_count >= 3:
                    log_warn("连续操作失败，自动退出以防止无限循环")
                    break

            # 询问是否继续
            if not interactive_ask_confirmation("是否继续其他操作？", False):  # 默认为否
                break

        if attempt_count >= max_attempts:
            log_warn("达到最大尝试次数，自动退出")

        print(f"{BLUE}{'='*60}")
        print("感谢使用SSH密钥生成和配置脚本！")
        print(f"{'='*60}{RESET}")

    except KeyboardInterrupt:
        log_info("\n用户中断操作")
    except Exception as e:
        log_error(f"程序执行过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
