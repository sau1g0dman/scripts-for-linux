# 安装指南

本文档详细介绍了Ubuntu服务器初始化脚本库的安装方法和配置选项。

## 📋 安装前准备

### 系统要求检查

在开始安装前，请确保您的系统满足以下要求：

```bash
# 检查Ubuntu版本
lsb_release -a

# 检查系统架构
uname -m

# 检查可用空间
df -h

# 检查内存
free -h

# 检查网络连接
ping -c 4 github.com
```

### 更新系统

建议在安装前更新系统：

```bash
sudo apt update
sudo apt upgrade -y
```

## 🚀 安装方法

### 方法一：一键安装（推荐）

这是最简单的安装方法，适合大多数用户：

```bash
# 下载并执行安装脚本
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/install.sh | bash
```

或者先下载再执行：

```bash
# 下载安装脚本
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/install.sh -o install.sh

# 查看脚本内容（可选）
cat install.sh

# 执行安装
chmod +x install.sh
./install.sh
```

### 方法二：克隆仓库

适合需要自定义或开发的用户：

```bash
# 克隆仓库
git clone https://github.com/sau1g0dman/scripts-for-linux.git
cd scripts-for-linux

# 设置执行权限
find scripts/ -name "*.sh" -type f -exec chmod +x {} \;

# 运行安装脚本
./install.sh

# 或者运行特定脚本
./scripts/shell/zsh-install.sh
```

### 方法三：分模块安装

适合只需要特定功能的用户：

#### 系统配置
```bash
# 时间同步
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/system/time-sync.sh)

# 软件源配置
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/system/mirrors.sh)
```

#### ZSH环境
```bash
# 标准版本
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install.sh)

# 国内源版本（推荐）
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install-gitee.sh)

# ARM版本
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-arm.sh)
```

#### 开发工具
```bash
# Neovim配置
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/development/nvim-setup.sh)
```

#### 安全配置
```bash
# SSH配置
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/security/ssh-config.sh)

# SSH密钥生成
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/security/ssh-keygen.sh)
```

#### Docker环境
```bash
# Docker安装
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-install.sh)

# Docker镜像推送工具
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-push.sh)
```

## ⚙️ 配置选项

### 环境变量

可以通过设置环境变量来自定义安装行为：

```bash
# 设置日志级别（0=DEBUG, 1=INFO, 2=WARN, 3=ERROR）
export LOG_LEVEL=1

# 启用自动安装模式（跳过确认提示）
export AUTO_INSTALL=true

# 自定义安装目录
export INSTALL_DIR="$HOME/.my-scripts"

# 然后运行安装脚本
./install.sh
```

### 配置文件

部分脚本支持配置文件自定义：

```bash
# ZSH配置文件
~/.zshrc

# SSH配置文件
~/.ssh/config

# Docker配置文件
/etc/docker/daemon.json
```

## 🔧 高级安装选项

### 离线安装

如果服务器无法直接访问互联网，可以使用离线安装：

```bash
# 在有网络的机器上下载
git clone https://github.com/sau1g0dman/scripts-for-linux.git
tar -czf scripts-for-linux.tar.gz scripts-for-linux/

# 传输到目标服务器
scp scripts-for-linux.tar.gz user@server:/tmp/

# 在目标服务器上解压并安装
cd /tmp
tar -xzf scripts-for-linux.tar.gz
cd scripts-for-linux
./install.sh
```

### 批量部署

使用Ansible或其他自动化工具进行批量部署：

```yaml
# ansible-playbook.yml
- hosts: ubuntu_servers
  tasks:
    - name: Download and run installation script
      shell: |
        curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/install.sh | bash
      become: yes
```

### Docker容器中使用

在Docker容器中使用脚本：

```dockerfile
FROM ubuntu:22.04

# 安装基础依赖
RUN apt-get update && apt-get install -y curl git sudo

# 创建用户
RUN useradd -m -s /bin/bash ubuntu && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER ubuntu
WORKDIR /home/ubuntu

# 运行安装脚本
RUN curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/install.sh | bash
```

## 📝 安装后配置

### 验证安装

安装完成后，建议验证各组件是否正常工作：

```bash
# 检查ZSH
zsh --version
echo $SHELL

# 检查Docker
docker --version
docker run hello-world

# 检查Neovim
nvim --version

# 检查SSH配置
ssh -T git@github.com
```

### 个性化配置

根据需要进行个性化配置：

```bash
# 配置Powerlevel10k主题
p10k configure

# 配置Git用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 配置SSH密钥
ssh-keygen -t ed25519 -C "your.email@example.com"
```

### 性能优化

对于低配置服务器，可以进行以下优化：

```bash
# 减少ZSH插件
# 编辑 ~/.zshrc，注释掉不需要的插件

# 优化Docker配置
# 编辑 /etc/docker/daemon.json，调整日志和存储设置

# 清理不需要的软件包
sudo apt autoremove -y
sudo apt autoclean
```

## 🔄 更新和维护

### 更新脚本

定期更新脚本到最新版本：

```bash
# 如果是克隆的仓库
cd scripts-for-linux
git pull origin main

# 重新运行安装脚本
./install.sh
```

### 备份配置

在更新前备份重要配置：

```bash
# 备份ZSH配置
cp ~/.zshrc ~/.zshrc.backup

# 备份SSH配置
cp -r ~/.ssh ~/.ssh.backup

# 备份Docker配置
sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
```

### 卸载

如果需要卸载，可以使用以下命令：

```bash
# 下载卸载脚本
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/uninstall.sh | bash

# 或者手动卸载
rm -rf ~/.oh-my-zsh
rm -f ~/.zshrc
# 恢复默认shell
chsh -s /bin/bash
```

## ❓ 常见问题

### 安装失败

如果安装失败，请检查：

1. 网络连接是否正常
2. 系统版本是否支持
3. 是否有足够的磁盘空间
4. 是否有sudo权限

### 权限问题

如果遇到权限问题：

```bash
# 检查sudo权限
sudo -v

# 添加用户到sudo组
sudo usermod -aG sudo $USER

# 重新登录
```

### 网络问题

如果网络访问有问题：

```bash
# 使用国内源
export USE_CHINA_MIRROR=true
./install.sh

# 或者配置代理
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080
```

更多问题请参考 [故障排除文档](troubleshooting.md)。
