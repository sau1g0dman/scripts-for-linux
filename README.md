# Ubuntu 服务器初始化脚本库

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Ubuntu%2020--22-orange.svg)
![Architecture](https://img.shields.io/badge/arch-x64%20%7C%20ARM64-green.svg)
![Shell](https://img.shields.io/badge/shell-bash-lightgrey.svg)

**一个用于Ubuntu 20-22服务器快速初始化和配置的脚本库**

[功能特性](#功能特性) • [快速开始](#快速开始) • [脚本说明](#脚本说明) • [安装指南](#安装指南) • [故障排除](#故障排除)

</div>

## 📋 项目简介

这是一个专为Ubuntu 20-22服务器设计的初始化脚本库，支持x64和ARM64架构。提供了一套完整的服务器配置解决方案，包括系统配置、开发环境搭建、容器化工具安装等功能。

### 🎯 设计目标

- **简化部署**：一键执行，自动化配置
- **模块化设计**：按功能分类，便于维护
- **跨架构支持**：同时支持x64和ARM64平台
- **错误处理**：完善的错误检测和恢复机制
- **中文友好**：全中文文档和提示信息

## ✨ 功能特性

### 🔧 系统配置
- **时间同步**：自动配置NTP时间同步
- **软件源**：配置国内镜像源，提升下载速度
- **系统更新**：安全的系统软件包更新

### 🐚 Shell环境
- **ZSH安装**：自动安装ZSH和Oh My Zsh
- **插件配置**：预配置常用插件（自动补全、语法高亮等）
- **主题美化**：Powerlevel10k主题配置
- **ARM支持**：专门优化的ARM版本

### 🛠️ 开发工具
- **Neovim**：现代化编辑器配置
- **LazyVim**：高效的Neovim配置框架
- **AstroNvim**：功能丰富的Neovim发行版
- **LazyGit**：优雅的Git管理工具

### 🔐 安全配置
- **SSH配置**：安全的SSH服务器配置
- **密钥管理**：自动生成和部署SSH密钥
- **权限设置**：合理的文件和目录权限

### 🐳 容器化
- **Docker安装**：一键安装Docker和Docker Compose
- **镜像加速**：配置国内Docker镜像源
- **镜像管理**：Docker镜像推送和管理工具
- **Harbor支持**：Harbor私有仓库集成

### 🛠️ 实用工具
- **磁盘格式化**：安全的磁盘格式化工具
- **系统监控**：基础的系统监控配置

## 🚀 快速开始

### 一键安装脚本

```bash
# 克隆仓库 进入目录 运行脚本
git  clone https://github.com/sau1g0dman/scripts-for-linux.git
cd  scripts-for-linux
bash install.sh
```

### 分模块使用

#### ZSH环境配置
```bash
# 标准版本
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install.sh)

# 国内源版本
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install-gitee.sh)

# ARM版本
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-arm.sh)
```

#### 系统配置
```bash
# 时间同步
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/system/time-sync.sh)

# 软件源配置
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/system/mirrors.sh)
```

#### Docker环境
```bash
# Docker安装
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-install.sh)

# Docker镜像推送工具
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-push.sh)
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

## 📁 项目结构

```
scripts-for-linux/
├── README.md                    # 项目说明文档
├── LICENSE                      # 开源许可证
├── install.sh                   # 一键安装脚本
├── docs/                        # 文档目录
│   ├── installation.md          # 安装指南
│   ├── troubleshooting.md       # 故障排除
│   └── modules/                 # 各模块详细文档
├── scripts/                     # 主要脚本目录
│   ├── common.sh                # 通用函数库
│   ├── system/                  # 系统配置
│   │   ├── time-sync.sh         # 时间同步
│   │   └── mirrors.sh           # 软件源配置
│   ├── shell/                   # Shell环境配置
│   │   ├── zsh-install.sh       # ZSH安装配置
│   │   ├── zsh-install-gitee.sh # ZSH安装（国内源）
│   │   └── zsh-arm.sh           # ARM版ZSH
│   ├── development/             # 开发工具
│   │   └── nvim-setup.sh        # Neovim配置
│   ├── security/                # 安全配置
│   │   ├── ssh-config.sh        # SSH配置
│   │   └── ssh-keygen.sh        # SSH密钥生成
│   ├── containers/              # 容器相关
│   │   ├── docker-install.sh    # Docker安装
│   │   ├── docker-mirrors.sh    # Docker镜像源
│   │   ├── docker-push.sh       # Docker推送工具
│   │   └── harbor-push.sh       # Harbor推送工具
│   └── utilities/               # 实用工具
│       └── disk-formatter.sh    # 磁盘格式化
└── themes/                      # 主题配置
    └── powerlevel10k/           # P10K主题
        ├── dracula.zsh
        ├── rainbow.zsh
        └── emoji.zsh
```

## 💻 系统要求

### 支持的操作系统
- Ubuntu 20.04 LTS (Focal Fossa)
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 22.10 (Kinetic Kudu)

### 支持的架构
- x86_64 (AMD64)
- ARM64 (AArch64)
- ARMv7 (部分脚本支持)

### 基础要求
- **网络连接**：需要互联网连接下载软件包
- **存储空间**：至少1GB可用空间
- **内存**：建议2GB以上RAM
- **权限**：需要sudo权限进行系统配置

### 依赖软件
脚本会自动安装以下基础依赖：
- `curl` - 用于下载文件
- `wget` - 备用下载工具
- `git` - 版本控制工具
- `unzip` - 解压工具
- `jq` - JSON处理工具

## 🔧 安装指南

### 方式一：一键安装（推荐）

```bash
# 下载安装脚本
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/install.sh -o install.sh

# 查看脚本内容（可选）
cat install.sh

# 执行安装
chmod +x install.sh
./install.sh
```

### 方式二：克隆仓库

```bash
# 克隆仓库
git clone https://github.com/sau1g0dman/scripts-for-linux.git
cd scripts-for-linux

# 设置执行权限
chmod +x scripts/**/*.sh

# 运行特定脚本
./scripts/shell/zsh-install.sh
```

### 方式三：直接执行

```bash
# 直接从网络执行（不推荐用于生产环境）
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install.sh)
```

## 📖 脚本说明

### 系统配置脚本

#### 时间同步 (`scripts/system/time-sync.sh`)
- **功能**：配置NTP时间同步，确保系统时间准确
- **支持**：多个NTP服务器，自动选择最快的服务器
- **用途**：解决TLS/SSL握手、软件包验证等时间相关问题

#### 软件源配置 (`scripts/system/mirrors.sh`)
- **功能**：配置Ubuntu软件源为国内镜像
- **支持**：阿里云、清华、中科大等多个镜像源
- **特性**：自动检测最快镜像源，支持ARM架构

### Shell环境脚本

#### ZSH安装 (`scripts/shell/zsh-install.sh`)
- **功能**：安装ZSH、Oh My Zsh、插件和主题
- **插件**：自动补全、语法高亮、历史搜索等
- **主题**：Powerlevel10k主题，支持自定义配置
- **特性**：自动配置.zshrc，设置为默认Shell

#### ARM版ZSH (`scripts/shell/zsh-arm.sh`)
- **功能**：专为ARM设备优化的ZSH安装脚本
- **支持**：OpenWrt、树莓派等ARM设备
- **优化**：减少内存占用，提升性能

### 容器化脚本

#### Docker安装 (`scripts/containers/docker-install.sh`)
- **功能**：安装Docker、Docker Compose、LazyDocker
- **配置**：自动配置镜像加速器，优化下载速度
- **验证**：运行测试容器验证安装

#### Docker推送工具 (`scripts/containers/docker-push.sh`)
- **功能**：搜索、拉取、标记、推送Docker镜像
- **特性**：交互式菜单，支持批量操作
- **用途**：简化镜像迁移到私有仓库的流程

### 开发工具脚本

#### Neovim配置 (`scripts/development/nvim-setup.sh`)
- **功能**：安装Neovim、LazyVim、AstroNvim
- **插件**：LSP、语法高亮、文件管理等
- **工具**：集成LazyGit等开发工具

### 安全配置脚本

#### SSH配置 (`scripts/security/ssh-config.sh`)
- **功能**：安全的SSH服务器配置
- **安全**：禁用root登录、配置密钥认证
- **优化**：性能和安全性平衡

#### SSH密钥管理 (`scripts/security/ssh-keygen.sh`)
- **功能**：生成SSH密钥对，自动部署公钥
- **支持**：多种密钥类型，批量部署
- **安全**：强密码保护，安全的密钥存储

## ⚠️ 注意事项

### 安全提醒
1. **生产环境**：建议先在测试环境验证脚本
2. **备份数据**：运行脚本前备份重要配置文件
3. **网络安全**：确保从可信源下载脚本
4. **权限控制**：仅在必要时使用sudo权限

### 使用建议
1. **分步执行**：建议分模块执行，便于问题定位
2. **日志查看**：注意查看脚本执行日志
3. **配置检查**：执行后验证配置是否正确
4. **定期更新**：定期更新脚本到最新版本

### 兼容性说明
1. **Ubuntu版本**：主要支持LTS版本
2. **架构支持**：x64和ARM64完全支持
3. **网络环境**：需要稳定的网络连接
4. **硬件要求**：低端设备可能需要更长时间

## 🐛 故障排除

### 常见问题

#### 网络连接问题
```bash
# 检查网络连接
ping -c 4 www.baidu.com

# 检查DNS解析
nslookup github.com

# 更换DNS服务器
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

#### 权限问题
```bash
# 检查sudo权限
sudo -v

# 添加用户到sudo组
sudo usermod -aG sudo $USER

# 重新登录使权限生效
```

#### 软件包安装失败
```bash
# 更新软件包列表
sudo apt update

# 修复损坏的软件包
sudo apt --fix-broken install

# 清理软件包缓存
sudo apt clean && sudo apt autoclean
```

#### ZSH配置问题
```bash
# 重置ZSH配置
rm -rf ~/.oh-my-zsh ~/.zshrc
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install.sh)

# 手动设置默认Shell
chsh -s $(which zsh)
```

#### Docker问题
```bash
# 检查Docker服务状态
sudo systemctl status docker

# 启动Docker服务
sudo systemctl start docker

# 添加用户到docker组
sudo usermod -aG docker $USER
```

### 获取帮助

如果遇到问题，可以通过以下方式获取帮助：

1. **查看日志**：脚本会输出详细的执行日志
2. **检查文档**：查看`docs/`目录下的详细文档
3. **提交Issue**：在GitHub仓库提交问题报告
4. **社区讨论**：参与项目讨论区

## 🤝 贡献指南

欢迎贡献代码和建议！

### 贡献方式
1. Fork本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

### 开发规范
- 遵循现有的代码风格
- 添加适当的注释和文档
- 确保脚本在不同架构上的兼容性
- 包含错误处理和日志输出

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 👨‍💻 作者

**saul**
- 邮箱: sau1amaranth@gmail.com
- GitHub: [@sau1g0dman](https://github.com/sau1g0dman)

## 🙏 致谢

感谢以下项目和社区的支持：
- [Oh My Zsh](https://ohmyz.sh/) - ZSH框架
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - ZSH主题
- [LazyVim](https://github.com/LazyVim/LazyVim) - Neovim配置
- [Docker](https://www.docker.com/) - 容器化平台
- Ubuntu社区和开源贡献者们

---

<div align="center">

**如果这个项目对您有帮助，请给个⭐️支持一下！**

</div>
