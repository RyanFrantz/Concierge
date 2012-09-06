# post event for Clinician Desktop app
echo "curl -d \"statusID=3\" --data-urlencode \"message=Database got dropped\" http://localhost:8080/apps/1/events"
#curl -d "statusID=3" --data-urlencode "message=Database got dropped" http://localhost:8080/apps/1/events
curl -d "statusID=3" --data-urlencode "message=problem" http://localhost:8080/apps/1/events
