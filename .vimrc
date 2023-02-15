set nocompatible
"set guifont=Sans\ 11
set guifont=Monospace\ 11
set isfname-=,
set isfname-==
set isfname+=$
set isfname+={
set isfname+=}
set isfname+=(
set isfname+=)
set suffixesadd+=.py
set suffixesadd+=.sv
set suffixesadd+=.v
set path+=$AMSHOME/tools/affirma_ams/etc/dms
set path+=$CDS_WORKAREA/..
set path+=$CDS_WORKAREA/../fv/pkg
set path+=$CDS_WORKAREA/../fv/models
set path+=$CDS_WORKAREA/../fv/models_sv
set path+=$HOME/python
filetype off
set rtp+=~/.vim/bundle/Vundle.vim/
"execute pathogen#infect()
"call vundle#begin()
call vundle#rc()
Plugin 'VundleVim/Vundle.vim'
Plugin 'templates'
Plugin 'python.vim'
Plugin 'matchit'
Plugin 'matchindent.vim'
"Plugin 'pathogen.vim'
"Plugin 'tlib'
"Plugin 'tSkeleton'
Plugin 'pgilad/vim-skeletons'
Plugin 'systemverilog.vim'
Plugin 'davidhalter/jedi-vim'
Plugin 'jiangmiao/auto-pairs'
"call vundle#end()
"colorscheme evening
"colorscheme slate
colorscheme koehler
filetype plugin indent on
nnoremap <C-b> : windo diffthis<return>
nnoremap <F7> : windo diffoff<return>
nnoremap <F9> : set ignorecase! ignorecase?
nnoremap <CR> o<Esc>
nnoremap <esc> :noh<return><esc>
:set ignorecase
:set showcmd
:nnoremap <F2> :!sco %<CR><CR>
:nnoremap <F3> :!sci -D %<CR><CR>
:nnoremap <F4> :!scr %<CR><CR>
:nnoremap <F5> "=strftime("%c")<CR>Pa by xwzhang <esc>
:inoremap <F5> <C-R>=strftime("%c")<CR> by xwzhang <esc>i
:inoremap <buffer> ;fo; <C-O>mzfor( $ii = 0; $ii <= 5; $ii++)<CR>{ // <CR><CR>}<CR><C-O>'z
" header of the test
:inoremap <buffer> ;th; <C-O>mz//Test created on <F5><C-O>'z
:imap <buffer> ;te; ;th;<C-O>o<C-O>x<C-O>xmodule Test_9238();<CR><CR>import type_i2c::*;<CR>import fsm_pkg::*;<CR><CR>string testName1;<CR>logic [15:0] odata;<CR>REG_ADDRS reg1;<C-O>mz<CR><CR>initial begin<CR>testName = "<C-O>"%p"<C-O>3X;<CR>testName1 = testName;<CR>startTest();<CR>Initialize;<CR>finishTest();<CR>$finish;<CR>end<CR><CR>endmodule<CR><C-O>'z<esc><C-S>
:inoremap <F6> xwzhang
:nnoremap <F6> ixwzhang<esc>
:inoremap <C-1> <esc>:set list!<CR>a
:nnoremap <C-1> <esc>:set list!<CR><esc>
:set mousemodel=extend
:iab <expr> dts strftime("%c")
:set number
:set expandtab
:set shiftwidth=4
":set tw=120
:set tw=0
:set tabstop=4
:set softtabstop=4
:set autoindent
:set smartindent
:set cindent
:set copyindent
:set incsearch 
:set ruler
:set laststatus=2
":set modeline
:set statusline=%f
:set statusline+=%=%l/%L
:set autochdir
:inoremap <c-s> <Esc>:update<CR>
:nnoremap <c-s> <Esc>:w!<CR>
":nnoremap ; :
:nnoremap g* *
:nnoremap g& &
:nnoremap * g*
:nnoremap & g&
:nnoremap j gj
:nnoremap k gk
:nnoremap gj j
:nnoremap gk k
:nnoremap l <Right>
:nnoremap h <C-H>
":nnoremap <expr> n 'Nn'[v:searchforward]
":nnoremap <expr> N 'nN'[v:searchforward]
:nnoremap [e :<c-u>execute 'move -1-' . v:count1<cr>
:nnoremap ]e :<c-u>execute 'move +' . v:count1<cr>
:nnoremap [<space> :put! =''<cr>
:nnoremap ]<space> :put =''<cr>
":inoremap <c-r> <Esc>:e<CR>i
:nnoremap <leader>w <C-w>v<C-w>l
:nnoremap <C-w>f <C-w><C-h>gf
":nnoremap gf <C-w><C-h>gf
:nnoremap <C-h> <C-w>h
:nnoremap <C-j> <C-w>j
:nnoremap <C-k> <C-w>k
:nnoremap <C-l> <C-w>l
:inoremap \fn <C-R>=expand("%:t")<CR>
:inoremap \ams_switch ams_switch SWITCH_(.a(), .b(),.on());<Esc>F_a
" show trailing whitespace chars
set list
set listchars=tab:>-,trail::,extends:#,nbsp:.
:highlight ExtraWhitespace ctermbg=red guibg=red
:match ExtraWhitespace /\s\+$/

:set tags=tags;
:abbr hte the
"Better buffer management - hide buffers instead of closing them
set hidden
set cursorline
set history=100
" Default history is only 20
set undolevels=100 "Use more levels of undo
nmap <Space> i<Space>
:filetype plugin on
:filetype indent on
":source ~/.vim_bak/plugin/templates.vim
:source ~/.vim/bundle/jiangmiao/auto-pairs/plugin/auto-pairs.vim
":let loaded_matchit = 1
syntax on
filetype plugin indent on
set whichwrap+=<,>,[,]
set nf=octal,hex,alpha

"set titlestring=%t%(\ %M%)%(\ (%{expand(\"%:p:h\")})%)%(\ %a%)\ -\ %{v:servername}
"let &titlestring = hostname() . "[" . expand("%:t") . "]"
"if &term == "screen"
  "set t_ts=^[k
  "set t_fs=^[\
"endif
"if &term == "screen" || &term == "xterm"
  "set title
"endif

"set title titlestring=%{expand(\"%:p:t\")}\ -%{strpart(expand(\"%:p:h\"),stridx(expand(\"%:p:h\"),\"/\",strlen(expand(\"%:p:h\"))-32))}%=b%n.\ %m\ %Y\ line\ %l\ of\ %L
set title titlestring=%{expand(\"%:p:t\")}-%{join(split(expand(\"%:p:h\"),\"/\")[-2:-1],\"/\")}%=b%n.\ %m\ %Y\ line\ %l\ of\ %L

iabbrev <silent> CWD: <C-R>=getcwd()<CR>
imap <silent> <C-C> <C-R>=string(eval(input("Calculate: ")))<CR>

augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost "~/.vimrc" source ~/.vimrc
augroup END " }
"autocmd FileType python set colorcolumn=120
"let g:pymode_options_max_line_length = 120
"let g:pymode_lint_options_pep8 = {'max_line_length': g:pymode_options_max_line_length}
"let g:pymode_options_colorcolumn = 1
" Pylint configuration file
let g:pymode_lint_config = '$HOME/pylint.rc'
let g:VIMFILESDIR="~/.vim/"
let g:author="Xiwen Zhang"
let g:user="Xiwen Zhang"
let g:username="Xiwen Zhang"
let g:email="xiwen.zhang@nuvoltatech.com"
let g:webpage='www.nuvoltatech.com'
let g:phone="+1-949-331-5435"
":source ~/.vim/plugin/vimtemplates.vim
:source ~/.vim/test.vim
:command! -nargs=+ Calc :py print <args>
:py from math import *
if has("autocmd")
  augroup templates
    "autocmd BufNewFile *.py 0r ~/.vim/templates/default.py
    "autocmd BufNewFile * call LoadFileTemplate("")
  augroup END
endif
:inoremap <c-s> <Esc>:update<CR>
:inoremap <c-z> <Esc>:w<CR>a
:nnoremap <c-s> <Esc>:w!<CR>
