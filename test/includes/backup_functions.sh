#!/bin/bash
# Developed by Athul
# This file contains functions  to dump database and files from custom remote servers
# Also contains functions to parse yaml files



function dbdump_legacy () {
        IP=$1
        PORT=$2
	SERVER_NAME=$3
        SAVE_PATH=$4

	mkdir -p $SAVE_PATH

	echo "$(date +'%d-%m-%Y %T') - Taking Database backups of $IP:$PORT to $SAVE_PATH" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
        for DATABASE in `ssh -oStrictHostKeyChecking=no -p$PORT $IP "mysql -u root -e 'show databases'"  | awk {'print $1'} |grep -v Database | grep -v _schema`;
        do
		echo "$(date +'%d-%m-%Y %T') - Taking backup of database $DATABASE from $IP to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
                ssh -oStrictHostKeyChecking=no -p$PORT $IP "mysqldump \
                 --user=root \
                 $DATABASE \
                 | gzip -9" > $SAVE_PATH/$DATABASE.sql.gz
		echo "$(date +'%d-%m-%Y %T') - Backup of database $DATABASE from $IP have been saved to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log

        done

}

function dbdump_single_legacy () {
        IP=$1
        PORT=$2
	SERVER_NAME=$3
        SAVE_PATH=$4
	DATABASE=$5
	mkdir -p $SAVE_PATH

	echo "$(date +'%d-%m-%Y %T') - Taking Database backups of $IP:$PORT to $SAVE_PATH" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	echo "$(date +'%d-%m-%Y %T') - Taking backup of database $DATABASE from $IP to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	ssh -oStrictHostKeyChecking=no -p$PORT $IP "mysqldump \
	 --user=root \
	 $DATABASE \
	 | gzip -9" > $SAVE_PATH/$DATABASE.sql.gz
	echo "$(date +'%d-%m-%Y %T') - Backup of database $DATABASE from $IP have been saved to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log


}



function list_remote_db () {
        IP=$1
        PORT=$2
        SERVER_NAME=$3
        DB_TYPE=$4

         if [[ -z ${4+x}  ]]; then
                 DB_TYPE="MYSQL"
         fi


        if [[ $DB_TYPE =~ "MYSQL" ]]; then
		DATABASES=$(ssh -oStrictHostKeyChecking=no -p$PORT $IP "mysql -e 'show databases' |tail -n +2 "| tr '\n' ' ')
         elif [[ $DB_TYPE =~ "POSTGRESQL" ]]; then
		 DATABASES=$(ssh -oStrictHostKeyChecking=no -p$PORT $IP 'echo -n c3UgcG9zdGdyZXMgLWMgJ2NkIC90bXA7IHBzcWwgLWMgIlNFTEVDVCBkYXRuYW1lIEZST00gcGdfZGF0YWJhc2U7IiAn|base64 -d|bash|tail -n +3|head -n -2'| tr '\n' ' ')
        fi
	
	echo "${DATABASES[@]}"


}






function dbdump_single () {
        IP=$1
        PORT=$2
        SERVER_NAME=$3
        SAVE_PATH=$4
        DATABASE=$5
        DB_TYPE=$6

         if [[ -z ${6+x}  ]]; then
                 DB_TYPE="MYSQL"
         fi


        mkdir -p $SAVE_PATH

        echo "$(date +'%d-%m-%Y %T') - Taking Database backups of $IP:$PORT to $SAVE_PATH" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
        echo "$(date +'%d-%m-%Y %T') - Taking backup of database $DATABASE from $IP to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
        if [[ $DB_TYPE =~ "MYSQL" ]]; then
                ssh -oStrictHostKeyChecking=no -p$PORT $IP "mysqldump \
                 --user=root \
                 $DATABASE \
                 | gzip -9" > $SAVE_PATH/$DATABASE.sql.gz
         elif [[ $DB_TYPE =~ "POSTGRESQL" ]]; then
                ssh -oStrictHostKeyChecking=no -p$PORT $IP "su postgres -c 'cd /tmp;pg_dump $DATABASE' | gzip -9" > $SAVE_PATH/$DATABASE.sql.gz
        fi

        echo "$(date +'%d-%m-%Y %T') - Backup of database $DATABASE from $IP have been saved to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log


}


function dbdump () {
        IP=$1
        PORT=$2
        SERVER_NAME=$3
        SAVE_PATH=$4
        DB_TYPE=$5

         if [[ -z ${5+x}  ]]; then
                 DB_TYPE="MYSQL"
         fi


        mkdir -p $SAVE_PATH

        echo "$(date +'%d-%m-%Y %T') - Taking Database dump of $IP:$PORT to $SAVE_PATH" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	echo "DB_TYPE: $DB_TYPE"


        if [[ $DB_TYPE =~ "MYSQL" ]]; then
                for DATABASE in `ssh -oStrictHostKeyChecking=no -p$PORT $IP "mysql -u root -e 'show databases'"  | awk {'print $1'} |grep -v Database | grep -v _schema`;
                do
                        echo "$(date +'%d-%m-%Y %T') - Taking backup of database $DATABASE from $IP to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
                        ssh -oStrictHostKeyChecking=no -p$PORT $IP "mysqldump \
                         --user=root \
                         $DATABASE \
                         | gzip -9" > $SAVE_PATH/$DATABASE.sql.gz
                        echo "$(date +'%d-%m-%Y %T') - Backup of database $DATABASE from $IP have been saved to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log

                done
        elif [[ $DB_TYPE =~ "POSTGRESQL" ]]; then
                echo "$(date +'%d-%m-%Y %T') - Taking backup of all $DB_TYPE databases from $IP to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
		

		DB_LIST=$(list_remote_db $IP $PORT $SERVER_NAME $DB_TYPE) 
		for db in $DB_LIST; do
			dbdump_single $IP $PORT $SERVER_NAME "$DEST_DIR_PREFIX/$SERVER_NAME/database/$TODAY" "$db" $DB_TYPE
		done


                #ssh -oStrictHostKeyChecking=no -p$PORT $IP "cd /tmp;su postgres -c 'pg_dumpall' | gzip -9" > ${SAVE_PATH}/${SERVER_NAME}_pg_all.sql.gz
                echo "$(date +'%d-%m-%Y %T') - Backup of  $DB_TYPE databases from $IP have been saved to $SAVE_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
        fi

}





function filedump() {
        IP=$1
        PORT=$2
	SERVER_NAME=$3
        REMOTE_PATH=$4	
        DEST_PATH=$5
	YESTERDAY_BACKUP=`echo $DEST_PATH | sed -e s/$TODAY/$YESTERDAY/g`

	#echo "Yesterday Backup path: $YESTERDAY_BACKUP" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	#echo "Today Backup Path: $DEST_PATH" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	#echo "Today: $TODAY" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	#echo "Yesterday: $YESTERDAY" |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log

	mkdir -p $DEST_PATH	
	echo "$(date +'%d-%m-%Y %T') - Taking backup of $REMOTE_PATH from $IP:$PORT to $DEST_PATH"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
	#rsync -avzh -e "ssh -p $PORT" root@$IP:$REMOTE_PATH $DEST_PATH --log-file=/backup/BACKUPLOG/$SERVER_NAME.log
	rsync -azvh -e "ssh -p $PORT" --exclude=".cache" --delete  root@$IP:$REMOTE_PATH --link-dest $YESTERDAY_BACKUP $DEST_PATH --log-file=/backup/BACKUPLOG/$SERVER_NAME.log
	echo "$(date +'%d-%m-%Y %T') - Backup job of $REMOTE_PATH from $IP:$PORT to $DEST_PATH finished!"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER_NAME.log

}



function filedump_from_filelist() {
        IP=$1
        PORT=$2
        SERVER_NAME=$3
        REMOTE_FILE_LIST=$4
        DEST_PATH=$5

        for REMOTE_PATH in `ssh -oStrictHostKeyChecking=no -p$PORT $IP "cat $REMOTE_FILE_LIST"`;
        do
                echo "$(date +'%d-%m-%Y %T') - Taking backup of $REMOTE_PATH from $IP:$PORT to $DEST_PATH"  >> $DEST_DIR_PREFIX/logs/$SERVER_NAME.log
                rsync -avzh -e "ssh -p $PORT" root@$IP:$REMOTE_PATH $DEST_PATH --log-file=/backup/BACKUPLOG/$SERVER_NAME.log
        done

}


function cleanup() {
	SERVER=$1

	if [ -d "$DEST_DIR_PREFIX/$SERVER/configs/$OLDEST_BACKUP" ] 
	then
		echo "$(date +'%d-%m-%Y %T') - Removing old backup $DEST_DIR_PREFIX/$SERVER/configs/$OLDEST_BACKUP"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER.log
		rm -rf $DEST_DIR_PREFIX/$SERVER/configs/$OLDEST_BACKUP
	fi	

	
	if [ -d "$DEST_DIR_PREFIX/$SERVER/database/$OLDEST_BACKUP" ] 
	then
		echo "$(date +'%d-%m-%Y %T') - Removing old backup $DEST_DIR_PREFIX/$SERVER/database/$OLDEST_BACKUP"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER.log
		rm -rf $DEST_DIR_PREFIX/$SERVER/database/$OLDEST_BACKUP
	fi

		
	if [ -d "$DEST_DIR_PREFIX/$SERVER/files/$OLDEST_BACKUP" ] 
	then
		echo "$(date +'%d-%m-%Y %T') - Removing old backup $DEST_DIR_PREFIX/$SERVER/files/$OLDEST_BACKUP"  |tee -a $DEST_DIR_PREFIX/logs/$SERVER.log
		rm -rf $DEST_DIR_PREFIX/$SERVER/files/$OLDEST_BACKUP
	fi	


}


