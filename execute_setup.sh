#!/bin/sh

# include config file
CONFIG_FILE="`dirname $0`/setup.conf"
if [ ! -f $CONFIG_FILE ]; then
    echo "Not found config file : ${CONFIG_FILE}" ; exit 1
fi
. $CONFIG_FILE

# include common file
COMMON_FILE="`dirname $0`/common.sh"
if [ ! -f $COMMON_FILE ]; then
    echo "Not found common file : ${COMMON_FILE}" ; exit 1
fi
. $COMMON_FILE


 . $OS_NAME/system_setup.sh
 . $OS_NAME/lamp_setup.sh
# . $OS_NAME/ssl_setup.sh
# . $OS_NAME/ftp_setup.sh
# . $OS_NAME/flockbird_setup.sh
