#!/bin/bash

echo "=========================================="
echo "SQL Server 2019 Podman Setup"
echo "=========================================="
echo ""

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "Error: Podman is not installed!"
    echo "Please install Podman first: https://podman.io/getting-started/installation"
    exit 1
fi

# Check if Podman Compose is installed
if ! podman compose version &> /dev/null 2>&1; then
    echo "Error: Podman Compose is not installed!"
    echo "Please install the Podman Compose plugin"
    exit 1
fi

echo "✓ Podman is installed"
echo "✓ Podman Compose is installed"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p queries backups scripts
touch backups/.gitkeep

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null

echo "✓ Directory structure created"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Warning: .env file not found!"
    echo ""

     # Check if .env.example exists
    if [ -f .env.example ]; then
        echo "Found .env.example file."
        echo "Creating .env from .env.example..."
        cp .env.example .env
        echo "✓ .env file created"
        echo ""
        echo "IMPORTANT: Please edit .env and set your SA_PASSWORD before continuing."
        echo "Run: nano .env (or use your preferred editor)"
        echo ""
        echo "Password requirements:"
        echo "   - At least 8 characters"
        echo "   - Contains uppercase, lowercase, digits, and special characters"
        echo ""
        exit 1
    else
        echo "Please create .env file with your configuration."
        echo "See .env.example for available options."
        exit 1
    fi
fi

echo "✓ Environment file found"
echo ""

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Validate SA password
if [ -z "$SA_PASSWORD" ]; then
    echo "Error: SA_PASSWORD not set in .env file!"
    exit 1
fi

echo "Configuration:"
echo "   - SQL Server Edition: ${MSSQL_PID:-Developer}"
echo "   - SQL Server Port: ${SQL_PORT:-1433}"
echo "   - Memory Limit: ${MSSQL_MEMORY_LIMIT_MB:-2048}MB"
echo "   - SQL Server Agent: ${MSSQL_AGENT_ENABLED:-true}"
echo ""

# Pull the image
echo "Pulling SQL Server 2019 image..."
podman compose pull

echo ""
echo "Starting SQL Server..."
podman compose up -d

echo ""
echo "Waiting for SQL Server to start..."
sleep 10

# Wait for health check
echo "Checking health status..."
for i in {1..30}; do
    if podman inspect mssql-server-2019 2>/dev/null | grep -q '"Status": "healthy"'; then
        echo ""
        echo "✓ SQL Server is healthy and ready!"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo ""
echo "Initializing database..."
bash scripts/init-db.sh

echo ""
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "SQL Server 2019 is now running with Podman!"
echo ""
echo "Connection Details:"
echo "  Server: localhost,${SQL_PORT:-1433}"
echo "  Username: sa"
echo "  Password: (check .env file)"
echo ""
echo "Quick Commands:"
echo "  Connect: bash scripts/connect.sh"
echo "  Backup: bash scripts/backup.sh"
echo "  Logs: podman compose logs -f"
echo "  Stop: podman compose down"
echo ""
