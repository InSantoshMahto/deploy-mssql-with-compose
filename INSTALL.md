# SQL Server 2019 Installation Guide for Podman

Complete step-by-step installation guide for setting up SQL Server 2019 with Podman on Ubuntu/Linux systems.

## Table of Contents

- [System Requirements](#system-requirements)
- [Step 1: Install Podman](#step-1-install-podman)
- [Step 2: Verify Podman Compose](#step-2-verify-podman-compose)
- [Step 3: Verify Podman Installation](#step-3-verify-podman-installation)
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

## Step 1: Install Podman

### Install Using Official Repository (Ubuntu 24.04)

**1. Download the Podman repository key:**

```bash
curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_24.04/Release.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/podman.gpg > /dev/null
```

**2. Add the Podman Apt Repository:**

```bash
# Add Podman's official Kubic repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/podman.gpg] \
  https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_24.04/ /" \
  | sudo tee /etc/apt/sources.list.d/podman.list > /dev/null

# Update package list
sudo apt-get update
```

**3. Install Podman packages:**

```bash
# Install Podman with compose plugin
sudo apt-get install -y podman podman-compose
```

### Configure Podman to Start on Boot

```bash
# Check if Podman service is running
systemctl status podman.socket

# Enable Podman service to start on boot (usually enabled by default)
sudo systemctl enable podman.socket
```

---

## Step 2: Verify Podman Compose

Podman Compose is included when you install `podman-compose` package.

**Verify Podman Compose is installed:**

```bash
# Check Podman Compose version
podman compose version
```

**Expected output:**
```
podman-compose version 1.x.x
```

---

## Step 3: Verify Podman Installation

Run these commands to ensure Podman is properly installed:

```bash
# Check Podman version
podman --version

# Check Podman Compose version
podman compose version

# Test Podman with hello-world
podman run --rm hello-world

# Check running containers
podman ps

# Check all containers (including stopped)
podman ps -a

# List Podman images
podman images

# View Podman disk usage
podman system df
```

Expected output should show version numbers and successful execution of commands.

---

## Step 4: Configure SQL Server

### Navigate to Project Directory

```bash
cd ~/deploy-mssql-with-compose
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
1. Verify Podman installation
2. Create necessary directories
3. Pull SQL Server 2019 image
4. Start the container
5. Wait for SQL Server to be ready
6. Display connection information

### Option B: Manual Setup

```bash
# Pull the SQL Server 2019 image
podman compose pull

# Start the container in detached mode
podman compose up -d

# View logs to monitor startup
podman compose logs -f sqlserver
```

**Wait for this message in logs:**
```
SQL Server is now ready for client connections.
```

Press `Ctrl+C` to exit log view.

### Monitor Startup Progress

```bash
# Check container status
podman ps

# View last 50 lines of logs
podman compose logs --tail=50 sqlserver

# Check health status
podman inspect mssql-server-2019 | grep -A 5 Health
```

---

## Step 6: Verify Installation

### Check Container Status

```bash
# Verify container is running
podman ps | grep mssql

# Expected output:
# CONTAINER ID   IMAGE                                        STATUS                    PORTS
# xxxxxxxxxxxx   mcr.microsoft.com/mssql/server:2019-latest   Up X minutes (healthy)    0.0.0.0:1433->1433/tcp
```

### Connect to SQL Server

**Using the connection script:**

```bash
bash scripts/connect.sh
```

**Manual connection:**

```bash
podman exec -it mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd \
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
podman volume ls | grep mssql

# Expected output:
# mssql-2019-data
# mssql-2019-log
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
podman compose logs sqlserver
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
podman ps | grep mssql

# Check if port is accessible
telnet localhost 1433

# Check firewall rules
sudo ufw status

# If firewall is blocking, allow port 1433
sudo ufw allow 1433
```

### Permission Denied Errors

**Note:** Podman uses SELinux/AppArmor by default and supports rootless operation via `/run/user/$(id -u)/podman/podman.sock`. Instead:

```bash
# Check if running as root
whoami

# If not root, ensure proper permissions in compose.yaml
# Restart the container with appropriate privileges
sudo podman compose up -d
```

### Podman Compose Command Issues

Always use the modern Podman Compose v5 (plugin) syntax:
```bash
# Correct - v5.1.3 plugin syntax (recommended)
podman compose up -d

# Avoid using standalone podman-compose (deprecated)
# podman-compose up -d
```

# Verify installation
podman compose version
# Expected: Podman Compose version v2.x.x
```

### Health Check Failing

```bash
# Check detailed health status
podman inspect mssql-server-2019 | grep -A 20 Health

# View SQL Server error log
podman exec mssql-server-2019 cat /var/opt/mssql/log/errorlog | tail -50
```

### Reset Everything

If you need to start completely fresh:

```bash
# Stop and remove containers
podman compose down

# Remove all volumes (WARNING: DELETES ALL DATA!)
podman volume rm mssql-2019-data mssql-2019-log

# Remove all SQL Server images
podman rmi mcr.microsoft.com/mssql/server:2019-latest

# Start fresh
podman compose up -d
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
0 2 * * * cd ~/deploy-mssql-with-compose && bash scripts/backup.sh AppDB >> /var/log/sqlserver-backup.log 2>&1
```

### 4. Configure Monitoring

```bash
# Monitor container health
watch -n 5 'podman ps | grep mssql'

# Monitor container resources
podman stats mssql-server-2019
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
podman compose up -d

# Stop SQL Server
podman compose down

# View logs
podman compose logs -f

# Connect to SQL Server
bash scripts/connect.sh

# Backup database
bash scripts/backup.sh AppDB

# Restore database
bash scripts/restore.sh <backup_file> <target_db>

# Check status
podman compose ps
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
make backup AppDB

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

# Restore backup
make restore AppDB_20260419_120000.bak AppDB

# Monitor resources
make stats
```

See **[MAKEFILE.md](MAKEFILE.md)** for complete Makefile documentation.

---

## Support & Resources

- **Project README**: `README.md` in this directory
- **Makefile Documentation**: `MAKEFILE.md` for all make commands
- **SQL Server Documentation**: https://docs.microsoft.com/en-us/sql/
- **Podman Documentation**: https://podman.io/
- **Ubuntu Help**: https://help.ubuntu.com/

---

## Installation Complete! 🎉

You now have a fully functional SQL Server 2019 instance running in Podman with:

✅ Persistent data storage  
✅ Automated initialization  
✅ Backup and restore capabilities  
✅ Sample database with data  
✅ Helper scripts for common tasks  

Start using SQL Server with:
```bash
bash scripts/connect.sh
```
</think>
