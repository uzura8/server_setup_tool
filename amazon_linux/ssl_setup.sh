# ssl_setup.sh
SSL_KEY_FILENAME="${SERVISE_DOMAIN}.key_${DATEYEAR}"

### Generate CSR ###
mkdir -p /etc/pki/tls/csr
cd /etc/pki/tls
openssl genrsa -des3 -out ./private/${SSL_KEY_FILENAME} 2048
openssl req -new -key ./private/${SSL_KEY_FILENAME} -out ./csr/${SERVISE_DOMAIN}.csr_${DATEYEAR}

cp ./private/${SSL_KEY_FILENAME} ./private/${SSL_KEY_FILENAME}.ori
openssl rsa -in ./private/${SSL_KEY_FILENAME} -out ./private/${SSL_KEY_FILENAME}
chmod 600 ./private/${SSL_KEY_FILENAME}

### set crt ###
echo "${SSL_CRT}" > /etc/pki/tls/certs/${SERVISE_DOMAIN}.crt_${DATEYEAR}
echo "${SSL_CA_CRT}" > etc/pki/tls/certs/ca.crt_${DATEYEAR}

### set original crt (for test env) ###
#openssl x509 -req -days 3650 -in /etc/pki/tls/csr/${SERVISE_DOMAIN}.csr_${DATEYEAR} -signkey /etc/pki/tls/private/${SSL_KEY_FILENAME} -out /etc/pki/tls/certs/${SERVISE_DOMAIN}.crt_${DATEYEAR}

chmod 600 /etc/pki/tls/certs/${SERVISE_DOMAIN}.crt_${DATEYEAR}

### mod_ssl setting ###
yum -y install mod24_ssl

### edit ssl.conf ###
#mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.ori
#
#cat > /etc/httpd/conf.d/ssl.conf <<EOF
#Listen 443
#SSLPassPhraseDialog  builtin
#SSLSessionCache         shmcb:/var/cache/mod_ssl/scache(512000)
#SSLSessionCacheTimeout  300
#SSLRandomSeed startup file:/dev/urandom  256
#SSLRandomSeed connect builtin
#SSLCryptoDevice builtin
#
#LogFormat "%V %h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"" combined
#LogFormat "%V %h %l %u %t \"%!414r\" %>s %b %D" common
#LogFormat "%{Referer}i -> %U" referer
#LogFormat "%{User-agent}i" agent
## No log from worm access
#SetEnvIf Request_URI "default\.ida" no_log
#SetEnvIf Request_URI "cmd\.exe" no_log
#SetEnvIf Request_URI "root\.exe" no_log
#SetEnvIf Request_URI "Admin\.dll" no_log
#SetEnvIf Request_URI "NULL\.IDA" no_log
## No log from intarnal access
##SetEnvIf Remote_Addr 127.0.0.1 no_log
## Log other access
#CustomLog logs/ssl_access_log combined env=!no_log
#EOF

cat >> /etc/httpd/conf.d/virtualhost.conf <<EOF

<VirtualHost *:443>
  SSLEngine on
  ServerName ${SERVISE_DOMAIN}
  DocumentRoot /var/www/sites/${SERVISE_DOMAIN}/public/
  SSLCertificateFile /etc/pki/tls/certs/${SERVISE_DOMAIN}.crt_${DATEYEAR}
  SSLCertificateKeyFile /etc/pki/tls/private/${SERVISE_DOMAIN}.key_${DATEYEAR}
  SSLCertificateChainFile /etc/pki/tls/certs/ca.crt_${DATEYEAR}
  #SSLCACertificateFile /etc/pki/tls/certs/ca.pem
</VirtualHost>
EOF

echo_and_exec "cat /etc/httpd/conf.d/ssl.conf"
echo_and_exec "cat /etc/httpd/conf.d/virtualhost.conf"
echo_and_exec "httpd -t"
next
service httpd restart
