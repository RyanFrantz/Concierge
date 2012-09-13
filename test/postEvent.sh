# post event for Clinician Desktop app
curl -d "statusID=2" -d "message=Backend database is being crushed by higher than normal IOPS." http://localhost:8080/apps/1/events
sleep 2
curl -d "statusID=3" -d "message=Database crashed." http://localhost:8080/apps/1/events
sleep 2
curl -d "statusID=1" -d "message=Maintenance was performed to correct the problem. The application is back online." http://localhost:8080/apps/1/events

# request tracker
curl -d "statusID=4" -d "message=Request Tracker needs some indexes rebuilt." http://localhost:8080/apps/2/events
sleep 2
curl -d "statusID=2" -d "message=Request Tracker is experiencing disk performance issues." http://localhost:8080/apps/2/events
sleep 2
#curl -d "statusID=3" -d "message=The database has gone offline." http://localhost:8080/apps/2/events
#sleep 2
curl -d "statusID=1" -d "message=The database performance issue has been corrected." http://localhost:8080/apps/2/events
