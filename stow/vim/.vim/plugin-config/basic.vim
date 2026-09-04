"不兼容vi
set nocompatible
"可加载插件
filetype plugin on
"跳转标签元素
runtime macros/matchit.vim
"配色方案
colorscheme habamax
"显示命令字符
set showcmd
"显示绝对行号
set number
"显示相对行号
set relativenumber
"高亮选区
set hlsearch
"更新预览选区
set incsearch
"制表距离
set tabstop=4
"缩进距离
set shiftwidth=4
"高亮光标所在行
set cursorline
"Ex命令行补全菜单
set wildmenu
set wildmode=full
"命令历史记录
set history=200
"启用隐藏缓冲区
set hidden
"启用mouse
set mouse=a
"test
set nowritebackup
set nobackup
" 设置 backspace 选项
set backspace=indent,eol,start
"关闭蜂鸣
set visualbell
set noerrorbells
"使搜索和命令行补全忽略大小写
set ignorecase
"在 ignorecase 生效的情况下，如果搜索模式包含大写字母，则进行区分大小写的搜索
set smartcase
"显示当前光标位置
set ruler
"高亮光标所在的屏幕列
set cursorcolumn
"编码
set termencoding=utf-8
set encoding=utf8
set fileencodings=utf8,ucs-bom,gbk,cp936,gb2312,gb18030
"中文文档
set helplang=cn
autocmd FileType * setlocal formatoptions-=r formatoptions-=o

command! Scratch enew | setlocal buftype=nofile bufhidden=hide noswapfile
