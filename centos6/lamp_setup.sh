#lamp_setup.sh

###  install LAMP packages ###
yum install -y ImageMagick ImageMagick-devel
yum install -y --enablerepo=epel ack libmcrypt
yum install -y --enablerepo=remi --enablerepo=remi-php56 httpd mysql-server memcached php php-devel gd-last php-gd php-opcache php-mbstring php-mcrypt php-mysqlnd php-ncurses php-pdo php-xml php-pear php-memcache php-pecl-memcached
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
chmod g+s /var/www/sites /var/www/html
ls -ald /var/www/sites
next

### Apache setting ###
#### delete apache test pages
rm -f /etc/httpd/conf.d/welcome.conf
rm -f /var/www/error/noindex.html

#### Edit httpd.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.ori
sed -e "s/^ServerTokens OS/ServerTokens Prod/" /etc/httpd/conf/httpd.conf > /tmp/httpd.conf.$$
sed -e "s/^ServerSignature On/ServerSignature Off/g" /tmp/httpd.conf.$$ > /tmp/httpd.conf.2.$$
sed -e "s/^\(AddDefaultCharset UTF-8\)/#\1/g" /tmp/httpd.conf.2.$$ > /tmp/httpd.conf.3.$$
sed -e "s/^\(LoadModule .\+\)$/#\1/" /tmp/httpd.conf.3.$$ > /tmp/httpd.conf.4.$$
sed -e "s/^\(LogFormat .\+\)$/#\1/" /tmp/httpd.conf.4.$$ > /tmp/httpd.conf.5.$$
sed -e "s/^\(CustomLog .\+\)$/#\1/" /tmp/httpd.conf.5.$$ > /tmp/httpd.conf.6.$$
cat >> /tmp/httpd.conf.6.$$ <<EOF

ServerName ${SERVISE_DOMAIN}:80

LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule auth_digest_module modules/mod_auth_digest.so
LoadModule authn_file_module modules/mod_authn_file.so
LoadModule authn_alias_module modules/mod_authn_alias.so
LoadModule authn_anon_module modules/mod_authn_anon.so
LoadModule authn_dbm_module modules/mod_authn_dbm.so
LoadModule authn_default_module modules/mod_authn_default.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_user_module modules/mod_authz_user.so
LoadModule authz_owner_module modules/mod_authz_owner.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_dbm_module modules/mod_authz_dbm.so
LoadModule authz_default_module modules/mod_authz_default.so
LoadModule include_module modules/mod_include.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule logio_module modules/mod_logio.so
LoadModule env_module modules/mod_env.so
LoadModule ext_filter_module modules/mod_ext_filter.so
LoadModule mime_magic_module modules/mod_mime_magic.so
LoadModule expires_module modules/mod_expires.so
LoadModule deflate_module modules/mod_deflate.so
LoadModule headers_module modules/mod_headers.so
LoadModule usertrack_module modules/mod_usertrack.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule mime_module modules/mod_mime.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
LoadModule info_module modules/mod_info.so
LoadModule vhost_alias_module modules/mod_vhost_alias.so
LoadModule negotiation_module modules/mod_negotiation.so
LoadModule dir_module modules/mod_dir.so
LoadModule actions_module modules/mod_actions.so
LoadModule speling_module modules/mod_speling.so
LoadModule userdir_module modules/mod_userdir.so
LoadModule alias_module modules/mod_alias.so
LoadModule substitute_module modules/mod_substitute.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule cache_module modules/mod_cache.so
LoadModule suexec_module modules/mod_suexec.so
LoadModule disk_cache_module modules/mod_disk_cache.so
LoadModule cgi_module modules/mod_cgi.so
LoadModule version_module modules/mod_version.so

LogFormat "%V %h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%V %h %l %u %t \"%r\" %>s %b %D" common
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
  ServerName localhost
  VirtualDocumentRoot /var/www/sites/%0/public
</VirtualHost>

<Directory "/var/www/sites">
  AllowOverride All
</Directory>
EOF

echo_and_exec "/etc/init.d/httpd configtest"
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
;mbstring.language = Japanese
;mbstring.internal_encoding = utf-8
EOF
echo_and_exec "cat /etc/php.d/my.ini"
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

[mysqldump]
default-character-set=utf8
EOF
cat /tmp/my.cnf.$$
next
mv /tmp/my.cnf.$$ /etc/my.cnf

### start lamp ###
chkconfig httpd on
chkconfig mysqld on
/etc/init.d/mysqld start
/etc/init.d/httpd start
mysql_secure_installation


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
