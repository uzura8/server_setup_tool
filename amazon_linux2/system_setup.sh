#system_setup.sh

### lang setting  ###
localectl set-locale LANG=ja_JP.utf8
cat /etc/locale.conf
next

### Add yum optional repository ###
amazon-linux-extras enable epel
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
#yum --enablerepo=epel -y update remi-release

#### Setting yum update ###
#yum update -y --enablerepo=rpmforge-extras git
yum -y update
yum -y install yum-cron
cp /etc/yum/yum-cron.conf /etc/yum/yum-cron.conf.ori
sed -e "s|^apply_updates = no|apply_updates = yes|" /etc/yum/yum-cron.conf > /tmp/yum-cron.conf.$$
mv /tmp/yum-cron.conf.$$ /etc/yum/yum-cron.conf
systemctl start yum-cron
systemctl enable yum-cron

yum -y groupinstall base "Development tools"

### install etckeeper ###
yum --enablerepo=epel -y install etckeeper
touch /etc/.gitignore
echo "shadow*" >> /etc/.gitignore
echo "gshadow*" >> /etc/.gitignore
echo "passwd*" >> /etc/.gitignore
echo "group*" >> /etc/.gitignore
git config --global user.email "${GIT_USER_EMAIL}"
git config --global user.name "${GIT_USER_NAME}"
etckeeper init
etckeeper commit "First Commit"

### nkf install
yum install -y nkf --enablerepo=epel

### Setting logwatch ###
yum -y install logwatch
echo "MailTo = ${ADMIN_EMAIL}" >> /etc/logwatch/conf/logwatch.conf
echo_and_exec "tail -n1 /etc/logwatch/conf/logwatch.conf"
next

### Disabled SELinux ###
setenforce 0
echo_and_exec "getenforce"
next

### firewalld disabled ###
systemctl stop firewalld.service
systemctl mask firewalld.service
echo_and_exec "systemctl list-unit-files | grep firewalld"
next

### denyhosts setting ###
#yum -y --enablerepo=epel install denyhosts
yum -y install rsyslog
systemctl start rsyslog
systemctl enable rsyslog

#echo "${ALLOW_IPS}" >> /var/lib/denyhosts/allowed-hosts
#echo_and_exec "cat /var/lib/denyhosts/allowed-hosts"
#next
#systemctl start denyhosts
#systemctl enable denyhosts

#### date setting ###
#ln -sf /usr/share/zoneinfo/Japan /etc/localtime

#### install postfix
yum -y install postfix
cp /etc/postfix/main.cf /etc/postfix/main.cf.ori
cat >> /etc/postfix/main.cf <<EOF

#smtp_tls_security_level = may # For postfix v2.3
smtpd_tls_received_header = yes
smtp_use_tls = yes

EOF
systemctl start postfix
systemctl enable postfix

#### set admin email
sed -i '/^root:/d' /etc/aliases
echo "root: ${ADMIN_EMAIL}" >> /etc/aliases
echo_and_exec "cat /etc/aliases | grep root"
next
newaliases

### install sar ###
#yum -y install sysstat

### install Mackerel ###
if [ -n "$MACKEREL_LICENCE_KEY" ]; then
	curl -fsSL https://mackerel.io/file/script/setup-all-yum-v2.sh | MACKEREL_APIKEY="${MACKEREL_LICENCE_KEY}" sh
fi

#### set ssh login alert mail
echo 'echo "\"$USER\" has logged in from $SSH_CLIENT at `date "+%Y/%m/%d %H:%M:%S"` to '$SERVISE_DOMAIN' " | mail -s "'$SERVISE_DOMAIN' sshd login alert" -r root@'$SERVISE_DOMAIN' '$ADMIN_EMAIL >> /etc/ssh/sshrc
#mkdir -p /usr/local/bin/
#cat > /usr/local/bin/ssh_alert.sh <<EOF
##!/bin/bash
#SOURCE_IP=${SSH_CLIENT%% *}
#for HOST in $ALLOW_IPS
#do
#  if [ $HOST == $SOURCE_IP ]; then
#    exit 0
#  fi
#done
#echo \"\"$USER\" has logged in from $SSH_CLIENT at `date +\"%Y/%m/%d %p %I:%M:%S\"` \" | mail -s \"$SERVISE_DOMAIN sshd login alert\" -r root@$SERVISE_DOMAIN $ADMIN_EMAIL
#EOF
#chmod 755 /usr/local/bin/ssh_alert.sh
#echo "/bin/bash /usr/local/bin/ssh_alert.sh" >> /etc/ssh/sshrc
