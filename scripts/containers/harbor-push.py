#!/usr/bin/env python3

"""
Harbor镜像推送脚本 - Python版本
作者: saul
版本: 1.1
描述: 搜索、拉取、标记并推送公共Docker镜像到私有仓库Harbor
"""

import os
import sys
import subprocess
import json
import requests
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
# 颜色定义
# =============================================================================
COLOR_GREEN = '\033[32m'
COLOR_RED = '\033[31m'
COLOR_BLUE = '\033[34m'
COLOR_YELLOW = '\033[33m'
COLOR_CYAN = '\033[36m'
COLOR_RESET = '\033[0m'

# =============================================================================
# Docker和依赖检查
# =============================================================================

def check_docker_installed():
    """检查Docker是否已安装"""
    try:
        subprocess.run(['docker', '--version'], check=True, capture_output=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def install_docker():
    """安装Docker"""
    print(f"{COLOR_RED}错误: 未找到Docker，请先安装Docker。是否安装docker? 请输入yes/y/enter或no/n:{COLOR_RESET}")
    install_choice = input().strip().lower()
    
    if install_choice in ['yes', 'y', '']:
        print(f"{COLOR_GREEN}正在安装Docker...{COLOR_RESET}")
        try:
            # 安装Docker
            docker_cmd = "bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh)"
            subprocess.run(docker_cmd, shell=True, check=True)
            
            print(f"{COLOR_GREEN}正在安装lazydocker...{COLOR_RESET}")
            # 安装LazyDocker
            lazydocker_cmd = "curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
            subprocess.run(lazydocker_cmd, shell=True, check=True)
            
            return True
        except subprocess.CalledProcessError as e:
            print(f"{COLOR_RED}Docker安装失败: {e}{COLOR_RESET}")
            return False
    else:
        print(f"{COLOR_RED}未安装Docker。请先安装Docker。{COLOR_RESET}")
        return False

def check_and_install_jq():
    """检查并安装jq"""
    try:
        subprocess.run(['jq', '--version'], check=True, capture_output=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("jq未安装。正在为您安装jq...")
        try:
            # 检测包管理器并安装jq
            if subprocess.run(['which', 'apt'], capture_output=True).returncode == 0:
                subprocess.run(['sudo', 'apt', 'update'], check=True, capture_output=True)
                subprocess.run(['sudo', 'apt', 'install', '-y', 'jq'], check=True, capture_output=True)
            elif subprocess.run(['which', 'yum'], capture_output=True).returncode == 0:
                subprocess.run(['sudo', 'yum', 'install', '-y', 'jq'], check=True, capture_output=True)
            else:
                print("未知的包管理器。请手动安装jq。")
                return False
            return True
        except subprocess.CalledProcessError as e:
            print(f"jq安装失败: {e}")
            return False

def show_welcome():
    """显示欢迎信息"""
    os.system('clear')
    print(f"{COLOR_BLUE}================================================================{COLOR_RESET}")
    print(f"{COLOR_GREEN} 欢迎使用 Harbor 镜像推送脚本{COLOR_RESET}")
    print(f"{COLOR_YELLOW} 作者: saul{COLOR_RESET}")
    print(f"{COLOR_YELLOW} 邮箱: sau1amaranth@gmail.com{COLOR_RESET}")
    print(f"{COLOR_YELLOW} 版本: 1.1{COLOR_RESET}")
    print(f"{COLOR_BLUE}================================================================{COLOR_RESET}")
    print(f"{COLOR_CYAN}本脚本将帮助您搜索、拉取、标记并推送公共Docker镜像到私有仓库 Harbor。{COLOR_RESET}")
    print(f"{COLOR_CYAN}请按照提示输入相关信息，然后脚本将自动完成后续操作。{COLOR_RESET}")
    print(f"{COLOR_BLUE}================================================================{COLOR_RESET}")

def search_private_image(harbor_url, username, password, project_name):
    """搜索私有仓库的镜像"""
    print(f"{COLOR_BLUE}搜索私有仓库镜像...{COLOR_RESET}")
    
    try:
        # 构建API URL
        api_url = f"https://{harbor_url}/api/v2.0/projects/{project_name}/repositories"
        
        # 发送请求
        response = requests.get(api_url, auth=(username, password), timeout=10)
        
        if response.status_code == 200:
            repositories = response.json()
            if repositories:
                print(f"{COLOR_GREEN}找到以下镜像:{COLOR_RESET}")
                for i, repo in enumerate(repositories, 1):
                    repo_name = repo.get('name', 'N/A')
                    print(f"{i}. {repo_name}")
                return repositories
            else:
                print(f"{COLOR_YELLOW}项目中没有找到镜像{COLOR_RESET}")
                return []
        else:
            print(f"{COLOR_RED}搜索失败: HTTP {response.status_code}{COLOR_RESET}")
            return []
    except requests.RequestException as e:
        print(f"{COLOR_RED}搜索私有镜像失败: {e}{COLOR_RESET}")
        return []

def search_public_image(image_name, limit=10):
    """搜索公共镜像"""
    print(f"{COLOR_BLUE}搜索公共镜像: {image_name}{COLOR_RESET}")
    
    try:
        # 使用Docker Hub API搜索
        url = f"https://hub.docker.com/v2/search/repositories/?query={image_name}&page_size={limit}"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        results = data.get('results', [])
        
        if results:
            print(f"{COLOR_GREEN}找到以下公共镜像:{COLOR_RESET}")
            for i, repo in enumerate(results, 1):
                name = repo.get('name', 'N/A')
                description = repo.get('short_description', 'No description')[:50]
                stars = repo.get('star_count', 0)
                is_official = repo.get('is_official', False)
                official_tag = " [OFFICIAL]" if is_official else ""
                
                print(f"{i:2d}. {name}{official_tag}")
                print(f"    描述: {description}")
                print(f"    星标: {stars}")
                print()
            return results
        else:
            print(f"{COLOR_YELLOW}未找到匹配的公共镜像{COLOR_RESET}")
            return []
    except requests.RequestException as e:
        print(f"{COLOR_RED}搜索公共镜像失败: {e}{COLOR_RESET}")
        return []

def pull_and_push_image(source_image, source_tag, harbor_url, project_name, target_image, target_tag, username, password):
    """拉取并推送镜像"""
    source_full = f"{source_image}:{source_tag}"
    target_full = f"{harbor_url}/{project_name}/{target_image}:{target_tag}"
    
    try:
        # 拉取源镜像
        print(f"{COLOR_BLUE}拉取镜像: {source_full}{COLOR_RESET}")
        subprocess.run(['docker', 'pull', source_full], check=True)
        print(f"{COLOR_GREEN}镜像拉取成功{COLOR_RESET}")
        
        # 标记镜像
        print(f"{COLOR_BLUE}标记镜像: {source_full} -> {target_full}{COLOR_RESET}")
        subprocess.run(['docker', 'tag', source_full, target_full], check=True)
        print(f"{COLOR_GREEN}镜像标记成功{COLOR_RESET}")
        
        # 登录Harbor
        print(f"{COLOR_BLUE}登录Harbor仓库...{COLOR_RESET}")
        login_cmd = f"echo '{password}' | docker login {harbor_url} -u {username} --password-stdin"
        subprocess.run(login_cmd, shell=True, check=True, capture_output=True)
        print(f"{COLOR_GREEN}Harbor登录成功{COLOR_RESET}")
        
        # 推送镜像
        print(f"{COLOR_BLUE}推送镜像: {target_full}{COLOR_RESET}")
        subprocess.run(['docker', 'push', target_full], check=True)
        print(f"{COLOR_GREEN}镜像推送成功！{COLOR_RESET}")
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"{COLOR_RED}操作失败: {e}{COLOR_RESET}")
        return False

def main():
    """主函数"""
    # 显示欢迎信息
    show_welcome()
    
    # 检查Docker
    if not check_docker_installed():
        if not install_docker():
            sys.exit(1)
    
    # 检查并安装jq
    if not check_and_install_jq():
        sys.exit(1)
    
    # 获取Harbor信息
    print(f"{COLOR_BLUE}请输入私有仓库地址（默认为harbor.hcegcorp.com）：{COLOR_RESET}")
    harbor_url = input().strip() or "harbor.hcegcorp.com"
    
    print(f"{COLOR_BLUE}请输入Harbor用户名：{COLOR_RESET}")
    username = input().strip()
    if not username:
        print(f"{COLOR_RED}用户名不能为空{COLOR_RESET}")
        sys.exit(1)
    
    print(f"{COLOR_BLUE}请输入Harbor密码：{COLOR_RESET}")
    password = getpass.getpass()
    if not password:
        print(f"{COLOR_RED}密码不能为空{COLOR_RESET}")
        sys.exit(1)
    
    print(f"{COLOR_BLUE}请输入项目名称：{COLOR_RESET}")
    project_name = input().strip()
    if not project_name:
        print(f"{COLOR_RED}项目名称不能为空{COLOR_RESET}")
        sys.exit(1)
    
    # 选择操作模式
    print(f"\n{COLOR_BLUE}请选择操作模式：{COLOR_RESET}")
    print("1. 搜索并推送公共镜像")
    print("2. 查看私有仓库镜像")
    
    choice = input("请输入选择 (1-2): ").strip()
    
    if choice == "1":
        # 搜索公共镜像模式
        search_term = input(f"{COLOR_BLUE}请输入要搜索的镜像名称：{COLOR_RESET}").strip()
        if not search_term:
            print(f"{COLOR_RED}搜索词不能为空{COLOR_RESET}")
            sys.exit(1)
        
        results = search_public_image(search_term)
        if not results:
            sys.exit(1)
        
        # 选择镜像
        try:
            img_choice = int(input("请选择镜像编号: ").strip())
            if 1 <= img_choice <= len(results):
                selected_image = results[img_choice - 1]['name']
            else:
                print(f"{COLOR_RED}无效的选择{COLOR_RESET}")
                sys.exit(1)
        except ValueError:
            print(f"{COLOR_RED}请输入有效的数字{COLOR_RESET}")
            sys.exit(1)
        
        # 获取标签和目标信息
        source_tag = input(f"请输入源镜像标签 (默认: latest): ").strip() or "latest"
        target_image = input(f"请输入目标镜像名称 (默认: {selected_image}): ").strip() or selected_image
        target_tag = input(f"请输入目标镜像标签 (默认: {source_tag}): ").strip() or source_tag
        
        # 执行推送
        pull_and_push_image(selected_image, source_tag, harbor_url, project_name, target_image, target_tag, username, password)
        
    elif choice == "2":
        # 查看私有仓库镜像
        search_private_image(harbor_url, username, password, project_name)
    else:
        print(f"{COLOR_RED}无效的选择{COLOR_RESET}")
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{COLOR_YELLOW}用户中断操作{COLOR_RESET}")
    except Exception as e:
        print(f"{COLOR_RED}程序执行过程中发生错误: {e}{COLOR_RESET}")
        sys.exit(1)
