# SQL Server 2019 Deployment Checklist (Podman)

Use this checklist to ensure proper deployment of SQL Server 2019 on Podman.

## 📋 Pre-Deployment Checklist

### System Requirements
- [ ] Ubuntu 24.04 LTS or later (64-bit)
- [ ] Minimum 2GB RAM available
- [ ] Minimum 10GB free disk space
- [ ] Internet connection for downloading images
- [ ] Sudo/root access for Podman installation

### Software Prerequisites
- [ ] Podman installed and running
- [ ] Podman Compose plugin installed
- [ ] User has proper permissions (run as root or non-root with k8s-file logging)

**Verify with:**
```bash
podman --version
podman compose version
podman ps
```

---

## 🔧 Configuration Checklist

### Environment Setup
- [ ] `.env.example` file reviewed
- [ ] `.env` file created (copy from `.env.example`)
- [ ] `ACCEPT_EULA=Y` is set
- [ ] `SA_PASSWORD` is configured with a **strong password**
- [ ] Password meets requirements:
   - [ ] At least 8 characters
   - [ ] Contains uppercase letters
   - [ ] Contains lowercase letters
   - [ ] Contains numbers
   - [ ] Contains special characters
- [ ] `MSSQL_PID` set to desired edition (Developer/Express/Enterprise)
- [ ] `SQL_PORT` configured (default: 1433)
- [ ] Memory limit set appropriately (`MSSQL_MEMORY_LIMIT_MB`)

### File Permissions
- [ ] All scripts in `scripts/` are executable
- [ ] `setup.sh` is executable
- [ ] Current user has write access to project directory

**Create .env file:**
```bash
cp .env.example .env
nano .env   # Edit with your values
```

**Make executable:**
```bash
chmod +x scripts/*.sh setup.sh
```

### Directory Structure
- [ ] `queries/` directory exists
- [ ] All 3 SQL initialization scripts present:
   - [ ] `01-create-database.sql`
   - [ ] `02-create-tables.sql`
   - [ ] `03-seed-data.sql`
- [ ] `backups/` directory exists
- [ ] `scripts/` directory exists with all helper scripts:
   - [ ] `connect.sh`
   - [ ] `backup.sh`
   - [ ] `restore.sh`
   - [ ] `verify.sh`

---

## 🚀 Deployment Checklist

### Initial Deployment
- [ ] Navigate to project directory
- [ ] Copy `.env.example` to `.env`
- [ ] Review and edit `.env` file with your values
- [ ] Run setup script: `bash setup.sh`
- [ ] Wait for "SQL Server is now ready" message
- [ ] Container status shows "healthy"

**Check status:**
```bash
podman compose ps
podman inspect mssql-server-2019 | grep Health
```

### Verify Deployment
- [ ] Container is running
- [ ] Container health check passes
- [ ] Port 1433 is accessible
- [ ] Can connect via `bash scripts/connect.sh`
- [ ] AppDB database exists
- [ ] Sample tables are created
- [ ] Sample data is present
- [ ] All 2 Podman volumes created:
   - [ ] `mssql-2019-data`
   - [ ] `mssql-2019-log`

**Verify with:**
```bash
bash scripts/verify.sh
```

### Test Basic Operations
- [ ] Can connect to SQL Server
- [ ] Can query system databases
- [ ] Can query AppDB database
- [ ] Can view sample data in tables
- [ ] Can create test backup
- [ ] Can restore from backup

**Test queries:**
```sql
SELECT @@VERSION;
GO
USE AppDB;
GO
SELECT * FROM Users;
GO
```

---

## 🔒 Security Checklist

### Password Security
- [ ] Default password changed from example
- [ ] Strong password used (12+ characters recommended for production)
- [ ] Password documented in secure location (password manager)
- [ ] `.env` file NOT committed to version control
- [ ] `.env` added to `.gitignore`

### Network Security
- [ ] Port 1433 not exposed to public internet
- [ ] Firewall rules configured (if applicable)
- [ ] Only necessary ports opened
- [ ] Container network isolated if needed

### Access Control
- [ ] SA account password secured
- [ ] Application-specific users created (not using SA)
- [ ] Minimum required permissions granted
- [ ] Audit logging enabled (if required)

### Data Protection
- [ ] Backup directory secured
- [ ] Backup files encrypted (if required)
- [ ] Volume encryption configured (if required)
- [ ] TLS/SSL configured for connections (if required)

---

## 💾 Backup & Recovery Checklist

### Backup Configuration
- [ ] Backup directory accessible: `./backups/`
- [ ] Sufficient disk space for backups
- [ ] Backup script tested successfully
- [ ] Can create manual backup: `bash scripts/backup.sh`
- [ ] Backup files have correct permissions

### Automated Backups (Production)
- [ ] Cron job configured for automated backups
- [ ] Backup schedule documented
- [ ] Backup retention policy defined
- [ ] Old backups automatically cleaned up
- [ ] Backup monitoring/alerts configured

**Example cron:**
```bash
0 2 * * * cd /path/to/HPCL && bash scripts/backup.sh AppDB
```

### Recovery Testing
- [ ] Restore script tested
- [ ] Can restore to new database
- [ ] Can restore to original database
- [ ] Recovery procedure documented
- [ ] Recovery time objective (RTO) verified
- [ ] Recovery point objective (RPO) verified

---

## 📊 Monitoring Checklist

### Container Monitoring
- [ ] Container health checks working
- [ ] Can view container logs: `podman compose logs -f`
- [ ] Can monitor resource usage: `podman stats`
- [ ] Container auto-restart configured (`restart: unless-stopped`)

### SQL Server Monitoring
- [ ] Can access SQL Server error log
- [ ] Can query system DMVs
- [ ] Database sizes monitored
- [ ] Transaction log sizes monitored
- [ ] Connection counts tracked

### Alerting (Production)
- [ ] Disk space alerts configured
- [ ] Memory usage alerts configured
- [ ] Container health alerts configured
- [ ] Backup failure alerts configured
- [ ] Connection failure alerts configured

---

## 📚 Documentation Checklist

### Documentation Complete
- [ ] README.md reviewed
- [ ] INSTALL.md reviewed for installation steps
- [ ] Connection details documented
- [ ] Backup procedures documented
- [ ] Recovery procedures documented
- [ ] Troubleshooting guide reviewed

### Team Knowledge
- [ ] Team trained on deployment process
- [ ] Team knows how to connect
- [ ] Team knows how to backup/restore
- [ ] Team knows how to troubleshoot
- [ ] Emergency contacts documented
- [ ] Escalation procedures documented

---

## 🧪 Testing Checklist

### Functional Testing
- [ ] Can create databases
- [ ] Can create tables
- [ ] Can insert data
- [ ] Can query data
- [ ] Can update data
- [ ] Can delete data
- [ ] Transactions work correctly
- [ ] Stored procedures execute
- [ ] Views return data

### Performance Testing
- [ ] Query performance acceptable
- [ ] Connection pooling works
- [ ] Concurrent connections tested
- [ ] Memory usage within limits
- [ ] Disk I/O performance acceptable

### Integration Testing
- [ ] Application can connect
- [ ] Connection strings validated
- [ ] Authentication works
- [ ] Application queries execute successfully
- [ ] Error handling works

---

## 🚦 Go-Live Checklist (Production Only)

### Pre-Production
- [ ] All above checklists completed
- [ ] UAT (User Acceptance Testing) completed
- [ ] Performance testing completed
- [ ] Load testing completed
- [ ] Security audit completed
- [ ] Backup/restore tested in production-like environment

### Production Deployment
- [ ] Change management approval obtained
- [ ] Deployment window scheduled
- [ ] Rollback plan documented
- [ ] Team on standby for deployment
- [ ] Monitoring dashboard ready
- [ ] Support tickets system ready

### Post-Deployment
- [ ] Application connectivity verified
- [ ] All services functioning
- [ ] No error messages in logs
- [ ] Performance metrics baseline established
- [ ] Backup schedule verified
- [ ] Monitoring alerts tested
- [ ] Documentation updated with production details

### Production-Specific Settings
- [ ] Use paid SQL Server edition (not Developer)
- [ ] License keys configured
- [ ] Production passwords set (different from dev/test)
- [ ] Production connection strings distributed
- [ ] SSL/TLS certificates installed
- [ ] Production monitoring enabled
- [ ] Production backup schedule active

---

## ✅ Final Verification

Run the verification script:
```bash
bash scripts/verify.sh
```

### Expected Results
- All checks pass (green checkmarks)
- Container status: healthy
- SQL Server accepting connections
- AppDB database accessible
- All volumes present
- All scripts executable

### If Issues Found
1. Review error messages from verify.sh
2. Check Podman logs: `podman compose logs`
3. Review INSTALL.md troubleshooting section
4. Check system resources (RAM, disk space)
5. Verify .env configuration

---

## 📝 Sign-Off

### Development Environment
- [ ] Deployed by: ________________
- [ ] Deployment date: ________________
- [ ] Verified by: ________________
- [ ] Issues found: ________________
- [ ] Issues resolved: ________________

### Production Environment
- [ ] Change request #: ________________
- [ ] Deployed by: ________________
- [ ] Deployment date/time: ________________
- [ ] Verified by: ________________
- [ ] Approved by: ________________
- [ ] Database administrator sign-off: ________________
- [ ] Application owner sign-off: ________________

---

## 🔄 Maintenance Checklist (Ongoing)

### Daily
- [ ] Check container is running: `podman compose ps`
- [ ] Review error logs for issues
- [ ] Monitor disk space

### Weekly
- [ ] Review backup success
- [ ] Clean old backup files
- [ ] Check database sizes
- [ ] Review performance metrics

### Monthly
- [ ] Update SQL Server image (if patches available)
- [ ] Review security settings
- [ ] Test backup restore
- [ ] Review and update documentation
- [ ] Audit user access

### Quarterly
- [ ] Full disaster recovery test
- [ ] Performance optimization review
- [ ] Capacity planning review
- [ ] Security audit

---

## 📞 Support & Escalation

### Support Resources
- Documentation: `/HPCL/README.md`
- SQL Server Docs: https://docs.microsoft.com/en-us/sql/
- Podman Docs: https://podman.io/

### Escalation Path
1. Check documentation
2. Review logs: `podman compose logs`
3. Run verify script: `bash scripts/verify.sh`
4. Contact: ________________ (Database Administrator)
5. Emergency contact: ________________

---

**Checklist Version:** 1.0.0  
**Last Updated:** 2024  
**Next Review:** ________________