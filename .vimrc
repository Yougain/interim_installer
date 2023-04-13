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

