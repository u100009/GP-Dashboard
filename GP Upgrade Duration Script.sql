Use Dynamics
Declare @db_verBuild as Int = 1596 --GP 2016 R2 --GP 2013 R2 2230 Patch
Declare @db_verMajor as Int = 18   --GP 2016 R2 --GP 2013 R2

-- Dynamics..DB_Upgrade
-- Table script - Version 4.1
-- Written by David Morinello
-- Updated 12/08/2016
-- Updated 09/19/2018 -Improved Elapsed time calculations
-- Updated 01/23/2019 - Fixed Variable type bug
-- Tells you you current status when run during a GP upgrade
-- Update the db_verBuild = 1860 to the version you are upgrading to

--Status Constant			Storage Value
--DU_STATUS_DONE 			0
--DU_STATUS_START 			1
--DU_STATUS_INSTALL 		2
--DU_STATUS_UPGRADE 		3
--DU_STATUS_BIND_DEFAULTS   7
--DU_STATUS_RECOMPILE		8
--                          9
--                          10
--                          15
--                          16
--DU_STATUS_CONVERT			23
--Table Conversion Step			23
--DU_STATUS_POST_CONVERT	30
--                          43
--                          48
--                          49
--                          52
--                          53
--                          54


--Status Constant			Storage Value
--DU_STATUS_DONE 			0
--DU_STATUS_START 			1
--DU_STATUS_INSTALL 		2
--DU_STATUS_UPGRADE 		3
--DU_STATUS_BIND_DEFAULTS   7
--DU_STATUS_RECOMPILE		8
--DU_STATUS_CONVERT			23
--DU_STATUS_POST_CONVERT	30
--Step Description
--1 Start of Process
--2 If an install, load Defaults (directory\DEFAULTS.extension)
--3 If an install, create Tables (directory\TABLES.extension)
--4 If an install, create Indexes (directory\INDEXES.extension)
--5 If an install, create Views (directory\VIEWS.extension)
--6 If an install, create DexProcs (directory\DEXPROCS.extension)
--7 If an upgrade, drop changed DexProcs (directory\DEXPROCS.DRP)
--8 If an upgrade, drop changed App Procs (directory\APPPROCS.DRP)
--9 If an upgrade, drop changed Indexes (directory\INDX.DRP)
--10 If an upgrade, drop changed Views (directory\VIEWS.DRP)
--11 If an upgrade, drop changed Triggers (directory\TRIGGERS.DRP)
--12 If an upgrade, drop changed Rules (directory\RULES.DRP)
--13 If an upgrade, drop deleted Tables (directory\TABLES.DRP)
--14 If an upgrade, run any SQL code updates (directory\SQL.NEW)
--15 If an upgrade, add new Tables (directory\TABLES.NEW)
--16 If an upgrade, add new Indexes (directory\INDX.NEW)
--17 If an upgrade, add new DexProcs (directory\DEXPROCS.NEW)
--18 If Lesson DB and an install, create Stubs (directory\STUBS.extension)
--19 If Lesson DB and an install, create Procs (directory\PROCS.extension)
--20 If Lesson DB and an install, create Tables (SQL\LESSON\TWO.CMP)
--21 If Lesson DB and an install, BCP in data (SQL\LESSON\DATA\BCPTEMP.BAT)
--21 If (not System DB) and an upgrade, start conversion/synchronization process
--21 If System DB, BCP in data (SQL\SYSTEM\DATA\BCPTEMP.BAT)
--30 End of conversion/synchronization process
--41 If an upgrade, add new Views (directory\VIEWS.extension)
--42 Create Triggers (directory\TRIGGERS.extension)
--43 Create Rules (directory\RULES.extension)
--44 If not Lesson DB, create Stubs (directory\STUBS.extension)
--45 If not Lesson DB, create Procs (directory\PROCS.extension)
--46 If (not System DB) and an install, create FRx data (directory\FRXDATA.SQL)
--47 If (not System DB), grant access (EXEC DBName..smGrantAccessOnAccountMSTR)
--48 Bind table defaults (EXEC DBName..smBindTableDefaults)
--49 Recompile procs (SQL\UTIL\RECOMP.SQL)
--50 If Company DB and an install, run Dynamics front-end logic to create the company
--51 If not System DB, create Business Alerts (SQL\COMPANY\ALERTS.SQL)
--0 Process completed

-- Look up and calulate the DB Sizes
IF OBJECT_ID('tempdb..#spacetable') IS NOT NULL 
DROP TABLE tempdb..#spacetable 
create table #spacetable
(
database_name varchar(50) ,
[total db size] int
)
insert into  #spacetable
EXECUTE master.sys.sp_MSforeachdb 'USE [?];
select x.[DATABASE NAME],
       y.[total size log]+x.[total size data] ''total db size''--,
from (select DB_NAME() ''DATABASE NAME'', sum(size*8/1024) ''total size data'',sum(FILEPROPERTY(name,''SpaceUsed'')*8/1024) ''space util''
,case when sum(size*8/1024)=0 then ''divide by zero'' else
substring(cast((sum(FILEPROPERTY(name,''SpaceUsed''))*1.0*100/sum(size)) as CHAR(50)),1,6) end ''percent fill''
from sys.master_files where database_id=DB_ID(DB_NAME())  and  type=0
group by type_desc  ) as x ,
(select 
sum(size*8/1024) ''total size log'',sum(FILEPROPERTY(name,''SpaceUsed'')*8/1024) ''space util''
,case when sum(size*8/1024)=0 then ''divide by zero'' else
substring(cast((sum(FILEPROPERTY(name,''SpaceUsed''))*1.0*100/sum(size)) as CHAR(50)),1,6) end ''percent fill''
from sys.master_files where database_id=DB_ID(DB_NAME())  and  type=1
group by type_desc  )y'

------ 
Declare @CompanyCount as INT
Select @CompanyCount = COUNT(*) from Dynamics..SY01500

SELECT db_name, PRODID, db_verMajor, db_verBuild, db_status, 
       Left(Convert(varchar(11) ,start_time, 0),11)+' ' + right(Convert(varchar ,start_time, 8), 8) as StartTime,
       Left(Convert(varchar(11) ,stop_time, 0),11)+' ' + right(Convert(varchar ,stop_time, 8), 8)  as StopTime,
       Convert(varchar, stop_time - start_time, 8) AS Duration,
       Case 
	   	 When db_status = 0  Then '1 - Upgraded' 
	   	 --When db_status = 0  Then '0 - DU_STATUS_DONE'
	   	 When db_status = 1  Then '2 - In Process: 1 - DU_STATUS_START' 
	   	 When db_status = 2  Then '2 - In Process: 2 - DU_STATUS_INSTALL' 
	   	 When db_status = 3  Then '2 - In Process: 3 - DU_STATUS_UPGRADE' 
	   	 When db_status = 7  Then '2 - In Process: 7 - DU_STATUS_BIND_DEFAULTS'  
	   	 When db_status = 8  Then '2 - In Process: 8 - DU_STATUS_RECOMPILE'
	   	 When db_status = 9  Then '2 - In Process: 9 - Drop changed Indexes (directory\INDX.DRP)'
	   	 When db_status = 10 Then '2 - In Process: 10 - Drop changed Views (directory\VIEWS.DRP)'
	   	 When db_status = 15 Then '2 - In Process: 15 - Add new Tables (directory\TABLES.NEW)'
	   	 When db_status = 16 Then '2 - In Process: 16 - Add new Indexes (directory\INDX.NEW)'
	   	 When db_status = 23 Then '2 - In Process: 23 - DU_STATUS_CONVERT'
	   	 When db_status = 30 Then '2 - In Process: 30 - DU_STATUS_POST_CONVERT'
	   	 When db_status = 43 Then '2 - In Process: 43 - Create Rules (directory\RULES.extension)'
	   	 When db_status = 48 Then '2 - In Process: 48 - Bind table defaults (EXEC DBName..smBindTableDefaults)'
	   	 When db_status = 49 Then '2 - In Process: 49 - Recompile procs (SQL\UTIL\RECOMP.SQL)'
	   	 When db_status = 51 Then '2 - In Process: 51 - Create Business Alerts (SQL\COMPANY\ALERTS.SQL)'
	   	 When db_status = 52 Then '2 - In Process: 52'
	   	 When db_status = 53 Then '2 - In Process: 53'
	   	 When db_status = 54 Then '2 - In Process: 54'
	   	 Else '2 - In Process'
	   End as Status,
	   format(#spacetable.[total db size] , 'N0') as [Total_Database_Size]
FROM  DB_Upgrade Inner Join #spacetable ON DB_Upgrade.db_name = #spacetable.database_name
WHERE PRODID = 0 and  db_verBuild = @db_verBuild
Union All
SELECT db_name, PRODID, db_verMajor, db_verBuild, db_status, 
       '' as StartTime, '' as StopTime, 
              '' AS Duration, 
       '3 - Not Upgraded' as status, 
	   format(#spacetable.[total db size] , 'N0') as [Total_Database_Size]
FROM  DB_Upgrade Inner Join #spacetable ON DB_Upgrade.db_name = #spacetable.database_name
WHERE PRODID = 0 and  (db_verBuild < @db_verBuild or db_verMajor < @db_verMajor)
ORDER BY status, StartTime asc

-- Percentage Complete
SELECT Count(*) as 'Completed', @CompanyCount as 'Total Databases', 
Rtrim(Cast(Cast(Cast(Count(*)as decimal)/@CompanyCount as decimal(3,2)) * 100 as Char)) as 'Percent Complete'
FROM  DB_Upgrade WHERE PRODID = 0 and db_verBuild = @db_verBuild and db_status = 0 and DB_Name <> 'Dynamics'

Declare @Percentage as Float = 0.00
Declare @Duration as INT = 0
Declare @Duration2 as INT = 0
Declare @Duration3 as INT = 0
Declare @DurationH as INT = 0
Declare @DurationM as INT 
Declare @StartTime as DateTime --Char(50)
Declare @DurationEstimate as INT = 0--DateTime --Char(50)
--***************************************************

SELECT @Percentage = Rtrim(Cast(Cast(Cast(Count(*)as decimal)/@CompanyCount as decimal(3,2)) as Char))
FROM  DB_Upgrade WHERE PRODID = 0 and db_verBuild = @db_verBuild and db_status = 0 and DB_Name <> 'Dynamics'

select @DurationH = SUM(Duration) / 3600, 
       @DurationM = (sum(Duration) / 3600) / 60 
from
(
SELECT Datediff(second, MIN(Start_Time), MAX(Stop_time)) AS Duration
FROM DB_Upgrade 
WHERE PRODID = 0 and  db_verBuild = @db_verBuild and db_status = 0
) y

--Improve Duration calc (I hope ;-})
select @Duration = Duration
from
(
SELECT Datediff(second, MIN(Start_Time), MAX(Stop_time)) AS Duration
FROM DB_Upgrade 
WHERE PRODID = 0 and  db_verBuild = @db_verBuild and db_status = 0
)x

SELECT 
    CONVERT(VARCHAR(12), @Duration /60/60/24)   + ' Day(s),  ' 
  + CONVERT(VARCHAR(12), @Duration /60/60 % 24) + ' Hour(s),  '
  + CONVERT(VARCHAR(2),  @Duration /60 % 60)    + ' Minute(s),  ' 
  + CONVERT(VARCHAR(2),  @Duration % 60)        + ' Second(s).' AS [Elapsed Time]

-- Estimate Time Calculation
If @Percentage = 0
Begin
   Select 0
End
Else Begin	
    Select @Duration2 = (@Duration * 100) / (@Percentage*100)
End

Select @StartTime = Left(Convert(varchar(11) ,start_time, 0),11)+' ' + right(Convert(varchar ,start_time, 8), 8)
FROM DB_Upgrade 
WHERE PRODID = 0 and  db_verBuild = @db_verBuild and db_name = 'Dynamics'

-- Times Calculations were broken for over 24 hours [Estimated Completion time], Now fixed(I hope)
select @DurationEstimate = @Duration * (100/@Percentage)

SELECT 
    CONVERT(VARCHAR(12), @Duration2 /60/60/24)   + ' Day(s),  ' 
  + CONVERT(VARCHAR(12), @Duration2 /60/60 % 24) + ' Hour(s),  '
  + CONVERT(VARCHAR(2),  @Duration2 /60 % 60)    + ' Minute(s),  ' 
  + CONVERT(VARCHAR(2),  @Duration2 % 60)        + ' Second(s).' AS [Estimate Time to Complete]

select @StartTime AS [Start Time], DATEADD(ss, @Duration2, @StartTime) AS [Estimate Date/Time to Complete]

--Drop Temp Table that looks up the DB Sizes
drop table #spacetable