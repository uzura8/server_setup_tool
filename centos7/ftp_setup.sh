#ftp_setup.sh

yum install -y vsftpd
cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.ori
sed -e "s|^anonymous_enable=YES|anonymous_enable=NO|" /etc/vsftpd/vsftpd.conf > /tmp/vsftpd.conf.$$
sed -e "s|^#\(xferlog_file=/var/log/xferlog\)|\1|g" /tmp/vsftpd.conf.$$ > /tmp/vsftpd.conf.2.$$
sed -e "s|^ferlog_std_format=YES|ferlog_std_format=NO|" /tmp/vsftpd.conf.2.$$ > /tmp/vsftpd.conf.3.$$
sed -e "s|^#\(ascii_upload_enable=YES\)|\1|g" /tmp/vsftpd.conf.3.$$ > /tmp/vsftpd.conf.4.$$
sed -e "s|^#\(ascii_download_enable=YES\)|\1|g" /tmp/vsftpd.conf.4.$$ > /tmp/vsftpd.conf.5.$$
sed -e "s|^#\(ftpd_banner=Welcome to blah FTP service.\)|\1|g" /tmp/vsftpd.conf.5.$$ > /tmp/vsftpd.conf.6.$$
sed -e "s|^#\(chroot_list_file=/etc/vsftpd/chroot_list\)|\1|g" /tmp/vsftpd.conf.6.$$ > /tmp/vsftpd.conf.7.$$
sed -e "s|^#\(ls_recurse_enable=YES\)|\1|g" /tmp/vsftpd.conf.7.$$ > /tmp/vsftpd.conf.8.$$
sed -e "s|^listen=NO|listen=YES|g" /tmp/vsftpd.conf.8.$$ > /tmp/vsftpd.conf.9.$$
sed -e "s|^\(listen_ipv6=YES\)|#\1|g" /tmp/vsftpd.conf.9.$$ > /tmp/vsftpd.conf.10.$$
sed -e "s|^local_umask=022|local_umask=002|g" /tmp/vsftpd.conf.10.$$ > /tmp/vsftpd.conf.11.$$
sed -e "s|^dirmessage_enable=YES|dirmessage_enable=NO|" /tmp/vsftpd.conf.11.$$ > /tmp/vsftpd.conf.12.$$
sed -e "s|^connect_from_port_20=YES|connect_from_port_20=NO|" /tmp/vsftpd.conf.12.$$ > /tmp/vsftpd.conf.13.$$
sed -e "s|^xferlog_std_format=YES|xferlog_std_format=NO|" /tmp/vsftpd.conf.13.$$ > /tmp/vsftpd.conf.14.$$
sed -e "s|^listen=NO|listen=YES|" /tmp/vsftpd.conf.14.$$ > /tmp/vsftpd.conf.15.$$
sed -e "s|^tcp_wrappers=YES|tcp_wrappers=NO|" /tmp/vsftpd.conf.15.$$ > /tmp/vsftpd.conf.16.$$
cat >> /tmp/vsftpd.conf.16.$$ <<EOF

# additional setting
use_localtime=YES
user_config_dir=/etc/vsftpd/vsftpd_user_conf
force_dot_files=YES
EOF

mv /tmp/vsftpd.conf.16.$$ /etc/vsftpd/vsftpd.conf

### add ftp user
sudo useradd ftp_admin
sudo passwd ftp_admin
sudo gpasswd -a ftp_admin webadmin

mkdir /etc/vsftpd/vsftpd_user_conf
cat > /etc/vsftpd/vsftpd_user_conf/ftp_admin <<EOF
local_root=/var/www/sites/${SERVISE_DOMAIN}
EOF

systemctl start vsftpd
systemctl enable vsftpd
systemctl status vsftpd

rm -f /tmp/vsftpd.conf.2.$$
rm -f /tmp/vsftpd.conf.3.$$
rm -f /tmp/vsftpd.conf.4.$$
rm -f /tmp/vsftpd.conf.5.$$
rm -f /tmp/vsftpd.conf.6.$$
rm -f /tmp/vsftpd.conf.7.$$
rm -f /tmp/vsftpd.conf.8.$$
rm -f /tmp/vsftpd.conf.9.$$
rm -f /tmp/vsftpd.conf.10.$$
rm -f /tmp/vsftpd.conf.11.$$
rm -f /tmp/vsftpd.conf.12.$$
rm -f /tmp/vsftpd.conf.13.$$
rm -f /tmp/vsftpd.conf.14.$$
rm -f /tmp/vsftpd.conf.15.$$

### iptables setting
iptables -A INPUT -p tcp -m tcp --dport 20 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 21 -j ACCEPT
systemctl restart iptables

### access allow/deny
echo "vsftpd: ALL" >> /etc/hosts.deny
echo "vsftpd: 127.0.0.1" >> /etc/hosts.allow
for ALLOW_IP in $ALLOW_IPS
do
	echo "vsftpd: ${ALLOW_IP}" >> /etc/hosts.allow
done
