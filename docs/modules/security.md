# 安全配置模块

安全配置模块提供了SSH服务器的安全配置和SSH密钥管理功能，确保服务器的安全性。

## 📋 模块概述

### 功能列表

- **SSH安全配置**：优化SSH服务器安全设置
- **SSH密钥管理**：自动生成和部署SSH密钥
- **访问控制**：配置用户访问权限
- **安全加固**：基础的系统安全加固
- **密钥认证**：配置基于密钥的身份认证

### 支持的系统

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 22.10
- 支持 x86_64 和 ARM64 架构

## 🔐 SSH安全配置脚本

### 脚本路径
`scripts/security/ssh-config.sh`

### 功能说明

SSH是服务器远程管理的主要方式，安全的SSH配置对服务器安全至关重要：

1. **访问控制**：限制登录用户和方式
2. **加密强度**：使用强加密算法
3. **认证方式**：配置密钥认证
4. **连接限制**：防止暴力破解攻击
5. **日志审计**：记录访问日志

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/security/ssh-config.sh)

# 或者下载后执行
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/security/ssh-config.sh -o ssh-config.sh
chmod +x ssh-config.sh
./ssh-config.sh
```

### 安全配置项

#### 基础安全设置
```bash
# 禁用root直接登录
PermitRootLogin no

# 禁用密码为空的用户登录
PermitEmptyPasswords no

# 启用公钥认证
PubkeyAuthentication yes

# 设置认证尝试次数
MaxAuthTries 3

# 设置最大会话数
MaxSessions 2

# 设置连接超时
ClientAliveInterval 300
ClientAliveCountMax 2
```

#### 协议和加密设置
```bash
# 使用SSH协议版本2
Protocol 2

# 配置加密算法
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# 配置MAC算法
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512

# 配置密钥交换算法
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
```

#### 访问控制设置
```bash
# 允许特定用户登录
AllowUsers user1 user2

# 禁止特定用户登录
DenyUsers baduser

# 允许特定组登录
AllowGroups ssh-users sudo

# 设置登录横幅
Banner /etc/ssh/banner
```

### 执行流程

1. **备份配置**：备份原始SSH配置文件
2. **安全检查**：检查当前SSH配置
3. **生成配置**：生成安全的SSH配置
4. **权限设置**：设置正确的文件权限
5. **服务重启**：重启SSH服务应用配置
6. **连接测试**：测试SSH连接是否正常

## 🔑 SSH密钥管理脚本

### 脚本路径
`scripts/security/ssh-keygen.sh`

### 功能说明

SSH密钥认证比密码认证更安全，提供：

1. **密钥生成**：生成强加密的SSH密钥对
2. **密钥部署**：自动部署公钥到目标服务器
3. **密钥管理**：管理多个SSH密钥
4. **批量部署**：支持批量部署到多台服务器
5. **密钥备份**：安全备份私钥

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/security/ssh-keygen.sh)

# 交互式使用
./scripts/security/ssh-keygen.sh
```

### 支持的密钥类型

#### Ed25519密钥（推荐）
```bash
# 生成Ed25519密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 特点：
# - 安全性高
# - 密钥长度短
# - 性能好
# - 现代加密算法
```

#### RSA密钥
```bash
# 生成4096位RSA密钥
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 特点：
# - 兼容性好
# - 广泛支持
# - 密钥长度较长
# - 传统加密算法
```

#### ECDSA密钥
```bash
# 生成ECDSA密钥
ssh-keygen -t ecdsa -b 521 -C "your_email@example.com"

# 特点：
# - 椭圆曲线加密
# - 性能较好
# - 密钥长度适中
```

### 密钥部署

#### 单服务器部署
```bash
# 复制公钥到服务器
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server.com

# 或者手动添加
cat ~/.ssh/id_ed25519.pub | ssh user@server.com "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### 批量部署
```bash
# 定义服务器列表
servers=(
    "user@server1.com"
    "user@server2.com"
    "user@server3.com"
)

# 批量部署公钥
for server in "${servers[@]}"; do
    echo "部署到: $server"
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "$server"
done
```

### 密钥管理

#### SSH配置文件
创建`~/.ssh/config`文件管理多个密钥：

```bash
# 默认配置
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519

# 特定服务器配置
Host myserver
    HostName server.example.com
    User myuser
    Port 2222
    IdentityFile ~/.ssh/myserver_key

# GitHub配置
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key

# 工作服务器配置
Host work-*
    User workuser
    IdentityFile ~/.ssh/work_key
    ProxyJump jumpserver.company.com
```

## 🔧 高级安全配置

### 双因素认证

配置SSH双因素认证：

```bash
# 安装Google Authenticator
sudo apt install libpam-google-authenticator

# 配置PAM
sudo nano /etc/pam.d/sshd
# 添加：auth required pam_google_authenticator.so

# 配置SSH
sudo nano /etc/ssh/sshd_config
# 修改：ChallengeResponseAuthentication yes
# 添加：AuthenticationMethods publickey,keyboard-interactive

# 用户配置
google-authenticator
```

### 端口敲门

配置端口敲门增强安全性：

```bash
# 安装knockd
sudo apt install knockd

# 配置knockd
sudo nano /etc/knockd.conf
```

```ini
[options]
    UseSyslog

[openSSH]
    sequence    = 7000,8000,9000
    seq_timeout = 5
    command     = /sbin/iptables -A INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
    tcpflags    = syn

[closeSSH]
    sequence    = 9000,8000,7000
    seq_timeout = 5
    command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
    tcpflags    = syn
```

### 防火墙配置

配置UFW防火墙：

```bash
# 启用UFW
sudo ufw enable

# 默认策略
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 允许SSH
sudo ufw allow ssh
sudo ufw allow 22/tcp

# 限制SSH连接频率
sudo ufw limit ssh

# 允许特定IP访问SSH
sudo ufw allow from 192.168.1.100 to any port 22

# 查看状态
sudo ufw status verbose
```

## 📝 安全最佳实践

### SSH密钥安全

1. **使用强密码**：为私钥设置强密码
2. **定期轮换**：定期更换SSH密钥
3. **权限控制**：设置正确的文件权限
4. **备份管理**：安全备份私钥
5. **密钥分离**：不同用途使用不同密钥

### 文件权限设置

```bash
# SSH目录权限
chmod 700 ~/.ssh

# 私钥权限
chmod 600 ~/.ssh/id_*

# 公钥权限
chmod 644 ~/.ssh/id_*.pub

# authorized_keys权限
chmod 600 ~/.ssh/authorized_keys

# config文件权限
chmod 600 ~/.ssh/config
```

### 监控和审计

#### SSH日志监控
```bash
# 查看SSH登录日志
sudo tail -f /var/log/auth.log

# 查看失败的登录尝试
sudo grep "Failed password" /var/log/auth.log

# 查看成功的登录
sudo grep "Accepted" /var/log/auth.log
```

#### 自动化监控脚本
```bash
#!/bin/bash
# SSH监控脚本

# 检查失败登录次数
failed_attempts=$(grep "Failed password" /var/log/auth.log | wc -l)

if [ $failed_attempts -gt 10 ]; then
    echo "警告：检测到 $failed_attempts 次失败登录尝试"
    # 发送邮件或其他通知
fi

# 检查新的SSH连接
new_connections=$(grep "Accepted" /var/log/auth.log | tail -10)
echo "最近的SSH连接："
echo "$new_connections"
```

## 🔧 故障排除

### 常见问题

#### SSH连接被拒绝
```bash
# 检查SSH服务状态
sudo systemctl status ssh

# 检查SSH配置
sudo sshd -t

# 查看SSH日志
sudo tail -f /var/log/auth.log

# 重启SSH服务
sudo systemctl restart ssh
```

#### 密钥认证失败
```bash
# 检查密钥权限
ls -la ~/.ssh/

# 检查authorized_keys
cat ~/.ssh/authorized_keys

# 测试密钥
ssh -i ~/.ssh/id_ed25519 -v user@server.com
```

#### 配置文件错误
```bash
# 验证SSH配置
sudo sshd -t

# 恢复备份配置
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config

# 重启服务
sudo systemctl restart ssh
```

### 紧急恢复

#### 通过控制台访问
如果SSH配置错误导致无法连接：

1. 通过物理控制台或VNC访问服务器
2. 恢复SSH配置文件备份
3. 重启SSH服务
4. 测试连接

#### 重置SSH配置
```bash
# 恢复默认配置
sudo cp /etc/ssh/sshd_config.dpkg-old /etc/ssh/sshd_config

# 或者重新安装SSH
sudo apt reinstall openssh-server

# 重启服务
sudo systemctl restart ssh
```

## 🔗 相关链接

- [OpenSSH官方文档](https://www.openssh.com/)
- [SSH安全配置指南](https://wiki.mozilla.org/Security/Guidelines/OpenSSH)
- [SSH密钥管理最佳实践](https://www.ssh.com/academy/ssh/key-management)
- [Ubuntu SSH文档](https://ubuntu.com/server/docs/service-openssh)
- [SSH强化指南](https://stribika.github.io/2015/01/04/secure-secure-shell.html)
