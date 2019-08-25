#!/bin/bash

############################
# CONFIG
############################
LOCAL_DIR="/backup"

FTP_DIR="/Backups"
FTP_SERVER=""
FTP_USERNAME="user"
FTP_PASSWORD="password"

DB_USER="root"
DB_PASSWORD="mysql_password"
DB_NAME="jira"

JIRA_DATA_DIR="/var/atlassian/application-data/jira/data"

ROTATION_HOURLY=0
ROTATION_DAILY=0
ROTATION_WEEKLY=2
ROTATION_MONTHLY=12

############################
# CALCULATE ROTATIONS
############################
ROTATION_DATE=""

if [ $1 == "h" ] && [ $ROTATION_HOURLY -gt 0 ]
then
	ROTATION_DATE=`date --date="$ROTATION_HOURLY hour ago" +%F_%H`
elif [ $1 == "d" ] && [ $ROTATION_DAILY -gt 0 ]
then
	ROTATION_DATE=`date --date="$ROTATION_DAILY day ago" +%F_%H`
elif [ $1 == "w" ] && [ $ROTATION_WEEKLY -gt 0 ]
then
	ROTATION_DATE=`date --date="$ROTATION_WEEKLY week ago" +%F_%H`
elif [ $1 == "m" ] && [ $ROTATION_MONTHLY -gt 0 ]
then
	ROTATION_DATE=`date --date="$ROTATION_MONTHLY month ago" +%F_%H`
else
	exit 1
fi

############################
# BACKUP AND REMOVE ROTATED
############################
DATE=`date +%F_%H`
FILE_NAME="$DB_NAME-$DATE-$1"
OLD_FILE_NAME="$DB_NAME-$ROTATION_DATE-$1"

# Local dump
mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > $LOCAL_DIR/$FILE_NAME.sql.gz
rm -f $LOCAL_DIR/$OLD_FILE_NAME.sql.gz

tar --exclude-vcs -zcf $LOCAL_DIR/$FILE_NAME.files.tgz $JIRA_DATA_DIR
rm -f $LOCAL_DIR/$OLD_FILE_NAME.files.tgz

# FTP
ftp -n $FTP_SERVER << END_SCRIPT
user "$FTP_USERNAME" "$FTP_PASSWORD"
binary
cd $FTP_DIR
lcd $LOCAL_DIR

put "$FILE_NAME.sql.gz"
delete "$DB_NAME-$ROTATION_DATE-$1.sql.gz"

put "$FILE_NAME.files.tgz"
delete "$OLD_FILE_NAME.files.tgz"

bye
END_SCRIPT
