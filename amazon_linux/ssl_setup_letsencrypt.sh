curl https://dl.eff.org/certbot-auto -o /usr/bin/certbot-auto
chmod 700 /usr/bin/certbot-auto
certbot-auto certonly --webroot -w /var/www/sites/${SERVISE_DOMAIN}/public -d $SERVISE_DOMAIN --email $ADMIN_EMAIL -n --agree-tos --debug

### mod_ssl setting ###
yum -y install mod24_ssl
cat >> /etc/httpd/conf.d/virtualhost.conf <<EOF
<VirtualHost *:443>
  SSLEngine on
  ServerName ${SERVISE_DOMAIN}
  DocumentRoot /var/www/sites/${SERVISE_DOMAIN}/public/
  SSLCertificateFile /etc/letsencrypt/live/${SERVISE_DOMAIN}/cert.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/${SERVISE_DOMAIN}/privkey.pem
  SSLCertificateChainFile /etc/letsencrypt/live/${SERVISE_DOMAIN}/chain.pem
</VirtualHost>
EOF

echo_and_exec "cat /etc/httpd/conf.d/ssl.conf"
echo_and_exec "cat /etc/httpd/conf.d/virtualhost.conf"
echo_and_exec "httpd -t"
next
service httpd graceful

#### add for etckeeper commit script
mkdir /root/bin/
cat >> /root/bin/letsencrypt_etckeeper_commit.sh <<EOF
#!/bin/sh
cd /etc/
git ci -m 'updated letsencrypt' .etckeeper ./letsencrypt
EOF
chmod 755 /root/bin/letsencrypt_etckeeper_commit.sh

#### add update ssl script to cron
echo "00 04 01 * * /usr/bin/certbot-auto renew --force-renew && /sbin/service httpd graceful &&  && /root/bin/letsencrypt_etckeeper_commit.sh" >> /etc/crontab
next
