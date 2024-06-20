##Install in Amazon Ubuntu
#!/bin/bash
sudo apt update -y

#sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" -y

#apt-cache policy docker-ce -y

#sudo apt install docker-ce -y

#sudo systemctl status docker

sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker $USER  # Replace with your system's username, e.g., 'ubuntu'
newgrp docker

sudo chmod 777 /var/run/docker.sock #if get permission error then update with 666
