# 系统配置模块

系统配置模块提供了Ubuntu服务器的基础系统配置功能，包括时间同步和软件源配置。

## 📋 模块概述

### 功能列表

- **时间同步**：配置NTP时间同步服务
- **软件源配置**：配置国内镜像源，提升下载速度
- **系统优化**：基础的系统性能优化

### 支持的系统

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 22.10
- 支持 x86_64 和 ARM64 架构

## ⏰ 时间同步脚本

### 脚本路径
`scripts/system/time-sync.sh`

### 功能说明

时间同步是服务器配置的重要基础，准确的系统时间对以下方面至关重要：

1. **TLS/SSL握手**：需要客户端和服务器时间同步（误差<5分钟）
2. **软件包验证**：apt/yum包管理器验证软件包签名依赖正确时间
3. **日志记录**：准确的时间戳对于日志分析和审计至关重要
4. **安全协议**：SSH、HTTPS等安全协议依赖时间同步

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/system/time-sync.sh)

# 或者下载后执行
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/system/time-sync.sh -o time-sync.sh
chmod +x time-sync.sh
./time-sync.sh
```

### 配置的NTP服务器

脚本按优先级配置以下NTP服务器：

1. **阿里云NTP服务器**（推荐）
   - ntp1.aliyun.com ~ ntp7.aliyun.com
   - time1.aliyun.com, time2.aliyun.com
   - ntp.aliyun.com

2. **公共NTP服务器**
   - cn.pool.ntp.org
   - ntp.ubuntu.com
   - time.google.com
   - time.cloudflare.com

### 执行流程

1. **环境检查**：检查系统类型和网络连接
2. **工具安装**：自动安装ntpdate或ntp工具
3. **服务器测试**：测试NTP服务器连通性
4. **时间同步**：执行时间同步操作
5. **时区配置**：设置为Asia/Shanghai时区
6. **验证结果**：显示同步前后的时间

### 示例输出

```
================================================================
🔧 系统初始化：时间同步配置
================================================================
[INFO] 2024-01-01 12:00:00 检查NTP时间同步工具...
[INFO] 2024-01-01 12:00:01 NTP工具已安装
[INFO] 2024-01-01 12:00:02 查找可用的NTP服务器...
[INFO] 2024-01-01 12:00:03 找到可用的NTP服务器: ntp1.aliyun.com
[INFO] 2024-01-01 12:00:04 当前系统时间: Mon Jan  1 12:00:04 CST 2024
[INFO] 2024-01-01 12:00:05 使用NTP服务器 ntp1.aliyun.com 同步时间...
[INFO] 2024-01-01 12:00:06 时间同步成功
[INFO] 2024-01-01 12:00:06 同步后系统时间: Mon Jan  1 12:00:06 CST 2024
```

## 📦 软件源配置脚本

### 脚本路径
`scripts/system/mirrors.sh`

### 功能说明

配置Ubuntu软件源为国内镜像，显著提升软件包下载速度。支持：

1. **自动检测**：自动检测最快的镜像源
2. **多源支持**：支持多个国内镜像源
3. **架构适配**：自动适配x86_64和ARM64架构
4. **备份恢复**：自动备份原始配置，支持恢复

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/system/mirrors.sh)

# 交互式配置
./scripts/system/mirrors.sh
```

### 支持的镜像源

按优先级排序：

1. **阿里云镜像**：mirrors.aliyun.com
2. **清华大学镜像**：mirrors.tuna.tsinghua.edu.cn
3. **中科大镜像**：mirrors.ustc.edu.cn
4. **网易镜像**：mirrors.163.com
5. **华为云镜像**：mirrors.huaweicloud.com

### 配置内容

脚本会配置以下软件源：

```bash
# 主要软件源
deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse

# 安全更新
deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse

# 推荐更新
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse

# 回退更新
deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
```

### 执行流程

1. **系统检测**：检测Ubuntu版本和架构
2. **网络测试**：测试各镜像源的连通性
3. **选择镜像**：自动选择最快的镜像源
4. **备份配置**：备份原始sources.list文件
5. **生成配置**：生成新的sources.list文件
6. **更新列表**：执行apt update更新软件包列表
7. **可选升级**：询问是否升级系统软件包

### 额外功能

脚本还支持配置额外的软件源：

#### Docker官方源
```bash
# 添加Docker GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加Docker软件源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### Node.js官方源
```bash
# 添加Node.js LTS源
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
```

## 🔧 高级配置

### 自定义NTP服务器

如果需要使用自定义的NTP服务器，可以修改脚本中的NTP_SERVERS数组：

```bash
# 编辑脚本
nano scripts/system/time-sync.sh

# 修改NTP服务器列表
readonly NTP_SERVERS=(
    "your.ntp.server.com"
    "backup.ntp.server.com"
    # ... 其他服务器
)
```

### 自定义镜像源

如果需要使用特定的镜像源：

```bash
# 编辑脚本
nano scripts/system/mirrors.sh

# 修改镜像源列表
readonly MIRRORS=(
    "your.mirror.server.com"
    "backup.mirror.server.com"
    # ... 其他镜像源
)
```

### 环境变量配置

支持通过环境变量自定义行为：

```bash
# 跳过用户确认
export AUTO_INSTALL=true

# 指定时区
export TIMEZONE="Asia/Shanghai"

# 指定镜像源
export PREFERRED_MIRROR="mirrors.aliyun.com"

# 执行脚本
./scripts/system/time-sync.sh
./scripts/system/mirrors.sh
```

## 📝 注意事项

### 时间同步注意事项

1. **网络要求**：需要能够访问NTP服务器
2. **权限要求**：需要sudo权限修改系统时间
3. **服务冲突**：可能与systemd-timesyncd服务冲突
4. **虚拟机环境**：某些虚拟机环境可能限制时间同步

### 软件源配置注意事项

1. **备份重要**：脚本会自动备份，但建议手动备份重要配置
2. **网络环境**：确保能够访问选择的镜像源
3. **架构匹配**：ARM设备会自动使用ports.ubuntu.com
4. **版本兼容**：确保镜像源支持您的Ubuntu版本

### 故障排除

#### 时间同步失败
```bash
# 手动同步时间
sudo ntpdate -s ntp1.aliyun.com

# 检查NTP服务状态
sudo systemctl status ntp

# 重启NTP服务
sudo systemctl restart ntp
```

#### 软件源更新失败
```bash
# 恢复原始配置
sudo cp /etc/apt/sources.list.backup.* /etc/apt/sources.list

# 手动更新
sudo apt update

# 清理缓存
sudo apt clean
```

## 🔗 相关链接

- [Ubuntu官方时间同步文档](https://ubuntu.com/server/docs/network-ntp)
- [Ubuntu软件源配置指南](https://help.ubuntu.com/community/Repositories)
- [阿里云镜像站](https://developer.aliyun.com/mirror/)
- [清华大学开源镜像站](https://mirrors.tuna.tsinghua.edu.cn/)
