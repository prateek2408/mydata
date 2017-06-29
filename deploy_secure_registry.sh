wget -qO- https://get.docker.com/ | sh
usermod -aG docker $(whoami)
apt-get -y install python-pip
apt-get -y install apache2-utils
pip install docker-compose

rm -rf  /opt/registry/

mkdir /opt/registry/
mkdir /opt/registry/data
mkdir /opt/registry/nginx

echo "
upstream docker-registry {
  server registry:5000;
}

server {
  listen 443;
  server_name mydomain.com;
  #ssl on;
  #ssl_certificate /etc/nginx/conf.d/domain.crt;
  #ssl_certificate_key /etc/nginx/conf.d/domain.key;
  client_max_body_size 0;
  chunked_transfer_encoding on;
  location /v2/ {
    if (\$http_user_agent ~ \"^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*$\" ) {
      return 404;
    }
    auth_basic "registry.localhost";
    auth_basic_user_file /etc/nginx/conf.d/registry.password;
    add_header 'Docker-Distribution-Api-Version' 'registry/2.0' always;
    proxy_pass                          http://docker-registry;
    proxy_set_header  Host              \$http_host;   # required for docker client's sake
    proxy_set_header  X-Real-IP         \$remote_addr; # pass on real client's IP
    proxy_set_header  X-Forwarded-For   \$proxy_add_x_forwarded_for;
    proxy_set_header  X-Forwarded-Proto \$scheme;
    proxy_read_timeout                  900;
  }
}" > /opt/registry/nginx/registry.conf

echo "
docker:\$apr1\$87MTwHGd\$mowtzAcE2VW0mzQl55XUA1
" > registry/nginx/registry.password

echo "
registry:
  image: registry:2
  ports:
    - 127.0.0.1:5000:5000
  environment:
    REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
  volumes:
    - /opt/registry/data:/data

nginx:
  image: "nginx:1.9"
  ports:
    - 5043:443
  links:
    - registry:registry
  volumes:
    - /opt/registry/nginx/:/etc/nginx/conf.d:ro
" > /opt/registry/docker-compose.yaml
cd /opt/registry/
docker-compose up -d

curl http://docker:docker123@localhost:5043/v2/
