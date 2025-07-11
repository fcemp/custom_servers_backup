#!/bin/bash
# Developed by Athul
# Script to manage yaml file, to be used in custom_server_backup script
# Run this script without arguments and you can see the currently added servers in the $YAML_FILE
# Run this script with -a flag to add a new server to $YAML_FILE
# Run this script with -d flag to delete a server from $YAML_FILE



YAML_FILE="/backup/scripts/custom_servers_backup/servers.yml"
YAML_BACKUP_DIR="/root/athul/custom_servers_script/yml/yaml_backup"

FZF_PATH="/usr/bin/fzy"
YQ_PATH="/usr/bin/yq"

#TEMP_DIR="/root/athul/custom_servers_script/tmp"
TEMP_DIR="/backup/scripts/custom_servers_backup/tmp"
YAML_PARSE_FUNCTIONS_PATH="/backup/scripts/includes"



TOP_KEY="servers"
LAST_KEY=$(cat $YAML_FILE| $YQ_PATH e '.servers|keys'|tail -1 |tr "-" " " | xargs)
NEW_KEY=$(($LAST_KEY + 1))



source ${YAML_PARSE_FUNCTIONS_PATH}/yaml_manager_functions.sh



POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--add)
      ADD="$2"
      add_new_server
      shift # past argument
      shift # past value
      ;;
    -d|--delete)
      DELETE="$2"
      delete_server
      shift # past argument
      shift # past value
      ;;
    -s|--single)
      SINGLE="$2"
      single_server_backup
      shift # past argument
      shift # past value
      ;;
    --default)
      DEFAULT=YES
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters


if [[ $# -eq 0 ]]; then
      echo "Listing currently listed servers in $YAML_FILE"
      list_servers
fi


