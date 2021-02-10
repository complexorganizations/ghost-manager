#!/bin/bash
# https://github.com/complexorganizations/ghost-manager

# Require script to be run as root
function super-user-check() {
  if [ "$EUID" -ne 0 ]; then
    echo "You need to run this script as super user."
    exit
  fi
}

# Check for root
super-user-check

# Detect Operating System
function dist-check() {
  if [ -e /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO=$ID
    DISTRO_VERSION=$VERSION_ID
  fi
}

# Check Operating System
dist-check

# Global variables
GHOST_PATH="/var/www/html"
GHOST_DEVELOPMENT_CONFIG_PATH="$GHOST_PATH/config.development.json"
GHOST_PRODUCTION_CONFIG_PATH="$GHOST_PATH/config.production.json"
GHOST_MANAGER_PATH="$GHOST_PATH/ghost-manager"
NGINX_GLOBAL_CONFIG="/etc/nginx/nginx.conf"

# Pre-Checks system requirements
function installing-system-requirements() {
  if [ ! -d "$GHOST_MANAGER_PATH" ]; then
    if [ "$DISTRO" == "ubuntu" ] && { [ "$DISTRO_VERSION" == "16.04" ] && [ "$DISTRO_VERSION" == "18.04" ] && [ "$DISTRO_VERSION" == "20.04" ]; }; then
      apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
    else
      echo "Error: $DISTRO not supported."
      exit
    fi
  fi
}

# Run the function and check for requirements
installing-system-requirements

# Check if there any other installation of ghost
function previous-ghost-installation() {
  if [ -d "$GHOST_PATH" ]; then
    if [ ! -d "$GHOST_MANAGER_PATH" ]; then
      if { [ -x "$(command -v ghost)" ] || [ -f "$GHOST_DEVELOPMENT_CONFIG_PATH" ] || [ -f "$GHOST_PRODUCTION_CONFIG_PATH" ]; }; then
        echo "Another ghost installation has been discovered."
        exit
      fi
    fi
  fi
}

# Exit the script if there are other installation
previous-ghost-installation

# Install Ghost Server
function install-ghost-server() {
  if { [ ! -x "$(command -v nginx)" ] || [ ! -x "$(command -v mysql)" ] || [ ! -x "$(command -v node)" ] || [ ! -x "$(command -v npm)" ]; }; then
    apt-get install nginx mysql-server nodejs npm -y
    npm install ghost-cli@latest -g
  fi
}

# Install Ghost
install-ghost-server

function configure-ghost() {
  USERNAME="$(openssl rand -hex 10)"
  PASSWORD="$(openssl rand -base64 50)"
  useradd -m -s /bin/bash "$USERNAME" -p "$PASSWORD"
  usermod -aG sudo "$USERNAME"
  chown "$USERNAME":"$USERNAME" /var/www/html/
  chmod 775 /var/www/html
  echo "Username: $USERNAME"
  echo "Password: $PASSWORD"
  if [ -x "$(command -v ghost)" ]; then
    ghost 
  fi
}
