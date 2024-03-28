#!/bin/bash
# Change $DEST_DIR_PREFIX to specify where to save the backups to



DEST_DIR_PREFIX="/backup/custom_servers"
YAML_FILE="/backup/scripts/custom_servers_backup/servers.yml"
INCLUDES_DIR="/backup/scripts/includes"
KEEP_BACKUPS_FOR=12



DateTimeStamp=$(date +%A)
DAY=$(date +%a)
TODAY=`date +"%Y%m%d"`
YESTERDAY=`date -d "1 day ago" +"%Y%m%d" `
#OLDEST_BACKUP=`date -d "12 days ago" +"%Y%m%d" `
OLDEST_BACKUP=`date -d "$KEEP_BACKUPS_FOR days ago" +"%Y%m%d" `;
