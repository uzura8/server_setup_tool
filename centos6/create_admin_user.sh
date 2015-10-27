#create_admin_user.sh

### install baseic  ###
yum -y groupinstall "Base" "Development tools"
yum -y install etckeeper screen

### install etckeeper ###
touch /etc/.gitignore
echo "shadow*" >> /etc/.gitignore
echo "gshadow*" >> /etc/.gitignore
echo "passwd*" >> /etc/.gitignore
echo "group*" >> /etc/.gitignore
etckeeper init
etckeeper commit "First Commit"

### Execute ADMIN_USER setting ###
# add ADMIN_USER
adduser ${ADMIN_USER}
passwd ${ADMIN_USER}
usermod -G wheel ${ADMIN_USER}

# Allows people in group wheel to run all commands
cp /etc/sudoers /tmp/sudoers.${DATE}.$$
sed -e "s/^# %wheel\(\s\+ALL=(ALL)\s\+ALL\)/%wheel\1/g" /etc/sudoers > /tmp/sudoers.$$
mv /tmp/sudoers.$$ /etc/sudoers
echo_and_exec "grep wheel /etc/sudoers"
next
rm /tmp/sudoers.${DATE}.$$

# Limited sudo user to wheel group
cp /etc/pam.d/su /tmp/su.${DATE}.$$
sed -e "s/^#\(auth\s\+required\s\+pam_wheel\.so\s\+use_uid\)/\1/g" /etc/pam.d/su > /tmp/su.$$
mv /tmp/su.$$ /etc/pam.d/su
echo_and_exec "grep pam_wheel /etc/pam.d/su"
next
rm /tmp/su.${DATE}.$$

# limited ssh login user to ADMIN_USER
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "AllowUsers ${ADMIN_USER}" >> /etc/ssh/sshd_config
echo_and_exec "tail -n2 /etc/ssh/sshd_config"
next
/etc/init.d/sshd restart


### bash setting ###
cat >> /home/srv_admin/.bash_profile <<EOF
export EDITOR=vim
export PS1="[\u@\h \W]\\$ "
EOF
source ~/.bash_profile

### screen setting ###
cat > /home/srv_admin/.screenrc <<EOF
escape ^Jj
hardstatus alwayslastline "[%02c] %-w%{=b bw}%n %t%{-}%+w"
startup_message off
vbell off
autodetach on
defscrollback 10000
termcapinfo xterm* ti@:te@
EOF
chown srv_admin. /home/srv_admin/.screenrc

### vim setting ###
cat > /home/srv_admin/.vimrc <<EOF
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
EOF
chown srv_admin. /home/srv_admin/.vimrc
