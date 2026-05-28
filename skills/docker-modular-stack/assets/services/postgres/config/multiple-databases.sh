### entrypoint.sh
#!/bin/bash

set -e
set -u

function create_user_and_database() {
    local database=$1
    echo "  Creating user and database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE USER $database;
        CREATE DATABASE $database;
        GRANT ALL PRIVILEGES ON DATABASE $database TO $database;
EOSQL
}

if [ -n "$ADDITIONAL_DBS" ]; then
    echo "Multiple database creation requested: $ADDITIONAL_DBS"
    IFS=',' read -ra DB_ARRAY <<< "$ADDITIONAL_DBS"
    for db in "${DB_ARRAY[@]}"; do
        create_user_and_database "$db"
    done
    echo "Multiple databases created"
fi