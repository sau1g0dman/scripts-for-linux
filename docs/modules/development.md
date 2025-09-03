# 开发工具模块

开发工具模块提供了现代化的开发环境配置，包括Neovim编辑器、LazyVim配置框架、AstroNvim发行版和LazyGit等工具。

## 📋 模块概述

### 功能列表

- **Neovim安装**：安装最新版本的Neovim编辑器
- **LazyVim配置**：高效的Neovim配置框架
- **AstroNvim发行版**：功能丰富的Neovim发行版
- **LazyGit工具**：优雅的Git管理TUI工具
- **LSP支持**：语言服务器协议支持
- **插件生态**：丰富的插件生态系统

### 支持的系统

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 22.10
- 支持 x86_64 和 ARM64 架构

## 📝 Neovim配置脚本

### 脚本路径
`scripts/development/nvim-setup.sh`

### 功能说明

Neovim是Vim的现代化重构版本，提供：

1. **异步支持**：异步插件和作业支持
2. **内置LSP**：内置语言服务器协议支持
3. **Lua配置**：使用Lua进行配置
4. **现代UI**：支持现代终端特性
5. **插件生态**：丰富的插件生态系统
6. **性能优化**：更好的性能和响应速度

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/development/nvim-setup.sh)

# 或者下载后执行
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/development/nvim-setup.sh -o nvim-setup.sh
chmod +x nvim-setup.sh
./nvim-setup.sh
```

### 安装的组件

#### 核心组件
1. **Neovim**：现代化的Vim编辑器
2. **Node.js**：插件运行时环境
3. **Python3**：Python插件支持
4. **Git**：版本控制工具
5. **Ripgrep**：快速文本搜索工具
6. **fd**：快速文件查找工具

#### 配置框架
1. **LazyVim**：高效的Neovim配置框架
2. **AstroNvim**：功能丰富的Neovim发行版
3. **自定义配置**：优化的个人配置

#### 开发工具
1. **LazyGit**：Git管理TUI工具
2. **Tree-sitter**：语法高亮和解析
3. **LSP客户端**：语言服务器支持
4. **调试器**：DAP调试协议支持

## 🚀 LazyVim配置框架

### 功能特性

LazyVim是一个现代化的Neovim配置框架：

1. **快速启动**：优化的启动速度
2. **模块化**：模块化的配置结构
3. **插件管理**：使用lazy.nvim插件管理器
4. **LSP集成**：完整的LSP支持
5. **美观界面**：现代化的用户界面
6. **键位映射**：合理的默认键位映射

### 主要插件

#### 界面增强
- **neo-tree.nvim**：文件浏览器
- **bufferline.nvim**：标签页管理
- **lualine.nvim**：状态栏
- **alpha-nvim**：启动屏幕
- **which-key.nvim**：键位提示

#### 编辑增强
- **nvim-cmp**：自动补全
- **nvim-autopairs**：自动配对
- **nvim-surround**：包围操作
- **comment.nvim**：注释插件
- **indent-blankline.nvim**：缩进线

#### 开发工具
- **nvim-lspconfig**：LSP配置
- **null-ls.nvim**：格式化和诊断
- **nvim-dap**：调试支持
- **gitsigns.nvim**：Git集成
- **telescope.nvim**：模糊查找

### 使用方法

```bash
# 安装LazyVim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# 启动Neovim
nvim
```

### 常用快捷键

#### 基础操作
- `<leader>` = `<Space>`
- `<leader>ff` - 查找文件
- `<leader>fg` - 全局搜索
- `<leader>fb` - 查找缓冲区
- `<leader>fh` - 查找帮助

#### 文件管理
- `<leader>e` - 打开/关闭文件浏览器
- `<leader>o` - 在文件浏览器中定位当前文件

#### 窗口管理
- `<C-h/j/k/l>` - 窗口间移动
- `<leader>w` - 窗口操作前缀
- `<leader>-` - 水平分割
- `<leader>|` - 垂直分割

#### Git操作
- `<leader>gg` - 打开LazyGit
- `<leader>gb` - Git blame
- `<leader>gf` - Git文件历史

## 🌟 AstroNvim发行版

### 功能特性

AstroNvim是一个功能丰富的Neovim发行版：

1. **开箱即用**：预配置的开发环境
2. **美观界面**：精美的用户界面
3. **完整功能**：包含所有常用功能
4. **易于定制**：简单的定制方式
5. **社区支持**：活跃的社区支持

### 安装方法

```bash
# 备份现有配置
mv ~/.config/nvim ~/.config/nvim.bak

# 克隆AstroNvim
git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim

# 启动Neovim
nvim
```

### 主要特性

#### 用户界面
- **Dashboard**：美观的启动界面
- **Statusline**：信息丰富的状态栏
- **Tabline**：标签页管理
- **Sidebar**：侧边栏文件浏览器

#### 开发功能
- **LSP支持**：多语言LSP支持
- **代码补全**：智能代码补全
- **语法高亮**：Tree-sitter语法高亮
- **代码格式化**：自动代码格式化
- **错误诊断**：实时错误检查

## 🎯 LazyGit工具

### 功能说明

LazyGit是一个简单的Git管理TUI工具：

1. **直观界面**：直观的文本用户界面
2. **快速操作**：快速的Git操作
3. **可视化**：可视化的Git历史
4. **键盘操作**：完全键盘操作
5. **功能完整**：支持大部分Git功能

### 安装方法

```bash
# Ubuntu安装
sudo add-apt-repository ppa:lazygit-team/release
sudo apt update
sudo apt install lazygit

# 或者使用脚本安装
curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' | xargs -I {} curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_{}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
```

### 使用方法

```bash
# 在Git仓库中启动
lazygit

# 或者在Neovim中使用
# 在LazyVim中按 <leader>gg
```

### 常用快捷键

#### 基础操作
- `j/k` - 上下移动
- `h/l` - 左右切换面板
- `Enter` - 选择/进入
- `Esc` - 返回/取消
- `q` - 退出

#### Git操作
- `a` - 暂存所有文件
- `A` - 修改最后一次提交
- `c` - 提交
- `P` - 推送
- `p` - 拉取
- `R` - 刷新

#### 分支操作
- `n` - 新建分支
- `o` - 创建拉取请求
- `M` - 合并
- `r` - 变基
- `d` - 删除分支

## 🔧 语言服务器配置

### 支持的语言

脚本会自动配置以下语言的LSP支持：

#### Web开发
- **TypeScript/JavaScript**：tsserver
- **HTML**：html-lsp
- **CSS**：css-lsp
- **JSON**：json-lsp
- **Vue.js**：volar
- **React**：typescript-language-server

#### 系统编程
- **Python**：pylsp, pyright
- **Go**：gopls
- **Rust**：rust-analyzer
- **C/C++**：clangd
- **Java**：jdtls

#### 脚本语言
- **Bash**：bash-language-server
- **Lua**：lua-language-server
- **PHP**：intelephense
- **Ruby**：solargraph

#### 配置文件
- **YAML**：yaml-language-server
- **TOML**：taplo
- **XML**：lemminx
- **Dockerfile**：dockerfile-language-server

### LSP配置示例

```lua
-- ~/.config/nvim/lua/config/lsp.lua
local lspconfig = require('lspconfig')

-- Python
lspconfig.pyright.setup({
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      }
    }
  }
})

-- TypeScript
lspconfig.tsserver.setup({
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }
    }
  }
})

-- Go
lspconfig.gopls.setup({
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
    },
  },
})
```

## 🎨 主题和外观

### 推荐主题

#### 暗色主题
- **Catppuccin**：现代暗色主题
- **Tokyo Night**：受Tokyo Night启发
- **Gruvbox**：经典暗色主题
- **One Dark**：Atom One Dark移植

#### 亮色主题
- **Catppuccin Latte**：亮色版本
- **One Light**：Atom One Light移植
- **GitHub Light**：GitHub风格亮色主题

### 字体推荐

#### Nerd Fonts
推荐使用Nerd Fonts以获得最佳图标支持：

```bash
# 安装Nerd Fonts
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

# 下载JetBrains Mono Nerd Font
curl -fLo "JetBrains Mono Regular Nerd Font Complete.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete.ttf

# 刷新字体缓存
fc-cache -fv
```

## 🔧 故障排除

### 常见问题

#### Neovim启动慢
```bash
# 检查启动时间
nvim --startuptime startup.log

# 查看启动日志
cat startup.log | sort -k2 -n
```

#### LSP不工作
```bash
# 检查LSP状态
:LspInfo

# 检查LSP日志
:LspLog

# 重启LSP
:LspRestart
```

#### 插件安装失败
```bash
# 检查网络连接
ping github.com

# 手动安装插件
:Lazy install

# 清理插件缓存
:Lazy clean
```

#### 字体图标显示异常
```bash
# 安装Nerd Fonts
# 设置终端字体为Nerd Font
# 重启终端
```

### 配置重置

如果配置出现问题，可以重置配置：

```bash
# 备份当前配置
mv ~/.config/nvim ~/.config/nvim.backup

# 重新安装
./scripts/development/nvim-setup.sh
```

## 🔗 相关链接

- [Neovim官方网站](https://neovim.io/)
- [LazyVim项目](https://github.com/LazyVim/LazyVim)
- [AstroNvim项目](https://github.com/AstroNvim/AstroNvim)
- [LazyGit项目](https://github.com/jesseduffield/lazygit)
- [Neovim插件列表](https://github.com/rockerBOO/awesome-neovim)
- [Nerd Fonts](https://www.nerdfonts.com/)
