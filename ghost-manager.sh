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
  fi
}

# Check Operating System
dist-check

# Global variables
GHOST_PATH="/var/www/html"
GHOST_DEVELOPMENT_CONFIG_PATH="$GHOST_PATH/config.development.json"
GHOST_PRODUCTION_CONFIG_PATH="$GHOST_PATH/config.production.json"
GHOST_MANAGER_PATH="$GHOST_PATH/ghost-manager"

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ] || [ "$DISTRO" == "alpine" ] || [ "$DISTRO" == "freebsd" ]; }; then
    if [ ! -x "$(command -v curl)" ]; then
      if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ]; }; then
        apt-get update && apt-get upgrade -y && apt-get install curl -y
      elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
        yum update -y && yum install curl
      elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
        pacman -Syu && pacman -Syu --noconfirm curl
      elif [ "$DISTRO" == "alpine" ]; then
        apk update && apk add curl
      elif [ "$DISTRO" == "freebsd" ]; then
        pkg update && pkg install curl
      fi
    fi
  else
    echo "Error: $DISTRO not supported."
    exit
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

if [ ! -f "$GHOST_MANAGER_PATH" ]; then

  # Install Ghost Server
  function install-ghost-server() {
    if { [ ! -x "$(command -v ghost)" ] || [ ! -x "$(command -v node)" ] || [ ! -x "$(command -v npm)" ] || [ ! -x "$(command -v nginx)" ] || [ ! -x "$(command -v mysql)" ]; }; then
      curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash
      if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ]; }; then
        apt-get update
        apt-get install nginx mysql-server nodejs -y
        npm install ghost-cli@latest -g
      elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
        echo "hello, world"
      elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
        echo "hello, world"
      elif [ "$DISTRO" == "alpine" ]; then
        echo "hello, world"
      elif [ "$DISTRO" == "freebsd" ]; then
        echo "hello, world"
      fi
      npm install ghost-cli@latest -g
    fi
  }

  # Install Ghost
  install-ghost-server

  function configure-mysql() {
    PASSWORD="$(openssl rand -base64 25)"
    mysql
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY "$PASSWORD"
    quit
    echo "MySQL Information"
    echo "Username: root"
    echo "Password: $PASSWORD"
  }

  function setup-linux-user() {
    if [ ! -f "$GHOST_MANAGER_PATH" ]; then
      USERNAME="$(openssl rand -hex 5)"
      PASSWORD="$(openssl rand -base64 25)"
      useradd -m -s /bin/bash "$USERNAME" -p "$PASSWORD"
      usermod -aG sudo "$USERNAME"
      chown "$USERNAME":"$USERNAME" /var/www/html/
      chmod 775 /var/www/html
      echo "Linux Information"
      echo "Username: $USERNAME"
      echo "Password: $PASSWORD"
    fi
  }

  setup-linux-user

  function ghost-path-setup() {
    if [ ! -f "$GHOST_MANAGER_PATH" ]; then
      mkdir -p $GHOST_PATH
      echo "Ghost: True" >>$GHOST_MANAGER_PATH
    fi
  }

  ghost-path-setup

else

  function after-install-input() {
    echo "What do you want to do?"
    echo "   1) Option #1"
    echo "   2) Option #2"
    echo "   3) Option #3"
    echo "   4) Option #4"
    echo "   5) Option #5"
    until [[ "$USER_OPTIONS" =~ ^[0-9]+$ ]] && [ "$USER_OPTIONS" -ge 1 ] && [ "$USER_OPTIONS" -le 5 ]; do
      read -rp "Select an Option [1-5]: " -e -i 1 USER_OPTIONS
    done
    case $USER_OPTIONS in
    1)
      echo "Hello, World!"
      ;;
    2)
      echo "Hello, World!"
      ;;
    3)
      echo "Hello, World!"
      ;;
    4)
      echo "Hello, World!"
      ;;
    5)
      echo "Hello, World!"
      ;;
    esac
  }

  # run the function
  after-install-input

fi
