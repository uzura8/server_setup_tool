#flockbird_setup.sh

### setup rsa for git ###
mkdir /home/${ADMIN_USER}/.ssh
echo "${SSH_ID_RSA_PUB}" > /home/${ADMIN_USER}/.ssh/id_rsa.pub
echo "${SSH_ID_RSA}" > /home/${ADMIN_USER}/.ssh/id_rsa

chown -R ${ADMIN_USER}. /home/${ADMIN_USER}/.ssh
chmod 700 /home/${ADMIN_USER}/.ssh
chmod 600 /home/${ADMIN_USER}/.ssh/id_rsa
echo_and_exec "ls -al /home/${ADMIN_USER}/.ssh"
next

mkdir /root/.ssh/
cp /home/${ADMIN_USER}/.ssh/id_rsa /root/.ssh/
cp /home/${ADMIN_USER}/.ssh/id_rsa.pub /root/.ssh/
chown root. /root/.ssh/*

### DB buckup ###
mkdir -p /home/${ADMIN_USER}/backup/mysql
cd /home/${ADMIN_USER}/backup/mysql
git clone https://github.com/uzura8/db_daily_backup.git
cd db_daily_backup/
chmod u+x backup.sh
cp setting.conf.sample setting.conf
chown -R ${ADMIN_USER}. /home/${ADMIN_USER}/backup
sed -e "s/sampl_db_name/${APP_DB_NAME}/" setting.conf > /tmp/setting.conf.$$
mv /tmp/setting.conf.$$ setting.conf
echo_and_exec "grep DB_LIST setting.conf"
next

#### add cron
echo "0 5 * * * root /home/${ADMIN_USER}/backup/mysql/db_daily_backup/backup.sh" > /etc/cron.d/flockbird
echo_and_exec "cat /etc/cron.d/flockbird"
next

### setup flockbird ###
cd /var/www/sites/
git clone ${APP_GIT_URL} ${SERVISE_DOMAIN}
cd ${SERVISE_DOMAIN}
sed -e "s/^\(\s\+'dsn'\s\+=>\s\+\)'mysql.\+',/\1'mysql:host=localhost;dbname=${APP_DB_NAME}',/" config.php.sample > /tmp/config.php.$$
sed -e "s/^\(\s\+'username'\s\+=>\s\+\)'.*',/\1'${MYSQL_USER_NAME}',/" /tmp/config.php.$$ > /tmp/config.php.2.$$
sed -e "s/^\(\s\+'password'\s\+=>\s\+\)'.*',/\1'${MYSQL_USER_PASS}',/" /tmp/config.php.2.$$ > /tmp/config.php.3.$$
sed -e "s/put_some_key_for_encryption_in_here/${APP_FBD_ENCRYPTION_KEY}/" /tmp/config.php.3.$$ > /tmp/config.php.4.$$
diff -u config.php.sample /tmp/config.php.4.$$
next
mv /tmp/config.php.4.$$ config.php
rm -f /tmp/config.php.$$
rm -f /tmp/config.php.2.$$
rm -f /tmp/config.php.3.$$
rm -f /tmp/config.php.4.$$

sh bin/setup/setup.sh
chown -R ${ADMIN_USER}:webadmin /var/www/sites/${SERVISE_DOMAIN}
echo_and_exec "ls -al /var/www/sites/${SERVISE_DOMAIN}"
next

rm -f /root/.ssh/id_rsa
rm -f /root/.ssh/id_rsa.pub
