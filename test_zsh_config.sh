#!/bin/bash

# =============================================================================
# ZSH配置功能测试脚本
# 作者: saul
# 描述: 测试 zsh-install.sh 中的插件配置管理功能
# =============================================================================

set -euo pipefail

# 导入颜色定义
readonly RED=$(printf '\033[31m' 2>/dev/null || echo '')
readonly GREEN=$(printf '\033[32m' 2>/dev/null || echo '')
readonly YELLOW=$(printf '\033[33m' 2>/dev/null || echo '')
readonly BLUE=$(printf '\033[34m' 2>/dev/null || echo '')
readonly CYAN=$(printf '\033[36m' 2>/dev/null || echo '')
readonly RESET=$(printf '\033[m' 2>/dev/null || echo '')

# 日志函数
log_info() {
    echo -e "${CYAN}[TEST]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${RESET} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${RESET} $1"
}

# 测试智能插件配置管理
test_smart_plugin_config() {
    log_info "测试智能插件配置管理功能..."
    
    # 创建测试目录
    local test_dir="/tmp/zsh-config-test-$$"
    mkdir -p "$test_dir"
    
    # 测试用例1: 现有插件配置存在的情况
    log_info "测试用例1: 现有插件配置存在"
    cat > "$test_dir/.zshrc" << 'EOF'
# 测试配置文件
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git sudo extract)

source $ZSH/oh-my-zsh.sh
EOF
    
    # 模拟智能插件配置管理函数
    smart_plugin_config_test() {
        local zshrc_file="$1"
        local temp_file=$(mktemp)
        
        # 复制原配置
        cp "$zshrc_file" "$temp_file"
        
        # 定义完整的插件列表
        local complete_plugins="git extract systemadmin zsh-interactive-cd systemd sudo docker ubuntu man command-not-found common-aliases docker-compose zsh-autosuggestions zsh-syntax-highlighting tmux zoxide you-should-use"
        
        # 检查是否存在 plugins=() 配置行
        if grep -q "^plugins=" "$temp_file"; then
            echo "发现现有插件配置，进行智能合并..."
            
            # 提取现有插件列表
            local current_line=$(grep "^plugins=" "$temp_file")
            echo "当前插件配置行: $current_line"
            
            # 提取括号内的插件列表
            local current_plugins=$(echo "$current_line" | sed 's/^plugins=(//' | sed 's/)$//' | tr -s ' ' | sed 's/^ *//;s/ *$//')
            echo "当前插件列表: $current_plugins"
            
            # 将现有插件转换为数组
            local existing_array=()
            if [ -n "$current_plugins" ]; then
                IFS=' ' read -ra existing_array <<< "$current_plugins"
            fi
            
            # 将完整插件列表转换为数组
            local complete_array=()
            IFS=' ' read -ra complete_array <<< "$complete_plugins"
            
            # 合并插件列表，避免重复
            local merged_plugins=()
            local plugin_exists
            
            # 先添加现有插件
            for plugin in "${existing_array[@]}"; do
                [ -n "$plugin" ] && merged_plugins+=("$plugin")
            done
            
            # 添加新插件（如果不存在）
            for new_plugin in "${complete_array[@]}"; do
                plugin_exists=false
                for existing_plugin in "${merged_plugins[@]}"; do
                    if [ "$existing_plugin" = "$new_plugin" ]; then
                        plugin_exists=true
                        break
                    fi
                done
                
                if [ "$plugin_exists" = false ]; then
                    merged_plugins+=("$new_plugin")
                    echo "添加新插件: $new_plugin"
                fi
            done
            
            # 生成新的插件配置行
            local new_plugins_line="plugins=(${merged_plugins[*]})"
            echo "新插件配置行: $new_plugins_line"
            
            # 替换插件配置行
            sed -i "s/^plugins=.*/$new_plugins_line/" "$temp_file"
            echo "插件配置已更新，包含 ${#merged_plugins[@]} 个插件"
            
        else
            echo "未找到插件配置，创建新的插件配置..."
            
            # 在 Oh My Zsh 源之前添加插件配置
            if grep -q "source.*oh-my-zsh.sh" "$temp_file"; then
                sed -i "/source.*oh-my-zsh.sh/i\\plugins=($complete_plugins)" "$temp_file"
                echo "已添加完整插件配置"
            else
                # 如果没有找到 source 行，在文件开头添加
                sed -i "1i\\plugins=($complete_plugins)" "$temp_file"
                echo "已在文件开头添加插件配置"
            fi
        fi
        
        # 应用更改
        mv "$temp_file" "$zshrc_file"
        return 0
    }
    
    # 执行测试
    smart_plugin_config_test "$test_dir/.zshrc"
    
    # 验证结果
    if grep -q "plugins=(git sudo extract systemadmin zsh-interactive-cd systemd docker ubuntu man command-not-found common-aliases docker-compose zsh-autosuggestions zsh-syntax-highlighting tmux zoxide you-should-use)" "$test_dir/.zshrc"; then
        log_success "测试用例1通过: 插件配置正确合并"
    else
        log_error "测试用例1失败: 插件配置合并不正确"
        echo "实际配置:"
        grep "plugins=" "$test_dir/.zshrc"
    fi
    
    # 测试用例2: 无现有插件配置的情况
    log_info "测试用例2: 无现有插件配置"
    cat > "$test_dir/.zshrc2" << 'EOF'
# 测试配置文件
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

source $ZSH/oh-my-zsh.sh
EOF
    
    smart_plugin_config_test "$test_dir/.zshrc2"
    
    # 验证结果
    if grep -q "plugins=(git extract systemadmin zsh-interactive-cd systemd sudo docker ubuntu man command-not-found common-aliases docker-compose zsh-autosuggestions zsh-syntax-highlighting tmux zoxide you-should-use)" "$test_dir/.zshrc2"; then
        log_success "测试用例2通过: 新插件配置正确添加"
    else
        log_error "测试用例2失败: 新插件配置添加不正确"
        echo "实际配置:"
        cat "$test_dir/.zshrc2"
    fi
    
    # 清理测试文件
    rm -rf "$test_dir"
    
    log_info "智能插件配置管理功能测试完成"
}

# 测试 Powerlevel10k 配置
test_p10k_config() {
    log_info "测试 Powerlevel10k 配置功能..."
    
    # 创建测试目录
    local test_dir="/tmp/p10k-config-test-$$"
    mkdir -p "$test_dir"
    
    # 创建测试配置文件
    cat > "$test_dir/.zshrc" << 'EOF'
# 测试配置文件
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git)

source $ZSH/oh-my-zsh.sh
EOF
    
    # 模拟 ensure_p10k_config 函数
    ensure_p10k_config_test() {
        local zshrc_file="$1"
        local temp_file=$(mktemp)
        
        echo "确保 Powerlevel10k 配置..."
        
        # 复制原配置
        cp "$zshrc_file" "$temp_file"
        
        # 检查是否已有 p10k.zsh 源配置
        if ! grep -q "\[.*-f.*\.p10k\.zsh.*\].*source.*\.p10k\.zsh" "$temp_file"; then
            echo "添加 Powerlevel10k 配置源..."
            
            # 在文件末尾添加 p10k 配置
            cat >> "$temp_file" << 'EOF'

# Powerlevel10k 配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
            echo "已添加 Powerlevel10k 配置源"
        else
            echo "Powerlevel10k 配置源已存在"
        fi
        
        # 应用更改
        mv "$temp_file" "$zshrc_file"
        return 0
    }
    
    # 执行测试
    ensure_p10k_config_test "$test_dir/.zshrc"
    
    # 验证结果
    if grep -q "\[.*-f.*\.p10k\.zsh.*\].*source.*\.p10k\.zsh" "$test_dir/.zshrc"; then
        log_success "Powerlevel10k 配置测试通过"
    else
        log_error "Powerlevel10k 配置测试失败"
        echo "实际配置:"
        cat "$test_dir/.zshrc"
    fi
    
    # 清理测试文件
    rm -rf "$test_dir"
    
    log_info "Powerlevel10k 配置功能测试完成"
}

# 主测试函数
main() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE}ZSH配置功能测试${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
    
    test_smart_plugin_config
    echo
    test_p10k_config
    echo
    
    log_success "所有测试完成"
}

# 运行测试
main "$@"
