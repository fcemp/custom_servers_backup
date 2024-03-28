YAML_FILE="/backup/scripts/custom_servers_backup/test/servers.yml"
YQ_PATH="/usr/bin/yq"

function get_server_name(){
	        SERVER_KEY=$1
		        echo "$(cat $YAML_FILE |$YQ_PATH e ".servers.$SERVER_KEY.name"|tr -d "[:blank:]")"
}

get_server_name '39'
