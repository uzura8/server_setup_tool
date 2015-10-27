# ssl_setup.sh
SSL_KEY_FILENAME="${SERVISE_DOMAIN}.key_${DATEYEAR}"

### Generate CSR ###
mkdir -p /etc/pki/tls/csr
cd /etc/pki/tls
openssl genrsa -des3 -out ./private/${SSL_KEY_FILENAME} 2048
openssl req -new -key ./private/${SSL_KEY_FILENAME} -out ./csr/${SERVISE_DOMAIN}.csr_${DATEYEAR}

cp ./private/${SSL_KEY_FILENAME} ./private/${SSL_KEY_FILENAME}.ori
openssl rsa -in ./private/${SSL_KEY_FILENAME} -out ./private/${SSL_KEY_FILENAME}

### mod_ssl setting ###
#yum -y install mod_ssl

