#!/bin/bash

# SQL Server 2019 Verification Script
# This script checks if SQL Server is properly installed and running using Podman

echo "=========================================="
echo "SQL Server 2019 Health Check"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

SA_PASSWORD=${SA_PASSWORD:-"MyStrong@Pass123"}
SQL_PORT=${SQL_PORT:-1433}

# Check counter
CHECKS_PASSED=0
CHECKS_FAILED=0

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
     ((CHECKS_PASSED++))
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
     ((CHECKS_FAILED++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "Running system checks..."
echo ""

# 1. Check Podman installation
echo "1. Checking Podman..."
if command -v podman &> /dev/null; then
    PODMAN_VERSION=$(podman --version)
    print_success "Podman is installed: $PODMAN_VERSION"
else
    print_error "Podman is not installed"
    echo "   Install from: https://podman.io/getting-started/installation"
fi

# 2. Check Podman Compose installation
echo "2. Checking Podman Compose..."
if podman compose version &> /dev/null 2>&1; then
    COMPOSE_VERSION=$(podman compose version)
    print_success "Podman Compose is installed: $COMPOSE_VERSION"
else
    print_error "Podman Compose is not installed"
fi

# 3. Check if container exists
echo "3. Checking SQL Server container..."
if podman ps -a --format '{{.Names}}' | grep -q "mssql-server-2019"; then
    print_success "SQL Server container exists"

     # Check if running
    if podman ps --format '{{.Names}}' | grep -q "mssql-server-2019"; then
        print_success "SQL Server container is running"

         # Get container status
        STATUS=$(podman ps --format '{{.Status}}' --filter "name=mssql-server-2019")
        echo "   Status: $STATUS"
    else
        print_error "SQL Server container exists but is not running"
        echo "   Run: podman compose up -d"
    fi
else
    print_error "SQL Server container not found"
    echo "   Run: bash setup.sh"
fi

# 4. Check health status
echo "4. Checking container health..."
if podman ps --format '{{.Names}}' | grep -q "mssql-server-2019"; then
    HEALTH=$(podman inspect --format='{{.State.Health.Status}}' mssql-server-2019 2>/dev/null)
    if [ "$HEALTH" = "healthy" ]; then
        print_success "Container is healthy"
    elif [ "$HEALTH" = "starting" ]; then
        print_warning "Container is starting (wait a moment)"
    else
        print_error "Container health check failed: $HEALTH"
    fi
fi

# 5. Check port binding
echo "5. Checking port binding..."
if podman ps --format '{{.Names}}' | grep -q "mssql-server-2019"; then
    PORT_BINDING=$(podman port mssql-server-2019 1433 2>/dev/null)
    if [ ! -z "$PORT_BINDING" ]; then
        print_success "Port 1433 is bound to: $PORT_BINDING"
    else
        print_error "Port 1433 is not bound"
    fi
fi

# 6. Check if port is accessible
echo "6. Checking port accessibility..."
if nc -z localhost ${SQL_PORT} 2>/dev/null; then
    print_success "Port ${SQL_PORT} is accessible"
elif timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/${SQL_PORT}" 2>/dev/null; then
    print_success "Port ${SQL_PORT} is accessible"
else
    print_error "Port ${SQL_PORT} is not accessible"
fi

# 7. Check volumes
echo "7. Checking Podman volumes..."
VOLUME_COUNT=0
for VOLUME in mssql-2019-data mssql-2019-log mssql-2019-secrets; do
    if podman volume ls | grep -q "$VOLUME"; then
         ((VOLUME_COUNT++))
    fi
done
if [ $VOLUME_COUNT -eq 3 ]; then
    print_success "All 3 Podman volumes exist"
else
    print_error "Missing volumes (found $VOLUME_COUNT/3)"
fi

# 8. Check SQL Server connectivity
echo "8. Testing SQL Server connection..."
if podman ps --format '{{.Names}}' | grep -q "mssql-server-2019"; then
    if podman exec mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT 1" -b -o /dev/null 2>/dev/null; then
        print_success "SQL Server is accepting connections"
    else
        print_error "Cannot connect to SQL Server"
        print_warning "Check if password in .env is correct"
    fi
fi

# 9. Check if AppDB exists
echo "9. Checking AppDB database..."
if podman ps --format '{{.Names}}' | grep -q "mssql-server-2019"; then
    DB_CHECK=$(podman exec mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT DB_ID('AppDB')" -h -1 2>/dev/null | tr -d ' \n\r')
    if [ ! -z "$DB_CHECK" ] && [ "$DB_CHECK" != "NULL" ]; then
        print_success "AppDB database exists (ID: $DB_CHECK)"

         # Count tables
        TABLE_COUNT=$(podman exec mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "${SA_PASSWORD}" -d AppDB -Q "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'" -h -1 2>/dev/null | tr -d ' \n\r')
        if [ ! -z "$TABLE_COUNT" ]; then
            echo "   Tables found: $TABLE_COUNT"
        fi
    else
        print_error "AppDB database not found"
    fi
fi

# 10. Check disk space
echo "10. Checking disk space..."
if command -v df &> /dev/null; then
    DISK_AVAIL=$(df -h . | awk 'NR==2 {print $4}')
    print_success "Available disk space: $DISK_AVAIL"
fi

# 11. Check memory usage
echo "11. Checking container memory..."
if podman ps --format '{{.Names}}' | grep -q "mssql-server-2019"; then
    MEM_USAGE=$(podman stats --no-stream --format "{{.MemUsage}}" mssql-server-2019 2>/dev/null)
    if [ ! -z "$MEM_USAGE" ]; then
        print_success "Memory usage: $MEM_USAGE"
    fi
fi

# 12. Check backup directory
echo "12. Checking backup directory..."
if [ -d "./backups" ]; then
    print_success "Backup directory exists"
    BACKUP_COUNT=$(ls -1 ./backups/*.bak 2>/dev/null | wc -l)
    echo "   Backup files: $BACKUP_COUNT"
else
    print_error "Backup directory not found"
fi

# 13. Check init scripts
echo "13. Checking initialization scripts..."
INIT_SCRIPT_COUNT=$(ls -1 ./queries/*.sql 2>/dev/null | wc -l)
if [ $INIT_SCRIPT_COUNT -ge 3 ]; then
    print_success "Found $INIT_SCRIPT_COUNT initialization script(s)"
else
    print_warning "Expected 3 init scripts, found $INIT_SCRIPT_COUNT"
fi

# 14. Check helper scripts
echo "14. Checking helper scripts..."
HELPER_SCRIPTS=("connect.sh" "backup.sh" "restore.sh")
SCRIPT_COUNT=0
for SCRIPT in "${HELPER_SCRIPTS[@]}"; do
    if [ -f "./scripts/$SCRIPT" ]; then
        if [ -x "./scripts/$SCRIPT" ]; then
             ((SCRIPT_COUNT++))
        else
            print_warning "scripts/$SCRIPT exists but is not executable"
        fi
    fi
done
if [ $SCRIPT_COUNT -eq ${#HELPER_SCRIPTS[@]} ]; then
    print_success "All helper scripts are present and executable"
else
    print_warning "Found $SCRIPT_COUNT/${#HELPER_SCRIPTS[@]} executable scripts"
fi

# 15. Check .env file
echo "15. Checking configuration..."
if [ -f ".env" ]; then
    print_success ".env file exists"

     # Check if password is default
    if grep -q "SA_PASSWORD=MyStrong@Pass123" .env; then
        print_warning "You are using the default password - consider changing it"
    fi
else
    print_error ".env file not found"
fi

# Summary
echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo -e "${GREEN}Passed:${NC} $CHECKS_PASSED"
if [ $CHECKS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed:${NC} $CHECKS_FAILED"
fi
echo ""

# Overall status
if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ System is healthy!${NC}"
    echo ""
    echo "Quick commands:"
    echo "  Connect:    bash scripts/connect.sh"
    echo "  Backup:     bash scripts/backup.sh"
    echo "  View logs:  podman compose logs -f"
    echo "  Stop:       podman compose down"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Issues detected - see errors above${NC}"
    echo ""
    echo "Common fixes:"
    echo "  Start SQL Server:  podman compose up -d"
    echo "  View logs:         podman compose logs"
    echo "  Reset everything:  podman compose down -v && bash setup.sh"
    echo ""
    exit 1
fi
