#!/bin/bash

# configure vars

DB_USER="mmuser"
DB_NAME="mattermost"
DB_PASS=""
DB_HOST="db"
RETENTION="0"
DATA_PATH="/mattermost/data/"

# calculate epoch in milisec
delete_before=$(date  --date="$RETENTION day ago"  "+%s%3N")
#delete_before=$(date  "+%s%3N")
echo $(date  --date="$RETENTION day ago")

# get list of files to be removed
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SELECT Path FROM FileInfo WHERE CreateAt < '$delete_before';" > /tmp/mattermost-paths.list
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SELECT ThumbnailPath from FileInfo WHERE CreateAt < '$delete_before';" >> /tmp/mattermost-paths.list
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SELECT PreviewPath from FileInfo WHERE CreateAt < '$delete_before';" >> /tmp/mattermost-paths.list

# cleanup db 
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "DELETE FROM Posts WHERE CreateAt < '$delete_before';"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "DELETE FROM FileInfo WHERE CreateAt < '$delete_before';"

# delete files
while read -r fp; do
        if [ -n "$fp" ]; then
                echo "$DATA_PATH""$fp"
                shred -u "$DATA_PATH""$fp"
        fi
done < /tmp/mattermost-paths.list

#cleanup after yourself
rm /tmp/mattermost-paths.list

#cleanup empty data dirs
find $DATA_PATH -type d -empty -delete
exit 0

