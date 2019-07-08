#!/bin/bash

############################
# CONFIG
############################
LOCAL_DIR="/backup"

FTP_DIR="/Backups/server"
FTP_SERVER=""
FTP_USERNAME="user"
FTP_PASSWORD="password"

DB_USER="root"
DB_PASSWORD="mysql_password"
DB_NAMES=( "test" )

ROTATION_HOURLY=0
ROTATION_DAILY=0
ROTATION_WEEKLY=4
ROTATION_MONTHLY=12

############################
# CALCULATE ROTATIONS
############################
DATE=`date +%F_%H`
ROTATION_DATE=''

if [ $1 == "h" ] && [ $ROTATION_HOURLY -gt 0 ]
then
        ROTATION_DATE=`date --date="$ROTATION_HOURLY hour ago" +%F_%H`
elif [ $1 == "d" ] && [ $ROTATION_DAILY -gt 0 ]
then
        ROTATION_DATE=`date --date="$ROTATION_DAILY day ago" +%F_%H`
elif [ $1 == "w" ] && [ $ROTATION_WEEKLY -gt 0 ]
then
        ROTATION_DATE=`date --date="$(($ROTATION_WEEKLY*7)) day ago" +%F_%H`
elif [ $1 == "m" ] && [ $ROTATION_MONTHLY -gt 0 ]
then
        ROTATION_DATE=`date --date="$ROTATION_MONTHLY month ago" +%F_%H`
else
        exit 1
fi

############################
# BACKUP AND REMOVE ROTATED
############################
for i in "${DB_NAMES[@]}"
do
        mysqldump -u $DB_USER -p$DB_PASSWORD $i | gzip > $LOCAL_DIR/$i-$1-$DATE.sql.gz
        rm -f $LOCAL_DIR/$i-$1-$ROTATION_DATE.sql.gz

        ftp -n $FTP_SERVER << END_SCRIPT
        user "$FTP_USERNAME" "$FTP_PASSWORD"
        binary
        cd $FTP_DIR
        lcd $LOCAL_DIR
        put "$i-$1-$DATE.sql.gz"
        delete "$i-$1-$ROTATION_DATE.sql.gz"
        bye
END_SCRIPT
done
