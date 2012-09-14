# post event for Clinician Desktop app
curl -d "statusID=2" -d "message=Backend database is being crushed by higher than normal IOPS." http://localhost/apps/1/events
sleep 2
curl -d "statusID=3" -d "message=Database crashed." http://localhost/apps/1/events
sleep 2
curl -d "statusID=1" -d "message=Maintenance was performed to correct the problem. The application is back online." http://localhost/apps/1/events

# request tracker
curl -d "statusID=4" -d "message=Request Tracker needs some indexes rebuilt." http://localhost/apps/2/events
sleep 2
curl -d "statusID=2" -d "message=Request Tracker is experiencing disk performance issues." http://localhost/apps/2/events
sleep 2
#curl -d "statusID=3" -d "message=The database has gone offline." http://localhost/apps/2/events
#sleep 2
curl -d "statusID=1" -d "message=The database performance issue has been corrected." http://localhost/apps/2/events
sleep 2

# Ad Hoc Reporting
curl -d "statusID=4" -d "message=The Ad Hoc Reporting application is scheduled for routine maintenance from 2200hrs EST to 2300hrs EST." http://localhost/apps/6/events
sleep 2

# Service DNS
curl -d "statusID=2" -d "message=Host dns2 is unavailable.  All other DNS servers are available." http://localhost/services/1/events
