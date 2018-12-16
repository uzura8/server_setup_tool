#create_admin_user.sh

### install baseic  ###
yum -y groupinstall "Base" "Development tools"
yum -y install screen

### bash setting ###
cat >> /home/${ADMIN_USER}/.bash_profile <<EOF
export PS1="[\u@\h \W]\\$ "
export EDITOR=vim
alias V='vim -R -'
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
ln -s /home/${ADMIN_USER}/.vimrc /root/

### git setting
cat > /home/${ADMIN_USER}/.gitconfig <<EOF
[color]
  diff = auto
  status = auto
  branch = auto
  interactive = auto
[alias]
  co = checkout
  st = status
  ci = commit -v
  di = diff
  di-file = diff --name-only
  up = pull --rebase
  br = branch
  ll  = log --graph --pretty=full --stat
  l  = log --oneline
EOF
echo "${GIT_USER_CONF}" >> /home/${ADMIN_USER}/.gitconfig
chown ${ADMIN_USER}. /home/${ADMIN_USER}/.gitconfig
ln -s /home/${ADMIN_USER}/.gitconfig /root/
