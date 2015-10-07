mkdir -p auth
mkdir -p data

cat <<EOF > auth/nginx.conf
upstream docker-registry {
  server registry:5000;
}

server {
  listen 443 ssl;
  server_name docker-ci.oxagile.com;

  # SSL
  ssl on;
  ssl_certificate /etc/nginx/conf.d/domain.crt;
  ssl_certificate_key /etc/nginx/conf.d/domain.key;

  # Recommandations from https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
  ssl_protocols TLSv1.1 TLSv1.2;
  ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;

  # disable any limits to avoid HTTP 413 for large image uploads
  client_max_body_size 0;

  # required to avoid HTTP 411: see Issue #1486 (https://github.com/docker/docker/issues/1486)
  chunked_transfer_encoding on;

  location /v2/ {
    # Do not allow connections from docker 1.5 and earlier
    # docker pre-1.6.0 did not properly set the user agent on ping, catch "Go *" user agents
    if ($http_user_agent ~ "^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*$" ) {
          return 404;
          
      }

     auth_basic "Registry realm";
     auth_basic_user_file /etc/nginx/conf.d/nginx.htpasswd;	
     add_header 'Docker-Distribution-Api-Version' 'registry/2.0' always;
              
    proxy_pass                          http://docker-registry;
    proxy_set_header  Host              \$http_host;   # required for docker client's sake
    proxy_set_header  X-Real-IP         \$remote_addr; # pass on real client's IP
    proxy_set_header  X-Forwarded-For   \$proxy_add_x_forwarded_for;
    proxy_set_header  X-Forwarded-Proto \$scheme;
    proxy_read_timeout                  900;
  }
}
EOF

docker run --entrypoint htpasswd httpd:2.4 -bn testuser testpassword > auth/nginx.htpasswd

cp domain.crt auth
cp domain.key auth

cat <<EOF > docker-compose.yml
nginx:
  image: "nginx:1.9"
  ports:
    - 5043:443
  links:
    - registry:registry
  volumes:
    - `pwd`/auth/:/etc/nginx/conf.d

registry:
  image: registry:2
  ports:
    - 5000:5000
  volumes:
    - `pwd`/data:/var/lib/registry
EOF

