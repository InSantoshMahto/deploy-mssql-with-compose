# SQL Server 2019 Podman Setup

Run SQL Server 2019 in a Podman container with persistent storage, automated initialization, backup/restore scripts, and a pre-populated sample database.

## Table of Contents

- [📋 Prerequisites](#-prerequisites)
- [📁 Project Structure](#-project-structure)
- [🚀 Quick Start Guide](#-quick-start-guide)
- [🔧 Configuration](#-configuration)
- [🎓 What You'll Get](#-what-youll-get)
- [🗄️ Database Management](#️-database-management)
- [🧪 Test the Setup](#-test-the-setup)
- [🎮 Essential Commands](#-essential-commands)
- [⚙️ Podman Commands](#️-podman-commands)
- [📊 Volume Management](#-volume-management)
- [🔍 Monitoring & Troubleshooting](#-monitoring--troubleshooting)
- [📝 Sample Database Schema](#-sample-database-schema)
- [❓ Common Questions](#-common-questions)
- [🔒 Security Best Practices](#-security-best-practices)
- [🔄 Automated Backups with Cron](#-automated-backups-with-cron)
- [🌐 Connecting from Applications](#-connecting-from-applications)
- [🆘 Need Help?](#-need-help)
- [📖 Learn More](#-learn-more)
- [📚 Additional Resources](#-additional-resources)
- [📄 License](#-license)
- [🤝 Support](#-support)
- [🚦 Next Steps](#-next-steps)
- [📋 Changelog](#-changelog)


## 📋 Prerequisites

- **Operating System**: Ubuntu 24.04 LTS or later (64-bit)
- **RAM**: Minimum 2GB, Recommended 4GB+
- **Disk Space**: Minimum 10GB free space
- **Podman**: Installed and configured
- **Internet Connection**: For downloading SQL Server image

## 📁 Project Structure

```
├── compose.yaml              # Podman Compose configuration file
├── setup.sh                  # Automated setup script
├── .env.example              # Environment variables template
├── .gitignore               # Git ignore rules
├── INSTALL.md               # Installation guide
├── README.md                # This file
├── CHECKLIST.md             # Deployment checklist
├── Makefile                 # Command wrapper
├── Makefile.md              # Makefile documentation
├── queries/                 # Database initialization scripts
│   ├── 01-create-database.sql
│   ├── 02-create-tables.sql
│   └── 03-seed-data.sql
├── backups/                 # Database backup files
├── scripts/                 # Helper scripts
│   ├── connect.sh
│   ├── backup.sh
│   ├── restore.sh
│   ├── verify.sh
│   └── init-db.sh
```

## 🚀 Quick Start Guide

### 1. Install Podman (if not already installed)

**If you don't have Podman installed**, follow the installation guide in [INSTALL.md](INSTALL.md#step-1-install-podman).

**If you already have Podman**, verify it's working:

```bash
# Check Podman is installed
podman --version

# Test Podman with hello-world
podman run --rm hello-world
```

### 2. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env file and change the SA password
nano .env

# IMPORTANT: Use a strong password!
# Example: SA_PASSWORD=YourStrong@Password123
```

### 3. Make Scripts Executable

```bash
chmod +x scripts/*.sh
chmod +x setup.sh
```

### 4. Run Setup

```bash
# Automated setup
bash setup.sh

# OR manually start
podman compose up -d
```

### 5. Verify Installation

```bash
# Run verification script
bash scripts/verify.sh

# OR manually check
podman compose ps
podman compose logs -f sqlserver
bash scripts/connect.sh
```

## 🔧 Configuration

### Environment Variables (.env)

> **Note:** Copy `.env.example` to `.env` and update with your values.

```bash
cp .env.example .env
nano .env   # Edit with your values
```

| Variable | Default | Description |
|----------|---------|-------------|
| `ACCEPT_EULA` | Y | Accept SQL Server EULA (required) |
| `SA_PASSWORD` | - | SA user password (**REQUIRED** - must be strong) |
| `MSSQL_PID` | Developer | SQL Server edition (Developer, Express, Standard, Enterprise) |
| `MSSQL_AGENT_ENABLED` | true | Enable SQL Server Agent |
| `MSSQL_COLLATION` | SQL_Latin1_General_CP1_CI_AS | Default collation |
| `MSSQL_MEMORY_LIMIT_MB` | 2048 | Memory limit in MB |
| `SQL_PORT` | 1433 | SQL Server port mapping |

**See `.env.example` for detailed descriptions and examples of all available configuration options.**

### 🔑 Password Requirements

The SA password **MUST** meet these requirements:

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

## 🎓 What You'll Get

After setup, you'll have:

### 1. Running SQL Server 2019
- Container name: `mssql-server-2019`
- Port: `1433` (configurable via `.env`)
- Edition: Developer (free, fully featured)
- Memory: Configurable via `MSSQL_MEMORY_LIMIT_MB`

### 2. Sample Database (AppDB)
Pre-populated with realistic data:
- **Users** table (5 sample users)
- **Categories** table (5 categories)
- **Products** table (11 products)
- **Orders** table (5 orders)
- **OrderItems** table (order details)
- **Views** for reporting
- **Stored procedures** for search

### 3. Persistent Storage
Your data survives container restarts:
- `mssql-2019-data` - Database files (.mdf)
- `mssql-2019-log` - Transaction logs (.ldf)
- `./backups/` - Backup files (mapped to host directory)

## 🗄️ Database Management

### Connect to SQL Server

**Using the helper script:**
```bash
bash scripts/connect.sh
```

**From host (if sqlcmd is installed):**
```bash
sqlcmd -S localhost,1433 -U sa -P 'YourPassword'
```

**Using Podman exec:**
```bash
podman exec -it mssql-server-2019 /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P 'YourPassword'
```

### Create Backup

**Using the helper script:**
```bash
# Backup default database (AppDB)
bash scripts/backup.sh

# Backup specific database
bash scripts/backup.sh MyDatabase
```

**Manual backup (SQL):**
```sql
BACKUP DATABASE AppDB 
TO DISK = '/var/opt/mssql/backups/AppDB_manual.bak'
WITH FORMAT, COMPRESSION;
GO
```

### Restore from Backup

**Using the helper script:**
```bash
# List available backups
ls -lh backups/

# Restore to new database
bash scripts/restore.sh AppDB_20240101_120000.bak AppDB_Restored

# Restore to original database (overwrites existing)
bash scripts/restore.sh AppDB_20240101_120000.bak AppDB
```

## 🧪 Test the Setup

Once connected, try these queries:

```sql
-- Check version
SELECT @@VERSION;
GO

-- Use sample database
USE AppDB;
GO

-- View all users
SELECT * FROM Users;
GO

-- View products with categories
SELECT p.ProductName, p.Price, c.CategoryName
FROM Products p
JOIN Categories c ON p.CategoryId = c.CategoryId;
GO

-- View order summary
SELECT * FROM vw_OrderSummary;
GO

-- Search for products
EXEC sp_SearchProducts @SearchTerm = 'Laptop';
GO

-- View order details
SELECT 
    o.OrderId,
    u.Username,
    o.OrderDate,
    p.ProductName,
    oi.Quantity,
    oi.UnitPrice,
     (oi.Quantity * oi.UnitPrice) AS LineTotal
FROM Orders o
INNER JOIN Users u ON o.UserId = u.UserId
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
INNER JOIN Products p ON oi.ProductId = p.ProductId
WHERE o.OrderId = 1;
GO
```

## 🎮 Essential Commands

```bash
# Start SQL Server
podman compose up -d

# Stop SQL Server
podman compose down

# View logs
podman compose logs -f

# Check status
podman compose ps

# Connect to database
bash scripts/connect.sh

# Backup database
bash scripts/backup.sh AppDB

# Restore database
bash scripts/restore.sh <backup-file> <target-db>

# Verify installation
bash scripts/verify.sh

# Restart SQL Server
podman compose restart
```

## ⚙️ Podman Commands

```bash
# Start services
podman compose up -d

# Stop services
podman compose down

# Restart services
podman compose restart

# View logs (follow mode)
podman compose logs -f

# View last 100 lines
podman compose logs --tail=100 sqlserver

# Check container status
podman compose ps

# Execute bash in container
podman exec -it mssql-server-2019 bash
```

### Complete Cleanup

```bash
# Stop and remove containers (keeps volumes)
podman compose down

# Stop and remove everything including volumes (DELETES ALL DATA!)
podman compose down -v

# Remove specific volumes
podman volume rm mssql-2019-data mssql-2019-log
```

## 📊 Volume Management

### Volume Information

Podman volumes store persistent data:
- **mssql-2019-data**: Database files (.mdf)
- **mssql-2019-log**: Transaction log files (.ldf)
- `./backups/`: Backup files (mapped to host directory)

### Volume Commands

```bash
# List all SQL Server volumes
podman volume ls | grep mssql

# Inspect volume details
podman volume inspect mssql-2019-data

# Check volume disk usage
podman system df -v | grep mssql

# Backup entire volume to tar file
podman run --rm \
     -v mssql-2019-data:/data \
     -v $(pwd)/volume-backups:/backup \
    ubuntu tar czf /backup/mssql-data-$(date +%Y%m%d).tar.gz -C /data .
```

### Volume Locations (Inside Container)

- Data files: `/var/opt/mssql/data`
- Log files: `/var/opt/mssql/log`
- Backups: `/var/opt/mssql/backups` (mapped to `./backups` on host)

## 🔍 Monitoring & Troubleshooting

### Health Checks

```bash
# Run verification script (recommended)
bash scripts/verify.sh

# Check container health status
podman inspect mssql-server-2019 | grep -A 10 Health

# View SQL Server error log
podman exec mssql-server-2019 cat /var/opt/mssql/log/errorlog

# Monitor container resources
podman stats mssql-server-2019
```

### SQL Server Information

```sql
-- Check SQL Server version
SELECT @@VERSION;
GO

-- Check SQL Server properties
SELECT SERVERPROPERTY('ProductVersion') AS Version,
       SERVERPROPERTY('ProductLevel') AS Level,
       SERVERPROPERTY('Edition') AS Edition;
GO

-- View server configuration
EXEC sp_configure;
GO

-- Check memory usage
SELECT 
     (physical_memory_in_use_kb/1024) AS Memory_usedby_Sqlserver_MB,
     (locked_page_allocations_kb/1024) AS Locked_pages_used_Sqlserver_MB,
     (total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,
    process_physical_memory_low,
    process_virtual_memory_low
FROM sys.dm_os_process_memory;
GO

-- List all databases
SELECT name, database_id, create_date 
FROM sys.databases
ORDER BY name;
GO

-- Check database sizes
SELECT 
    DB_NAME(database_id) AS DatabaseName,
     (size * 8.0 / 1024) AS SizeMB
FROM sys.master_files
ORDER BY DatabaseName;
GO

-- Check active connections
SELECT 
    DB_NAME(dbid) as DatabaseName,
    COUNT(dbid) as NumberOfConnections
FROM sys.sysprocesses
WHERE dbid > 0
GROUP BY dbid;
GO
```

### Common Issues

#### Container won't start

```bash
# Check logs for errors
podman compose logs

# Common causes:
# 1. Weak SA password - must meet complexity requirements
# 2. Port 1433 already in use - check with: sudo netstat -tlnp | grep 1433
# 3. Insufficient memory - need at least 2GB RAM
# 4. EULA not accepted - set ACCEPT_EULA=Y in .env
```

#### Can't connect to SQL Server

```bash
# Verify container is running
podman ps | grep mssql

# Check port binding
podman port mssql-server-2019

# Test network connectivity
telnet localhost 1433

# Check firewall (if applicable)
sudo ufw status

# Wait 30 seconds - SQL Server takes time to initialize
```

#### Reset Everything

```bash
# Complete cleanup and fresh start
podman compose down -v
podman volume rm mssql-2019-data mssql-2019-log
bash setup.sh
```

## 📝 Sample Database Schema

The initialization scripts create an **AppDB** database with the following schema:

### Tables

- **Users**: User accounts and profiles
- **Categories**: Product categories
- **Products**: Product catalog
- **Orders**: Customer orders
- **OrderItems**: Order line items

### Views

- **vw_OrderSummary**: Summary of orders with user information

### Stored Procedures

- **sp_SearchProducts**: Search products by name, category, and price range

## ❓ Common Questions

### Q: Do I need to install SQL Server on my machine?
**A:** No! Everything runs in Podman. You only need Podman installed.

### Q: Will my data be lost when I stop the container?
**A:** No! Data is stored in Podman volumes and persists across restarts.

### Q: Can I use this in production?
**A:** The setup is production-ready, but:
- Change the SA password to a strong, unique password
- Consider using a paid SQL Server edition (not Developer)
- Set up automated backups with monitoring
- Review and harden security settings
- Follow the deployment checklist in CHECKLIST.md

### Q: How do I backup my data?
**A:** Use the backup script: `bash scripts/backup.sh AppDB`

### Q: How much disk space do I need?
**A:** Minimum 10GB free space recommended for the container, database, and backups.

### Q: Can I change the port?
**A:** Yes! Edit `SQL_PORT=1433` in the `.env` file.

### Q: How do I connect from my application?
**A:** See the "Connecting from Applications" section below for connection strings.

## 🔒 Security Best Practices

1. **Change Default Password**
    - Never use default passwords in production
    - Use a password manager to generate strong passwords
    - Use different passwords for different environments

2. **Environment Variables**
    - Never commit `.env` file to version control (already in .gitignore)
    - Store production credentials securely
    - Rotate passwords regularly

3. **Network Security**
    - Don't expose port 1433 to the public internet
    - Use firewall rules to restrict access
    - Consider using Podman networks for service-to-service communication
    - Enable TLS/SSL for connections in production

4. **Regular Updates**
    - Keep SQL Server image updated
    - Monitor Microsoft security advisories
    - Test updates in non-production environments first

5. **Backup Strategy**
    - Automate backups with cron jobs
    - Store backups in secure, off-site location
    - Test restore procedures regularly
    - Implement backup retention policies

6. **Access Control**
    - Create application-specific users instead of using SA
    - Grant minimum required permissions (principle of least privilege)
    - Use strong authentication
    - Enable audit logging for sensitive operations

## 🔄 Automated Backups with Cron

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd ~/deploy-mssql-with-compose && bash scripts/backup.sh AppDB >> /var/log/sqlserver-backup.log 2>&1

# Add weekly backup rotation (keep last 4 weeks)
0 3 * * 0 find ~/deploy-mssql-with-compose/backups -name "*.bak" -mtime +28 -delete
```

## 🌐 Connecting from Applications

### .NET Connection String

```csharp
Server=localhost,1433;Database=AppDB;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=True;
```

### Python (pyodbc)

```python
import pyodbc

conn = pyodbc.connect(
     'DRIVER={ODBC Driver 17 for SQL Server};'
     'SERVER=localhost,1433;'
     'DATABASE=AppDB;'
     'UID=sa;'
     'PWD=YOUR_PASSWORD;'
     'TrustServerCertificate=yes;'
)
```

### Node.js (mssql)

```javascript
const sql = require('mssql');

const config = {
    server: 'localhost',
    port: 1433,
    database: 'AppDB',
    user: 'sa',
    password: 'YOUR_PASSWORD',
    options: {
        encrypt: true,
        trustServerCertificate: true
     }
};

const pool = await sql.connect(config);
```

### Java (JDBC)

```java
String connectionUrl = "jdbc:sqlserver://localhost:1433;" +
     "databaseName=AppDB;" +
     "user=sa;" +
     "password=YOUR_PASSWORD;" +
     "encrypt=true;" +
     "trustServerCertificate=true;";

Connection conn = DriverManager.getConnection(connectionUrl);
```

## 🆘 Need Help?

### Container won't start?
```bash
podman compose logs
```
Common causes: weak password, port in use, insufficient RAM

### Can't connect?
```bash
podman ps | grep mssql
bash scripts/verify.sh
```
Wait 30-60 seconds - SQL Server takes time to initialize

### Want to reset everything?
```bash
podman compose down -v
bash setup.sh
```

## 📖 Learn More

- **Complete Installation Guide** → [INSTALL.md](INSTALL.md)
- **Deployment Checklist** → [CHECKLIST.md](CHECKLIST.md)
- **SQL Server Docs** → https://docs.microsoft.com/en-us/sql/
- **Podman Docs** → https://podman.io/

## 📚 Additional Resources

- [SQL Server 2019 Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)
- [Podman SQL Server Guide](https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-podman)
- [SQL Server on Linux](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-overview)
- [T-SQL Reference](https://docs.microsoft.com/en-us/sql/t-sql/language-reference)
- [Podman Compose Documentation](https://podman.io/docs/compose-file)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Support

- **Issues/Bugs**: Open an issue on GitHub
- **Questions**: Check INSTALL.md troubleshooting section
- **Production Issues**: Review CHECKLIST.md deployment checklist

## 🚦 Next Steps

After SQL Server is up and running:

1. Explore the sample database (AppDB)
2. Test backup and restore procedures
3. Connect your application using connection strings in README
4. Set up automated backups for production use
5. Review security best practices in this documentation

## 📋 Changelog

### Version 1.0.0
- Initial release with SQL Server 2019 on Podman
- Sample database (AppDB) included
- Backup and restore scripts
- Makefile support
