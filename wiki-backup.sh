#!/bin/bash

############################
# CONFIG
############################
LOCAL_DIR="/backup"

FTP_DIR="/Backups"
FTP_SERVER=""
FTP_USERNAME="user"
FTP_PASSWORD="password"

WIKI_DIRS=( "/var/www/html/wiki" )

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
WIKI_READ_ONLY="\$wgReadOnly = 'Performing backup';"
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
LOCAL_SETTINGS=""
WIKI_NAME=""
FILE_NAME=""
OLD_FILE_NAME=""

for i in "${WIKI_DIRS[@]}"
do
	# Populate variables
	LOCAL_SETTINGS="$i/LocalSettings.php"
	DB_NAME="$(grep -oE '\$wgDBname = \".*\";' $LOCAL_SETTINGS | tail -1 | sed 's/$wgDBname = \"//g;s/\";//g')"
	DB_USER="$(grep -oE '\$wgDBuser = \".*\";' $LOCAL_SETTINGS | tail -1 | sed 's/$wgDBuser = \"//g;s/\";//g')"
	DB_PASSWORD="$(grep -oE '\$wgDBpassword = \".*\";' $LOCAL_SETTINGS | tail -1 | sed 's/$wgDBpassword = \"//g;s/\";//g')"
	WIKI_NAME="$(grep -oE '\$wgMetaNamespace = \".*\";' $LOCAL_SETTINGS | tail -1 | sed 's/$wgMetaNamespace = \"//g;s/\";//g')"
	FILE_NAME="$WIKI_NAME-$DATE-$1"
	OLD_FILE_NAME="$WIKI_NAME-$ROTATION_DATE-$1"

	# Make Wiki ReadOnly
	echo $WIKI_READ_ONLY >> $LOCAL_SETTINGS

	# Local dump
	mysqldump -u $DB_USER -p $DB_PASSWORD $DB_NAME | gzip > $LOCAL_DIR/$FILE_NAME.sql.gz
	rm -f $LOCAL_DIR/$OLD_FILE_NAME.sql.gz

	tar --exclude-vcs -zcf $LOCAL_DIR/$FILE_NAME.files.tgz $i
	rm -f $LOCAL_DIR/$OLD_FILE_NAME.files.tgz

	php $i/maintenance/dumpBackup.php --full | gzip > $LOCAL_DIR/$FILE_NAME.xml.gz
	rm -f $LOCAL_DIR/$OLD_FILE_NAME.xml.gz

	# FTP dump
	ftp -n $FTP_SERVER << END_SCRIPT
	user "$FTP_USERNAME" "$FTP_PASSWORD"
	binary
	cd $FTP_DIR
	lcd $LOCAL_DIR

	put "$FILE_NAME.sql.gz"
	delete "$OLD_FILE_NAME.sql.gz"

	put "$FILE_NAME.files.tgz"
	delete "$OLD_FILE_NAME.files.tgz"

	put "$FILE_NAME.xml.gz"
	delete "$OLD_FILE_NAME.xml.gz"

	bye
END_SCRIPT

	# Undo Wiki ReadOnly
	sed -i "s/$WIKI_READ_ONLY//ig" $LOCAL_SETTINGS
done
