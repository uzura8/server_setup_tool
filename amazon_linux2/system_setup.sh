#system_setup.sh

### Add yum optional repository ###
mkdir /root/src/
cd /root/src/
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
wget http://mirror.fairway.ne.jp/dag/redhat/el7/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-7.rpm
rpm -Uvh rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm

cp /etc/yum.repos.d/epel.repo /tmp/epel.repo.${DATE}.$$
sed -e "s/^\(enabled\s*=\s*\)1/\10/g" /etc/yum.repos.d/epel.repo > /tmp/epel.repo.$$
mv /tmp/epel.repo.$$ /etc/yum.repos.d/epel.repo
echo_and_exec "grep enabled= /etc/yum.repos.d/epel.repo"
next
rm /tmp/epel.repo.${DATE}.$$

cp /etc/yum.repos.d/rpmforge.repo /tmp/rpmforge.repo.${DATE}.$$
sed -e "s/^\(enabled\s*=\s*\)1/\10/g" /etc/yum.repos.d/rpmforge.repo > /tmp/rpmforge.repo.$$
mv /tmp/rpmforge.repo.$$ /etc/yum.repos.d/rpmforge.repo
echo_and_exec "grep enabled= /etc/yum.repos.d/rpmforge.repo"
next
rm /tmp/rpmforge.repo.${DATE}.$$

### Setting yum update ###
yum update -y --enablerepo=rpmforge-extras git
yum -y update
yum -y install yum-cron
/etc/rc.d/init.d/yum-cron start
chkconfig yum-cron on

### install etckeeper ###
yum -y install etckeeper
touch /etc/.gitignore
echo "shadow*" >> /etc/.gitignore
echo "gshadow*" >> /etc/.gitignore
echo "passwd*" >> /etc/.gitignore
echo "group*" >> /etc/.gitignore
etckeeper init
etckeeper commit "First Commit"

### Setting logwatch ###
yum -y install logwatch
echo "MailTo = ${ADMIN_EMAIL}" >> /etc/logwatch/conf/logwatch.conf
echo_and_exec "tail -n1 /etc/logwatch/conf/logwatch.conf"
next

### Disabled SELinux ###
setenforce 0
echo_and_exec "getenforce"
next

### Iptables setting ###
/etc/rc.d/init.d/iptables stop
chkconfig iptables off
echo_and_exec "chkconfig --list iptables"
next

### denyhosts setting ###
yum -y --enablerepo=epel install denyhosts
echo "${ALLOW_IPS}" >> /var/lib/denyhosts/allowed-hosts
echo_and_exec "cat /var/lib/denyhosts/allowed-hosts"
next
/etc/init.d/denyhosts start
/sbin/chkconfig denyhosts on

#### date setting ###
ln -sf /usr/share/zoneinfo/Japan /etc/localtime

### postfix setting ###
#### stop sendmail
/etc/rc.d/init.d/sendmail stop
yum -y remove sendmail

#### install postfix
yum -y install postfix
chkconfig postfix on
echo_and_exec "chkconfig --list postfix"
next
/etc/init.d/postfix start

#### set admin email
sed -i '/^root:/d' /etc/aliases
echo "root: ${ADMIN_EMAIL}" >> /etc/aliases
echo_and_exec "cat /etc/aliases | grep root"
next
newaliases

### install sar ###
yum -y install sysstat

#### install newrelic ###
#rpm -Uvh http://download.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
#yum install -y newrelic-sysmond
#nrsysmond-config --set license_key=${NEWRELIC_LICENCE_KEY}
#/etc/init.d/newrelic-sysmond start

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

### set ssh login alert mail
mkdir -p /usr/local/bin/
cat > /usr/local/bin/ssh_alert.sh <<EOF
#!/bin/bash
SOURCE_IP=${SSH_CLIENT%% *}
for HOST in $ALLOW_IPS
do
  if [ $HOST == $SOURCE_IP ]; then
    exit 0
  fi
done
echo \"\"$USER\" has logged in from $SSH_CLIENT at `date +\"%Y/%m/%d %p %I:%M:%S\"` \" | mail -s \"$SERVISE_DOMAIN sshd login alert\" -r root@$SERVISE_DOMAIN $ADMIN_EMAIL
EOF
chmod 755 /usr/local/bin/ssh_alert.sh
echo "/bin/bash /usr/local/bin/ssh_alert.sh" >> /etc/ssh/sshrc
