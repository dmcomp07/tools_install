#!/bin/bash

# Check for hardware prerequisites
mem_size=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
echo "Minimum memory required : 4Gi (4194304KB)"
echo "Available memory : $mem_size KB "
if [[ $mem_size -lt 4194304 ]]; then
  echo "Error: Your system does not meet the minimum memory requirement of 4GB " >&2
  exit 1
fi

num_cpus=$(nproc)
echo "Minimum CPU cores required : 2 cores"
echo "Available CPU cores : $num_cpus cores"
if [[ $num_cpus -lt 2 ]]; then
  echo "Error: Your system does not meet the minimum CPU requirement of 2 cores " >&2
  exit 1
fi


sudo apt update -y
sudo useradd --system --no-create-home --shell /bin/false prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz

tar -xvf prometheus-2.47.1.linux-amd64.tar.gz
cd prometheus-2.47.1.linux-amd64/
sudo mkdir -p /data /etc/prometheus
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

sudo chown -R prometheus:prometheus /etc/prometheus/ /data/


cat <<EOF > /etc/systemd/system/prometheus.service

[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl enable prometheus
sudo systemctl start prometheus

sudo systemctl status prometheus

