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
GHOST_CONTENT_PATH="$GHOST_PATH/content"
GHOST_BACKUP_PATH="/backup/content"
GHOST_MANAGER_UPDATE_URL="https://raw.githubusercontent.com/complexorganizations/ghost-manager/main/ghost-manager.sh"

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ] || [ "$DISTRO" == "alpine" ] || [ "$DISTRO" == "freebsd" ]; }; then
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v openssl)" ]; }; then
      if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ]; }; then
        apt-get update && apt-get upgrade -y && apt-get install curl openssl -y
      elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
        yum update -y && yum install curl openssl
      elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
        pacman -Syu && pacman -Syu --noconfirm curl openssl
      elif [ "$DISTRO" == "alpine" ]; then
        apk update && apk add curl openssl
      elif [ "$DISTRO" == "freebsd" ]; then
        pkg update && pkg install curl openssl
      fi
    fi
  else
    echo "Error: $DISTRO not supported."
    exit
  fi
}

# Run the function and check for requirements
installing-system-requirements

if [ ! -f "$GHOST_MANAGER_PATH" ]; then

  # Check if there any other installation of ghost
  function previous-ghost-installation() {
    if [ -d "$GHOST_PATH" ]; then
      if [ ! -d "$GHOST_MANAGER_PATH" ]; then
        if { [ -f "$GHOST_DEVELOPMENT_CONFIG_PATH" ] || [ -f "$GHOST_PRODUCTION_CONFIG_PATH" ]; }; then
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
    if { [ ! -x "$(command -v ghost)" ] || [ ! -x "$(command -v node)" ] || [ ! -x "$(command -v npm)" ] || [ ! -x "$(command -v nginx)" ] || [ ! -x "$(command -v mysql)" ]; }; then
      if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ]; }; then
        curl -sL https://deb.nodesource.com/setup_12.x | bash -
        apt-get update
        apt-get install nginx mariadb-server nodejs -y
      elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
        curl -sL https://rpm.nodesource.com/setup_12.x | bash -
        yum update
        yum install nginx mariadb-server nodejs -y
      elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
        pacman -Syu
        pacman -Syu --noconfirm nginx mariadb nodejs
      elif [ "$DISTRO" == "alpine" ]; then
        apk add nginx mariadb nodejs
      elif [ "$DISTRO" == "freebsd" ]; then
        pkg install nginx mariadb nodejs
      fi
      npm install ghost-cli@latest -g
    fi
  }

  # Install Ghost
  install-ghost-server

  function configure-mysql() {
    if [ -x "$(command -v mysql)" ]; then
      MYSQL_DB_IP="localhost"
      MYSQL_DB_PORT="3306"
      MYSQL_DB_USER="root"
      MYSQL_DB_PASSWORD="$(openssl rand -hex 10)"
      printf "n\n n\n y\n y\n y\n y\n" | mysql_secure_installation
      mysql -e "ALTER USER '$MYSQL_DB_USER'@'$MYSQL_DB_IP' IDENTIFIED BY '$MYSQL_DB_PASSWORD';"
      echo "MySQL Information"
      echo "IP Address: $MYSQL_DB_IP"
      echo "Port: $MYSQL_DB_PORT"
      echo "Username: $MYSQL_DB_USER"
      echo "Password: $MYSQL_DB_PASSWORD"
    fi
  }

  configure-mysql

  function setup-linux-user() {
    if [ -x "$(command -v mysql)" ]; then
      rm -rf $GHOST_PATH
      mkdir -p $GHOST_PATH
      LINUX_USERNAME="$(openssl rand -hex 5)"
      LINUX_PASSWORD="$(openssl rand -hex 10)"
      useradd -m -s /bin/bash "$LINUX_USERNAME"
      echo -e "$LINUX_PASSWORD\n$LINUX_PASSWORD" | passwd "$LINUX_USERNAME"
      usermod -aG sudo "$LINUX_USERNAME"
      chown "$LINUX_USERNAME":"$LINUX_USERNAME" $GHOST_PATH
      chmod 775 $GHOST_PATH
      find $GHOST_PATH* -type d -exec chmod 775 {} \;
      find $GHOST_PATH* -type f -exec chmod 664 {} \;
      cd "$GHOST_PATH" || exit
      echo "Linux Information"
      echo "Username: $LINUX_USERNAME"
      echo "Password: $LINUX_PASSWORD"
      sudo -u "$LINUX_USERNAME" ghost install
    fi
  }

  setup-linux-user

  function ghost-path-setup() {
    if [ -d "$GHOST_CONTENT_PATH" ]; then
      if [ ! -f "$GHOST_MANAGER_PATH" ]; then
        echo "Ghost: True" >>$GHOST_MANAGER_PATH
      fi
    fi
  }

  ghost-path-setup

else

  function after-install-input() {
    echo "What do you want to do?"
    echo "   1) Update Ghost"
    echo "   2) Start Ghost"
    echo "   3) Stop Ghost"
    echo "   4) Restart Ghost"
    echo "   5) Ghost Doctor"
    echo "   6) Ghost Log"
    echo "   7) Backup Ghost"
    echo "   8) Backup Uninstall"
    echo "   9) Update This Script"
    until [[ "$USER_OPTIONS" =~ ^[0-9]+$ ]] && [ "$USER_OPTIONS" -ge 1 ] && [ "$USER_OPTIONS" -le 9 ]; do
      read -rp "Select an Option [1-5]: " -e -i 1 USER_OPTIONS
    done
    case $USER_OPTIONS in
    1)
      cd $GHOST_PATH || exit
      ghost update
      ;;
    2)
      cd $GHOST_PATH || exit
      ghost start
      ;;
    3)
      cd $GHOST_PATH || exit
      ghost stop
      ;;
    4)
      cd $GHOST_PATH || exit
      ghost restart
      ;;
    5)
      cd $GHOST_PATH || exit
      ghost doctor
      ;;
    6)
      cd $GHOST_PATH || exit
      ghost log
      ;;
    7)
      if [ -d "$GHOST_CONTENT_PATH" ]; then
        rm -rf $GHOST_BACKUP_PATH
        cp -r $GHOST_CONTENT_PATH $GHOST_BACKUP_PATH
      fi
      ;;
    8)
      cd $GHOST_PATH || exit
      ghost uninstall
      ;;
    9)
      CURRENT_FILE_PATH="$(realpath "$0")"
      if [ -f "$CURRENT_FILE_PATH" ]; then
        curl -o "$CURRENT_FILE_PATH" $GHOST_MANAGER_UPDATE_URL
        chmod +x "$CURRENT_FILE_PATH" || exit
      fi
      ;;
    esac
  }

  # run the function
  after-install-input

fi
