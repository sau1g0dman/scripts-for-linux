# Shell环境模块

Shell环境模块提供了现代化的ZSH环境配置，包括Oh My Zsh、插件和主题的自动安装和配置。

## 📋 模块概述

### 功能列表

- **ZSH安装**：自动安装ZSH和Oh My Zsh框架
- **插件配置**：预配置常用插件（自动补全、语法高亮等）
- **主题美化**：Powerlevel10k主题配置
- **ARM优化**：专门优化的ARM版本
- **国内源支持**：支持使用国内镜像源加速下载

### 支持的系统

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 22.10
- 支持 x86_64、ARM64 和 ARMv7 架构
- 特别优化OpenWrt等嵌入式系统

## 🐚 ZSH安装脚本

### 脚本路径
- `scripts/shell/zsh-install.sh` - 标准版本
- `scripts/shell/zsh-install-gitee.sh` - 国内源版本
- `scripts/shell/zsh-arm.sh` - ARM优化版本

### 功能说明

ZSH是一个功能强大的Shell，相比bash提供了：

1. **智能补全**：更强大的Tab补全功能
2. **语法高亮**：实时语法高亮显示
3. **历史搜索**：增强的命令历史搜索
4. **主题支持**：丰富的主题和提示符定制
5. **插件生态**：庞大的插件生态系统

### 使用方法

#### 标准版本
```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install.sh)

# 或者下载后执行
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install.sh -o zsh-install.sh
chmod +x zsh-install.sh
./zsh-install.sh
```

#### 国内源版本（推荐）
```bash
# 使用国内源，下载速度更快
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install-gitee.sh)
```

#### ARM版本
```bash
# 专为ARM设备优化
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-arm.sh)
```

### 安装的组件

#### 核心组件
1. **ZSH Shell**：现代化的Shell环境
2. **Oh My Zsh**：ZSH配置管理框架
3. **Powerlevel10k**：高性能主题

#### 预装插件
1. **zsh-autosuggestions**：命令自动建议
2. **zsh-syntax-highlighting**：语法高亮
3. **zsh-completions**：额外的补全功能
4. **git**：Git集成插件
5. **sudo**：双击ESC添加sudo
6. **extract**：智能解压插件
7. **z**：智能目录跳转

### 配置文件

脚本会自动生成优化的`.zshrc`配置文件：

```bash
# ZSH配置文件 - 自动生成

# Oh My Zsh配置
export ZSH="$HOME/.oh-my-zsh"

# 主题设置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件配置
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    sudo
    extract
    z
)

# 加载Oh My Zsh
source $ZSH/oh-my-zsh.sh

# 用户配置
export LANG=en_US.UTF-8
export EDITOR='vim'

# 别名设置
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# 历史记录配置
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# 自动补全配置
autoload -U compinit
compinit

# Powerlevel10k即时提示
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 加载Powerlevel10k配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

## 🎨 主题配置

### Powerlevel10k主题

Powerlevel10k是一个高性能的ZSH主题，提供：

1. **快速渲染**：优化的渲染性能
2. **丰富信息**：Git状态、系统信息等
3. **高度定制**：可配置的提示符元素
4. **图标支持**：支持Nerd Fonts图标

### 主题配置

安装完成后，运行以下命令配置主题：

```bash
# 配置Powerlevel10k主题
p10k configure
```

### 预设主题文件

项目提供了几个预设的主题配置：

- `themes/powerlevel10k/rainbow.zsh` - 彩虹主题
- `themes/powerlevel10k/dracula.zsh` - Dracula主题
- `themes/powerlevel10k/emoji.zsh` - Emoji主题

使用预设主题：

```bash
# 复制预设主题配置
cp themes/powerlevel10k/rainbow.zsh ~/.p10k.zsh

# 重新加载ZSH配置
source ~/.zshrc
```

## 🔧 高级配置

### 自定义插件

添加额外的ZSH插件：

```bash
# 进入插件目录
cd ~/.oh-my-zsh/custom/plugins

# 克隆插件
git clone https://github.com/zsh-users/zsh-history-substring-search.git

# 编辑.zshrc添加插件
nano ~/.zshrc
# 在plugins数组中添加：zsh-history-substring-search
```

### 自定义别名

在`.zshrc`中添加自定义别名：

```bash
# 编辑配置文件
nano ~/.zshrc

# 添加自定义别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Docker别名
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# Git别名
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
```

### 环境变量配置

支持通过环境变量自定义安装行为：

```bash
# 启用自动安装模式
export AUTO_INSTALL=true

# 自定义主题
export ZSH_THEME="agnoster"

# 自定义插件列表
export ZSH_PLUGINS="git,zsh-autosuggestions,zsh-syntax-highlighting"

# 执行安装
./scripts/shell/zsh-install.sh
```

## 📱 ARM设备优化

### ARM版本特性

ARM版本针对嵌入式设备进行了特别优化：

1. **内存优化**：减少内存占用
2. **性能优化**：优化启动速度
3. **插件精简**：只安装必要插件
4. **兼容性**：支持OpenWrt等系统

### 适用设备

- 树莓派 (Raspberry Pi)
- OpenWrt路由器
- ARM开发板
- 嵌入式Linux设备

### 使用方法

```bash
# ARM设备专用版本
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-arm.sh)
```

## 🌐 国内源支持

### Gitee镜像版本

为了解决国内网络访问GitHub较慢的问题，提供了Gitee镜像版本：

```bash
# 使用Gitee镜像
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/shell/zsh-install-gitee.sh)
```

### 镜像源配置

脚本会自动配置以下镜像源：

1. **Oh My Zsh**：使用Gitee镜像
2. **插件仓库**：使用国内镜像
3. **主题仓库**：使用加速镜像

## 📝 使用技巧

### 常用快捷键

- `Ctrl + A`：移动到行首
- `Ctrl + E`：移动到行尾
- `Ctrl + R`：搜索历史命令
- `Ctrl + L`：清屏
- `Tab`：自动补全
- `ESC ESC`：在命令前添加sudo

### 插件功能

#### zsh-autosuggestions
- 根据历史记录自动建议命令
- 按右箭头键接受建议

#### zsh-syntax-highlighting
- 实时语法高亮
- 错误命令显示为红色

#### z插件
```bash
# 智能目录跳转
z documents  # 跳转到包含documents的目录
z doc        # 模糊匹配
```

## 🔧 故障排除

### 常见问题

#### ZSH安装失败
```bash
# 手动安装ZSH
sudo apt update
sudo apt install -y zsh

# 检查安装
which zsh
zsh --version
```

#### Oh My Zsh安装失败
```bash
# 清理旧安装
rm -rf ~/.oh-my-zsh

# 手动安装
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### 主题显示异常
```bash
# 安装字体
sudo apt install -y fonts-powerline

# 安装Nerd Fonts
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLo "DroidSansMono Nerd Font Complete.otf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf
fc-cache -fv
```

#### 默认Shell设置失败
```bash
# 手动设置默认Shell
chsh -s $(which zsh)

# 或者编辑/etc/passwd
sudo nano /etc/passwd
# 修改用户行的shell路径为/usr/bin/zsh
```

### 性能优化

#### 启动速度优化
```bash
# 禁用不需要的插件
# 编辑~/.zshrc，注释掉不需要的插件

# 优化补全系统
# 在~/.zshrc中添加：
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
```

#### 内存优化
```bash
# 限制历史记录大小
export HISTSIZE=1000
export SAVEHIST=1000

# 禁用不需要的功能
unsetopt share_history
```

## 🔗 相关链接

- [ZSH官方文档](https://zsh.sourceforge.io/)
- [Oh My Zsh项目](https://ohmyz.sh/)
- [Powerlevel10k主题](https://github.com/romkatv/powerlevel10k)
- [ZSH插件列表](https://github.com/unixorn/awesome-zsh-plugins)
- [Nerd Fonts字体](https://www.nerdfonts.com/)
