#!/bin/bash
sudo apt update
sudo apt install apache2 -y

sudo groupadd terraform
sudo useradd -s /bin/bash -m -d /home/backup-user -G admin,terraform -c 'added by Terraform' backup-user