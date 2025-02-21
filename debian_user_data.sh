#!/bin/bash

# Update base OS software
export DEBIAN_FRONTEND=noninteractive
apt update
apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -q -y --force-yes

# Add Docker's official GPG key:
apt-get install -y curl ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install ECS init agent
curl https://s3.${region}.amazonaws.com/amazon-ecs-agent-${region}/amazon-ecs-init-latest.amd64.deb -o /tmp/ecs.deb
dpkg -i /tmp/ecs.deb
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
systemctl enable --now --no-block ecs.service
systemctl restart ecs