#!/bin/sh

yum install -y python36-devel python36-libs python36-setuptools python36-pip
yum install -y httpd-devel
pip3 install mod_wsgi
MOD_WSGI_PATH=`find /usr/local/lib64/python3.6/ -type f -name "mod_wsgi*.so"`
cat >> /etc/httpd/conf.d/virtualhost.conf <<EOF

LoadModule wsgi_module ${MOD_WSGI_PATH}
<VirtualHost *:80>
  ServerName example.com
  DocumentRoot /var/www/sites/${SERVISE_DOMAIN}
  WSGIScriptAlias / /var/www/sites/${SERVISE_DOMAIN}/adapter.wsgi
  <Directory "/var/www/sites/${SERVISE_DOMAIN}/">
    Order deny,allow
    Allow from all
  </Directory>
</VirtualHost>

EOF
#systemctl httpd restart
