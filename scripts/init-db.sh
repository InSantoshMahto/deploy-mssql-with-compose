#!/bin/bash

# SQL Server Database Initialization Script
# Runs all SQL scripts from the queries directory

echo "=========================================="
echo "SQL Server Database Initialization"
echo "=========================================="
echo ""

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

SA_PASSWORD=${SA_PASSWORD:-"MyStrong@Pass123"}

# Check if container is running
if ! docker ps | grep -q mssql-server-2019; then
    echo "Error: SQL Server container is not running!"
    echo "Start it with: docker compose up -d"
    exit 1
fi

# Check if SQL Server is ready
echo "Checking if SQL Server is ready..."
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker exec mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
        -C -S localhost -U sa -P "${SA_PASSWORD}" \
        -Q "SELECT 1" -b -o /dev/null 2>/dev/null; then
        echo "✓ SQL Server is ready"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo ""
    echo "Error: SQL Server did not become ready in time"
    exit 1
fi

echo ""

# Check if queries directory exists
if [ ! -d "queries" ]; then
    echo "Error: queries directory not found!"
    exit 1
fi

# Count SQL files
SQL_FILES=$(ls -1 queries/*.sql 2>/dev/null | wc -l)
if [ $SQL_FILES -eq 0 ]; then
    echo "Error: No SQL files found in queries directory!"
    exit 1
fi

echo "Found $SQL_FILES SQL script(s) to execute"
echo ""

# Run each SQL script in order
SUCCESS_COUNT=0
FAIL_COUNT=0

for script in queries/*.sql; do
    if [ -f "$script" ]; then
        SCRIPT_NAME=$(basename "$script")
        echo "─────────────────────────────────────────"
        echo "Executing: $SCRIPT_NAME"
        echo "─────────────────────────────────────────"

        if docker exec -i mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
            -C -S localhost -U sa -P "${SA_PASSWORD}" < "$script"; then
            echo "✓ $SCRIPT_NAME completed successfully"
            ((SUCCESS_COUNT++))
        else
            echo "✗ $SCRIPT_NAME failed!"
            ((FAIL_COUNT++))
        fi
        echo ""
    fi
done

# Summary
echo "=========================================="
echo "Initialization Summary"
echo "=========================================="
echo "Scripts executed: $SQL_FILES"
echo "Successful: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo "⚠ Some scripts failed to execute"
    exit 1
else
    echo "✓ All scripts executed successfully"
    echo ""

    # List databases
    echo "Current databases:"
    docker exec mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
        -C -S localhost -U sa -P "${SA_PASSWORD}" \
        -Q "SELECT name FROM sys.databases ORDER BY name" -h -1

    echo ""
    echo "Database initialization complete!"
fi
