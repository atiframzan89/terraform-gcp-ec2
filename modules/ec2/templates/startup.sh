#!/bin/bash

set -x
echo "Running startup script..."
apt-get update -y
apt-get install -y nginx
systemctl start nginx
echo "<h1>Hello from Startup Script!</h1>" > /var/www/html/index.html