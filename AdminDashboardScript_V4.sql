USE [DYNAMICS]	--<<<<<<< CHANGE TO YOUR SYSTEM DATABASE NAME (usually DYNAMICS)
-- USE CTRL+H in SSMS to replace DYNAMICS by your real System DB name if not default.
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*-- =============================================
-- Title: AdminDashboardScript
-- Author: Steve Erbach & Beat Bucher
-- Create date: 6-Mar-2018
-- Description:	Query the SY05000 table for GP Activity.
-- Revised: 17:21 2024-09-25
-- Revision: V1 - Removed ORDER BY clause.
--			 V2 - Enhanced the code with DROP statements and modified 24hrs tracking
--			 V3 - Added new views & sp for User activities, plus emeUserCount table (BB)
--				  for long-term license tracking. Granted SELECT to ACTIVITY TABLE
--			 v4 - Added missing views from the old version to simplify queries (vwOpenBatches, vwResourcesinUse,
--					vwProcessesbyUser, vwSessions)
-- NOTE: This procedure uses the FORMAT function.
--		  Will not work in SQL versions before 2012.
-- NOTE: This procedure also uses the DATE data type 
-- 		  and the TIME data type.
--		  Will not work in SQL versions before 2012.
-- WARNING:  If you want to use this on prior SQL version, 
--		  you'll need to comment out the proper line (see inline comment)
--        in [usp24hrActivityTracking] and comment out the entire section 
--		  of the code for [usp24hrActivityTracking2]
-- =============================================*/
/******************************************************************************
** Execute ths current script under the 'sa' account or a domain user 
** that does have sysadmin or dbcreator SQL role permissions.
******************************************************************************/
-- Delete Prior version of the SP's, Tables and functions if EXISTS
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'Track_activity_code')
DROP TABLE Track_activity_code
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'FiveMins')
DROP TABLE FiveMins
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'udfDatediffToWords')
DROP FUNCTION udfDatediffToWords
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp24hrActivityTracking')
DROP PROCEDURE usp24hrActivityTracking
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp24hrActivityTracking2')
DROP PROCEDURE usp24hrActivityTracking2
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'uspFillTempSY00500Table')
DROP PROCEDURE uspFillTempSY00500Table
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'uspLocksInUse')
DROP PROCEDURE uspLocksInUse
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'uspFillTempActiveBatchesTable')
DROP PROCEDURE uspFillTempActiveBatchesTable
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'uspGPUserList')
DROP PROCEDURE uspGPUserList
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vwDashboardUsers')
DROP VIEW vwDashboardUsers
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw12HourActivity')
DROP VIEW vw12HourActivity
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw16DayActivity')
DROP VIEW vw16DayActivity
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vwOpenBatches')
DROP VIEW vwOpenBatches
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vwResourcesinUse')
DROP VIEW vwResourcesinUse
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vwSessions')
DROP VIEW vwSessions
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vwProcessesbyUser')
DROP VIEW vwProcessesbyUser
GO


/******************************************************************************
***** Object:  Table [dbo].[FiveMins]    Script Date: 9/2/2021 8:30:21 PM *****
******************************************************************************/

-- Create the 5 minutes table for the final query in usp24hrActivityTracking2

CREATE TABLE [dbo].[FiveMins]
(
	[FiveMinPeriod] [time](7) NOT NULL
 , CONSTRAINT [PK_FiveMins] PRIMARY KEY CLUSTERED([FiveMinPeriod] ASC)
	WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
ON [PRIMARY];
GO


SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
INSERT INTO [dbo].[FiveMins]([FiveMinPeriod])
SELECT '00:00:00' UNION ALL
SELECT '00:05:00' UNION ALL
SELECT '00:10:00' UNION ALL
SELECT '00:15:00' UNION ALL
SELECT '00:20:00' UNION ALL
SELECT '00:25:00' UNION ALL
SELECT '00:30:00' UNION ALL
SELECT '00:35:00' UNION ALL
SELECT '00:40:00' UNION ALL
SELECT '00:45:00' UNION ALL
SELECT '00:50:00' UNION ALL
SELECT '00:55:00' UNION ALL
SELECT '01:00:00' UNION ALL
SELECT '01:05:00' UNION ALL
SELECT '01:10:00' UNION ALL
SELECT '01:15:00' UNION ALL
SELECT '01:20:00' UNION ALL
SELECT '01:25:00' UNION ALL
SELECT '01:30:00' UNION ALL
SELECT '01:35:00' UNION ALL
SELECT '01:40:00' UNION ALL
SELECT '01:45:00' UNION ALL
SELECT '01:50:00' UNION ALL
SELECT '01:55:00' UNION ALL
SELECT '02:00:00' UNION ALL
SELECT '02:05:00' UNION ALL
SELECT '02:10:00' UNION ALL
SELECT '02:15:00' UNION ALL
SELECT '02:20:00' UNION ALL
SELECT '02:25:00' UNION ALL
SELECT '02:30:00' UNION ALL
SELECT '02:35:00' UNION ALL
SELECT '02:40:00' UNION ALL
SELECT '02:45:00' UNION ALL
SELECT '02:50:00' UNION ALL
SELECT '02:55:00' UNION ALL
SELECT '03:00:00' UNION ALL
SELECT '03:05:00' UNION ALL
SELECT '03:10:00' UNION ALL
SELECT '03:15:00' UNION ALL
SELECT '03:20:00' UNION ALL
SELECT '03:25:00' UNION ALL
SELECT '03:30:00' UNION ALL
SELECT '03:35:00' UNION ALL
SELECT '03:40:00' UNION ALL
SELECT '03:45:00' UNION ALL
SELECT '03:50:00' UNION ALL
SELECT '03:55:00' UNION ALL
SELECT '04:00:00' UNION ALL
SELECT '04:05:00'
COMMIT;
RAISERROR (N'[dbo].[FiveMins]: Insert Batch: 1.....Done!', 10, 1) WITH NOWAIT;
GO

BEGIN TRANSACTION;
INSERT INTO [dbo].[FiveMins]([FiveMinPeriod])
SELECT '04:10:00' UNION ALL
SELECT '04:15:00' UNION ALL
SELECT '04:20:00' UNION ALL
SELECT '04:25:00' UNION ALL
SELECT '04:30:00' UNION ALL
SELECT '04:35:00' UNION ALL
SELECT '04:40:00' UNION ALL
SELECT '04:45:00' UNION ALL
SELECT '04:50:00' UNION ALL
SELECT '04:55:00' UNION ALL
SELECT '05:00:00' UNION ALL
SELECT '05:05:00' UNION ALL
SELECT '05:10:00' UNION ALL
SELECT '05:15:00' UNION ALL
SELECT '05:20:00' UNION ALL
SELECT '05:25:00' UNION ALL
SELECT '05:30:00' UNION ALL
SELECT '05:35:00' UNION ALL
SELECT '05:40:00' UNION ALL
SELECT '05:45:00' UNION ALL
SELECT '05:50:00' UNION ALL
SELECT '05:55:00' UNION ALL
SELECT '06:00:00' UNION ALL
SELECT '06:05:00' UNION ALL
SELECT '06:10:00' UNION ALL
SELECT '06:15:00' UNION ALL
SELECT '06:20:00' UNION ALL
SELECT '06:25:00' UNION ALL
SELECT '06:30:00' UNION ALL
SELECT '06:35:00' UNION ALL
SELECT '06:40:00' UNION ALL
SELECT '06:45:00' UNION ALL
SELECT '06:50:00' UNION ALL
SELECT '06:55:00' UNION ALL
SELECT '07:00:00' UNION ALL
SELECT '07:05:00' UNION ALL
SELECT '07:10:00' UNION ALL
SELECT '07:15:00' UNION ALL
SELECT '07:20:00' UNION ALL
SELECT '07:25:00' UNION ALL
SELECT '07:30:00' UNION ALL
SELECT '07:35:00' UNION ALL
SELECT '07:40:00' UNION ALL
SELECT '07:45:00' UNION ALL
SELECT '07:50:00' UNION ALL
SELECT '07:55:00' UNION ALL
SELECT '08:00:00' UNION ALL
SELECT '08:05:00' UNION ALL
SELECT '08:10:00' UNION ALL
SELECT '08:15:00'
COMMIT;
RAISERROR (N'[dbo].[FiveMins]: Insert Batch: 2.....Done!', 10, 1) WITH NOWAIT;
GO

BEGIN TRANSACTION;
INSERT INTO [dbo].[FiveMins]([FiveMinPeriod])
SELECT '08:20:00' UNION ALL
SELECT '08:25:00' UNION ALL
SELECT '08:30:00' UNION ALL
SELECT '08:35:00' UNION ALL
SELECT '08:40:00' UNION ALL
SELECT '08:45:00' UNION ALL
SELECT '08:50:00' UNION ALL
SELECT '08:55:00' UNION ALL
SELECT '09:00:00' UNION ALL
SELECT '09:05:00' UNION ALL
SELECT '09:10:00' UNION ALL
SELECT '09:15:00' UNION ALL
SELECT '09:20:00' UNION ALL
SELECT '09:25:00' UNION ALL
SELECT '09:30:00' UNION ALL
SELECT '09:35:00' UNION ALL
SELECT '09:40:00' UNION ALL
SELECT '09:45:00' UNION ALL
SELECT '09:50:00' UNION ALL
SELECT '09:55:00' UNION ALL
SELECT '10:00:00' UNION ALL
SELECT '10:05:00' UNION ALL
SELECT '10:10:00' UNION ALL
SELECT '10:15:00' UNION ALL
SELECT '10:20:00' UNION ALL
SELECT '10:25:00' UNION ALL
SELECT '10:30:00' UNION ALL
SELECT '10:35:00' UNION ALL
SELECT '10:40:00' UNION ALL
SELECT '10:45:00' UNION ALL
SELECT '10:50:00' UNION ALL
SELECT '10:55:00' UNION ALL
SELECT '11:00:00' UNION ALL
SELECT '11:05:00' UNION ALL
SELECT '11:10:00' UNION ALL
SELECT '11:15:00' UNION ALL
SELECT '11:20:00' UNION ALL
SELECT '11:25:00' UNION ALL
SELECT '11:30:00' UNION ALL
SELECT '11:35:00' UNION ALL
SELECT '11:40:00' UNION ALL
SELECT '11:45:00' UNION ALL
SELECT '11:50:00' UNION ALL
SELECT '11:55:00' UNION ALL
SELECT '12:00:00' UNION ALL
SELECT '12:05:00' UNION ALL
SELECT '12:10:00' UNION ALL
SELECT '12:15:00' UNION ALL
SELECT '12:20:00' UNION ALL
SELECT '12:25:00'
COMMIT;
RAISERROR (N'[dbo].[FiveMins]: Insert Batch: 3.....Done!', 10, 1) WITH NOWAIT;
GO

BEGIN TRANSACTION;
INSERT INTO [dbo].[FiveMins]([FiveMinPeriod])
SELECT '12:30:00' UNION ALL
SELECT '12:35:00' UNION ALL
SELECT '12:40:00' UNION ALL
SELECT '12:45:00' UNION ALL
SELECT '12:50:00' UNION ALL
SELECT '12:55:00' UNION ALL
SELECT '13:00:00' UNION ALL
SELECT '13:05:00' UNION ALL
SELECT '13:10:00' UNION ALL
SELECT '13:15:00' UNION ALL
SELECT '13:20:00' UNION ALL
SELECT '13:25:00' UNION ALL
SELECT '13:30:00' UNION ALL
SELECT '13:35:00' UNION ALL
SELECT '13:40:00' UNION ALL
SELECT '13:45:00' UNION ALL
SELECT '13:50:00' UNION ALL
SELECT '13:55:00' UNION ALL
SELECT '14:00:00' UNION ALL
SELECT '14:05:00' UNION ALL
SELECT '14:10:00' UNION ALL
SELECT '14:15:00' UNION ALL
SELECT '14:20:00' UNION ALL
SELECT '14:25:00' UNION ALL
SELECT '14:30:00' UNION ALL
SELECT '14:35:00' UNION ALL
SELECT '14:40:00' UNION ALL
SELECT '14:45:00' UNION ALL
SELECT '14:50:00' UNION ALL
SELECT '14:55:00' UNION ALL
SELECT '15:00:00' UNION ALL
SELECT '15:05:00' UNION ALL
SELECT '15:10:00' UNION ALL
SELECT '15:15:00' UNION ALL
SELECT '15:20:00' UNION ALL
SELECT '15:25:00' UNION ALL
SELECT '15:30:00' UNION ALL
SELECT '15:35:00' UNION ALL
SELECT '15:40:00' UNION ALL
SELECT '15:45:00' UNION ALL
SELECT '15:50:00' UNION ALL
SELECT '15:55:00' UNION ALL
SELECT '16:00:00' UNION ALL
SELECT '16:05:00' UNION ALL
SELECT '16:10:00' UNION ALL
SELECT '16:15:00' UNION ALL
SELECT '16:20:00' UNION ALL
SELECT '16:25:00' UNION ALL
SELECT '16:30:00' UNION ALL
SELECT '16:35:00'
COMMIT;
RAISERROR (N'[dbo].[FiveMins]: Insert Batch: 4.....Done!', 10, 1) WITH NOWAIT;
GO

BEGIN TRANSACTION;
INSERT INTO [dbo].[FiveMins]([FiveMinPeriod])
SELECT '16:40:00' UNION ALL
SELECT '16:45:00' UNION ALL
SELECT '16:50:00' UNION ALL
SELECT '16:55:00' UNION ALL
SELECT '17:00:00' UNION ALL
SELECT '17:05:00' UNION ALL
SELECT '17:10:00' UNION ALL
SELECT '17:15:00' UNION ALL
SELECT '17:20:00' UNION ALL
SELECT '17:25:00' UNION ALL
SELECT '17:30:00' UNION ALL
SELECT '17:35:00' UNION ALL
SELECT '17:40:00' UNION ALL
SELECT '17:45:00' UNION ALL
SELECT '17:50:00' UNION ALL
SELECT '17:55:00' UNION ALL
SELECT '18:00:00' UNION ALL
SELECT '18:05:00' UNION ALL
SELECT '18:10:00' UNION ALL
SELECT '18:15:00' UNION ALL
SELECT '18:20:00' UNION ALL
SELECT '18:25:00' UNION ALL
SELECT '18:30:00' UNION ALL
SELECT '18:35:00' UNION ALL
SELECT '18:40:00' UNION ALL
SELECT '18:45:00' UNION ALL
SELECT '18:50:00' UNION ALL
SELECT '18:55:00' UNION ALL
SELECT '19:00:00' UNION ALL
SELECT '19:05:00' UNION ALL
SELECT '19:10:00' UNION ALL
SELECT '19:15:00' UNION ALL
SELECT '19:20:00' UNION ALL
SELECT '19:25:00' UNION ALL
SELECT '19:30:00' UNION ALL
SELECT '19:35:00' UNION ALL
SELECT '19:40:00' UNION ALL
SELECT '19:45:00' UNION ALL
SELECT '19:50:00' UNION ALL
SELECT '19:55:00' UNION ALL
SELECT '20:00:00' UNION ALL
SELECT '20:05:00' UNION ALL
SELECT '20:10:00' UNION ALL
SELECT '20:15:00' UNION ALL
SELECT '20:20:00' UNION ALL
SELECT '20:25:00' UNION ALL
SELECT '20:30:00' UNION ALL
SELECT '20:35:00' UNION ALL
SELECT '20:40:00' UNION ALL
SELECT '20:45:00'
COMMIT;
RAISERROR (N'[dbo].[FiveMins]: Insert Batch: 5.....Done!', 10, 1) WITH NOWAIT;
GO

BEGIN TRANSACTION;
INSERT INTO [dbo].[FiveMins]([FiveMinPeriod])
SELECT '20:50:00' UNION ALL
SELECT '20:55:00' UNION ALL
SELECT '21:00:00' UNION ALL
SELECT '21:05:00' UNION ALL
SELECT '21:10:00' UNION ALL
SELECT '21:15:00' UNION ALL
SELECT '21:20:00' UNION ALL
SELECT '21:25:00' UNION ALL
SELECT '21:30:00' UNION ALL
SELECT '21:35:00' UNION ALL
SELECT '21:40:00' UNION ALL
SELECT '21:45:00' UNION ALL
SELECT '21:50:00' UNION ALL
SELECT '21:55:00' UNION ALL
SELECT '22:00:00' UNION ALL
SELECT '22:05:00' UNION ALL
SELECT '22:10:00' UNION ALL
SELECT '22:15:00' UNION ALL
SELECT '22:20:00' UNION ALL
SELECT '22:25:00' UNION ALL
SELECT '22:30:00' UNION ALL
SELECT '22:35:00' UNION ALL
SELECT '22:40:00' UNION ALL
SELECT '22:45:00' UNION ALL
SELECT '22:50:00' UNION ALL
SELECT '22:55:00' UNION ALL
SELECT '23:00:00' UNION ALL
SELECT '23:05:00' UNION ALL
SELECT '23:10:00' UNION ALL
SELECT '23:15:00' UNION ALL
SELECT '23:20:00' UNION ALL
SELECT '23:25:00' UNION ALL
SELECT '23:30:00' UNION ALL
SELECT '23:35:00' UNION ALL
SELECT '23:40:00' UNION ALL
SELECT '23:45:00' UNION ALL
SELECT '23:50:00' UNION ALL
SELECT '23:55:00'
COMMIT;
RAISERROR (N'[dbo].[FiveMins]: Insert Batch: 6.....Done!', 10, 1) WITH NOWAIT;
GO

-- Create the Activity tracking code table for the final query in usp24hrActivityTracking2
/******************************************************************************
***** Object:  Table [dbo].[Track_activity_code]    Script Date: 9/2/2021 8:30:21 PM *****
******************************************************************************/

CREATE TABLE [dbo].[Track_activity_code](
	[code] [int] NULL,
	[description] [varchar](100) NULL
) ON [PRIMARY]
GO


SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
INSERT INTO [dbo].[Track_activity_code]([code], [description])
SELECT 1, N'Max users logged in -or- User logged in already' UNION ALL
SELECT 2, N'Successful attempt to log in' UNION ALL
SELECT 3, N'Window was successfully opened' UNION ALL
SELECT 4, N'Access to window was denied' UNION ALL
SELECT 5, N'Report was printed' UNION ALL
SELECT 6, N'Access to print report was denied' UNION ALL
SELECT 7, N'Master record added' UNION ALL
SELECT 8, N'Master record modified' UNION ALL
SELECT 9, N'Master record deleted' UNION ALL
SELECT 10, N'User used process server' UNION ALL
SELECT 11, N'Window has begun/finished processing' UNION ALL
SELECT 12, N'Check Links process begun' UNION ALL
SELECT 14, N'Routine has begun/finished processing' UNION ALL
SELECT 15, N'Successful attempt to log out' UNION ALL
SELECT 16, N'Modifier successfully accessed' UNION ALL
SELECT 17, N'Report Writer successfully accessed' UNION ALL
SELECT 18, N'Transaction record added' UNION ALL
SELECT 19, N'Transaction record deleted' UNION ALL
SELECT 20, N'Transaction record modified' UNION ALL
SELECT 21, N'Setup record added' UNION ALL
SELECT 22, N'Setup record deleted' UNION ALL
SELECT 23, N'Setup record modified' UNION ALL
SELECT 102, N'Quick entry has begun/finished posting' UNION ALL
SELECT 103, N'Batch has begun/finished posting -or- an error occurred while posting' UNION ALL
SELECT 105, N'Bank deposit entry has begun/finished posting' UNION ALL
SELECT 106, N'Bank transaction entry has begun/finished posting' UNION ALL
SELECT 107, N'Reconcile bank statement has begun/finished posting' UNION ALL
SELECT 109, N'Bank transfer entry has begun/finished posting' UNION ALL
SELECT 201, N'Receivables Sales Entry batch has begun/finished posting' UNION ALL
SELECT 202, N'Receivables Cash Receipts batch has begun/finished posting' UNION ALL
SELECT 207, N'Sales Transaction Entry batch has begun/finished posting -or- an error occurred while posting' UNION ALL
SELECT 208, N'Sales Voided Transactions has begun/finished posting' UNION ALL
SELECT 301, N'Payables Trx Entry batch has begun/finished posting' UNION ALL
SELECT 302, N'Computer checks batch has begun/finished posting' UNION ALL
SELECT 306, N'Payment Entry batch has begun/finished posting' UNION ALL
SELECT 308, N'Receivings Trx Entry batch has begun/finished posting' UNION ALL
SELECT 311, N'Purchasing Invoice Entry batch as begun/finished posting' UNION ALL
SELECT 315, N'Returns Trx Entry batch has begun/finished posting' UNION ALL
SELECT 401, N'Transaction Entry batch has begun/finished posting'
COMMIT;
RAISERROR (N'[dbo].[Track_activity_code]: Insert Batch: 1.....Done!', 10, 1) WITH NOWAIT;
GO


-- Function udfDatediffToWords
CREATE FUNCTION [dbo].[udfDatediffToWords] 
( 
     @d1 DATETIME, 
     @d2 DATETIME 
) 
RETURNS VARCHAR(255) 
AS 
-- =============================================
-- Author: Unknown
-- Create date: 12/1/2003
-- Description: Convert the DATEDIFF function to return
--		Days, Hours, and Minutes.
--	*** SQL Server 2016 or later only! ***
-- =============================================
BEGIN 
     DECLARE @minutes INT, @word VARCHAR(255) 
     SET @minutes = ABS(DATEDIFF(MINUTE, @d1, @d2)) 
     IF @minutes = 0 
         SET @word = '0 minutes.' 
     ELSE 
		 BEGIN 
			 SET @word = '' 
			 IF @minutes >= 1440
				BEGIN
					IF @minutes/1440 = 1 SET @word = @word + '1 day, ';
					ELSE SET @word = @word + RTRIM(@minutes/1440)+' days, ';
				END

			SET @minutes = @minutes % 1440;
			IF @minutes >= 60 
				BEGIN
					IF @minutes/60 = 1 SET @word = @word + '1 hour, ';
					ELSE SET @word = @word + RTRIM(@minutes/60)+' hours, ';
				END
			SET @minutes = @minutes % 60 
			IF @minutes = 1 SET @word = @word + '1 minute';
			ELSE SET @word = @word + RTRIM(@minutes)+' minutes.' 
		 END 
     RETURN @word 
END 
GO
RAISERROR (N'Function udfDateDiffToWords created!', 10, 1) WITH NOWAIT;
GO

-- SP usp24hrActivityTracking
CREATE PROCEDURE [dbo].[usp24hrActivityTracking] @dynDB char(15)
AS

-- =============================================
-- Author: Steve Erbach
-- Create date: 6-Mar-2018
-- Description:	Query the SY05000 table for GP Activity.
-- Revised: 14-Jan-2019
-- Revision: Removed ORDER BY clause.
-- NOTE: This procedure uses the FORMAT function.
--		  Will not work in SQL versions before 2012.
-- NOTE: This procedure also uses the DATE data type
--		  and the TIME data type.
--		  Will work in SQL versions before 2012 if 
--		  you comment out the proper line (see inline comment)
-- =============================================
	 

BEGIN

	SET NOCOUNT ON;

	DECLARE @sql varchar(MAX);

	SET @sql = 'SELECT DISTINCT RTRIM(CMPNYNAM) AS Company
	  , RTRIM(USERID) AS UserID
	  , INQYTYPE
	  , CONVERT(date, DATE1) AS DATE1
	  , FORMAT(CONVERT(time, TIME1), ''hh\:mm'', ''en-us'') AS TIME1 -- Comment this line for SQL 2008 and below
	  --, CONVERT(varchar, TIME1, 108) as TIME1 --hh:mm:ss  uncomment this line for SQL 2008 & below
	  , RTRIM(SECDESC) AS [Description]
	 FROM ' + RTRIM(@dynDB) + '..SY05000
	 WHERE DATE1 + TIME1 > DATEADD(hour, -24, GETDATE());'
	 --ORDER BY
		-- DATE1 DESC
	 -- , TIME1 DESC;'

	  EXECUTE (@sql);

END
GO
RAISERROR (N'Stored Procs [usp24hrActivityTracking] created!', 10, 1) WITH NOWAIT;
GO

-- SP usp24hrActivityTracking2  (new improved version)
CREATE PROCEDURE [dbo].[usp24hrActivityTracking2]
	 @dynDB char(15)
AS
-- =============================================
-- Author: Steve Erbach
-- Create date: 5-Aug-2021
-- Description:	Query the SY05000 table for GP Activity.
--		  Combine with FiveMin table to space out the Activity
--		  in 5 minute blocks during the day.
--
-- TEST: EXECUTE dbo.usp24hrActivityTracking2 'DYNAMICS'
-- =============================================
BEGIN

	SET NOCOUNT ON;

	DECLARE @sql varchar(MAX);

	SET @sql = 'DECLARE @trackingDay datetime = CONVERT(datetime, CONVERT(date, GETDATE()));
		  WITH tracking AS (
				SELECT rawData.*
					 , FORMAT(TIMEFROMPARTS(rawData.FiveMinSegment*5/60, rawData.FiveMinSegment*5 % 60, 0, 0, 0), ''hh\:mm'') AS minTime
				FROM (
					 SELECT DISTINCT RTRIM(CMPNYNAM) AS Company
								, RTRIM(USERID) AS UserID
								, INQYTYPE
								, CONVERT(date, DATE1) AS DATE1
								, FORMAT(CONVERT(time, TIME1), ''hh\:mm'', ''en-us'') AS TIME1
								, RTRIM(SECDESC) AS [Description]
								, DATEDIFF(minute, @trackingDay, DATE1+TIME1)/5 AS FiveMinSegment
								, track_activity_code.[Description] AS Code
								, TIME1 AS origTIME1
						  FROM dbo.SY05000
						  LEFT OUTER JOIN dbo.Track_activity_code
								ON SY05000.INQYTYPE = Track_activity_code.code
						  WHERE DATE1 = @trackingDay
				) AS rawData
	 ),
	 maxMin AS (
		  SELECT MIN(tracking.minTime) AS earliest
				, MAX(tracking.minTime) AS latest
		  FROM tracking
	 )
	 SELECT mins.FiveMinPeriod
		  , ISNULL(tracking.Company, '''') AS Company
		  , ISNULL(tracking.UserID, ''---'') AS UserID
		  , ISNULL(tracking.INQYTYPE, 0) AS INQYTYPE
		  , ISNULL(tracking.DATE1, CONVERT(date, @trackingDay)) AS DATE1
		  , ISNULL(tracking.TIME1, FORMAT(CONVERT(time, mins.FiveMinPeriod), ''hh\:mm'', ''en-us'')) AS TIME1
		  , ISNULL(tracking.[Description], '''') AS [Description]
		  , ISNULL(tracking.FiveMinSegment, DATEDIFF(minute, @trackingDay, @trackingDay+CONVERT(datetime, mins.FiveMinPeriod))/5) AS FiveMinSegment
		  , ISNULL(tracking.Code, '''') AS Code
		  , ISNULL(tracking.origTIME1, CONVERT(datetime, ''1900-01-01'') + CONVERT(datetime, mins.FiveMinPeriod)) AS origTIME1
		  , ISNULL(tracking.minTime, FORMAT(mins.FiveMinPeriod, ''hh\:mm'')) AS minTime
	 FROM dbo.FiveMins AS mins
	 LEFT OUTER JOIN tracking
		  ON mins.FiveMinPeriod = tracking.minTime
	 INNER JOIN maxMin
		  ON mins.FiveMinPeriod BETWEEN maxMin.earliest AND maxMin.latest
	 ORDER BY FiveMinPeriod;';

	  EXECUTE (@sql);

END
GO
RAISERROR (N'Stored Procs [usp24hrActivityTracking2] created!', 10, 1) WITH NOWAIT;
GO
-- SP uspFillTempSY00500Table
CREATE PROCEDURE [dbo].[uspFillTempSY00500Table]
	@dynDB varchar(15)
	, @shouldCreate bit		-- 1=Yes, create the #ActiveBatches table; 0=No, #ActiveBatches will be created external to this sproc.
AS
-- =============================================
-- Author:	Steve Erbach
-- Create date: 7-Feb-2018
-- Description:	Create a Temp table containing the details
--		of all of the MDKTOPST and BCHSTTUS field from all 
--		of the SY00500 tables from all GP Companies where
--		MKDTOPST != 0 OR BCHSTTUS != 0.
-- Modified: 17-Jan-2019
-- Modification: Added USERID column.
-- =============================================
BEGIN

	SET NOCOUNT ON;

	IF @shouldCreate = 1
	BEGIN
		IF OBJECT_ID('tempdb..#ActiveBatches') IS NOT NULL DROP TABLE #ActiveBatches;

		CREATE TABLE #ActiveBatches (
			TableName varchar(30)
			, BatchSource char(15)
			, TRXSORCE char(13)
			, [Batch#] char(15)
			, SERIES varchar(15)
			, MKDTOPST tinyint
			, NUMOFTRX int
			, BACHFREQ varchar(15)
			, BCHCOMNT char(61)
			, BCHTOTAL numeric(19, 5)
			, CREATDDT datetime
			, BCHSTTUS smallint
			, BatchStatusDescription varchar(100)
			, USERID char(15)
		);
	END

	DECLARE @sql varchar(MAX);
	DECLARE @dbID char(5)
		, @companyID smallint
		, @companyName char(65);

	SET @sql = 'DECLARE comp_cursor CURSOR
	FOR
		SELECT a.INTERID
			, a.CMPANYID
			, a.CMPNYNAM
		FROM ' + @dynDB + '..SY01500 AS a
		WHERE a.CMPANYID > -1
			AND a.EnableGLReporting = 1;';

	EXECUTE (@sql);

	OPEN comp_cursor
	FETCH NEXT FROM comp_cursor
	INTO @dbID, @companyID, @companyName;

	WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @sql = 'INSERT INTO #ActiveBatches (TableName, BatchSource, TRXSORCE, [Batch#], SERIES, MKDTOPST, NUMOFTRX, BACHFREQ, BCHCOMNT, BCHTOTAL, CREATDDT, BCHSTTUS, BatchStatusDescription, USERID)
				SELECT ''' + RTRIM(@dbID) + '..SY00500''
					, BCHSOURC
					, TRXSORCE
					, BACHNUMB
					, CASE SERIES
						WHEN 1 THEN ''All''
						WHEN 2 THEN ''Financial''
						WHEN 3 THEN ''Sales''
						WHEN 4 THEN ''Purchasing''
						WHEN 5 THEN ''Inventory''
						WHEN 6 THEN ''Payroll - USA''
						WHEN 7 THEN ''Project''
						ELSE ''--Unknown--''
					END AS SERIES
					, MKDTOPST
					, NUMOFTRX
					, CASE BACHFREQ
						WHEN 1 THEN ''Single Use''
						WHEN 2 THEN ''Weekly''
						WHEN 3 THEN ''Biweekly''
						WHEN 4 THEN ''Semi-Monthly''
						WHEN 5 THEN ''Monthly''
						WHEN 6 THEN ''Bi-Monthly''
						WHEN 7 THEN ''Quarterly''
						WHEN 8 THEN ''Misc.''
						ELSE ''--Unknown--''
					END AS BACHFREQ
					, BCHCOMNT
					, BCHTOTAL
					, CREATDDT
					, BCHSTTUS
					, CASE BCHSTTUS
						WHEN 0 THEN ''Available''
						WHEN 1 THEN ''Batch is currently posting''
						WHEN 2 THEN ''Batch is currently being deleted''
						WHEN 3 THEN ''Batch is currently receiving transactions from outside the module''
						WHEN 4 THEN ''Batch is done posting''
						WHEN 5 THEN ''Batch is currently being printed''
						WHEN 6 THEN ''Batch is currently being updated''
						WHEN 7 THEN ''Batch was interrupted during posting''
						WHEN 8 THEN ''Batch was interrupted during printing''
						WHEN 9 THEN ''Batch was interrupted during updating of tables''
						WHEN 10 THEN ''Recurring batch has application errors and one or more transactions did not post''
						WHEN 11 THEN ''Single-use batch has application errors and one or more transactions did not post''
						WHEN 15 THEN ''A posting error occurred while trying to post a batch of computer checks''
						WHEN 20 THEN ''Batch was interrupted during the processing of computer checks''
						WHEN 25 THEN ''Batch was interrupted during the printing of the computer check alignment''
						WHEN 30 THEN ''Batch was interrupted during the printing of computer checks''
						WHEN 35 THEN ''Batch was interrupted during the printing of a check alignment form before reprinting checks''
						WHEN 40 THEN ''Batch was interrupted during the voiding of computer checks''
						WHEN 45 THEN ''Batch was interrupted during the reprinting of computer checks''
						WHEN 50 THEN ''Batch was interrupted during the processing of the remittance report''
						WHEN 55 THEN ''Batch was interrupted during the processing of the remittance Alignment report''
						WHEN 60 THEN ''Batch was interrupted during the printing of the remittance report''
						WHEN 100 THEN ''Batch is processing computer checks''
						WHEN 105 THEN ''A check alignment form is being printed before printing checks''
						WHEN 110 THEN ''Batch is printing computer checks''
						WHEN 115 THEN ''A check alignment form is being printed before reprinting checks''
						WHEN 120 THEN ''Batch is voiding computer checks''
						WHEN 125 THEN ''Batch is reprinting computer checks''
						WHEN 130 THEN ''Batch is processing the remittance report''
						WHEN 135 THEN ''A remittance alignment form is being printed''
						WHEN 140 THEN ''A remittance form is being printed''
						ELSE ''--Unknown--''
					END AS BatchStatusDescription
					, USERID
				FROM ' + RTRIM(@dbID) + '.dbo.SY00500;';

			EXECUTE (@sql);

			FETCH NEXT FROM comp_cursor
			INTO @dbID, @companyID, @companyName;

		END

	CLOSE comp_cursor;
	DEALLOCATE comp_cursor;

	IF @shouldCreate = 1
	BEGIN
		SELECT *
		FROM #ActiveBatches
		WHERE MKDTOPST != 0
			OR BCHSTTUS != 0;
	END

END

GO
RAISERROR (N'Stored Procs [uspFillTempSY00500Table] created!', 10, 1) WITH NOWAIT;
GO
-- SP uspLocksInUse
CREATE PROCEDURE [dbo].[uspLocksInUse] 
	@dynDB varchar(15)
	, @shouldCreate bit		-- 1=Yes, create the #DexLock table; 0=No, #DexLock created external to this sproc
AS
-- =============================================
-- Author:	Steve Erbach
-- Create date: 12-Feb-2018
-- Description:	Return list of Locked documents from all
--		active Companies.
-- =============================================
BEGIN

	SET NOCOUNT ON;

	IF @shouldCreate = 1
	BEGIN
		IF OBJECT_ID('tempdb..#DexLock') IS NOT NULL DROP TABLE #DexLock;

		CREATE TABLE #DexLock (
			[UserID] char(15)
			, [DocNo Locked] varchar(30)
			, LoginDate datetime
			, [table_path_name] char(100)
		);
	END

	DECLARE @sql varchar(MAX);
	DECLARE @dbID char(5)
		, @companyID smallint
		, @companyName char(65);

	-- CMPANYID -1 is the TWO database
	SET @sql = 'DECLARE comp_cursor CURSOR
	FOR
		SELECT a.INTERID
			, a.CMPANYID
			, a.CMPNYNAM
		FROM ' + @dynDB + '..SY01500 AS a
		WHERE a.CMPANYID > -1
			AND a.EnableGLReporting = 1;';		-- 1 = Enabled; 0 = Disabled
	EXECUTE (@sql);

	OPEN comp_cursor
	FETCH NEXT FROM comp_cursor
	INTO @dbID, @companyID, @companyName;

	WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @sql = 'INSERT INTO #DexLock ([UserID], [DocNo Locked], LoginDate, [table_path_name])
					SELECT ISNULL(act.USERID, ''LoggedOutUser'') AS [UserID]
						, CASE ISNULL(po.DEX_ROW_ID, 0)
							WHEN 0 THEN ''''
							ELSE ISNULL(LEFT(''PO: '' + po.PONUMBER, 45), '''')
						END AS [DocNo Locked]
						, ISNULL(act.logindat, ''1900-01-01'') AS [LoginDate]
						, lck.[table_path_name]
					FROM [tempdb].[dbo].[DEX_LOCK] AS lck
					LEFT OUTER JOIN ' + RTRIM(@dynDB) + '..ACTIVITY AS act
						ON act.sqlsesid = lck.session_id
					LEFT OUTER JOIN ' + RTRIM(@dbID) + '.dbo.POP10100 AS po
						ON lck.row_id = po.DEX_ROW_ID
							AND lck.[table_path_name] = ''' + RTRIM(@dbID) + '.dbo.POP10100''
				UNION
					SELECT ISNULL(act.USERID, ''LoggedOutUser'') AS [UserID]
						, CASE ISNULL(popivc.DEX_ROW_ID, 0)
							WHEN 0 THEN ''''
							ELSE ISNULL(LEFT(''POP IVC: '' + popivc.POPRCTNM, 45), '''')
						END AS [DocNo Locked]
						, ISNULL(act.logindat, ''1900-01-01'') AS [LoginDate]
						, lck.[table_path_name]
					FROM [tempdb].[dbo].[DEX_LOCK] AS lck
					LEFT OUTER JOIN ' + RTRIM(@dynDB) + '..ACTIVITY AS act
						ON act.sqlsesid = lck.session_id
					LEFT OUTER JOIN ' + RTRIM(@dbID) + '.dbo.POP10300 AS popivc
						ON lck.row_id = popivc.DEX_ROW_ID
							AND lck.[table_path_name] = ''' + RTRIM(@dbID) + '.dbo.POP10300''
				UNION
					SELECT ISNULL(act.USERID, ''LoggedOutUser'') AS [UserID]
						, CASE ISNULL(sop.DEX_ROW_ID, 0)
							WHEN 0 THEN ''''
							ELSE ISNULL(LEFT(''SOP: '' + sop.SOPNUMBE, 45), '''')
						END AS [DocNo Locked]
						, ISNULL(act.logindat, ''1900-01-01'') AS [LoginDate]
						, lck.[table_path_name]
					FROM [tempdb].[dbo].[DEX_LOCK] AS lck
					LEFT OUTER JOIN ' + RTRIM(@dynDB) + '..ACTIVITY AS act
						ON act.sqlsesid = lck.session_id
					LEFT OUTER JOIN ' + RTRIM(@dbID) + '.dbo.SOP10100 AS sop
						ON lck.row_id = sop.DEX_ROW_ID
							AND lck.table_path_name = ''' + RTRIM(@dbID) + '.dbo.SOP10100''
				UNION
					SELECT ISNULL(act.USERID, ''LoggedOutUser'') AS [UserID]
						, CASE ISNULL(spwh.DEX_ROW_ID, 0)
							WHEN 0 THEN ''''
							ELSE ISNULL(LEFT(''SOP PMT: '' + spwh.DOCNUMBR, 45), '''')
						END AS [DocNo Locked]
						, ISNULL(act.logindat, ''1900-01-01'') AS [LoginDate]
						, lck.[table_path_name]
					FROM [tempdb].[dbo].[DEX_LOCK] AS lck
					LEFT OUTER JOIN ' + RTRIM(@dynDB) + '..ACTIVITY AS act
						ON act.sqlsesid = lck.session_id
					LEFT OUTER JOIN ' + RTRIM(@dbID) + '.dbo.SOP10103 AS spwh
						ON lck.row_id = spwh.DEX_ROW_ID
							AND lck.table_path_name = ''' + RTRIM(@dbID) + '.dbo.SOP10103''
				UNION
					SELECT ISNULL(act.USERID, ''LoggedOutUser'') AS [UserID]
						, CASE ISNULL(rmkey.DEX_ROW_ID, 0)
							WHEN 0 THEN ''''
							ELSE ISNULL(LEFT(''RM: '' + rmkey.DOCNUMBR, 45), '''')
						END AS [DocNo Locked]
						, ISNULL(act.logindat, ''1900-01-01'') AS [LoginDate]
						, lck.[table_path_name]
					FROM [tempdb].[dbo].[DEX_LOCK] AS lck
					LEFT OUTER JOIN ' + RTRIM(@dynDB) + '..ACTIVITY AS act
						ON act.sqlsesid = lck.session_id
					LEFT OUTER JOIN ' + RTRIM(@dbID) + '.dbo.RM00401 AS rmkey
						ON lck.row_id = rmkey.DEX_ROW_ID
							AND lck.[table_path_name] = ''' + RTRIM(@dbID) + '.dbo.RM00401''
				UNION
					SELECT ISNULL(act.USERID, ''LoggedOutUser'') AS [UserID]
						, CASE ISNULL(pm.DEX_ROW_ID, 0)
							WHEN 0 THEN ''''
							ELSE ISNULL(LEFT(''PM VCH: '' + pm.VCHNUMWK, 45), '''')
						END AS [DocNo Locked]
						, ISNULL(act.logindat, ''1900-01-01'') AS [LoginDate]
						, lck.[table_path_name]
					FROM [tempdb].[dbo].[DEX_LOCK] AS lck
					LEFT OUTER JOIN ' + RTRIM(@dynDB) + '..ACTIVITY AS act
						ON act.sqlsesid = lck.session_id
					LEFT OUTER JOIN ' + RTRIM(@dbID) + '.dbo.PM10000 AS pm
						ON lck.row_id = pm.DEX_ROW_ID
							AND lck.[table_path_name] = ''' + RTRIM(@dbID) + '.dbo.PM10000'';';

			EXECUTE (@sql);

			FETCH NEXT FROM comp_cursor
			INTO @dbID, @companyID, @companyName;

		END

	CLOSE comp_cursor;
	DEALLOCATE comp_cursor;

	DELETE
	FROM #DexLock
	WHERE RTRIM([DocNo Locked]) = '';

	IF @shouldCreate = 1
	BEGIN
		SELECT *
		FROM #DexLock;
		DROP TABLE #DexLock;
	END

END
GO
RAISERROR (N'Stored Procs [uspLocksInUser] created!', 10, 1) WITH NOWAIT;
GO

-- SP uspFillTempActiveBatchesTable
CREATE PROCEDURE [dbo].[uspFillTempActiveBatchesTable]
	@dynDB varchar(15)
AS
-- =============================================
-- Author:	Steve Erbach
-- Create date: 26-Feb-2018
-- Description:	Fill the Quick Stats table on the GP Admin
--		Dashboard.
-- Modified: 17-Jan-2019
-- Modification: Added USERID field to #ActiveBatches.
-- =============================================
BEGIN

	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#ActiveBatches') IS NOT NULL DROP TABLE #ActiveBatches;
	CREATE TABLE #ActiveBatches (
		TableName varchar(30)
		, BatchSource char(15)
		, TRXSORCE char(13)
		, [Batch#] char(15)
		, SERIES varchar(15)
		, MKDTOPST tinyint
		, NUMOFTRX int
		, BACHFREQ varchar(15)
		, BCHCOMNT char(61)
		, BCHTOTAL numeric(19, 5)
		, CREATDDT datetime
		, BCHSTTUS smallint
		, BatchStatusDescription varchar(100)
		, USERID char(15)
	);

	IF OBJECT_ID('tempdb..#DexLock') IS NOT NULL DROP TABLE #DexLock;
	CREATE TABLE #DexLock (
		[UserID] char(15)
		, [DocNo Locked] varchar(30)
		, LoginDate datetime
		, [table_path_name] char(100)
	);

	IF OBJECT_ID('tempdb..#StatCount') IS NOT NULL DROP TABLE #StatCount;
	CREATE TABLE #StatCount (
		  Stat varchar(25)
		  , [Count] numeric(5, 1)
	 );

	EXECUTE dbo.uspFillTempSY00500Table @dynDB, 0;
	EXECUTE dbo.uspLocksInUse @dynDB, 0;

	DECLARE @sql varchar(MAX);

	INSERT INTO #StatCount (Stat, [Count])
		SELECT 'Active Batches' AS Stat
			, ISNULL((SELECT COUNT(*) FROM #ActiveBatches WHERE MKDTOPST != 0 OR BCHSTTUS != 0), 0) * 1.0
				+ ISNULL((SELECT COUNT(*) FROM #ActiveBatches WHERE (BCHSTTUS BETWEEN 7 AND 99) OR (BCHSTTUS > 140)), 0) * 0.1
			AS [Count];

	SET @sql = 'INSERT INTO #StatCount (Stat, [Count])
		SELECT ''Locks in Use/Orphans'' AS Stat
			, ISNULL((SELECT COUNT(*) FROM #DexLock), 0) * 1.0
				+ ISNULL(COUNT(*), 0) * 0.1 AS [Count]
		FROM (
			SELECT ''tempdb..DEX_LOCK'' AS TableName
				, L.*
			FROM tempdb..DEX_LOCK AS L
				WHERE NOT EXISTS (
					SELECT A.*
					FROM ' + RTRIM(@dynDB) + '..ACTIVITY AS A 
					WHERE L.session_id = A.SQLSESID
				)
		) AS c;'

	EXECUTE (@sql);

	SET @sql = 'INSERT INTO #StatCount (Stat, [Count])
		SELECT ''Open Batches'' AS Stat
			, ISNULL(
				(
					 COUNT(*) * 1.0 
					 + (
						  SELECT SUM(
								(
									 CASE c.LinkToActivity
										  WHEN ''OK'' THEN 0
										  ELSE 1
									 END
								)
						  )
						) * 0.1
				), 0.0
			) AS [Count]
		FROM (
		SELECT
			B.*
			, CASE ISNULL(
				(
					SELECT A.USERID 
					FROM ' + RTRIM(@dynDB) + '..ACTIVITY AS A 
					WHERE B.USERID = A.USERID 
						AND B.CMPNYNAM = A.CMPNYNAM
				), ''X'')
				WHEN ''X'' THEN ''No match''
				ELSE ''OK''
			END AS LinkToActivity
			, CASE B.WINTYPE
				WHEN 1 THEN ''Batch lock on Open Trx''
				WHEN 2 THEN ''Batch lock on Open batch''
				WHEN 3 THEN ''Invoice Entry''
				WHEN 4 THEN ''SOP Sales Trx Entry''
				WHEN 5 THEN ''IV-Transfer''
				WHEN 13 THEN ''IV In transit xfer''
				WHEN 100 THEN ''Trx lock on Open Trx''
				WHEN -32767 THEN ''GL Entry''
				ELSE ''Who knows?''
			END AS [Description]
		FROM ' + RTRIM(@dynDB) + '..SY00800 AS B
		) AS c;';

	EXECUTE (@sql);

	SET @sql = 'INSERT INTO #StatCount (Stat, [Count])
		SELECT ''Processes'' AS Stat
			, COUNT(msp.spid) AS [Count]
		FROM [master].sys.sysprocesses AS msp
		LEFT OUTER JOIN ' + RTRIM(@dynDB) + '..SY01400 AS um
			ON msp.loginame = um.USERID;';

	EXECUTE (@sql);

	SET @sql = 'INSERT INTO #StatCount (Stat, [Count])
		SELECT ''Resources in Use'' AS Stat
			, ISNULL((COUNT(*) * 1.0 + (SELECT SUM((CASE c.LinkToActivity
						WHEN ''OK'' THEN 0
						ELSE 1
					END))) * 0.1), 0.0) AS [Count]
		FROM (
			SELECT
				CASE ISNULL(
					(
						SELECT A.USERID 
						FROM ' + RTRIM(@dynDB) + '..ACTIVITY AS A 
						INNER JOIN ' + RTRIM(@dynDB) + '..SY01500 AS C 
							ON C.CMPNYNAM = A.CMPNYNAM 
						WHERE R.USERID = A.USERID 
							AND R.CMPANYID = C.CMPANYID
					), ''X'')
					WHEN ''X'' THEN ''No match''
					ELSE ''OK''
				END AS LinkToActivity
				, R.*
			FROM ' + RTRIM(@dynDB) + '..SY00801 AS R
		) AS c;';

	EXECUTE (@sql);

	SET @sql = 'INSERT INTO #StatCount (Stat, [Count])
		SELECT ''Sessions/Orphans'' AS Stat
			, COUNT(*) * 1.0
				+ SUM(x.[SQL status]) * 0.1 AS [Count]
		FROM (
			SELECT CASE
					WHEN ds.[SQL status] = ''No match'' AND ds.Spid_count > 0 THEN 1
					WHEN ds.[SQL status] = ''No match'' AND ds.Spid_count = 0 THEN 1
					ELSE 0
				END AS [SQL status]
			FROM (
				SELECT ISNULL(ses.session_id, 0) AS session_id
					 , ISNULL(ses.sqlsvr_spid, 0) AS sqlsvr_spid
					 , CASE
						WHEN ISNULL(ses.session_id, 0) = 0 THEN ''No DEX_SESSION''
						WHEN ISNULL(act.USERID, ''---'') = ''---'' THEN ''No ACTIVITY''
						ELSE ''OK''
					 END AS LinkToActivity
					, ISNULL(act.USERID, ''---'') AS USERID
					, ISNULL(act.CMPNYNAM, ''---'') AS CMPNYNAM
					, ISNULL(RTRIM(P.[status]), ''No match'') AS [SQL status]
					, (
						SELECT COUNT(*)
						FROM [master].sys.sysprocesses
						WHERE (loginame = act.USERID)
					) AS Spid_count
				FROM ' + RTRIM(@dynDB) + '..ACTIVITY AS act
				FULL OUTER JOIN tempdb..DEX_SESSION AS ses
					ON ses.session_id = act.SQLSESID
				LEFT OUTER JOIN [master].sys.sysprocesses AS P
					ON ses.sqlsvr_spid = P.spid
					AND act.USERID = P.loginame
			) AS ds
		) AS x;';

	 EXECUTE (@sql);

	 SELECT * FROM #StatCount;

	DROP TABLE #ActiveBatches;
	DROP TABLE #DexLock;
	DROP TABLE #StatCount;

END
GO
RAISERROR (N'Stored Procs [uspFillTempActiveBatchesTable] created!', 10, 1) WITH NOWAIT;
GO

-- SP uspGPUserList
CREATE PROCEDURE [dbo].[uspGPUserList]
AS
-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: GP User List for GP Admin Dashboard.
--
-- TEST: EXECUTE dbo.uspGPUserList
-- =============================================
BEGIN

	SET NOCOUNT ON;

	 SELECT RTRIM(um.USERNAME) AS [User Name]
		 , CASE um.UserType
			 WHEN 1 THEN 'Full'
			 WHEN 2 THEN 'Limited'
			 WHEN 4 THEN 'Self-serve'
			 ELSE '---'
		 END AS [Type]
		 , RTRIM(da.CMPNYNAM) AS Company
		 , FORMAT(da.LOGINDAT, 'yyyy-MM-dd', 'en-us') + ' ' + FORMAT(da.LOGINTIM, 'HH:mm', 'en-us') AS [Logged in at]
		 , CONVERT(varchar, ABS(DATEDIFF(minute, da.LOGINDAT + da.LOGINTIM, GETDATE()))) + ' minutes' AS [For how long?]
		 , da.SQLSESID AS [Session]
		 , S.sqlsvr_spid AS GP_spid
		 , (
			 SELECT COUNT(*)
			 FROM [master].sys.sysprocesses AS ms
			 WHERE (loginame = da.USERID)
		 ) AS Spid_count
		 , CASE ISNULL(om.USERID, '---')
			 WHEN '---'
				 THEN 'OK'
			 ELSE 'No SQL session'
		 END AS [Status]
		 , ISNULL(RTRIM(P.[status]), 'No match') AS [Proc status]
		 , ISNULL(
			 (
				 SELECT FORMAT(MIN(last_batch), 'h:mm tt', 'en-us') AS LastBatch
				 FROM (
					 SELECT TOP (1) last_batch
					 FROM [master].sys.sysprocesses
					 WHERE (loginame = da.USERID)
					 ORDER BY last_batch DESC
				 ) AS m
			 ), 'xxx'
		 ) AS [Last]
		 , ISNULL(DATEDIFF(mi, 
				 (
					 SELECT MIN(m_3.last_batch) AS LastBatch
					 FROM (
						 SELECT TOP (1) last_batch
						 FROM [master].sys.sysprocesses
						 WHERE (loginame = da.USERID)
						 ORDER BY last_batch DESC
					 ) AS m_3
				 ), GETDATE()
			 ), - 999
		 ) AS [Mins.]
		 , ISNULL(
			 (
				 SELECT FORMAT(MIN(m_2.last_batch), 'h:mm tt', 'en-us') AS LastBatch
				 FROM (
					 SELECT TOP (2) last_batch
					 FROM [master].sys.sysprocesses
					 WHERE (loginame = da.USERID)
					 ORDER BY last_batch DESC
				 ) AS m_2
			 ), 'xxx'
		 ) AS [2nd Last]
		 , ISNULL(DATEDIFF(mi, 
			 (
				 SELECT MIN(m_1.last_batch) AS LastBatch
				 FROM (
					 SELECT TOP (2) last_batch
					 FROM [master].sys.sysprocesses
					 WHERE (loginame = da.USERID)
					 ORDER BY last_batch DESC
				 ) AS m_1
			 ), GETDATE()), - 999
		 ) AS [Mins. 2nd]
		 , ISNULL(b.batch_count, 0) AS B
		 , ISNULL(r.resource_count, 0) AS R
		 , ISNULL(t.table_locks, 0) AS T
		 ----, ct.ClientType
	 FROM dbo.ACTIVITY AS da
	 LEFT OUTER JOIN (
		 SELECT USERID
		 FROM dbo.ACTIVITY
		 WHERE USERID NOT IN (
			 SELECT DISTINCT loginame
			 FROM [master].sys.sysprocesses
		 )
	 ) AS om
		 ON da.USERID = om.USERID
	 LEFT OUTER JOIN dbo.SY01400 AS um
		 ON da.USERID = um.USERID
	 LEFT OUTER JOIN tempdb.dbo.DEX_SESSION AS S
		 ON da.SQLSESID = S.session_id
	 LEFT OUTER JOIN [master].sys.sysprocesses AS P
		 ON S.sqlsvr_spid = P.spid
		 AND da.USERID = P.loginame
	 LEFT OUTER JOIN (
		 SELECT USERID
			 , COUNT(*) AS batch_count
		 FROM dbo.SY00800
		 GROUP BY USERID
	 ) AS b
		 ON da.USERID = b.USERID
	 LEFT OUTER JOIN (
		 SELECT USERID
			 , COUNT(*) AS resource_count
		 FROM dbo.SY00801
		 GROUP BY USERID
	 ) AS r
		 ON da.USERID = r.USERID
	 LEFT OUTER JOIN (
		 SELECT session_id
			 , COUNT(*) AS table_locks
		 FROM tempdb.dbo.DEX_LOCK
		 GROUP BY session_id
	 ) AS t
		 ON da.SQLSESID = t.session_id
	 --LEFT OUTER JOIN (
		--  SELECT DISTINCT s.loginame
		--		, CASE
		--			 WHEN c.client_net_address IN ('192.168.16.35') THEN 'Remote'
		--			 ELSE 'Local'
		--		END AS ClientType
		--  FROM dbo.ACTIVITY AS a 
		--  INNER JOIN master..sysprocesses AS s
		--		ON a.USERID = s.loginame
		--  INNER JOIN sys.dm_exec_connections AS c 
		--		ON c.session_id = s.spid
	 --) AS ct
		  --ON da.USERID = ct.loginame
	 ORDER BY [Mins.]
		 , [Mins. 2nd]
		 , [User Name];

END
GO
RAISERROR (N'Stored Procs [uspGPUserList] created!', 10, 1) WITH NOWAIT;
GO

-- View vwDashboardUsers

CREATE VIEW [dbo].[vwDashboardUsers]
AS
-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: GP User List for GP Admin Dashboard.
--
-- TEST: SELECT * From dbo.vwDashboardUsers
-- =============================================
	SELECT TOP (100) PERCENT
		RTRIM(um.USERNAME) AS [User Name]
	 , CASE um.UserType
			WHEN 1
				THEN 'Full'
		ELSE 'Limited'
		END AS Type
	 , CASE ISNULL(om.USERID, '---')
			WHEN '---'
				THEN 'OK'
		ELSE 'No SQL session'
		END AS Status
	 , ISNULL(RTRIM(P.status), 'No match') AS [Proc status]
	 , RTRIM(da.CMPNYNAM) AS Company
	 , FORMAT(da.LOGINDAT, 'yyyy-MM-dd', 'en-us')+' '+FORMAT(da.LOGINTIM, 'HH:mm', 'en-us') AS [Logged in at]
	 --, ct.ClientType
	FROM dbo.ACTIVITY AS da
		  LEFT OUTER JOIN
	(
		SELECT
			USERID
		FROM dbo.ACTIVITY
		WHERE(USERID NOT IN
	(
		SELECT DISTINCT
			loginame
		FROM master.sys.sysprocesses
	))
	) AS om
			  ON da.USERID = om.USERID
		  LEFT OUTER JOIN dbo.SY01400 AS um
			  ON da.USERID = um.USERID
		  LEFT OUTER JOIN tempdb.dbo.DEX_SESSION AS S
			  ON da.SQLSESID = S.session_id
		  LEFT OUTER JOIN master.sys.sysprocesses AS P
			  ON S.sqlsvr_spid = P.spid
				  AND da.USERID = P.loginame
	--	  LEFT OUTER JOIN
	--(
	--	SELECT DISTINCT
	--		s.loginame
	--	 , CASE
	--			WHEN c.client_net_address IN('192.168.16.35')
	--				THEN 'Remote'
	--		ELSE 'Local'
	--		END AS ClientType
	--	FROM dbo.ACTIVITY AS a
	--		  INNER JOIN master.sys.sysprocesses AS s
	--			  ON a.USERID = s.loginame
	--		  INNER JOIN sys.dm_exec_connections AS c
	--			  ON c.session_id = s.spid
	--	WHERE(c.client_net_address <> '<local machine>')
	--) AS ct
	--		  ON da.USERID = ct.loginame;
GO
GO
RAISERROR (N'View [vwDashboardUsers] created!', 10, 1) WITH NOWAIT;
GO
-- =============================================
-- TrackUser_1_CreateTable__emeUSERCOUNT.sql 
-- Created by Robert.Cavill@emecoequipment.com 
-- Modified by Beat Bucher (beat.bucher@outlook.com) 
-- 2008, 2011, 2016
-- =============================================

/****** Object:  Table [dbo].[emeUSERCOUNT]    Script Date: 06/12/2008 14:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
-- Do not drop the emeUSERCOUNT table if it exists already to not lose precious data.

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'emeUSERCOUNT')
	BEGIN
	RAISERROR (N'Table [emeUSERCOUNT] already exists!', 10, 1) WITH NOWAIT
	END
ELSE
	BEGIN
	CREATE TABLE [dbo].[emeUSERCOUNT](
		[MODULE] [varchar](10) NOT NULL,
		[MONITORDATE] [datetime] NOT NULL,
		[ACTIVITY] [int] NULL,
	PRIMARY KEY CLUSTERED 
		(
			[MODULE] ASC,
			[MONITORDATE] ASC
		) ON [PRIMARY]
	) ON [PRIMARY]
	RAISERROR (N'Table [emeUSERCOUNT] created!', 10, 1) WITH NOWAIT;
	END
GO
SET ANSI_PADDING OFF

-- Important step! otherwise GP users going to face SQL error messages when login into GP
GRANT DELETE ON [dbo].[emeUSERCOUNT] TO [DYNGRP]
GO
GRANT INSERT ON [dbo].[emeUSERCOUNT] TO [DYNGRP]
GO
GRANT SELECT ON [dbo].[emeUSERCOUNT] TO [DYNGRP]
GO
GRANT UPDATE ON [dbo].[emeUSERCOUNT] TO [DYNGRP]
GO


-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: view to check GP license use for past 12 hours
--
-- TEST: SELECT * From dbo.vw12HourActivity
-- =============================================
CREATE VIEW [dbo].[vw12HourActivity]
AS
SELECT        'GP' AS Module, MONITORDATE, ACTIVITY
FROM            dbo.emeUSERCOUNT
WHERE        (MONITORDATE >= DATEADD(hh, - 12, GETDATE())) AND (ACTIVITY > 0)
GO

RAISERROR (N'View [vw12HourActivity] created!', 10, 1) WITH NOWAIT;
GO

-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: view to check GP license use for past 2 weeks
--
-- TEST: SELECT * From dbo.vw16DayActivity
-- =============================================

CREATE VIEW [dbo].[vw16DayActivity]
AS
SELECT        MONITORDATE, CONVERT(datetime, CONVERT(Varchar(10), MONITORDATE, 101)) AS ActivityDate, CONVERT(Varchar(2), MONITORDATE, 114) AS ActivityHour, ACTIVITY
FROM            dbo.emeUSERCOUNT
WHERE        (MONITORDATE >= DATEADD(dd, - 16, GETDATE()))
GO

RAISERROR (N'View [vw16DayActivity] created!', 10, 1) WITH NOWAIT;
GO

-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: view to check Open Batches
--
-- TEST: SELECT * From dbo.vwOpenBatches
-- =============================================
CREATE VIEW [dbo].[vwOpenBatches]
AS
SELECT
	CASE ISNULL(
		(
			SELECT A.USERID 
			FROM DYNAMICS..ACTIVITY AS A 
			WHERE B.USERID = A.USERID 
				AND B.CMPNYNAM = A.CMPNYNAM
		), 'X')
		WHEN 'X' THEN 'No match'
		ELSE 'OK'
	END AS LinkToActivity
	, CASE B.WINTYPE
		WHEN 1 THEN 'Batch lock on Open Trx'
		WHEN 2 THEN 'Batch lock on Open batch'
		WHEN 3 THEN 'Invoice Entry'
		WHEN 4 THEN 'SOP Sales Trx Entry'
		WHEN 5 THEN 'IV-Transfer'
		WHEN 13 THEN 'IV In transit xfer'
		WHEN 100 THEN 'Trx lock on Open Trx'
		WHEN -32767 THEN 'GL Entry'
		ELSE 'Who knows?'
	END AS [Description]
	, B.*
FROM DYNAMICS..SY00800 AS B
GO

RAISERROR (N'View [vwOpenBatches] created!', 10, 1) WITH NOWAIT;
GO

-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: view to query Resources in Use
--
-- TEST: SELECT * From dbo.vwResourcesinUse
-- =============================================
CREATE VIEW [dbo].[vwResourcesinUse]
AS
SELECT
	CASE ISNULL(
		(
			SELECT A.USERID 
			FROM DYNAMICS..ACTIVITY AS A 
			INNER JOIN DYNAMICS..SY01500 AS C 
				ON C.CMPNYNAM = A.CMPNYNAM 
			WHERE R.USERID = A.USERID 
				AND R.CMPANYID = C.CMPANYID
		), 'X')
		WHEN 'X' THEN 'No match'
		ELSE 'OK'
	END LinkToActivity
	, R.*
FROM DYNAMICS..SY00801 AS R
GO
RAISERROR (N'View [vwResourcesinUse] created!', 10, 1) WITH NOWAIT;
GO

-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: view to query Resources in Use
--
-- TEST: SELECT * From dbo.vwSessions
-- =============================================
CREATE VIEW [dbo].[vwSessions]
AS
SELECT ds.TableName
	, ds.session_id
	, ds.sqlsvr_spid
	, ds.LinkToActivity
	, ds.USERID
	, ds.CMPNYNAM
	, CASE
		WHEN ds.[SQL status] = 'No match' AND ds.Spid_count > 0 THEN 'Unlinked'
		ELSE ds.[SQL status]
	END AS [SQL status]
	, ds.Spid_count
FROM (
	SELECT 'tempdb..DEX_SESSION' AS TableName
		 , ISNULL(ses.session_id, 0) AS session_id
		 , ISNULL(ses.sqlsvr_spid, 0) AS sqlsvr_spid
		 , CASE
			WHEN ISNULL(ses.session_id, 0) = 0 THEN 'No DEX_SESSION'
			WHEN ISNULL(act.USERID, '---') = '---' THEN 'No ACTIVITY'
			ELSE 'OK'
		 END AS LinkToActivity
		, ISNULL(act.USERID, '---') AS USERID
		, ISNULL(act.CMPNYNAM, '---') AS CMPNYNAM
		, ISNULL(RTRIM(P.[status]), 'No match') AS [SQL status]
		, (
			SELECT COUNT(*)
			FROM [master].sys.sysprocesses
			WHERE (loginame = act.USERID)
		) AS Spid_count
	FROM DYNAMICS..ACTIVITY AS act
	FULL OUTER JOIN tempdb..DEX_SESSION AS ses
		ON ses.session_id = act.SQLSESID
	LEFT OUTER JOIN [master].sys.sysprocesses AS P
		ON ses.sqlsvr_spid = P.spid
		AND act.USERID = P.loginame
) AS ds
GO
RAISERROR (N'View [vwSessions] created!', 10, 1) WITH NOWAIT;
GO
-- =============================================
-- Author: Steve Erbach
-- Create date: 2019-11-04
-- Description: view to query Resources in Use
--
-- TEST: SELECT * From dbo.vwProcessesbyUser
-- =============================================
CREATE VIEW [dbo].[vwProcessesbyUser]
AS
SELECT '[master].sys.sysprocesses' AS TableName
	, FORMAT(login_time,'yyyy-MM-dd','en-us')+' '+FORMAT(login_time,'HH:mm','en-us') AS [Login]
	, FORMAT(last_batch,'yyyy-MM-dd','en-us')+' '+FORMAT(last_batch,'HH:mm','en-us') AS LastBatch
	, RTRIM(status) AS [Status]
	, RTRIM(cmd) AS Cmd
	, RTRIM(loginame) AS loginName
	, spid
FROM [master].sys.sysprocesses
ORDER BY loginName
GO
GO
RAISERROR (N'View [vwProcessesbyUser] created!', 10, 1) WITH NOWAIT;
GO
-- Grant access to [rpt_all user] to all dashboard objects
GRANT SELECT ON [dbo].[ACTIVITY] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[Track_activity_code] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[FiveMins] TO [rpt_all user]
GO
GRANT EXECUTE ON [dbo].[udfDatediffToWords] TO [rpt_all user]
GO
GRANT EXECUTE ON [dbo].[usp24hrActivityTracking] TO [rpt_all user]
GO
GRANT EXECUTE ON [dbo].[usp24hrActivityTracking2] TO [rpt_all user]
GO
GRANT EXECUTE ON [dbo].[uspFillTempSY00500Table] TO [rpt_all user]
GO
GRANT EXECUTE ON [dbo].[uspLocksInUse] TO [rpt_all user]
GO
GRANT EXECUTE ON [dbo].[uspFillTempActiveBatchesTable] TO [rpt_all user]
GO
GRANT EXECUTE ON [dbo].[uspGPUserList] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[vwDashboardUsers] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[vw12HourActivity] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[vw16DayActivity] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[vwOpenBatches] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[vwResourcesinUse] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[vwSessions] TO [rpt_all user]
GO
GRANT SELECT ON  [dbo].[vwProcessesbyUser] TO [rpt_all user]
GO
RAISERROR (N'Permissions Granted to [rpt_all user] for all created objects!', 10, 1) WITH NOWAIT;
GO