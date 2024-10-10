# GP-Dashboard
GP Dashboard on a Dime for System Admins
The Excel GP Admin Dashboard is a project that goes back in the late years of 2010's and early 2020's when GPUG members Steve Erbach and Beat Bucher decided to join resources and puut together some of the nifty SQL scripts they had devlopped over the years of administrating Dynamics GP in their respective jobs. 
The result is a combination of SQL scripts and an Excel Workbook that queries data from your GP back-end system (SQL Server) and presents them nicely in various tabs, with a main "Dhasboard" providing a summary of what's going on. The dashbaord was built with System Admins in mind, so they could keep the Excel open in resized mode to see the vital data about their GP instance. The workbook can be set to refresh the data automatically every X minutes, so it would require minimal intervention. 
Read carefully thru the various text files to know how to install the whole project. Ideally the setup should be done in SQL with a user having 'sysadmin' privileges to make sure permissions are granted properly. 
There has been various versions of the GP Admin Dashboard over the years, the latest version V4 has been refined in a way that a single script should cover everything. 
# DISCLAIMER!
The scripts and workbook are provided "as-is" with no warranty of succes, as there are too many unknown factors that could break or prevent the dashboard to work (namely on the SQL server security side). If you need assistance, please reach out to the authors thru the Linked-In group. 
