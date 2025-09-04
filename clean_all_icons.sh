#!/bin/bash

# =============================================================================
# 清理所有Shell脚本中的emoji图标
# 作者: saul
# 版本: 1.0
# 描述: 扫描并移除所有.sh文件中的emoji和Unicode装饰字符
# =============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly CYAN='\033[36m'
readonly RESET='\033[0m'

# 日志函数
log_info() {
    echo -e "${CYAN}[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1${RESET}"
}

# 显示头部信息
show_header() {
    echo -e "${BLUE}================================================================${RESET}"
    echo -e "${BLUE} 清理所有Shell脚本中的emoji图标${RESET}"
    echo -e "${BLUE}================================================================${RESET}"
    echo
}

# 定义要清理的emoji图标列表
declare -A EMOJI_REPLACEMENTS=(
    # 常用emoji
    ["🚀"]=""
    ["📥"]=""
    ["❌"]=""
    ["✅"]=""
    ["🧹"]=""
    ["🔧"]=""
    ["🐚"]=""
    ["🛠️"]=""
    ["🔐"]=""
    ["🐳"]=""
    ["📦"]=""
    ["🎯"]=""
    ["💡"]=""
    ["🔄"]=""
    ["⚠️"]=""
    ["📝"]=""
    ["📋"]=""
    ["🎨"]=""
    ["🎉"]=""
    ["🔍"]=""
    ["🌐"]=""
    ["👤"]=""
    ["🎁"]=""
    ["⏭️"]=""
    ["🔌"]=""
    ["⚙️"]=""
    ["📁"]=""
    ["📧"]=""
    ["🔖"]=""
    ["📊"]=""
    # 数字emoji
    ["1️⃣"]="1."
    ["2️⃣"]="2."
    ["3️⃣"]="3."
    ["4️⃣"]="4."
    ["5️⃣"]="5."
    ["6️⃣"]="6."
    ["7️⃣"]="7."
    ["8️⃣"]="8."
    ["9️⃣"]="9."
    ["0️⃣"]="0."
)

# 检查文件是否包含emoji
has_emoji() {
    local file="$1"
    # 使用更简单的方法检查是否包含emoji
    if grep -P "[\x{1F300}-\x{1F9FF}]|[\x{2600}-\x{26FF}]|[\x{2700}-\x{27BF}]|📧|🔖|📊" "$file" 2>/dev/null; then
        return 0
    fi
    return 1
}

# 清理单个文件中的emoji
clean_file_emoji() {
    local file="$1"
    local temp_file=$(mktemp)
    local changes_made=false

    # 复制原文件到临时文件
    cp "$file" "$temp_file"

    # 应用所有emoji替换
    for emoji in "${!EMOJI_REPLACEMENTS[@]}"; do
        local replacement="${EMOJI_REPLACEMENTS[$emoji]}"
        if grep -q "$emoji" "$temp_file" 2>/dev/null; then
            # 使用perl进行安全的替换
            if perl -i -pe "s/\Q$emoji\E/$replacement/g" "$temp_file" 2>/dev/null; then
                changes_made=true
            fi
        fi
    done

    if [ "$changes_made" = true ]; then
        # 替换回原文件
        mv "$temp_file" "$file"
        return 0
    else
        # 没有变化，删除临时文件
        rm -f "$temp_file"
        return 1
    fi
}

# 主清理函数
main() {
    show_header

    log_info "开始扫描Shell脚本文件..."

    # 查找所有.sh文件
    local shell_files=()
    while IFS= read -r -d '' file; do
        shell_files+=("$file")
    done < <(find /root/scripts-for-linux -name "*.sh" -type f -print0 2>/dev/null)

    if [ ${#shell_files[@]} -eq 0 ]; then
        log_warn "未找到任何Shell脚本文件"
        exit 0
    fi

    log_info "找到 ${#shell_files[@]} 个Shell脚本文件"
    echo

    local processed_count=0
    local cleaned_count=0

    # 处理每个文件
    for file in "${shell_files[@]}"; do
        log_info "检查文件: $file"

        if has_emoji "$file"; then
            log_info "  发现emoji图标，正在清理..."

            # 创建备份
            cp "$file" "$file.emoji-backup-$(date +%Y%m%d-%H%M%S)"

            if clean_file_emoji "$file"; then
                log_success "  清理完成"
                ((cleaned_count++))
            else
                log_warn "  清理失败"
            fi
        else
            log_info "  无emoji图标，跳过"
        fi

        ((processed_count++))
    done

    echo
    log_info "处理完成统计："
    log_info "  总文件数: ${#shell_files[@]}"
    log_info "  已处理: $processed_count"
    log_info "  已清理: $cleaned_count"

    # 验证清理结果
    echo
    log_info "验证清理结果..."

    local remaining_files=0
    for file in "${shell_files[@]}"; do
        if has_emoji "$file"; then
            log_warn "文件仍包含emoji: $file"
            ((remaining_files++))
        fi
    done

    if [ $remaining_files -eq 0 ]; then
        log_success "所有emoji图标已成功清理"
    else
        log_warn "仍有 $remaining_files 个文件包含emoji图标"
    fi

    echo
    log_info "清理操作完成"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
