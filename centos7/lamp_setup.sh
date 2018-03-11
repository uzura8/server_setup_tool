#lamp_setup.sh

###  install LAMP packages ###
yum install -y --enablerepo=remi ImageMagick ImageMagick-devel
yum install -y --enablerepo=epel libmcrypt libtidy
yum install --enablerepo=remi gd-last
yum install -y httpd httpd-devel
yum -y remove mariadb-libs
rm -rf /var/lib/mysql/
#yum -y install perl-Data-Dumper
yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
yum install -y mysql mysql-server mysql-devel mysql-utilities
yum install -y --enablerepo=remi,remi-php71 php php-cli php-common php-devel php-pear php-gd php-mbstring php-xml php-mcrypt php-opcache php-pecl-apcu php-fpm php-phpunit-PHPUnit php-mysqlnd php-mysql php-pdo php-gmp
pecl install imagick

### Add webadmin group ###
groupadd webadmin
gpasswd -a ${ADMIN_USER} webadmin
gpasswd -a apache webadmin

### Create Web directries ###
echo "umask 002" > /etc/profile.d/umask.sh
mkdir -p /var/www/sites
chown ${ADMIN_USER} /var/www/sites
chgrp webadmin /var/www/sites
chmod -R 775 /var/www/sites
chmod -R g+w /var/www/sites
chmod -R g+s /var/www/sites
ls -ald /var/www/sites
next

### Apache setting ###
#### delete apache test pages
rm -f /etc/httpd/conf.d/welcome.conf
rm -f /var/www/error/noindex.html

#### Edit httpd.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.ori

sed -e "s|^#ServerName www.example.com:80|ServerName ${SERVISE_DOMAIN}:80|" /etc/httpd/conf/httpd.conf > /tmp/httpd.conf.$$
sed -e "s|^\(AddDefaultCharset UTF-8\)|#\1|g" /tmp/httpd.conf.$$ > /tmp/httpd.conf.2.$$
sed -e "s|^\(\s\+\)\(CustomLog .\+\)$|\1#\2|" /tmp/httpd.conf.2.$$ > /tmp/httpd.conf.3.$$
cat >> /tmp/httpd.conf.3.$$ <<EOF

ServerSignature Off
ServerTokens Prod

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
  Require all denied
</DirectoryMatch>
<Files ~ "^\.git">
  Require all denied
</Files>

EOF

mv /tmp/httpd.conf.3.$$ /etc/httpd/conf/httpd.conf

#### vertual host setting
cat > /etc/httpd/conf.d/virtualhost.conf <<EOF

<VirtualHost *:80>
  ServerName localhost
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
cp /etc/my.cnf /tmp/my.cnf.$$
cat >> /tmp/my.cnf.$$ <<EOF

### Additional setting
character-set-server=utf8
default_password_lifetime=0
log-timestamps=system
lower_case_table_names=1
max_allowed_packet=128MB
explicit_defaults_for_timestamp=TRUE
server-id=1
log-bin=mysql-bin
expire_logs_days=3
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow_query.log
long_query_time=1.0
EOF
cat /tmp/my.cnf.$$
next
mv /tmp/my.cnf.$$ /etc/my.cnf

### start mysql ###
service mysqld start
cat /var/log/mysqld.log | grep 'password is generated'
mysql_secure_installation
systemctl enable mysqld.service
echo_and_exec "systemctl is-enabled mysqld.service"
next

### Log rotate setting ###
#### httpd log
cp /etc/logrotate.d/httpd $DATA_DIR/backups/httpd.ori
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
