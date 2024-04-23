#!/bin/bash
# Developed by Athul
# Script to take custom server's incremental backup
# Specify the server, ip,port,databases,configs and files in the $YAML_FILE and 
# this server will automatically backup them to  $DEST_DIR_PREFIX directory.
# Variables are defined in ./configuration_vars.sh file.




arg="$1"
if [[ ! -f ${arg} ]]; then
	echo "[x] -  File doesn't exist! Exiting..."
	echo "[x] - Please provide a valid servers.yaml file as argument 1!"
	exit
else
	echo "Taking server list from file ${arg}..."
	YAML_FILE="${arg}"

fi


echo "Yaml file:"
echo "${YAML_FILE}"
cat ${YAML_FILE}



# Import variables
#source /backup/scripts/custom_servers_backup/configuration_vars.sh

# Config of configuration_vars.sh

## Change $DEST_DIR_PREFIX to specify where to save the backups to



DEST_DIR_PREFIX="/backup/custom_servers"
INCLUDES_DIR="/backup/scripts/includes"
KEEP_BACKUPS_FOR=12



DateTimeStamp=$(date +%A)
DAY=$(date +%a)
TODAY=`date +"%Y%m%d"`
YESTERDAY=`date -d "1 day ago" +"%Y%m%d" `
#OLDEST_BACKUP=`date -d "12 days ago" +"%Y%m%d" `
OLDEST_BACKUP=`date -d "$KEEP_BACKUPS_FOR days ago" +"%Y%m%d" `;



# End of config configuration_vars.sh







# Import custom functions
source $INCLUDES_DIR/backup_functions.sh
source $INCLUDES_DIR/yaml_functions.sh


echo "$(date +'%d-%m-%Y %T') - Script execution started" |tee -a "$DEST_DIR_PREFIX/logs/script.log"

for i in $(get_server_list); do
	SERVER_NAME="$(get_server_name $i)"
        IP="$(get_server_ip $i)"
        PORT="$(get_server_port $i)"
	DATABASES=$(get_database_list $i )
	DBTYPE=$(get_dbtype $i )  
	DB_EXCLUDES=$(get_database_exclusions $i )
	
	
	
	echo "DATABASES: ${DATABASES[@]}"

	echo "$(date +'%d-%m-%Y %T') - Starting backup of $SERVER_NAME ($IP:$PORT)"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	
	mkdir -p $DEST_DIR_PREFIX/$SERVER_NAME/configs
	mkdir -p $DEST_DIR_PREFIX/$SERVER_NAME/database
	mkdir -p $DEST_DIR_PREFIX/$SERVER_NAME/files

	# If $DB_EXCLUDES contains values that is not "Null", then exclude them from $DATABASES
	if ! $(echo "$DB_EXCLUDES" | grep -wiq "Null") ; then
		if $(echo "$DATABASES" | grep -wiq "Null") ; then
			# get db list from remote, populate $databases and exclude the $db_exclude from $databases
			temp_db_list=$(list_remote_db $IP $PORT $SERVER_NAME $DBTYPE)
			DATABASES=("${temp_db_list[@]}")
		fi
			#echo "Not Null. Value : ${DB_EXCLUDES[@]}"
			echo "$(date +'%d-%m-%Y %T') - Excluding the following databases: ${DB_EXCLUDES[@]}"
			for i in "${DB_EXCLUDES[@]}"; do
				DATABASES=("${DATABASES[@]//$i}")
			done

	fi


	# If database variable is empty in yml, then all databases will be dumped
	if  $(echo "$DATABASES" | grep -wiq "Null") ; then
		echo "$(date +'%d-%m-%Y %T') - No specific database mentioned. Starting to dump all databases..."
		# Database Dump and Sync
		#dbdump $IP $PORT $SERVER_NAME "$DEST_DIR_PREFIX/$SERVER_NAME/database/$TODAY" 
		dbdump $IP $PORT $SERVER_NAME "$DEST_DIR_PREFIX/$SERVER_NAME/database/$TODAY"  $DBTYPE 
        else
		echo "$(date +'%d-%m-%Y %T') - Specific databases mentioned. Dumping only the mentioned databases..."
		for db in $DATABASES; do 
			dbdump_single $IP $PORT $SERVER_NAME "$DEST_DIR_PREFIX/$SERVER_NAME/database/$TODAY" "$db" $DBTYPE
		done
        fi


	
	for config in $(get_configs_list $i); do
		echo $config
		filedump $IP $PORT $SERVER_NAME  $config "$DEST_DIR_PREFIX/$SERVER_NAME/configs/$TODAY"
	done

	for file in $(get_files_list $i); do
		echo $file
		filedump $IP $PORT $SERVER_NAME  $file "$DEST_DIR_PREFIX/$SERVER_NAME/files/$TODAY"
	done
	
	# Remove backups older than 11 days	
	cleanup $SERVER_NAME
	echo "$(date +'%d-%m-%Y %T') - Backup of $SERVER_NAME ($IP:$PORT) was finished!"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log

	# Line from old script. Kept for legacy reasons.
	echo "bacckup completed client server  $SERVER_NAME"  >>/backup/BACKUPLOG/${SERVER_NAME}.log




	
	
done

echo "$(date +'%d-%m-%Y %T') - Script execution finished!" |tee -a "$DEST_DIR_PREFIX/logs/script.log"
# END OF SCRIPT



