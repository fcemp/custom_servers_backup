#!/bin/bash

FZF_PATH="/usr/bin/fzy"
YQ_PATH="/usr/bin/yq"
#YAML_FILE="/backup/scripts/custom_servers_backup/servers.yml"
#YAML_BACKUP_DIR="/root/athul/custom_servers_script/yml/yaml_backup"
YAML_BACKUP_DIR="/backup/scripts/custom_servers_backup/yml/yaml_backup"

TOP_KEY="servers"
LAST_KEY=$(cat $YAML_FILE|yq e '.servers|keys'|tail -1 |tr "-" " " | xargs)
NEW_KEY=$(($LAST_KEY + 1))


SUPPORTED_DBS=(MYSQL POSTGRESQL)
DEFAULT_CONFIGS=(/etc/apache2 /etc/httpd /etc/httpd.conf /etc/mysql/my.cnf /etc/alternatives/my.cnf /etc/mysql/mysql.cnf  /etc/nginx /etc/varnish /etc/redis /etc/postgresql/ /var/lib/pgsql/data/postgresql.conf )

function yes_or_no(){
	# Return 0 if Yes, Else return 1

	ACTION=$1
	YES_ACTION=$2
	NO_ACTION=$3

	if [[ -z "${YES_ACTION//}" ]]; then
		YES_ACTION="proceed"
	fi

	if [[ -z "${NO_ACTION//}" ]]; then
		NO_ACTION="Exiting..."
	fi


	read -p "Do you want to $ACTION ? (yes/no) " yn

	case $yn in 
		yes|y ) echo "$YES_ACTION"
			return 0;;
		no|n ) echo "$NO_ACTION";
			return 1;;
		* ) echo invalid response;
			return 1;;
	esac
}

function get_server_list(){
	SERVERS_LIST=$(cat $YAML_FILE | $YQ_PATH e ".$TOP_KEY|keys"|tr "-" " "|tr -d "[:blank:]")
	echo "$SERVERS_LIST"
}

function get_database_list(){
	SERVER_KEY=$1
	DATABASES=$(cat $YAML_FILE | $YQ_PATH e ".$TOP_KEY.$SERVER_KEY.database"|tr "-" " "|tr -d "[:blank:]")
	#DATABASES=$(get_database_list $i|tr -d "[:blank:]" )
	if [[  $DATABASES = *[!\ ]*  ]]; then
		echo "$DATABASES"
	else
		echo "Null"
	fi

}


function get_configs_list(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE | $YQ_PATH e ".$TOP_KEY.$SERVER_KEY.configs"|tr "-" " "|tr -d "[:blank:]")"

}

function get_files_list(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE | $YQ_PATH e ".$TOP_KEY.$SERVER_KEY.files"|tr "-" " "|tr -d "[:blank:]")"

}


function get_server_name(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE |$YQ_PATH e ".$TOP_KEY.$SERVER_KEY.name"|tr -d "[:blank:]")"
}


function get_server_ip(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE |$YQ_PATH e ".$TOP_KEY.$SERVER_KEY.ip"|tr "-" " "|tr -d "[:blank:]")"
}


function get_server_port(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE |$YQ_PATH e ".$TOP_KEY.$SERVER_KEY.port"|tr "-" " "|tr -d "[:blank:]")"
}




# YAML insert data functions


function backup_yaml(){
	mkdir -p ${YAML_BACKUP_DIR}
	random_suffix=$(echo "$(date +'%Y-%m-%d')-$(shuf -i 1000-10000 -n1)")
	cp ${YAML_FILE}  ${YAML_BACKUP_DIR}/$(basename $YAML_FILE).${random_suffix}
#	echo "YAML FILE: ${YAML_FILE}"
#	echo "YAML_BACKUP_DIR: ${YAML_BACKUP_DIR}"
#	echo "cp ${YAML_FILE}  ${YAML_BACKUP_DIR}/$(basename $YAML_FILE).${random_suffix}"

}


function check_key(){
	SERVER_KEY=$1
	SUB_KEY=$2
	cat $YAML_FILE |pathEnv=."${TOP_KEY}"."${SERVER_KEY}" valueEnv="${SUB_KEY}"  $YQ_PATH 'eval(strenv(pathEnv))|has(strenv(valueEnv))'



}

function append_value(){
	SERVER_KEY=$1
	SUB_KEY=$2
	VALUE=$3

	cat $YAML_FILE |pathEnv=."${TOP_KEY}"."${SERVER_KEY}"."${SUB_KEY}" valueEnv="${VALUE}"  $YQ_PATH -i 'eval(strenv(pathEnv)) += strenv(valueEnv)' $YAML_FILE
}



function add_value(){
	SERVER_KEY=$1
	SUB_KEY=$2
	VALUE=$3
	cat $YAML_FILE |pathEnv=."${TOP_KEY}"."${SERVER_KEY}"."${SUB_KEY}" valueEnv="${VALUE}"  $YQ_PATH -i 'eval(strenv(pathEnv)) = strenv(valueEnv)' ${YAML_FILE}


}


function delete_key(){
	# Given key.subkey , this function will delete $TOP_KEY.key.subkey and all it's contents
	SERVER_KEY=$1
	SUB_KEY=$2
	cat $YAML_FILE |pathEnv=."${TOP_KEY}"."${SERVER_KEY}"."${SUB_KEY}"   $YQ_PATH -i 'del(eval(strenv(pathEnv)))' $YAML_FILE


}

function add_list_element(){
	SERVER_KEY=$1
	SUB_KEY=$2
	VALUE=$3
	if $(check_key $SERVER_KEY $SUB_KEY); then
		cat $YAML_FILE |pathEnv=."${TOP_KEY}"."${SERVER_KEY}"."${SUB_KEY}" valueEnv="${VALUE}"  $YQ_PATH -i 'eval(strenv(pathEnv)) += strenv(valueEnv)' $YAML_FILE
	else
		cat $YAML_FILE |pathEnv=."${TOP_KEY}"."${SERVER_KEY}"."${SUB_KEY}".[0] valueEnv="${VALUE}"  $YQ_PATH -i 'eval(strenv(pathEnv)) = strenv(valueEnv)' $YAML_FILE
	fi


}


function read_configs(){
	echo " "
        printf "Enter the configuration directories to backup. One per line."
	printf "\nPress Enter after entering a value."
        echo "Press Ctrl + D when done."
        echo "Default configs list:"
        printf '%s\n' "${DEFAULT_CONFIGS[@]}"
	echo " "
        printf "If you want to use the default configuration list, press Ctrl + D:"
	echo " "
        readarray -t CONFIGS
        declare -a CONFIGS

}

function read_files(){
	echo " "
	printf "Enter the user  directories (Files) to backup. One per line."
	printf "\nPress Enter after entering a value."
        printf "Press Ctrl + D when done: "
        readarray -t FILES
        declare -a FILES

}


function read_databases(){
	echo " "
        printf "Enter the databases to backup. One per line."
	printf "\nPress Enter after entering a value."
        printf "Press Ctrl + D when done. \n"
        printf "If ALL databases need to be backed up, Just press Ctrl + D: "
        readarray -t DATABASES
        declare -a DATABASES

}

function read_db_excludes(){
	echo " "
        printf "Enter the databases to EXCLUDE from backup. One per line."
	printf "\nPress Enter after entering a value."
        printf "Press Ctrl + D when done. \n"
        printf "If NO databases need to be EXCLUDED from backup, Just press Ctrl + D: "
        readarray -t DB_EXCLUDES
        declare -a DB_EXCLUDES

}

function is_var_in_array(){
	var="${1^^}"
	shift
	arr=("$@")
	if [[ " ${arr[*]} " =~ " ${var} " ]]; then
		echo 'true'
	else
		echo 'false'
	fi
}





function add_new_server(){
	backup_yaml
	# Add new server 
	read -r -p "Enter server name: " SERVER_NAME
	read -r -p  "Enter Server IP: " IP
	read -r -p  "Enter SSH Port. Simply press enter if it's 22: " PORT
	echo ""
	printf  "Enter Database Type (MYSQL,POSTGRESQL).\n"
	read -r -p  "Just press Enter if Database Type is MYSQL: " DB_TYPE
	
	if [[ -z ${PORT//}  ]]; then
	       PORT=22
	fi

	temp=${DB_TYPE^^}
	DB_TYPE=$temp
	if [[ -z "${DB_TYPE//}"  ]]; then 
		DB_TYPE="MYSQL"
	fi

	if $(is_var_in_array "${DB_TYPE}" "${SUPPORTED_DBS[@]}"); then
		:
	else
		echo "$DB_TYPE is not supported"
		exit
		
	fi
	


	read_configs
	echo " "
	
	# If config list is empty, assign default config list

	if (( ${#CONFIGS[@]} )); then
		:
	else
		CONFIGS=("${DEFAULT_CONFIGS[@]}")
	fi


	read_databases
	echo " "
	
	read_db_excludes
	echo ""
	
	read_files
	echo " "

	
	echo "Review the new server configuration, before adding to $YAML_FILE file:"
	echo "Server Name : $SERVER_NAME"
	echo "IP: $IP"
	echo "PORT: $PORT"
	echo "DB Type: $DB_TYPE"
	echo " "
	echo "Datbases: "
	printf '%s\n' "${DATABASES[@]}"
	echo " "
	echo "Datbases to exclude: "
	printf '%s\n' "${DB_EXCLUDES[@]}"
	echo " "
	echo "Config files:"
	printf '%s\n' "${CONFIGS[@]}"
	echo " "
	echo "User files:"
	printf '%s\n' "${FILES[@]}"

        read -p "Do you want to add this server? (yes/no) " yn

        case $yn in
                yes|y ) echo "Adding new server to $YAML_FILE ..."
			echo ""
			
			# Adding server to file
			add_value $NEW_KEY "name" $SERVER_NAME
			add_value $NEW_KEY "ip" $IP
			add_value $NEW_KEY "port" $PORT
			add_value $NEW_KEY "dbtype" $DB_TYPE
			
			for i in ${!CONFIGS[@]}; do 
				var="${CONFIGS[$i]}"; 
				add_list_element $NEW_KEY configs $var
			done

			if (( ${#DATABASES[@]} )); then
				for i in ${!DATABASES[@]}; do
					 var="${DATABASES[$i]}";
					add_list_element $NEW_KEY databases $var
				done
			else
				add_value $NEW_KEY "databases" " "
				
			 fi


			if (( ${#DB_EXCLUDES[@]} )); then
				for i in ${!DB_EXCLUDES[@]}; do
					 var="${DB_EXCLUDES[$i]}";
					add_list_element $NEW_KEY db_excludes $var
				done
			else
				add_value $NEW_KEY "db_excludes" " "
				
			 fi

			for i in ${!FILES[@]}; do 
				var="${FILES[$i]}"; 
				add_list_element $NEW_KEY files $var
			done


			echo "A new server has been added to $YAML_FILE with the following configuration:"
			echo "Server Name : $SERVER_NAME"
			echo "IP: $IP"
			echo "PORT: $PORT"
			echo "DB Type: $DB_TYPE"
			echo " "
			echo "Datbases: "
			printf '%s\n' "${DATABASES[@]}"
			echo " "
			echo "Datbases to exclude: "
			printf '%s\n' "${DB_EXCLUDES[@]}"
			echo " "
			echo "Config files:"
			printf '%s\n' "${CONFIGS[@]}"
			echo " "
			echo "User files:"
			printf '%s\n' "${FILES[@]}"
				return 0;;
                no|n ) echo "You've selected No. Exiting script...";
                        return 1;;
                * ) echo invalid response;
                        return 1;;
        esac

	
}


function delete_server(){
	backup_yaml
        keys=$(cat $YAML_FILE|pathEnv=."${TOP_KEY}" yq 'eval(strenv(pathEnv)) | keys' |tr "-" " "|tr '"' " ")
        :> $TEMP_DIR/servers_list.txt
        for i in ${keys//}; do
                ip_of_key=$(cat  $YAML_FILE| pathEnv=."${TOP_KEY}"."${i}".ip $YQ_PATH 'eval(strenv(pathEnv))')
                server_name_of_key=$(cat  $YAML_FILE| pathEnv=."${TOP_KEY}"."${i}".name $YQ_PATH 'eval(strenv(pathEnv))')
                echo "$i : ${server_name_of_key} ${ip_of_key}" >> $TEMP_DIR/servers_list.txt
        done

        server_to_delete=$(cat $TEMP_DIR/servers_list.txt | $FZF_PATH  )
        if [[ "$?" == "1" ]]; then
                exit
        fi
        server_id_to_delete=$(echo $server_to_delete | awk '{print $1}' )
        #server_name_to_delete=$(echo $server_to_delete | awk '{print $3}' )
        #server_ip_to_delete=$(echo $server_to_delete | awk '{print $4}' )
        yes_or_no "remove server >> $server_to_delete  << from $YAML_FILE " "Removing server $server_to_delete  from $YAML_FILE ..."
        if [[ "$?" == "0" ]]; then
                cat $YAML_FILE| pathEnv=."${TOP_KEY}"."${server_id_to_delete}" yq 'del(eval(strenv(pathEnv)))' > ${TEMP_DIR}/servers_temp.yml
                mv ${TEMP_DIR}/servers_temp.yml $YAML_FILE
                echo "Success!"
        fi	


}

function list_servers(){
        keys=$(cat $YAML_FILE|pathEnv=."${TOP_KEY}" yq 'eval(strenv(pathEnv)) | keys' |tr "-" " "|tr '"' " ")
        :> $TEMP_DIR/servers_list.txt
        for i in ${keys//}; do
                ip_of_key=$(cat  $YAML_FILE| pathEnv=."${TOP_KEY}"."${i}".ip $YQ_PATH 'eval(strenv(pathEnv))')
                server_name_of_key=$(cat  $YAML_FILE| pathEnv=."${TOP_KEY}"."${i}".name $YQ_PATH 'eval(strenv(pathEnv))')
                echo "$i : ${server_name_of_key} ${ip_of_key}" >> $TEMP_DIR/servers_list.txt
        done
	server_id_to_delete=$(cat $TEMP_DIR/servers_list.txt | $FZF_PATH |awk '{print $1}' )

	cat $YAML_FILE| pathEnv=."${TOP_KEY}"."${server_id_to_delete}" $YQ_PATH 'eval(strenv(pathEnv))'


}




