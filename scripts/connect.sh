#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

SA_PASSWORD=${SA_PASSWORD:-"MyStrong@Pass123"}
SQL_PORT=${SQL_PORT:-1433}

echo "=========================================="
echo "SQL Server 2019 Connection"
echo "=========================================="
echo ""
echo "Connecting to SQL Server..."
echo "Server: localhost,${SQL_PORT}"
echo "User: sa"
echo ""

# Connect using sqlcmd from within the container
docker exec -it mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
    -C \
    -S localhost \
    -U sa \
    -P "${SA_PASSWORD}"

echo ""
echo "Connection closed."
