#curl -d "statusID=2" http://localhost:3000/apps/2/status
#curl -d "statusID=3" http://localhost:3000/apps/2/status
#curl -d "statusID=1" http://localhost:3000/hosts/2/status

#### 'Web Servers' status is 'UP'
#echo -e "\ncurl -d "statusID=1" http://localhost:3000/services/2/status\n"
#curl -d "statusID=1" http://localhost:3000/services/2/status
#echo -e "\ncurl http://localhost:3000/services/2/status\n"
#curl http://localhost:3000/services/2/status
#echo -e "\n\nDEPS:"
#echo -e "\ncurl http://localhost:3000/services/2/deps\n"
#curl http://localhost:3000/services/2/deps

#### 'Web Servers' status is 'DOWN'
echo -e "\ncurl -d "statusID=2" http://localhost:3000/services/2/status\n"
curl -d "statusID=2" http://localhost:3000/services/2/status
echo -e "\ncurl http://localhost:3000/services/2/status\n"
curl http://localhost:3000/services/2/status
echo -e "\n\nDEPS:"
echo -e "\ncurl http://localhost:3000/services/2/deps\n"
curl http://localhost:3000/services/2/deps
