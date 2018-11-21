#create_admin_user.sh

### install baseic  ###
yum -y groupinstall "Base" "Development tools"
yum -y install screen
yum -y install etckeeper screen

### install etckeeper ###
touch /etc/.gitignore
echo "shadow*" >> /etc/.gitignore
echo "gshadow*" >> /etc/.gitignore
echo "passwd*" >> /etc/.gitignore
echo "group*" >> /etc/.gitignore
etckeeper init
etckeeper commit "First Commit"

### bash setting ###
cat >> /home/${ADMIN_USER}/.bash_profile <<EOF
export EDITOR=vim
export PS1="[\u@\h \W]\\$ "
EOF
source ~/.bash_profile

### screen setting ###
cat > /home/${ADMIN_USER}/.screenrc <<EOF
escape ^Jj
hardstatus alwayslastline "[%02c] %-w%{=b bw}%n %t%{-}%+w"
startup_message off
vbell off
autodetach on
defscrollback 10000
termcapinfo xterm* ti@:te@
EOF
chown ${ADMIN_USER}. /home/${ADMIN_USER}/.screenrc

### vim setting ###
cat > /home/${ADMIN_USER}/.vimrc <<EOF
syntax on
"set number
set enc=utf-8
set fenc=utf-8
set fencs=iso-2022-jp,euc-jp,cp932
set backspace=2
set noswapfile
"set shiftwidth=4
"set tabstop=4
set shiftwidth=2
set tabstop=2
"set expandtab
set hlsearch
set backspace=indent,eol,start
"" for us-keybord
"nnoremap ; :
"nnoremap : ;
"" Remove comment out as you like
"hi Comment ctermfg=DarkGray
EOF
chown ${ADMIN_USER}. /home/${ADMIN_USER}/.vimrc
