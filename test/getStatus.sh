#curl http://localhost:3000/apps/2/status
#curl http://localhost:3000/hosts/2/status
#curl http://localhost:3000/services/2/status
#### host deps
#echo "curl http://localhost:3000/hosts"
#curl http://localhost:3000/hosts
#echo "curl http://localhost:3000/hosts/2/deps"
#curl http://localhost:3000/hosts/2/deps
#### service deps
echo -e "\ncurl http://localhost:3000/services"
curl http://localhost:3000/services
echo -e "\ncurl http://localhost:3000/services/2/deps"
curl http://localhost:3000/services/2/deps
