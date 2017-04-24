#system_setup.sh

### Add yum optional repository ###
rpm -ivh http://ftp.riken.jp/Linux/fedora/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
cp /etc/yum.repos.d/epel.repo /tmp/epel.repo.${DATE}.$$
sed -e "s/^\(enabled\s*=\s*\)1/\10/g" /etc/yum.repos.d/epel.repo > /tmp/epel.repo.$$
mv /tmp/epel.repo.$$ /etc/yum.repos.d/epel.repo
echo_and_exec "grep enabled= /etc/yum.repos.d/epel.repo"
next
rm /tmp/epel.repo.${DATE}.$$
yum --enablerepo=epel -y update epel-release

#cp /etc/yum.repos.d/rpmforge.repo /tmp/rpmforge.repo.${DATE}.$$
#sed -e "s/^\(enabled\s*=\s*\)1/\10/g" /etc/yum.repos.d/rpmforge.repo > /tmp/rpmforge.repo.$$
#mv /tmp/rpmforge.repo.$$ /etc/yum.repos.d/rpmforge.repo
#echo_and_exec "grep enabled= /etc/yum.repos.d/rpmforge.repo"
#next
#rm /tmp/rpmforge.repo.${DATE}.$$

rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum --enablerepo=epel -y update remi-release

#### Setting yum update ###
#yum update -y --enablerepo=rpmforge-extras git
yum -y update
yum -y install yum-cron
/etc/rc.d/init.d/yum-cron start
chkconfig yum-cron on

### screen install
yum install -y screen

### nkf install
yum localinstall -y http://mirror.centos.org/centos/6/os/x86_64/Packages/nkf-2.0.8b-6.2.el6.x86_64.rpm

### Setting logwatch ###
yum -y install logwatch
echo "MailTo = ${ADMIN_EMAIL}" >> /etc/logwatch/conf/logwatch.conf
echo_and_exec "tail -n1 /etc/logwatch/conf/logwatch.conf"
next

### Disabled SELinux ###
setenforce 0
echo_and_exec "getenforce"
next

cp /etc/sysconfig/selinux /tmp/selinux.${DATE}.$$
sed -e "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux > /tmp/selinux.$$
mv /tmp/selinux.$$ /etc/sysconfig/selinux
echo_and_exec "grep SELINUX= /etc/sysconfig/selinux"
next
rm /tmp/selinux.${DATE}.$$

### Iptables install & setting ###
systemctl stop firewalld.service
systemctl mask firewalld.service
echo_and_exec "systemctl list-unit-files | grep firewalld"
next

yum -y install iptables-services
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

iptables -A INPUT -s 10.0.0.0/8 -j DROP
iptables -A INPUT -d 10.0.0.0/8 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -j DROP
iptables -A INPUT -d 172.16.0.0/12 -j DROP
iptables -A INPUT -s 192.168.0.0/16 -j DROP
iptables -A INPUT -d 192.168.0.0/16 -j DROP

iptables -A INPUT -d 0.0.0.0/8 -j DROP
iptables -A INPUT -d 255.255.255.255 -j DROP

iptables -A INPUT -f -j DROP

iptables -A INPUT -p tcp -m state --state NEW ! --syn -j DROP

iptables -A INPUT -p tcp --dport 113 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p icmp --icmp-type echo-request -m hashlimit --hashlimit 1/s --hashlimit-burst 5 --hashlimit-mode srcip --hashlimit-name input_icmp  --hashlimit-htable-expire 300000 -j DROP

iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

iptables -P INPUT   DROP
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD DROP

#### check setting
iptables -L --line-numbers -n
next
systemctl save iptables.service
systemctl restart iptables.service
systemctl enable iptables

### denyhosts setting ###
yum -y --enablerepo=epel install denyhosts
yum -y install rsyslog
systemctl start rsyslog
systemctl enable rsyslog
echo "${ALLOW_IPS}" >> /var/lib/denyhosts/allowed-hosts
echo_and_exec "cat /var/lib/denyhosts/allowed-hosts"
next
systemctl start denyhosts
systemctl enable denyhosts

#### ntp setting ###
## TODO: add ntp setup

### postfix setting ###
#### stop sendmail
/etc/rc.d/init.d/sendmail stop
yum -y remove sendmail

#### install postfix
yum -y install postfix
systemctl start postfix
systemctl enable postfix

#### set admin email
sed -i '/^root:/d' /etc/aliases
echo "root: ${ADMIN_EMAIL}" >> /etc/aliases
echo_and_exec "cat /etc/aliases | grep root"
next
newaliases

### install sar ###
yum -y install sysstat

### install newrelic ###
rpm -Uvh http://download.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
yum install -y newrelic-sysmond
nrsysmond-config --set license_key=${NEWRELIC_LICENCE_KEY}
/etc/init.d/newrelic-sysmond start

### git setting
cat > /home/${ADMIN_USER}/.gitconfig <<EOF
[color]
  diff = auto
  status = auto
  branch = auto
  interactive = auto
EOF
echo "${GIT_USER_CONF}" >> /home/${ADMIN_USER}/.gitconfig
chown ${ADMIN_USER}. /home/${ADMIN_USER}/.gitconfig
cp /home/${ADMIN_USER}/.gitconfig /root/
