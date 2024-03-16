USE [master];
GO

IF NOT EXISTS (SELECT *
FROM sys.sql_logins
WHERE name = 'newuser')
BEGIN
    CREATE LOGIN [newuser] WITH PASSWORD = 'password123', CHECK_POLICY = OFF;
    ALTER SERVER ROLE [sysadmin] ADD MEMBER [newuser];
END
GO
