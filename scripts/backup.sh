#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

SA_PASSWORD=${SA_PASSWORD:-"MyStrong@Pass123"}
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
DATABASE_NAME=${1:-"AppDB"}
BACKUP_FILE="${DATABASE_NAME}_${BACKUP_DATE}.bak"

echo "=========================================="
echo "SQL Server Database Backup"
echo "=========================================="
echo "Database: ${DATABASE_NAME}"
echo "Backup file: ${BACKUP_FILE}"
echo ""

# Check if container is running
if ! podman ps | grep -q mssql-server-2019; then
    echo "Error: SQL Server container is not running!"
    exit 1
fi

# Perform backup
echo "Starting backup..."
podman exec -i mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
    -C \
     -S localhost \
     -U sa \
     -P "${SA_PASSWORD}" \
     -Q "BACKUP DATABASE [${DATABASE_NAME}] TO DISK = N'/var/opt/mssql/backups/${BACKUP_FILE}' WITH NOFORMAT, NOINIT, NAME = '${DATABASE_NAME}-full', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Backup completed successfully!"
    echo "=========================================="
    echo "Backup location (container): /var/opt/mssql/backups/${BACKUP_FILE}"
    echo "Backup location (host): ./backups/${BACKUP_FILE}"
    echo ""

     # Verify backup
    echo "Verifying backup..."
    podman exec -i mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
         -C \
         -S localhost \
         -U sa \
         -P "${SA_PASSWORD}" \
         -Q "RESTORE VERIFYONLY FROM DISK = N'/var/opt/mssql/backups/${BACKUP_FILE}'"

    echo ""
    echo "Backup verification completed!"
else
    echo ""
    echo "Error: Backup failed!"
    exit 1
fi
