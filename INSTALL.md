# SQL Server 2019 Installation Guide

Complete step-by-step installation guide for setting up SQL Server 2019 with Docker on Ubuntu.

## Table of Contents

- [System Requirements](#system-requirements)
- [Step 1: Install Docker](#step-1-install-docker)
- [Step 2: Verify Docker Compose](#step-2-verify-docker-compose)
- [Step 3: Verify Docker Installation](#step-3-verify-docker-installation)
- [Step 4: Configure SQL Server](#step-4-configure-sql-server)
- [Step 5: Deploy SQL Server](#step-5-deploy-sql-server)
- [Step 6: Verify Installation](#step-6-verify-installation)
- [Optional: Install SQL Server Tools](#optional-install-sql-server-tools)
- [Troubleshooting](#troubleshooting)

---

## System Requirements

- **Operating System**: Ubuntu 24.04 LTS or later (64-bit)
- **RAM**: Minimum 2GB, Recommended 4GB+
- **Disk Space**: Minimum 10GB free space
- **Processor**: 64-bit processor (x86_64/amd64)
- **Internet Connection**: Required for downloading images

---

## Step 1: Install Docker

### Uninstall Old Versions (if any)

```bash
# Remove old Docker versions
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove $pkg
done
```

### Install Using apt Repository (Recommended)

**1. Set up Docker's apt repository:**

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

**2. Install Docker packages:**

```bash
# Install the latest version
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**3. Verify installation:**

```bash
# Run the hello-world image
sudo docker run hello-world
```

### Configure Docker Permissions

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply the new group membership
newgrp docker

# Verify you can run docker without sudo
docker run hello-world
```

**Important:** 
- You may need to log out and log back in for group changes to take effect
- Alternatively, run `newgrp docker` to activate the changes immediately
- The `docker` group grants root-equivalent privileges. See [Docker security](https://docs.docker.com/engine/security/#docker-daemon-attack-surface) for details

### Configure Docker to Start on Boot

```bash
# Enable Docker service to start on boot (usually enabled by default)
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Check if Docker is running
sudo systemctl status docker
```

**Note:** On most modern Linux distributions, Docker is automatically configured to start on boot after installation.

---

## Step 2: Verify Docker Compose

Docker Compose is included as a plugin when you install Docker using the apt repository method.

**Verify Docker Compose is installed:**

```bash
# Check Docker Compose version
docker compose version
```

**Expected output:**
```
Docker Compose version v5.1.3
```

**Note:** 
- Docker Compose v5.1.3 (plugin) comes pre-installed with the `docker-compose-plugin` package
- The standalone V1 version (`docker-compose`) is deprecated and no longer recommended
- Always use `docker compose` (with space) instead of `docker-compose` (with hyphen)
- Docker Compose v5.x is part of Docker Engine 29.4.0 and uses API version 1.54

---

## Step 3: Verify Docker Installation

Run these commands to ensure Docker is properly installed:

```bash
# Check Docker version (should show 29.4.0)
docker --version

# Check Docker Compose version (should show v5.1.3)
docker compose version

# View Docker system information (should show API version 1.54)
docker info

# Test Docker with hello-world
docker run --rm hello-world

# Check running containers
docker ps

# Check all containers (including stopped)
docker ps -a

# List Docker images
docker images

# View Docker disk usage
docker system df
```

Expected output should show version numbers and successful execution of commands.

---

## Step 4: Configure SQL Server

### Navigate to Project Directory

```bash
cd ~/Developer/HPCL
# OR wherever you cloned/created the project
```

### Edit Environment Variables

```bash
# First, copy the example environment file
cp .env.example .env

# Then open .env file with your preferred editor
nano .env
# OR
vim .env
# OR
code .env
```

> **Note:** The `.env.example` file contains all available configuration options with detailed descriptions and examples. Copy it to `.env` and update with your actual values.

### Configure Required Settings

**Minimum required configuration in `.env`:**

```env
ACCEPT_EULA=Y
SA_PASSWORD=YourStrong@Password123
```

**Complete configuration with all options** (see `.env.example` for detailed descriptions):

```env
# Accept SQL Server EULA (REQUIRED)
ACCEPT_EULA=Y

# SA Password (REQUIRED - must be strong)
SA_PASSWORD=YourStrong@Password123

# SQL Server Edition (Developer, Express, Standard, Enterprise, Evaluation)
MSSQL_PID=Developer

# Enable SQL Server Agent
MSSQL_AGENT_ENABLED=true

# Default Collation
MSSQL_COLLATION=SQL_Latin1_General_CP1_CI_AS

# Memory Limit in MB
MSSQL_MEMORY_LIMIT_MB=2048

# Port Mapping
SQL_PORT=1433
```

### Password Requirements

Your SA password **MUST** meet these requirements:

✅ At least 8 characters long  
✅ Contains uppercase letters (A-Z)  
✅ Contains lowercase letters (a-z)  
✅ Contains numbers (0-9)  
✅ Contains special characters (!@#$%^&*)

**Valid password examples:**
- `MyStrong@Pass123`
- `SecureDB#2024!`
- `P@ssw0rd_SQL2019`

**Invalid password examples:**
- `password` (no uppercase, numbers, or special chars)
- `Pass123` (less than 8 chars, no special chars)
- `PASSWORD123` (no lowercase or special chars)

### Make Scripts Executable

```bash
# Make all scripts executable
chmod +x scripts/*.sh
chmod +x setup.sh
```

---

## Step 5: Deploy SQL Server

### Option A: Automated Setup (Recommended)

```bash
# Run the automated setup script
bash setup.sh
```

This script will:
1. Verify Docker installation
2. Create necessary directories
3. Pull SQL Server 2019 image
4. Start the container
5. Wait for SQL Server to be ready
6. Display connection information

### Option B: Manual Setup

```bash
# Pull the SQL Server 2019 image
docker compose pull

# Start the container in detached mode
docker compose up -d

# View logs to monitor startup
docker compose logs -f sqlserver
```

**Wait for this message in logs:**
```
SQL Server is now ready for client connections.
```

Press `Ctrl+C` to exit log view.

### Monitor Startup Progress

```bash
# Check container status
docker compose ps

# View last 50 lines of logs
docker compose logs --tail=50 sqlserver

# Check health status
docker inspect mssql-server-2019 | grep -A 5 Health
```

---

## Step 6: Verify Installation

### Check Container Status

```bash
# Verify container is running
docker ps | grep mssql

# Expected output:
# CONTAINER ID   IMAGE                                        STATUS                    PORTS
# xxxxxxxxxxxx   mcr.microsoft.com/mssql/server:2019-latest   Up X minutes (healthy)   0.0.0.0:1433->1433/tcp
```

### Connect to SQL Server

**Using the connection script:**

```bash
bash scripts/connect.sh
```

**Manual connection:**

```bash
docker exec -it mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
    -C \
    -S localhost \
    -U sa \
    -P 'YourStrong@Password123'
```

### Run Test Queries

Once connected, run these queries:

```sql
-- Check SQL Server version
SELECT @@VERSION;
GO

-- List all databases
SELECT name FROM sys.databases;
GO

-- Use the AppDB database
USE AppDB;
GO

-- List all tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
GO

-- View sample data
SELECT * FROM Users;
GO

-- Exit
EXIT
```

### Verify Volumes

```bash
# List SQL Server volumes
docker volume ls | grep mssql

# Expected output:
# mssql-2019-data
# mssql-2019-log
# mssql-2019-secrets
```

### Test Backup Functionality

```bash
# Create a test backup
bash scripts/backup.sh AppDB

# Verify backup file was created
ls -lh backups/

# Expected output: AppDB_YYYYMMDD_HHMMSS.bak
```

---

## Optional: Install SQL Server Tools

Install SQL Server command-line tools on the Ubuntu host for easier access.

### Add Microsoft Repository

```bash
# Import Microsoft GPG key
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

# Register Microsoft SQL Server Ubuntu repository for Ubuntu 24.04
curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/prod.list | \
    sudo tee /etc/apt/sources.list.d/mssql-release.list
```

### Install mssql-tools18

```bash
# Update package list
sudo apt-get update

# Install SQL Server command-line tools (version 18)
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
```

### Add to PATH

```bash
# Add to bash profile
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc

# Add to current session
export PATH="$PATH:/opt/mssql-tools18/bin"

# Reload bash profile
source ~/.bashrc
```

### Verify Installation

```bash
# Check sqlcmd version
sqlcmd -?

# Connect to SQL Server from host (use -C to trust self-signed certificate)
sqlcmd -C -S localhost,1433 -U sa -P 'YourStrong@Password123'
```

### Install Azure Data Studio (Optional GUI)

```bash
# Download Azure Data Studio
wget https://go.microsoft.com/fwlink/?linkid=2215509 -O azuredatastudio-linux.deb

# Install
sudo dpkg -i azuredatastudio-linux.deb

# Fix dependencies if needed
sudo apt-get install -f

# Launch
azuredatastudio
```

Connect using:
- **Server**: localhost,1433
- **Authentication**: SQL Login
- **User**: sa
- **Password**: (your SA password)

---

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker compose logs sqlserver
```

**Common issues:**

1. **Weak Password**
   ```
   ERROR: The sa password must be at least 8 characters
   ```
   **Solution:** Set a strong password in `.env` file

2. **Port Already in Use**
   ```
   Error: port is already allocated
   ```
   **Solution:** Check what's using port 1433:
   ```bash
   sudo netstat -tlnp | grep 1433
   # Kill the process or change SQL_PORT in .env
   ```

3. **Insufficient Memory**
   ```
   ERROR: sqlservr: This program requires a machine with at least 2000 megabytes of memory
   ```
   **Solution:** Free up RAM or increase system memory

4. **EULA Not Accepted**
   ```
   ERROR: EULA must be accepted
   ```
   **Solution:** Set `ACCEPT_EULA=Y` in `.env`

### Connection Refused

```bash
# Check if container is running
docker ps | grep mssql

# Check if port is accessible
telnet localhost 1433

# Check firewall rules
sudo ufw status

# If firewall is blocking, allow port 1433
sudo ufw allow 1433
```

### Permission Denied Errors

```bash
# Fix Docker permissions
sudo chmod 666 /var/run/docker.sock

# OR add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Scripts Not Executable

```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x setup.sh
```

### Docker Compose Command Issues

Always use the modern Docker Compose v5 (plugin) syntax:
```bash
# Correct - v5.1.3 plugin syntax (recommended)
docker compose up -d

# Deprecated - V1 standalone syntax (avoid)
docker-compose up -d
```

If `docker compose` doesn't work, ensure the plugin is installed:
```bash
sudo apt-get install -y docker-compose-plugin

# Verify installation
docker compose version
# Expected: Docker Compose version v5.1.3
```

### Health Check Failing

```bash
# Check detailed health status
docker inspect mssql-server-2019 | grep -A 20 Health

# View SQL Server error log
docker exec mssql-server-2019 cat /var/opt/mssql/log/errorlog | tail -50
```

### Reset Everything

If you need to start completely fresh:

```bash
# Stop and remove containers
docker compose down

# Remove all volumes (WARNING: DELETES ALL DATA!)
docker volume rm mssql-2019-data mssql-2019-log mssql-2019-secrets

# Remove all SQL Server images
docker rmi mcr.microsoft.com/mssql/server:2019-latest

# Start fresh
docker compose up -d
```

---

## Post-Installation Steps

### 1. Change Default Password

```sql
-- Connect as SA
USE master;
GO

-- Change SA password
ALTER LOGIN sa WITH PASSWORD = 'NewStrong@Password123';
GO
```

### 2. Create Application User

```sql
-- Create new login
CREATE LOGIN app_user WITH PASSWORD = 'AppUser@Pass123';
GO

-- Use AppDB
USE AppDB;
GO

-- Create user for the login
CREATE USER app_user FOR LOGIN app_user;
GO

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER app_user;
ALTER ROLE db_datawriter ADD MEMBER app_user;
GO
```

### 3. Set Up Automated Backups

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd ~/Developer/HPCL && bash scripts/backup.sh AppDB >> /var/log/sqlserver-backup.log 2>&1
```

### 4. Configure Monitoring

```bash
# Monitor container health
watch -n 5 'docker ps | grep mssql'

# Monitor container resources
docker stats mssql-server-2019
```

---

## Next Steps

Now that SQL Server is installed:

1. **Read the README.md** for detailed usage instructions
2. **Explore the sample database** (AppDB) with pre-populated data
3. **Test backup and restore** procedures
4. **Connect your application** using the connection strings in README
5. **Set up automated backups** for production use
6. **Review security best practices** in the documentation

---

## Quick Reference

### Essential Commands

```bash
# Start SQL Server
docker compose up -d

# Stop SQL Server
docker compose down

# View logs
docker compose logs -f

# Connect to SQL Server
bash scripts/connect.sh

# Backup database
bash scripts/backup.sh AppDB

# Restore database
bash scripts/restore.sh <backup_file> <target_db>

# Check status
docker compose ps
```

### Connection Details

- **Server**: localhost,1433
- **Username**: sa
- **Password**: (from .env file)
- **Database**: AppDB

---

## Using Makefile (Recommended)

After installation, you can use the Makefile for simplified management:

### Quick Commands

```bash
# Start SQL Server
make start

# Stop SQL Server
make stop

# Connect to database
make connect

# Backup AppDB
make backup-appdb

# Check status
make status

# View logs
make logs

# Run verification
make verify
```

### Complete Setup (Alternative to setup.sh)

```bash
make setup
```

### View All Available Commands

```bash
make help
```

### Common Operations

```bash
# Restart container
make restart

# Initialize database
make init-db

# List backups
make backup-list

# Restore backup
make restore FILE=AppDB_20260419_120000.bak DB=AppDB

# Show system info
make info

# Monitor resources
make stats
```

See **[MAKEFILE.md](MAKEFILE.md)** for complete Makefile documentation.

---

## Support & Resources

- **Project README**: `README.md` in this directory
- **Makefile Documentation**: `MAKEFILE.md` for all make commands
- **SQL Server Documentation**: https://docs.microsoft.com/en-us/sql/
- **Docker Documentation**: https://docs.docker.com/
- **Docker Install Ubuntu**: https://docs.docker.com/engine/install/ubuntu/
- **Ubuntu Help**: https://help.ubuntu.com/

---

## Installation Complete! 🎉

You now have a fully functional SQL Server 2019 instance running in Docker with:

✅ Persistent data storage  
✅ Automated initialization  
✅ Backup and restore capabilities  
✅ Sample database with data  
✅ Helper scripts for common tasks  

Start using SQL Server with:
```bash
bash scripts/connect.sh
```
