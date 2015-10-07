###Start registry-v2

curl -sSL https://get.docker.com | sh

curl -L https://github.com/docker/compose/releases/download/1.4.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 1000 -out domain.crt

docker-compose up -d

###Versions
Docker version 1.8.2, build 0a8c2e3
docker-compose version: 1.4.2

###Primary source
https://github.com/docker/distribution/blob/master/docs/nginx.md