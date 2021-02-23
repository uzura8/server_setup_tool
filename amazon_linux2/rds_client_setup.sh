#lamp_setup.sh

yum localinstall https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm -y
yum-config-manager --disable mysql80-community
yum-config-manager --enable mysql57-community
yum install -y  mysql-community-client.x86_64
