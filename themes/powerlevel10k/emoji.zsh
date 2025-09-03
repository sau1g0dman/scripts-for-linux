# Powerlevel10k Emoji主题配置
# 作者: saul
# 描述: 使用Emoji图标的Powerlevel10k主题配置

# 启用即时提示
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 临时设置选项
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # 卸载配置向导
  unset -f p10k-config-wizard

  # 左侧提示符元素
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon                 # 操作系统图标
    dir                     # 当前目录
    vcs                     # Git仓库状态
    prompt_char             # 提示符字符
  )

  # 右侧提示符元素
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # 退出状态
    command_execution_time  # 命令执行时间
    background_jobs         # 后台任务
    direnv                  # direnv状态
    asdf                    # asdf版本管理器
    virtualenv              # Python虚拟环境
    anaconda                # Anaconda环境
    pyenv                   # pyenv Python版本
    goenv                   # goenv Go版本
    nodenv                  # nodenv Node版本
    nvm                     # nvm Node版本
    nodeenv                 # nodeenv Node环境
    rbenv                   # rbenv Ruby版本
    rvm                     # rvm Ruby版本
    fvm                     # fvm Flutter版本
    luaenv                  # luaenv Lua版本
    jenv                    # jenv Java版本
    plenv                   # plenv Perl版本
    phpenv                  # phpenv PHP版本
    scalaenv                # scalaenv Scala版本
    haskell_stack           # Haskell Stack
    kubecontext             # Kubernetes上下文
    terraform               # Terraform工作区
    aws                     # AWS配置文件
    aws_eb_env              # AWS Elastic Beanstalk环境
    azure                   # Azure账户
    gcloud                  # Google Cloud配置
    google_app_cred         # Google应用凭据
    context                 # 用户@主机名
    nordvpn                 # NordVPN连接状态
    ranger                  # ranger文件管理器
    nnn                     # nnn文件管理器
    vim_shell               # Vim shell指示器
    midnight_commander      # Midnight Commander
    nix_shell               # Nix shell
    vi_mode                 # Vi模式指示器
    todo                    # todo.txt任务计数
    timewarrior             # timewarrior时间跟踪
    taskwarrior             # taskwarrior任务管理
    time                    # 当前时间
    ip                      # IP地址和带宽使用
    public_ip               # 公共IP地址
    proxy                   # 系统代理
    battery                 # 内部电池
    wifi                    # WiFi速度
    example                 # 示例自定义段
  )

  # 基本样式选项
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # 多行提示符
  typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='🚀'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='⚡'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='📝'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='✏️'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=

  # 操作系统图标
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=232
  typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=7
  typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='🐧'

  # 目录
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=39
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER='📁'
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=false
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=false

  # Git仓库状态
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='🌿'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='❓'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='❗'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='✅'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='⬇️'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='⬆️'
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='📦'
  typeset -g POWERLEVEL9K_VCS_TAG_ICON='🏷️'
  typeset -g POWERLEVEL9K_VCS_BOOKMARK_ICON='🔖'
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='💾'
  typeset -g POWERLEVEL9K_VCS_REMOTE_BRANCH_ICON='🌐'
  typeset -g POWERLEVEL9K_VCS_GIT_ICON='🔧'
  typeset -g POWERLEVEL9K_VCS_GIT_GITHUB_ICON='🐙'
  typeset -g POWERLEVEL9K_VCS_GIT_BITBUCKET_ICON='🪣'
  typeset -g POWERLEVEL9K_VCS_GIT_GITLAB_ICON='🦊'
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=76
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178

  # 状态
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✅'
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='❌'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='⚡'
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='🔧'

  # 命令执行时间
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION='⏱️'

  # 后台任务
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=37
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='⚙️'

  # Python虚拟环境
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=37
  typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION='🐍'
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # Anaconda环境
  typeset -g POWERLEVEL9K_ANACONDA_FOREGROUND=37
  typeset -g POWERLEVEL9K_ANACONDA_VISUAL_IDENTIFIER_EXPANSION='🐍'

  # Node.js版本
  typeset -g POWERLEVEL9K_NODEENV_FOREGROUND=70
  typeset -g POWERLEVEL9K_NODEENV_VISUAL_IDENTIFIER_EXPANSION='📗'
  typeset -g POWERLEVEL9K_NVM_FOREGROUND=70
  typeset -g POWERLEVEL9K_NVM_VISUAL_IDENTIFIER_EXPANSION='📗'
  typeset -g POWERLEVEL9K_NODENV_FOREGROUND=70
  typeset -g POWERLEVEL9K_NODENV_VISUAL_IDENTIFIER_EXPANSION='📗'

  # Go版本
  typeset -g POWERLEVEL9K_GOENV_FOREGROUND=37
  typeset -g POWERLEVEL9K_GOENV_VISUAL_IDENTIFIER_EXPANSION='🐹'

  # Ruby版本
  typeset -g POWERLEVEL9K_RBENV_FOREGROUND=168
  typeset -g POWERLEVEL9K_RBENV_VISUAL_IDENTIFIER_EXPANSION='💎'
  typeset -g POWERLEVEL9K_RVM_FOREGROUND=168
  typeset -g POWERLEVEL9K_RVM_VISUAL_IDENTIFIER_EXPANSION='💎'

  # Java版本
  typeset -g POWERLEVEL9K_JENV_FOREGROUND=32
  typeset -g POWERLEVEL9K_JENV_VISUAL_IDENTIFIER_EXPANSION='☕'

  # Kubernetes
  typeset -g POWERLEVEL9K_KUBECONTEXT_FOREGROUND=37
  typeset -g POWERLEVEL9K_KUBECONTEXT_VISUAL_IDENTIFIER_EXPANSION='⎈'

  # Terraform
  typeset -g POWERLEVEL9K_TERRAFORM_FOREGROUND=38
  typeset -g POWERLEVEL9K_TERRAFORM_VISUAL_IDENTIFIER_EXPANSION='🏗️'

  # AWS
  typeset -g POWERLEVEL9K_AWS_FOREGROUND=208
  typeset -g POWERLEVEL9K_AWS_VISUAL_IDENTIFIER_EXPANSION='☁️'

  # 时间
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=66
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION='🕐'

  # 电池
  typeset -g POWERLEVEL9K_BATTERY_LOW_THRESHOLD=20
  typeset -g POWERLEVEL9K_BATTERY_LOW_FOREGROUND=160
  typeset -g POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND=70
  typeset -g POWERLEVEL9K_BATTERY_CHARGED_FOREGROUND=70
  typeset -g POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND=178
  typeset -g POWERLEVEL9K_BATTERY_LOW_VISUAL_IDENTIFIER_EXPANSION='🔋'
  typeset -g POWERLEVEL9K_BATTERY_CHARGING_VISUAL_IDENTIFIER_EXPANSION='🔌'
  typeset -g POWERLEVEL9K_BATTERY_CHARGED_VISUAL_IDENTIFIER_EXPANSION='🔋'
  typeset -g POWERLEVEL9K_BATTERY_DISCONNECTED_VISUAL_IDENTIFIER_EXPANSION='🔋'

  # WiFi
  typeset -g POWERLEVEL9K_WIFI_FOREGROUND=68
  typeset -g POWERLEVEL9K_WIFI_VISUAL_IDENTIFIER_EXPANSION='📶'

  # 用户@主机名
  typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=180
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=180
  typeset -g POWERLEVEL9K_CONTEXT_VISUAL_IDENTIFIER_EXPANSION='👤'
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_VISUAL_IDENTIFIER_EXPANSION='👑'

  # 瞬时提示模式
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
}

# 恢复选项
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
