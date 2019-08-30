#!/bin/bash

############################
# CONFIG
############################
LOCAL_DIR="/backup"

FTP_DIR="/Backups/jira"
FTP_SERVER="backups.site.com"
FTP_USERNAME="ftpuser"
FTP_PASSWORD="ftppassword"

DB_NAMES=( "jira" )
DB_USERS=( "user" )
DB_PASSWORDS=( "password" )

FILES_DIR_GROUPS=( "/var/atlassian/application-data/jira/data" )

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
FILE_NAME=""
OLD_FILE_NAME=""

for i in "${!DB_NAMES[@]}"
do
	# Local dump
	FILE_NAME="${DB_NAMES[$i]}-$DATE-$1"
	OLD_FILE_NAME="${DB_NAMES[$i]}-$ROTATION_DATE-$1"
	
	mysqldump -u ${DB_USERS[$i]} -p${DB_PASSWORDS[$i]} ${DB_NAMES[$i]} | gzip > $LOCAL_DIR/$FILE_NAME.sql.gz
	rm -f $LOCAL_DIR/$OLD_FILE_NAME.sql.gz
	
	tar --exclude-vcs -zcf $LOCAL_DIR/$FILE_NAME.files.tgz ${FILES_DIR_GROUPS[$i]}
	rm -f $LOCAL_DIR/$OLD_FILE_NAME.files.tgz

	# FTP
	ftp -n $FTP_SERVER << END_SCRIPT
	user "$FTP_USERNAME" "$FTP_PASSWORD"
	binary
	cd $FTP_DIR
	lcd $LOCAL_DIR
	
	put "$FILE_NAME.sql.gz"
	delete "$OLD_FILE_NAME.sql.gz"
	
	put "$FILE_NAME.files.tgz"
	delete "$OLD_FILE_NAME.files.tgz"
	
	bye
END_SCRIPT
done