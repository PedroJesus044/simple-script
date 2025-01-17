sudo dnf check-update -y
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y --allowerasing docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker

export $(cat .env | xargs) && rails c

docker pull owncloud/server:${OWNCLOUD_VERSION}
docker pull mariadb:11.6.2-ubi
docker pull redis:6
