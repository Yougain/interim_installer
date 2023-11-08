syntax on
colorscheme molokai
set t_Co=256
set fileencoding=japan
set fileencodings=utf-8
set tabstop=4
let $LANG='ja_JP.UTF-8'
set encoding=utf-8
set backspace=indent,eol,start
fu! ResetSpaces()
    set expandtab
    %retab
endfunction

autocmd BufWritePre *.yml :call ResetSpaces()


if &term == "xterm"
  let &t_ti = &t_ti . "\e[?2004h"
  let &t_te = "\e[?2004l" . &t_te
  let &pastetoggle = "\e[201~"
 
  function XTermPasteBegin(ret)
    set paste
    return a:ret
  endfunction
 
  map <special> <expr> <Esc>[200~ XTermPasteBegin("i")
  imap <special> <expr> <Esc>[200~ XTermPasteBegin("")
  cmap <special> <Esc>[200~ <nop>
  cmap <special> <Esc>[201~ <nop>
endif

