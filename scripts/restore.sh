#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

SA_PASSWORD=${SA_PASSWORD:-"MyStrong@Pass123"}

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file> [target_database_name]"
    echo ""
    echo "Available backup files:"
    ls -lh backups/*.bak 2>/dev/null || echo "No backup files found in backups directory"
    exit 1
fi

BACKUP_FILE=$1
TARGET_DB=${2:-"AppDB_Restored"}

echo "=========================================="
echo "SQL Server Database Restore"
echo "=========================================="
echo "Backup file: ${BACKUP_FILE}"
echo "Target database: ${TARGET_DB}"
echo ""

# Check if container is running
if ! podman ps | grep -q mssql-server-2019; then
    echo "Error: SQL Server container is not running!"
    exit 1
fi

# Check if backup file exists
if [ ! -f "backups/${BACKUP_FILE}" ]; then
    echo "Error: Backup file 'backups/${BACKUP_FILE}' not found!"
    exit 1
fi

# Get logical file names from backup and extract them
echo "Detecting logical file names from backup..."

# Get logical names (first line is data file, second is log file)
LOGICAL_NAMES=$(podman exec -i mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
    -C -S localhost -U sa -P "${SA_PASSWORD}" \
     -h -1 -W \
     -Q "SET NOCOUNT ON; RESTORE FILELISTONLY FROM DISK = N'/var/opt/mssql/backups/${BACKUP_FILE}'" 2>/dev/null | awk 'NF {print $1}')

DATA_LOGICAL=$(echo "$LOGICAL_NAMES" | head -1)
LOG_LOGICAL=$(echo "$LOGICAL_NAMES" | tail -1)

if [ -z "$DATA_LOGICAL" ] || [ -z "$LOG_LOGICAL" ]; then
    echo "Error: Could not detect logical file names from backup!"
    exit 1
fi

echo "Detected logical names:"
echo "  Data file: ${DATA_LOGICAL}"
echo "  Log file:   ${LOG_LOGICAL}"
echo ""
echo "Starting restore..."

# Restore database with MOVE using detected logical names
podman exec -i mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
    -C -S localhost -U sa -P "${SA_PASSWORD}" \
     -Q "RESTORE DATABASE [${TARGET_DB}] FROM DISK = N'/var/opt/mssql/backups/${BACKUP_FILE}' WITH MOVE '${DATA_LOGICAL}' TO '/var/opt/mssql/data/${TARGET_DB}.mdf', MOVE '${LOG_LOGICAL}' TO '/var/opt/mssql/data/${TARGET_DB}_log.ldf', REPLACE, STATS = 10"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Restore completed successfully!"
    echo "=========================================="
    echo "Database '${TARGET_DB}' is now available"
else
    echo ""
    echo "Error: Restore failed!"
    exit 1
fi
