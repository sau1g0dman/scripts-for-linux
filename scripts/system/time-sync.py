#!/usr/bin/env python3

"""
系统时间同步脚本 - Python版本
作者: saul
版本: 1.0
描述: 自动配置和同步系统时间，支持Ubuntu 20-22 x64/ARM64
"""

import os
import sys
import subprocess
import time
import socket
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

# NTP服务器列表（按优先级排序）
NTP_SERVERS = [
    "ntp1.aliyun.com",
    "ntp2.aliyun.com", 
    "ntp3.aliyun.com",
    "ntp4.aliyun.com",
    "ntp5.aliyun.com",
    "ntp6.aliyun.com",
    "ntp7.aliyun.com",
    "time1.aliyun.com",
    "time2.aliyun.com",
    "ntp.aliyun.com",
    "cn.pool.ntp.org",
    "ntp.ubuntu.com",
    "time.google.com",
    "time.cloudflare.com"
]

# =============================================================================
# 时间同步函数
# =============================================================================

def check_ntp_server(server, timeout=5):
    """检查NTP服务器可用性"""
    try:
        # 使用socket检查NTP端口(123)是否可达
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((server, 123))
        sock.close()
        return result == 0
    except Exception:
        return False

def find_best_ntp_server():
    """查找最佳NTP服务器"""
    log_info("正在测试NTP服务器可用性...")
    
    available_servers = []
    for server in NTP_SERVERS:
        log_debug(f"测试服务器: {server}")
        if check_ntp_server(server):
            available_servers.append(server)
            log_info(f"✓ {server} - 可用")
        else:
            log_debug(f"✗ {server} - 不可用")
    
    if not available_servers:
        log_error("未找到可用的NTP服务器")
        return None
    
    best_server = available_servers[0]
    log_info(f"选择最佳NTP服务器: {best_server}")
    return best_server

def install_ntp_client():
    """安装NTP客户端"""
    log_info("检查NTP客户端安装状态...")
    
    # 检查是否已安装ntpdate或chrony
    ntp_tools = ['ntpdate', 'chrony', 'systemd-timesyncd']
    installed_tool = None
    
    for tool in ntp_tools:
        try:
            subprocess.run(['which', tool], check=True, capture_output=True)
            installed_tool = tool
            log_info(f"已安装NTP工具: {tool}")
            break
        except subprocess.CalledProcessError:
            continue
    
    if not installed_tool:
        log_info("安装NTP客户端...")
        try:
            execute_command("apt update", "更新包列表")
            execute_command("apt install -y ntpdate", "安装ntpdate")
            installed_tool = 'ntpdate'
            log_info("NTP客户端安装完成")
        except Exception as e:
            log_error(f"NTP客户端安装失败: {e}")
            return None
    
    return installed_tool

def sync_time_with_ntpdate(server):
    """使用ntpdate同步时间"""
    log_info(f"使用ntpdate同步时间: {server}")
    
    try:
        # 停止systemd-timesyncd服务（如果运行）
        try:
            subprocess.run(['systemctl', 'stop', 'systemd-timesyncd'], 
                          capture_output=True, check=False)
        except:
            pass
        
        # 使用ntpdate同步时间
        cmd = f"ntpdate -s {server}"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        
        log_info("时间同步成功")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"ntpdate时间同步失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False

def sync_time_with_timedatectl(server):
    """使用timedatectl同步时间"""
    log_info("使用timedatectl同步时间")
    
    try:
        # 启用NTP同步
        execute_command("timedatectl set-ntp true", "启用NTP同步")
        
        # 等待同步
        time.sleep(3)
        
        # 检查同步状态
        result = subprocess.run(['timedatectl', 'status'], 
                              capture_output=True, text=True, check=True)
        
        if 'NTP synchronized: yes' in result.stdout:
            log_info("时间同步成功")
            return True
        else:
            log_warn("时间同步状态未确认")
            return False
    except Exception as e:
        log_error(f"timedatectl时间同步失败: {e}")
        return False

def configure_ntp_service(server):
    """配置NTP服务"""
    log_info("配置NTP服务...")
    
    # 配置systemd-timesyncd
    timesyncd_conf = Path("/etc/systemd/timesyncd.conf")
    
    try:
        # 备份原配置
        if timesyncd_conf.exists():
            backup_path = timesyncd_conf.with_suffix(f".backup.{get_timestamp()}")
            shutil.copy2(timesyncd_conf, backup_path)
            log_info(f"已备份原配置: {backup_path}")
        
        # 创建新配置
        config_content = f"""[Time]
NTP={server}
FallbackNTP={' '.join(NTP_SERVERS[:5])}
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
"""
        
        with open(timesyncd_conf, 'w') as f:
            f.write(config_content)
        
        # 重启服务
        execute_command("systemctl daemon-reload", "重新加载systemd配置")
        execute_command("systemctl restart systemd-timesyncd", "重启时间同步服务")
        execute_command("systemctl enable systemd-timesyncd", "启用时间同步服务")
        
        log_info("NTP服务配置完成")
        return True
    except Exception as e:
        log_error(f"NTP服务配置失败: {e}")
        return False

def show_time_status():
    """显示时间状态"""
    log_info("当前时间状态:")
    
    try:
        # 显示当前时间
        result = subprocess.run(['date'], capture_output=True, text=True, check=True)
        print(f"当前时间: {result.stdout.strip()}")
        
        # 显示时区信息
        result = subprocess.run(['timedatectl', 'status'], 
                              capture_output=True, text=True, check=True)
        print("时间同步状态:")
        print(result.stdout)
        
        # 显示NTP服务状态
        try:
            result = subprocess.run(['systemctl', 'status', 'systemd-timesyncd', '--no-pager'], 
                                  capture_output=True, text=True, check=True)
            print("NTP服务状态:")
            print(result.stdout)
        except:
            pass
            
    except Exception as e:
        log_warn(f"获取时间状态失败: {e}")

def set_timezone():
    """设置时区"""
    if not interactive_ask_confirmation("是否设置时区？", True):
        return True
    
    log_info("设置时区...")
    
    # 常用时区列表
    timezones = {
        "1": "Asia/Shanghai",
        "2": "Asia/Hong_Kong", 
        "3": "Asia/Tokyo",
        "4": "Europe/London",
        "5": "America/New_York",
        "6": "UTC"
    }
    
    print("\n请选择时区:")
    print("1. 中国标准时间 (Asia/Shanghai)")
    print("2. 香港时间 (Asia/Hong_Kong)")
    print("3. 日本标准时间 (Asia/Tokyo)")
    print("4. 英国时间 (Europe/London)")
    print("5. 美国东部时间 (America/New_York)")
    print("6. 协调世界时 (UTC)")
    
    while True:
        choice = input("请选择时区 (1-6): ").strip()
        if choice in timezones:
            timezone = timezones[choice]
            break
        else:
            log_warn("请输入有效的选择 (1-6)")
    
    try:
        execute_command(f"timedatectl set-timezone {timezone}", f"设置时区为{timezone}")
        log_info(f"时区设置完成: {timezone}")
        return True
    except Exception as e:
        log_error(f"时区设置失败: {e}")
        return False

def main():
    """主函数"""
    try:
        # 初始化环境
        init_environment()
        
        # 显示脚本信息
        show_header("系统时间同步脚本", "1.0", "自动配置和同步系统时间")
        
        # 检查网络连接
        if not check_network():
            log_error("网络连接失败，无法同步时间")
            sys.exit(1)
        
        # 查找最佳NTP服务器
        best_server = find_best_ntp_server()
        if not best_server:
            log_error("未找到可用的NTP服务器")
            sys.exit(1)
        
        # 安装NTP客户端
        ntp_tool = install_ntp_client()
        if not ntp_tool:
            log_error("NTP客户端安装失败")
            sys.exit(1)
        
        # 设置时区
        set_timezone()
        
        # 同步时间
        sync_success = False
        if ntp_tool == 'ntpdate':
            sync_success = sync_time_with_ntpdate(best_server)
        else:
            sync_success = sync_time_with_timedatectl(best_server)
        
        if not sync_success:
            log_error("时间同步失败")
            sys.exit(1)
        
        # 配置NTP服务
        if interactive_ask_confirmation("是否配置NTP服务以保持时间同步？", True):
            configure_ntp_service(best_server)
        
        # 显示时间状态
        show_time_status()
        
        log_info("系统时间同步配置完成！")
        
    except KeyboardInterrupt:
        log_info("\n用户中断操作")
        sys.exit(1)
    except Exception as e:
        log_error(f"程序执行过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
