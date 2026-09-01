" -----------------------------------------------------------------------------
" Basics
" -----------------------------------------------------------------------------

set history=500

" Locale / menus
let $LANG = 'en_US.UTF-8'
set langmenu=en

" Use UTF-8 as standard encoding
set encoding=utf-8
set fileencodings=utf8,gbk,gb18030,gb2312,big5
set fileformats=unix,dos,mac

" -----------------------------------------------------------------------------
" Autocommands
" -----------------------------------------------------------------------------

augroup Vimrc
  autocmd!

  " Check file timestamps on focus/buffer enter
  if !has('ide')
    autocmd FocusGained,BufEnter * silent! checktime
  endif

  " Restore cursor position when reopening files
  autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line('$') |
        \   execute "normal! g'\"" |
        \ endif
augroup END

" -----------------------------------------------------------------------------
" Leader + keymaps
" -----------------------------------------------------------------------------

let mapleader = ' '

nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>p "+p
vnoremap <leader>p "+p

" Replace: select text, then <leader>r to pre-fill :%s/<selection>//g
vmap <leader>r "hy:%s/\C<C-r>h//g<left><left>

" Command-line editing
cnoremap <C-A> <Home>
cnoremap <C-E> <End>

" Count matches for the last search
nmap <leader>cnt :%s///gn<CR>

" :W sudo saves the file (handy for permission-denied)
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!

" Disable command-line window
nnoremap q: :

set jumpoptions=stack

" -----------------------------------------------------------------------------
" UI
" -----------------------------------------------------------------------------

set number
set relativenumber
set mouse=a
set path+=**

set list
set listchars=tab:→\ ,nbsp:␣,trail:•,precedes:«,extends:»

nmap <S-left> :vertical resize +3<CR>
nmap <S-right> :vertical resize -3<CR>
nmap <S-up> :resize -1<CR>
nmap <S-down> :resize +1<CR>

set scrolloff=7

set wildmenu
set wildignore=*.o,*~,*.pyc,*.class
if has('win16') || has('win32')
  set wildignore+=.git\*,.hg\*,.svn\*
else
  set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

set ruler
set hidden
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" -----------------------------------------------------------------------------
" Searching / performance
" -----------------------------------------------------------------------------

set ignorecase
set smartcase
set magic

set lazyredraw
set showmatch
set matchtime=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set timeoutlen=500

set foldcolumn=0

" -----------------------------------------------------------------------------
" Colors
" -----------------------------------------------------------------------------

try
  colorscheme nord
  set termguicolors
  set cursorline
catch
endtry

function! SwitchToLight() abort
  if has('nvim')
    lua require('visual_studio_code').setup({ mode = 'light' })
  endif
  colorscheme visual_studio_code
endfunction

function! SwitchToVSCode() abort
  if has('nvim')
    lua require('visual_studio_code').setup({ mode = 'dark' })
  endif
  colorscheme visual_studio_code
endfunction

function! SwitchToDark() abort
  if has('nvim')
    lua require('nord').setup({diff={mode='fg'},search={theme='vscode'},styles={comments={italic=false}}})
  endif
  colorscheme nord
endfunction

command! -nargs=0 Light call SwitchToLight()
command! -nargs=0 VSCode call SwitchToVSCode()
command! -nargs=0 Dark call SwitchToDark()

" -----------------------------------------------------------------------------
" Files, backups and swap
" -----------------------------------------------------------------------------

set nobackup
set nowritebackup
set noswapfile

" -----------------------------------------------------------------------------
" Text, tabs and indent
" -----------------------------------------------------------------------------

" set expandtab
set smarttab
set shiftwidth=4
set tabstop=4

set linebreak
set textwidth=500

set autoindent
set smartindent
set nowrap " Do not wrap lines

" -----------------------------------------------------------------------------
" Visual mode helpers
" -----------------------------------------------------------------------------

" Visual mode pressing * or # searches for the current selection.
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-r>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-r>=@/<CR><CR>

" -----------------------------------------------------------------------------
" Windows / buffers
" -----------------------------------------------------------------------------

map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-h> <C-w>h
map <C-l> <C-w>l

map <leader>cd :cd %:p:h<CR>:pwd<CR>
map <leader>tcd :tcd %:p:h<CR>:pwd<CR>

try
  set showtabline=2
catch
endtry

nmap ]b :bnext<CR>
nmap [b :bprevious<CR>

" -----------------------------------------------------------------------------
" Statusline
" -----------------------------------------------------------------------------

set laststatus=2

" -----------------------------------------------------------------------------
" Commands / helpers
" -----------------------------------------------------------------------------

function! CleanExtraSpaces() abort
  let save_cursor = getpos('.')
  let old_query = getreg('/')
  silent! %s/\s\+$//e
  call setpos('.', save_cursor)
  call setreg('/', old_query)
endfunction

command! -nargs=0 Trim call CleanExtraSpaces()

function! HasPaste() abort
  return &paste ? 'PASTE MODE  ' : ''
endfunction

function! CmdLine(str) abort
  call feedkeys(':' . a:str)
endfunction

function! VisualSelection(direction, extra_filter) range abort
  let l:saved_reg = @"
  execute 'normal! vgvy'

  let l:pattern = escape(@", "\\/.*'$^~[]")
  let l:pattern = substitute(l:pattern, "\n$", '', '')

  if a:direction ==# 'gv'
    call CmdLine("Ack '" . l:pattern . "' ")
  elseif a:direction ==# 'replace'
    call CmdLine('%s' . '/' . l:pattern . '/')
  endif

  let @/ = l:pattern
  let @" = l:saved_reg
endfunction

" -----------------------------------------------------------------------------
" Netrw
" -----------------------------------------------------------------------------

let g:netrw_winsize=25
let g:netrw_banner=0
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_liststyle=3
let g:netrw_chgwin=1

" -----------------------------------------------------------------------------
" Buffer close helper (:Bclose)
" -----------------------------------------------------------------------------

" Delete buffer while keeping window layout (don't close buffer windows).
" Version 2008-11-18 from http://vim.wikia.com/wiki/VimTip165
if v:version >= 700 && !exists('loaded_bclose') && !&cp
  let loaded_bclose = 1
  if !exists('bclose_multiple')
    let bclose_multiple = 1
  endif

  function! s:Warn(msg) abort
    echohl ErrorMsg
    echomsg a:msg
    echohl NONE
  endfunction

  function! s:Bclose(bang, buffer) abort
    if empty(a:buffer)
      let btarget = bufnr('%')
    elseif a:buffer =~# '^\d\+$'
      let btarget = bufnr(str2nr(a:buffer))
    else
      let btarget = bufnr(a:buffer)
    endif
    if btarget < 0
      call s:Warn('No matching buffer for ' . a:buffer)
      return
    endif
    if empty(a:bang) && getbufvar(btarget, '&modified')
      call s:Warn('No write since last change for buffer ' . btarget . ' (use :Bclose!)')
      return
    endif

    let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')
    if !g:bclose_multiple && len(wnums) > 1
      call s:Warn('Buffer is in multiple windows (use ":let bclose_multiple=1")')
      return
    endif

    let wcurrent = winnr()
    for w in wnums
      execute w . 'wincmd w'
      let prevbuf = bufnr('#')
      if prevbuf > 0 && buflisted(prevbuf) && prevbuf != btarget
        buffer #
      else
        bprevious
      endif
      if btarget == bufnr('%')
        let blisted = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != btarget')
        let bhidden = filter(copy(blisted), 'bufwinnr(v:val) < 0')
        let bjump = (bhidden + blisted + [-1])[0]
        if bjump > 0
          execute 'buffer ' . bjump
        else
          execute 'enew' . a:bang
        endif
      endif
    endfor

    execute 'bdelete' . a:bang . ' ' . btarget
    execute wcurrent . 'wincmd w'
  endfunction

  command! -bang -complete=buffer -nargs=? Bclose call <SID>Bclose(<q-bang>, <q-args>)
  cabbrev bd Bclose
endif

" -----------------------------------------------------------------------------
" Terminal
" -----------------------------------------------------------------------------

if exists(':terminal')
  nmap <leader>tm :sp<CR><C-w>j:resize -6<CR>:setlocal nonumber norelativenumber<CR>:terminal<CR>A
endif

" -----------------------------------------------------------------------------
" Quickfix
" -----------------------------------------------------------------------------

function! ToggleQuickFix() abort
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction
nnoremap <silent> <leader>q :call ToggleQuickFix()<CR>

" -----------------------------------------------------------------------------
" Count matches after / or ?
" -----------------------------------------------------------------------------

if has('nvim-0.4.0') || has('patch-8.2.0750')
  let s:MAXCOUNT = 100000
  let s:TIMEOUT = 500

  augroup index_after_slash
    autocmd!
    autocmd CmdlineLeave /,\? call s:index_after_slash()
  augroup END

  function! s:index_after_slash() abort
    if getcmdline() is# '' || state() =~# 'm'
      return
    endif
    call timer_start(0, {-> mode() =~# '[nv]' ? s:search_index() : 0})
  endfunction

  function! s:search_index() abort
    try
      let result = searchcount(#{maxcount: s:MAXCOUNT, timeout: s:TIMEOUT})
      let [current, total, incomplete] = [result.current, result.total, result.incomplete]
    catch
      echohl ErrorMsg | echom v:exception | echohl NONE
      return ''
    endtry

    let pat = substitute(@/, '\%x00', '^@', 'g')
    if incomplete == 0
      let msg = printf('[%*d/%d] %s', len(total), current, total, pat)
    elseif incomplete == 1
      let msg = printf('[?/??] %s', pat)
    else
      if result.total == (result.maxcount + 1) && result.current <= result.maxcount
        let msg = printf('[%*d/>%d] %s', len(total - 1), current, total - 1, pat)
      else
        let msg = printf('[>%*d/>%d] %s', len(total - 1), current - 1, total - 1, pat)
      endif
    endif

    if strchars(msg, 1) > (v:echospace + (&cmdheight - 1) * &columns)
      let n = v:echospace - 3
      let [n1, n2] = n % 2 ? [n / 2, n / 2] : [n / 2 - 1, n / 2]
      let msg = matchlist(msg, '\(.\{' .. n1 .. '}\).*\(.\{' .. n2 .. '}\)')[1:2]->join('...')
    endif

    echo msg
    return ''
  endfunction

  nmap n <plug>(n)<plug>(search_index)
  nmap N <plug>(N)<plug>(search_index)
  nnoremap <plug>(n) n
  nnoremap <plug>(N) N
  nnoremap <expr> <plug>(search_index) <sid>search_index()
endif

" -----------------------------------------------------------------------------
" Environment
" -----------------------------------------------------------------------------

let $PATH = '/opt/homebrew/bin:' . $HOME . '/go/bin:/usr/local/go/bin:/usr/local/bin:' . $PATH
