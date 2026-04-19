-- =============================================
-- Create Application Database
-- =============================================

USE master;
GO

-- Drop database if exists (for testing only)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'AppDB')
BEGIN
    ALTER DATABASE AppDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AppDB;
END
GO

-- Create new database
CREATE DATABASE AppDB
ON PRIMARY
(
    NAME = AppDB_Data,
    FILENAME = '/var/opt/mssql/data/AppDB.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = AppDB_Log,
    FILENAME = '/var/opt/mssql/data/AppDB_log.ldf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 10MB
);
GO

-- Set recovery model
ALTER DATABASE AppDB SET RECOVERY SIMPLE;
GO

PRINT 'Database AppDB created successfully';
GO
