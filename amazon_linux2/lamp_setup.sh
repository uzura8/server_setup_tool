#lamp_setup.sh

amazon-linux-extras enable php7.2
#amazon-linux-extras install php7.2

###  install LAMP packages ###
yum install -y ImageMagick ImageMagick-devel
yum install -y ack libmcrypt
yum install -y httpd httpd-devel zlib-devel
yum install -y php php-mysqlnd php-devel php-gd php-opcache php-mbstring php-pdo php-pear php-pecl-imagick

# Add webadmin group ###
groupadd webadmin
gpasswd -a ${ADMIN_USER} webadmin
gpasswd -a apache webadmin

### Create Web directries ###
echo "umask 002" > /etc/profile.d/umask.sh
mkdir -p /var/www/sites
chown ${ADMIN_USER} /var/www/sites /var/www/html
chgrp webadmin /var/www/sites /var/www/html
chmod 775 /var/www/sites /var/www/html
chmod g+s /var/www/sites /var/www/html
ls -ald /var/www/sites
next

### Apache setting ###
#### delete apache test pages
rm -f /etc/httpd/conf.d/welcome.conf
rm -f /var/www/error/noindex.html

#### Edit httpd.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.ori

sed -e "s/^#ServerName www.example.com:80/ServerName ${SERVISE_DOMAIN}:80/" /etc/httpd/conf/httpd.conf > /tmp/httpd.conf.$$
sed -e "s/^\(AddDefaultCharset UTF-8\)/#\1/g" /tmp/httpd.conf.$$ > /tmp/httpd.conf.2.$$
sed -e "s/^\(\s\+\)\(CustomLog .\+\)$/\1#\2/" /tmp/httpd.conf.2.$$ > /tmp/httpd.conf.3.$$
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
error_reporting = E_ALL & ~E_NOTICE
error_log = "/var/log/php/php_errors.log" 
[mbstring]
mbstring.language = Japanese
mbstring.internal_encoding = utf-8
EOF
echo_and_exec "cat /etc/php.d/my.ini"
next

### start httpd ###
systemctl start httpd
systemctl enable httpd

### Log rotate setting ###
#### httpd log
cp /etc/logrotate.d/httpd $DATA_DIR/backups/httpd.ori
sed -e "s/^\(\s\+\)\(missingok\)/\1daily\n\1dateext\n\1rotate 16\n\1\2/" /etc/logrotate.d/httpd > /tmp/logrotate.d.httpd.$$
cat /tmp/logrotate.d.httpd.$$
next
mv /tmp/logrotate.d.httpd.$$ /etc/logrotate.d/httpd

## Remove comment out here, if install mysql on web server 
#yum install -y mysql55-server mysql55

## Remove comment out here, if install mysql on web server 
#### MySQL setting ###
#mkdir /var/log/mysql
#chown mysql. /var/log/mysql
#chmod 775 /var/log/mysql
#
#cp /etc/my.cnf /etc/my.cnf.ori
#sed -e "s/^\(\[mysqld_safe\]\)/character-set-server=utf8\nmax_allowed_packet=128MB\nlog-bin=mysql-bin\nexpire_logs_days=3\nslow_query_log=ON\nslow_query_log_file=\/var\/log\/mysql\/slow_query.log\nlong_query_time=1\n\n\1/" /etc/my.cnf > /tmp/my.cnf.$$
#cat >> /tmp/my.cnf.$$ <<EOF
#
#[client]
#default-character-set=utf8
#
#[mysqldump]
#default-character-set=utf8
#EOF
#cat /tmp/my.cnf.$$
#next
#mv /tmp/my.cnf.$$ /etc/my.cnf

##### mysql log
#cat > /root/.my.cnf <<EOF
#[mysqladmin]
#password=${MYSQL_ROOT_PASS}
#user=root
#
#[mysqldump]
#password=${MYSQL_ROOT_PASS}
#user=root
#EOF

#chkconfig mysqld on
#/etc/init.d/mysqld start
#mysql_secure_installation

#sudo chmod 600 /root/.my.cnf
#
#cat >> /etc/logrotate.d/mysqld <<EOF
#/var/log/mysql/slow_query.log {
#    create 640 mysql mysql
#    notifempty
#    rotate 16
#    minsize 1M
#    missingok
#    compress
#    sharedscripts
#    delaycompress
#    postrotate
#        /usr/bin/mysqladmin --defaults-extra-file=/root/.my.cnf flush-logs
#    endscript
#}
#EOF
#cat /etc/logrotate.d/mysqld
#next
