#!/bin/bash

# Function to check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to install Docker
install_docker() {
    echo "Docker is not installed. Installing Docker..."
    
    # Update package index and install dependencies
    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up the stable repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # Verify Docker installation
    sudo docker --version

    echo "Docker installation completed."
}

# Function to run SonarQube container
run_sonarqube() {
    echo "Running SonarQube container..."
    sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube
}

# Main script
while true; do
    if check_docker; then
        echo "Docker is already installed."
        run_sonarqube
        break
    else
        install_docker
    fi
done

