# Makefile Documentation

Simple wrapper commands for managing SQL Server 2019 Docker deployment.

## Overview

The Makefile provides convenient shortcuts for running shell scripts and common Docker Compose commands. It's a thin wrapper that makes common operations easier to remember and execute.

---

## Quick Reference

```bash
make help          # Show all available commands
make setup         # Run complete setup
make start         # Start SQL Server
make connect       # Connect to database
make backup        # Backup database
make verify        # Run health checks
```

---

## Available Commands

### Setup & Initialization

#### `make setup`
Run complete setup script.

**Executes:** `bash setup.sh`

**What it does:**
- Checks Docker installation
- Creates directory structure
- Sets up environment
- Starts container
- Initializes database

**Usage:**
```bash
make setup
```

---

#### `make init-db`
Initialize or reinitialize database.

**Executes:** `bash scripts/init-db.sh`

**What it does:**
- Runs SQL scripts from `queries/` directory
- Creates AppDB database
- Creates tables
- Inserts sample data

**Usage:**
```bash
make init-db
```

---

### Container Management

#### `make start`
Start SQL Server container.

**Executes:** `docker compose up -d`

**Usage:**
```bash
make start
```

---

#### `make stop`
Stop SQL Server container.

**Executes:** `docker compose down`

**Usage:**
```bash
make stop
```

---

#### `make restart`
Restart SQL Server container.

**Executes:** `docker compose restart`

**Usage:**
```bash
make restart
```

---

#### `make status` / `make ps`
Show container status.

**Executes:** `docker compose ps`

**Usage:**
```bash
make status
# or
make ps
```

**Example output:**
```
NAME                IMAGE                           STATUS                   PORTS
mssql-server-2019   mcr.microsoft.com/mssql/...    Up 5 minutes (healthy)   0.0.0.0:1433->1433/tcp
```

---

#### `make logs`
View container logs in follow mode.

**Executes:** `docker compose logs -f`

**Usage:**
```bash
make logs
```

Press `Ctrl+C` to exit.

---

#### `make health`
Check container health status.

**Executes:** `docker inspect --format='{{.State.Health.Status}}' mssql-server-2019`

**Usage:**
```bash
make health
```

**Possible outputs:**
- `healthy` - Container is running properly
- `starting` - Container is initializing
- `unhealthy` - Health check is failing
- `Container not running` - Container is stopped

---

### Database Operations

#### `make connect`
Connect to SQL Server using sqlcmd.

**Executes:** `bash scripts/connect.sh`

**Usage:**
```bash
make connect
```

Opens an interactive SQL session where you can run queries.

---

#### `make backup`
Backup a database.

**Executes:** `bash scripts/backup.sh DatabaseName`

**Usage:**
```bash
# Backup specific database
make backup AppDB

# Backup custom database
make backup MyDatabase
```

**What it creates:**
```
backups/DatabaseName_YYYYMMDD_HHMMSS.bak
```

---

#### `make restore`
Restore database from backup.

**Executes:** `bash scripts/restore.sh backup_file.bak TargetDatabase`

**Usage:**
```bash
make restore backup_file.bak TargetDatabase
```

**Example:**
```bash
# Just use the filename (not full path)
make restore AppDB_20260419_120000.bak AppDB_Restored
```

---

#### `make verify`
Run system verification checks.

**Executes:** `bash scripts/verify.sh`

**Usage:**
```bash
make verify
```

**What it checks:**
- Docker installation
- Container status
- SQL Server connectivity
- Database existence
- Volume status
- Script permissions

---

### Cleanup

#### `make clean`
Stop and remove containers (keeps volumes and data).

**Executes:** `docker compose down`

**Usage:**
```bash
make clean
```

**Preserves:**
- Database volumes (data, logs, secrets)
- Backup files
- Docker images

---

#### `make clean-all`
Stop and remove containers AND volumes.

**⚠️ WARNING:** This deletes all database data!

**Executes:** `docker compose down -v`

**Usage:**
```bash
make clean-all
```

**Deletes:**
- Containers
- All volumes (database data, logs, secrets)

**Preserves:**
- Backup files
- Docker images

---

## Common Workflows

### First Time Setup

```bash
# 1. View available commands
make help

# 2. Run complete setup
make setup

# 3. Verify everything works
make verify
```

---

### Daily Development

```bash
# Start SQL Server
make start

# Connect and work with database
# Work with database
make connect

# Backup when done
make backup AppDB

# Stop SQL Server
make stop
```

---

### Troubleshooting

```bash
# Check status
make status

# Check health
make health

# View logs
make logs

# Run verification
make verify
```

---

## Direct Script Usage

All Makefile commands simply wrap shell scripts. You can also run scripts directly:

```bash
# Instead of make commands, use scripts directly:
bash setup.sh
bash scripts/connect.sh
bash scripts/backup.sh AppDB
bash scripts/restore.sh AppDB_20260419_120000.bak TargetDB
bash scripts/verify.sh
bash scripts/init-db.sh
```

---

## Docker Compose Commands

The Makefile wraps these Docker Compose commands:

| Make Command | Docker Compose Command |
|--------------|------------------------|
| `make start` | `docker compose up -d` |
| `make stop` | `docker compose down` |
| `make restart` | `docker compose restart` |
| `make status` | `docker compose ps` |
| `make logs` | `docker compose logs -f` |
| `make clean` | `docker compose down` |
| `make clean-all` | `docker compose down -v` |

You can use either the Makefile commands or Docker Compose commands directly.

---

## Examples

### Complete Setup and Verification

```bash
make setup
make verify
```

---

### Daily Operations

```bash
# Morning - start SQL Server
make start
make status

# Work with database
make connect

# Afternoon - backup
make backup DB=AppDB

# Evening - stop
make stop
```

---

### Backup and Restore

```bash
# Create backup
make backup AppDB

# Restore to new database
make restore AppDB_20260419_120000.bak TestDB

# Restore over existing database
make restore AppDB_20260419_120000.bak AppDB
```

---

### Reset Everything

```bash
# Complete reset (deletes all data)
make clean-all

# Start fresh
make start
make init-db
make verify
```

---

## Tips

1. **Use `make help` to see all commands**
   ```bash
   make help
   ```

2. **Tab completion works with make**
   ```bash
   make st<TAB>  # completes to 'make start'
   ```

3. **Chain commands if needed**
   ```bash
   make start && make verify
   ```

4. **Use scripts directly for more control**
   ```bash
   bash scripts/backup.sh AppDB
   bash scripts/backup.sh MyDatabase
   ```

---

## Summary

The Makefile provides:
- ✅ Simple wrapper for shell scripts
- ✅ Easy-to-remember command names
- ✅ Quick access to common operations
- ✅ No duplication of script functionality
- ✅ Direct Docker Compose commands when needed

**Main commands:**
```bash
make setup                        # First time setup
make start                        # Start container
make stop                         # Stop container
make connect                      # Connect to SQL
make backup AppDB                 # Backup database
make restore backup.bak TargetDB  # Restore database
make verify                       # Health checks
make clean                        # Remove containers
```

For detailed information about what each script does, see:
- **README.md** - Main documentation
- **INSTALL.md** - Installation guide
- Individual script files in `scripts/` directory

---

**Version:** 2.0.0 (Simplified)  
**Last Updated:** 2024