# mysql service implements the service API

# Output service credentials as env variables
function service_get_credentials_env () {
  local service_name="${1:-}"
  [[ -z "$service_name" ]] && fail service_get_credentials_env passed an empty service_name
  local database_name="${2:-}"

  cat <<EOF
DB_HOST="$(get_service_instance "$service_name" | jq -r -e '.credentials.host')"
DB_PASSWORD="$(get_service_instance "$service_name" | jq -r -e '.credentials.password')"
DB_PORT="$(get_service_instance "$service_name" | jq -r -e '.credentials.port')"
DB_USER="$(get_service_instance "$service_name" | jq -r -e '.credentials.username')"
DB_NAME="${database_name:-$(get_service_instance "$service_name" | jq -r -e '.credentials.db_name')}"
EOF
}

function service_backup () {
  mysqldump --no-tablespaces --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" --no-create-db --verbose "$DB_NAME"
}

function service_restore () {
  mysql --binary-mode --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" "$DB_NAME"
}

function service_list_databases () {
  mysql --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" -e "SHOW DATABASES;"
}

function service_create_database () {
  mysql --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" -e "CREATE DATABASE \`$DB_NAME\`;"
}

function service_delete_database () {
  mysql --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" -e "DROP DATABASE \`$DB_NAME\`;"
}

function service_execute_sql () {
  mysql --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" "$DB_NAME" -e "$1;"
}

