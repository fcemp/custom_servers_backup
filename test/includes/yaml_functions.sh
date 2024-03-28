#!/bin/bash
# Developed by Athul
# This file contains functions to parse yaml files

YQ_PATH="/usr/bin/yq"

# YAML Parse functions

function get_server_list(){
	SERVERS_LIST=$(cat $YAML_FILE | $YQ_PATH e '.servers|keys'|sed 's/-//'|tr -d "[:blank:]")
	echo "$SERVERS_LIST"
}

function get_dbtype(){
        SERVER_KEY=$1
        echo "$(cat $YAML_FILE | $YQ_PATH e ".servers.$SERVER_KEY.dbtype"|sed 's/-//'|tr -d "[:blank:]")"

}


function get_server_list(){
	SERVERS_LIST=$(cat $YAML_FILE | $YQ_PATH e '.servers|keys'|sed 's/-//'|tr -d "[:blank:]")
	echo "$SERVERS_LIST"
}

function get_database_list(){
	SERVER_KEY=$1
	DATABASES=$(cat $YAML_FILE | $YQ_PATH e ".servers.$SERVER_KEY.databases"|sed 's/-//'|tr -d "[:blank:]")
	#DATABASES=$(get_database_list $i|tr -d "[:blank:]" )
	if [[  $DATABASES = *[!\ ]*  ]]; then
		echo "$DATABASES"
	else
		echo "Null"
	fi

}

function get_database_exclusions(){
	SERVER_KEY=$1
	DB_EXCLUDES=$(cat $YAML_FILE | $YQ_PATH e ".servers.$SERVER_KEY.db_excludes"|sed 's/-//'|tr -d "[:blank:]")
	#DATABASES=$(get_database_list $i|tr -d "[:blank:]" )
	if [[  $DB_EXCLUDES = *[!\ ]*  ]]; then
		echo "$DB_EXCLUDES"
	else
		echo "Null"
	fi

}


function get_configs_list(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE | $YQ_PATH e ".servers.$SERVER_KEY.configs"|sed 's/-//'|tr -d "[:blank:]")"

}

function get_files_list(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE | $YQ_PATH e ".servers.$SERVER_KEY.files"|sed 's/-//' |tr -d "[:blank:]")"

}


function get_server_name(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE |$YQ_PATH e ".servers.$SERVER_KEY.name"|tr -d "[:blank:]")"
}


function get_server_ip(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE |$YQ_PATH e ".servers.$SERVER_KEY.ip"|sed 's/-//' |tr -d "[:blank:]")"
}


function get_server_port(){
	SERVER_KEY=$1
	echo "$(cat $YAML_FILE |$YQ_PATH e ".servers.$SERVER_KEY.port"|sed 's/-//'|tr -d "[:blank:]")"
}


