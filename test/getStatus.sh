#curl http://localhost:3000/apps/2/status
#curl http://localhost:3000/hosts/2/status
#curl http://localhost:3000/services/2/status
####
echo "curl http://localhost:3000/apps"
curl http://localhost:3000/apps
echo "curl http://localhost:3000/apps/2/deps"
curl http://localhost:3000/apps/2/deps
####
echo -e "\ncurl http://localhost:3000/services"
curl http://localhost:3000/services
echo -e "\ncurl http://localhost:3000/services/2/deps"
curl http://localhost:3000/services/2/deps
