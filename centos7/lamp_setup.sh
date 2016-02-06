#lamp_setup.sh
cp /etc/yum.repos.d/CentOS-Base.repo /tmp/CentOS-Base.repo.${DATE}.$$
sed -e "s/^\(priority=1\)/\1\nexclude=php*" /etc/yum.repos.d/CentOS-Base.repo > /tmp/CentOS-Base.repo.$$
mv /tmp/CentOS-Base.repo.$$ /etc/yum.repos.d/CentOS-Base.repo
echo_and_exec "cat /etc/yum.repos.d/CentOS-Base.repo | grep -A2 priority=1"
next
rm /tmp/CentOS-Base.repo.${DATE}.$$

###  install LAMP packages ###
yum install -y ImageMagick ImageMagick-devel
yum install -y --enablerepo=epel libmcrypt libtidy
yum install --enablerepo=remi gd-last
yum install -y httpd httpd-devel
yum -y remove mariadb-libs
rm -rf /var/lib/mysql/
#yum -y install perl-Data-Dumper
yum install -y http://repo.mysql.com/mysql-community-release-el7-7.noarch.rpm
#yum -y install mysql-community-server
yum install -y mysql mysql-server mysql-devel mysql-utilities
yum install -y --enablerepo=remi,remi-php56 php php-devel php-pear php-gd php-mbstring php-xml php-mcrypt php-opcache php-pecl-apcu php-fpm php-phpunit-PHPUnit php-mysqlnd php-pdo
pecl install imagick

### Add webadmin group ###
groupadd webadmin
gpasswd -a ${ADMIN_USER} webadmin
gpasswd -a apache webadmin

### Create Web directries ###
echo "umask 002" > /etc/profile.d/umask.sh
mkdir -p /var/www/sites
chown ${ADMIN_USER} /var/www/sites /var/www/html
chgrp webadmin /var/www/sites /var/www/html
chmod 775 /var/www/sites /var/www/html
chmod g+w /var/www/sites /var/www/html
ls -ald /var/www/sites
next

### Apache setting ###
#### delete apache test pages
rm -f /etc/httpd/conf.d/welcome.conf
rm -f /var/www/error/noindex.html

#### Edit httpd.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.ori


sed -e "s/^#ServerName www.example.com:80/ServerName ${SERVISE_DOMAIN}:80/" /etc/httpd/conf/httpd.conf > /tmp/httpd.conf.$$
sed -e "s/^ServerSignature On/ServerSignature Off/g" /tmp/httpd.conf.$$ > /tmp/httpd.conf.2.$$
sed -e "s/^\(AddDefaultCharset UTF-8\)/#\1/g" /tmp/httpd.conf.2.$$ > /tmp/httpd.conf.3.$$
sed -e "s/^\(LoadModule .\+\)$/#\1/" /tmp/httpd.conf.3.$$ > /tmp/httpd.conf.4.$$
sed -e "s/^\(LogFormat .\+\)$/#\1/" /tmp/httpd.conf.4.$$ > /tmp/httpd.conf.5.$$
sed -e "s/^\(CustomLog .\+\)$/#\1/" /tmp/httpd.conf.5.$$ > /tmp/httpd.conf.6.$$
cat >> /tmp/httpd.conf.6.$$ <<EOF

ServerSignature Off

LogFormat "%V %h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%V %h %l %u %t \"%!414r\" %>s %b %D" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

# No log from worm access
SetEnvIf Request_URI "default\.ida" no_log
SetEnvIf Request_URI "cmd\.exe" no_log
SetEnvIf Request_URI "root\.exe" no_log
SetEnvIf Request_URI "Admin\.dll" no_log
SetEnvIf Request_URI "NULL\.IDA" no_log
# No log from intarnal access
SetEnvIf Remote_Addr 127.0.0.1 no_log
# Log other access
CustomLog logs/access_log combined env=!no_log

<DirectoryMatch ~ "/\.(svn|git)/">
    Deny from All
</DirectoryMatch>
<Files ~ "^\.git">
    Deny from All
</Files>

EOF

mv /tmp/httpd.conf.6.$$ /etc/httpd/conf/httpd.conf

#### vertual host setting
cat > /etc/httpd/conf.d/virtualhost.conf <<EOF
NameVirtualHost *:80

<VirtualHost *:80>
  VirtualDocumentRoot /var/www/sites/%0/public
</VirtualHost>

<Directory "/var/www/sites">
  AllowOverride All
</Directory>
EOF

echo_and_exec "service httpd configtest"
next
rm -f /tmp/httpd.conf.$$
rm -f /tmp/httpd.conf.2.$$
rm -f /tmp/httpd.conf.3.$$
rm -f /tmp/httpd.conf.4.$$
rm -f /tmp/httpd.conf.5.$$


### PHP setting ###
cat > /etc/php.d/my.ini <<EOF
extension=imagick.so

short_open_tag = Off
expose_php = Off
memory_limit = 128M
post_max_size = 20M
upload_max_filesize = 20M
max_execution_time = 300
date.timezone = Asia/Tokyo

[mbstring]
mbstring.language = Japanese
mbstring.internal_encoding = utf-8

EOF
echo_and_exec "cat /etc/php.d/my.ini"
next

### start http ###
systemctl start httpd
systemctl enable httpd
echo_and_exec "systemctl is-enabled httpd"
next

### MySQL setting ###
mkdir /var/log/mysql
chown mysql. /var/log/mysql
chmod 775 /var/log/mysql

cp /etc/my.cnf /etc/my.cnf.ori
sed -e "s/^\(\[mysqld_safe\]\)/character-set-server=utf8\nmax_allowed_packet=128MB\nlog-bin=mysql-bin\nexpire_logs_days=3\nslow_query_log=ON\nslow_query_log_file=\/var\/log\/mysql\/slow_query.log\nlong_query_time=1\n\n\1/" /etc/my.cnf > /tmp/my.cnf.$$
cat >> /tmp/my.cnf.$$ <<EOF

[client]
default-character-set=utf8

[mysql]
default-character-set=utf8

[mysqldump]
default-character-set=utf8
EOF
cat /tmp/my.cnf.$$
next
mv /tmp/my.cnf.$$ /etc/my.cnf

### start lamp ###
mysql_secure_installation
systemctl enable mysqld.service
echo_and_exec "systemctl is-enabled mysqld.service"
next

### Log rotate setting ###
#### httpd log
cp /etc/logrotate.d/httpd /etc/logrotate.d/httpd.ori
sed -e "s/^\(\s\+\)\(missingok\)/\1daily\n\1dateext\n\1rotate 16\n\1\2/" /etc/logrotate.d/httpd > /tmp/logrotate.d.httpd.$$
cat /tmp/logrotate.d.httpd.$$
next
mv /tmp/logrotate.d.httpd.$$ /etc/logrotate.d/httpd

#### mysql log
cat > /root/.my.cnf <<EOF
[mysqladmin]
password=${MYSQL_ROOT_PASS}
user=root

[mysqldump]
password=${MYSQL_ROOT_PASS}
user=root
EOF

sudo chmod 600 /root/.my.cnf

cat >> /etc/logrotate.d/mysqld <<EOF
/var/log/mysql/slow_query.log {
    create 640 mysql mysql
    notifempty
    rotate 16
    minsize 1M
    missingok
    compress
    sharedscripts
    delaycompress
    postrotate
        /usr/bin/mysqladmin --defaults-extra-file=/root/.my.cnf flush-logs
    endscript
}
EOF
cat /etc/logrotate.d/mysqld
next
