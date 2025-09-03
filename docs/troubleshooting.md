# 故障排除指南

本文档提供了使用Ubuntu服务器初始化脚本库时可能遇到的常见问题及其解决方案。

## 🔍 问题诊断

### 获取详细日志

首先启用详细日志来诊断问题：

```bash
# 设置调试模式
export LOG_LEVEL=0

# 重新运行脚本
./install.sh
```

### 检查系统状态

```bash
# 检查系统信息
uname -a
lsb_release -a

# 检查磁盘空间
df -h

# 检查内存使用
free -h

# 检查网络连接
ping -c 4 github.com
curl -I https://github.com
```

## 🌐 网络相关问题

### 问题：无法连接到GitHub

**症状**：
```
curl: (7) Failed to connect to github.com port 443: Connection refused
```

**解决方案**：

1. **检查网络连接**：
```bash
# 测试基本网络连接
ping -c 4 8.8.8.8

# 测试DNS解析
nslookup github.com
```

2. **配置DNS服务器**：
```bash
# 临时配置DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# 永久配置DNS（Ubuntu 18.04+）
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
```

3. **使用代理**：
```bash
# 设置HTTP代理
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080

# 设置Git代理
git config --global http.proxy http://proxy.example.com:8080
git config --global https.proxy http://proxy.example.com:8080
```

4. **使用国内镜像**：
```bash
# 使用Gitee镜像
export USE_CHINA_MIRROR=true
bash <(curl -sSL https://gitee.com/sau1g0dman/scripts-for-linux/raw/main/install.sh)
```

### 问题：下载速度慢

**解决方案**：

1. **使用国内源**：
```bash
# 使用清华大学镜像
export GITHUB_MIRROR="https://mirror.ghproxy.com/"
./install.sh
```

2. **配置Git加速**：
```bash
# 配置Git使用代理
git config --global url."https://mirror.ghproxy.com/https://github.com".insteadOf "https://github.com"
```

## 🔐 权限相关问题

### 问题：sudo权限不足

**症状**：
```
sudo: command not found
user is not in the sudoers file
```

**解决方案**：

1. **切换到root用户**：
```bash
su -
# 添加用户到sudo组
usermod -aG sudo username
```

2. **编辑sudoers文件**：
```bash
# 使用visudo编辑
visudo

# 添加以下行
username ALL=(ALL:ALL) ALL
```

3. **重新登录**：
```bash
# 退出并重新登录使权限生效
exit
```

### 问题：文件权限错误

**症状**：
```
Permission denied
```

**解决方案**：

1. **检查文件权限**：
```bash
ls -la scripts/
```

2. **设置正确权限**：
```bash
# 设置脚本执行权限
find scripts/ -name "*.sh" -type f -exec chmod +x {} \;

# 设置目录权限
chmod 755 scripts/
```

3. **修复所有者**：
```bash
# 修改文件所有者
sudo chown -R $USER:$USER scripts/
```

## 📦 软件包管理问题

### 问题：apt更新失败

**症状**：
```
E: Could not get lock /var/lib/dpkg/lock-frontend
E: Unable to locate package
```

**解决方案**：

1. **解决锁定问题**：
```bash
# 杀死可能的apt进程
sudo killall apt apt-get

# 删除锁文件
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*

# 重新配置dpkg
sudo dpkg --configure -a
```

2. **修复损坏的软件包**：
```bash
# 修复损坏的软件包
sudo apt --fix-broken install

# 清理软件包缓存
sudo apt clean
sudo apt autoclean

# 更新软件包列表
sudo apt update
```

3. **更换软件源**：
```bash
# 备份原始sources.list
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 使用阿里云镜像
sudo sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
sudo apt update
```

### 问题：PPA添加失败

**症状**：
```
gpg: keyserver receive failed: No dirmngr
```

**解决方案**：

```bash
# 安装必要的工具
sudo apt update
sudo apt install -y software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# 重新添加PPA
sudo add-apt-repository ppa:example/ppa
```

## 🐚 ZSH相关问题

### 问题：ZSH安装失败

**症状**：
```
zsh: command not found
```

**解决方案**：

1. **手动安装ZSH**：
```bash
sudo apt update
sudo apt install -y zsh
```

2. **检查安装状态**：
```bash
which zsh
zsh --version
```

3. **设置默认Shell**：
```bash
# 添加zsh到shells列表
echo $(which zsh) | sudo tee -a /etc/shells

# 设置为默认shell
chsh -s $(which zsh)
```

### 问题：Oh My Zsh安装失败

**解决方案**：

1. **手动安装**：
```bash
# 删除可能存在的目录
rm -rf ~/.oh-my-zsh

# 手动下载安装
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

2. **使用国内镜像**：
```bash
# 使用Gitee镜像
sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"
```

### 问题：主题显示异常

**症状**：
- 字符显示为方块
- 图标无法显示
- 颜色异常

**解决方案**：

1. **安装字体**：
```bash
# 安装Powerline字体
sudo apt install -y fonts-powerline

# 安装Nerd Fonts
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLo "DroidSansMono Nerd Font Complete.otf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf
fc-cache -fv
```

2. **配置终端**：
```bash
# 设置终端字体为Nerd Font
# 在终端设置中选择 "DroidSansMono Nerd Font"
```

3. **重新配置主题**：
```bash
p10k configure
```

## 🐳 Docker相关问题

### 问题：Docker安装失败

**症状**：
```
docker: command not found
```

**解决方案**：

1. **手动安装Docker**：
```bash
# 更新软件包
sudo apt update

# 安装依赖
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 添加Docker GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加Docker仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

2. **启动Docker服务**：
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

3. **添加用户到docker组**：
```bash
sudo usermod -aG docker $USER
# 重新登录使权限生效
```

### 问题：Docker权限错误

**症状**：
```
permission denied while trying to connect to the Docker daemon socket
```

**解决方案**：

```bash
# 添加用户到docker组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker

# 测试Docker
docker run hello-world
```

### 问题：Docker镜像拉取失败

**解决方案**：

1. **配置镜像加速器**：
```bash
# 创建daemon.json
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

# 重启Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 🔧 SSH相关问题

### 问题：SSH连接失败

**症状**：
```
ssh: connect to host example.com port 22: Connection refused
```

**解决方案**：

1. **检查SSH服务**：
```bash
# 检查SSH服务状态
sudo systemctl status ssh

# 启动SSH服务
sudo systemctl start ssh
sudo systemctl enable ssh
```

2. **检查防火墙**：
```bash
# 检查防火墙状态
sudo ufw status

# 允许SSH端口
sudo ufw allow ssh
sudo ufw allow 22
```

3. **检查SSH配置**：
```bash
# 检查SSH配置文件
sudo nano /etc/ssh/sshd_config

# 确保以下设置
Port 22
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
```

### 问题：SSH密钥认证失败

**解决方案**：

1. **检查密钥权限**：
```bash
# 设置正确的权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 644 ~/.ssh/authorized_keys
```

2. **重新生成密钥**：
```bash
# 生成新的SSH密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 添加到SSH代理
ssh-add ~/.ssh/id_ed25519
```

## 💾 存储相关问题

### 问题：磁盘空间不足

**症状**：
```
No space left on device
```

**解决方案**：

1. **清理系统**：
```bash
# 清理软件包缓存
sudo apt clean
sudo apt autoclean
sudo apt autoremove -y

# 清理日志文件
sudo journalctl --vacuum-time=7d

# 清理临时文件
sudo rm -rf /tmp/*
```

2. **查找大文件**：
```bash
# 查找大文件
sudo find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# 分析磁盘使用
sudo du -h --max-depth=1 /
```

## 🔄 系统恢复

### 备份重要配置

在进行故障排除前，建议备份重要配置：

```bash
# 备份用户配置
tar -czf ~/backup-$(date +%Y%m%d).tar.gz ~/.bashrc ~/.zshrc ~/.ssh/ ~/.gitconfig

# 备份系统配置
sudo tar -czf /root/system-backup-$(date +%Y%m%d).tar.gz /etc/ssh/ /etc/docker/
```

### 恢复默认配置

如果配置出现问题，可以恢复默认配置：

```bash
# 恢复bash
chsh -s /bin/bash
rm -f ~/.zshrc
cp /etc/skel/.bashrc ~/

# 重新安装
./install.sh
```

## 📞 获取帮助

如果以上解决方案都无法解决您的问题，请：

1. **查看详细日志**：运行脚本时启用调试模式
2. **搜索已知问题**：在GitHub Issues中搜索相似问题
3. **提交问题报告**：在GitHub仓库创建新的Issue
4. **联系作者**：发送邮件到 sau1@maranth@gmail.com

### 问题报告模板

提交问题时请包含以下信息：

```
**环境信息**
- 操作系统：Ubuntu 22.04
- 架构：x86_64
- 脚本版本：1.0

**问题描述**
详细描述遇到的问题

**重现步骤**
1. 执行命令...
2. 出现错误...

**错误日志**
粘贴完整的错误日志

**已尝试的解决方案**
列出已经尝试过的解决方法
```

这样可以帮助我们更快地定位和解决问题。
