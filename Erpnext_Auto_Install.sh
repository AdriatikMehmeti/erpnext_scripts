#!/bin/bash
: '
This script was made to work even minimal install Linux image.
Simple to use, give it permission execute "chmod +x Erpnext_Auto_Install.sh"
'

clear
echo $'[#]============================================\n[#] AUTOMATE ERPNEXT INSTALL. Running...\n[#] Credits: TIKI\n[#]============================================\n'

# UPDATE & UPGRADE SYSTEM IMAGE
echo $'[+] Update And Upgrade System.\n'
apt-get update > /dev/null
apt-get upgrade > /dev/null

# INSTALL BASE PACKAGE
echo "[+] Install Base Package."
apt -y install sudo gcc g++ make cmake build-essential apt-utils net-tools > /dev/null

# INSTALL BASE LIBS
echo "[+] Install Base Libs."
apt -y install libncurses5-dev zlib1g-dev libnss3-dev libgdbm-dev libssl-dev libsqlite3-dev libffi-dev libreadline-dev libbz2-dev libyaml-0-2 wkhtmltopdf > /dev/null

# INSTALL BASE TOOLS
echo "[+] Install Base Tools."
apt -y install curl wget cron vim nano git > /dev/null

# INSTALL PYTHON PACKAGE
echo "[+] Install Python Package."
apt -y install python3-venv python3-dev python3-pip python3-distutils > /dev/null

# INSTALL BASE SERVICES
echo "[+] Install Base Services."
apt -y install redis-server nodejs npm mariadb-server apache2 nginx > /dev/null

service mariadb start

# INSTALL PYTHON PACKAGE
echo $'[+] Install Python Packages.\n'
apt -y install python3-cliapp python3-markdown python3-pygments python3-ttystatus python3-yaml > /dev/null

# INSTALL PYTHON 3.10 MANUALLY
echo "[+] Download Python 3.10 ."
wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
echo "[+] Extract Python 3.10 ."
tar -xvf Python-3.10.0.tgz > /dev/null
cd Python-3.10.0
echo "[+] Install Python 3.10 ."
sudo ./configure --enable-optimizations > /dev/null
make > /dev/null
sudo make install > /dev/null
cd ../

# PYTHON REPLACE
echo "[+] Move to Python 3.10 ."
mv /usr/bin/python3 /usr/bin/python3BAK
sudo cp /usr/local/bin/python3.10 /usr/bin/python3

# REMOVE UNNECESARY
echo "[+] Clean directory ."
sudo rm -rf Python-3.10.0 Python-3.10.0.tgz

# UPGRADE PIP
echo $'[+] Upgrade pip.\n'
/usr/bin/python3 -m pip install --upgrade pip > /dev/null

# USER ADD SYSTEM
echo $'[+] Create System User ERPNEXT.\n'
useradd -m -s /bin/bash erpnext
passwd erpnext
usermod -aG sudo erpnext

# INSTALL NODE 14 MANUALLY
echo "[+] Download Nodejs v14."
wget https://nodejs.org/dist/v14.17.3/node-v14.17.3-linux-x64.tar.xz
echo "[+] Extract Nodejs v14."
tar -xvf node-v14.17.3-linux-x64.tar.xz > /dev/null
echo "[+] Install Nodejs v14."
cd node-v14.17.3-linux-x64
sudo make > /dev/null
sudo make install > /dev/null
cd ../
sudo cp -r node-v14.17.3-linux-x64/{bin,include,lib,share} /usr/ > /dev/null
export PATH=/usr/node-v14.17.3-linux-x64/bin:$PATH
source ~/.bashrc

# REMOVE UNNECESARY
echo "[+] Clean directory."
sudo rm -rf node-v14.17.3-linux-x64 node-v14.17.3-linux-x64.tar.xz

# INSTALL YARN GLOBALY
echo "[+] Install Yarn."
sudo npm install -g yarn > /dev/null
echo $'[+] Yarn Symbolic links Done.\n'
sudo ln -s /usr/local/lib/node_modules/yarn/bin/yarn /usr/bin/

# DATABASE CONFIGURE
echo $'[+] Database MariaDB Configure.\n'
sudo service mariadb stop > /dev/null
sudo mv /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.BAK
sudo curl https://raw.githubusercontent.com/faheemkhan5/ERPNext-MariaDB-FIle/main/50-server.cnf > 50-server.cnf
sudo mv 50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
sudo service mariadb restart

# CREATE BENCH DIRECTORY
echo $'[+] Create Bench Directory.\n'
sudo mkdir -p /srv/bench
sudo chown -R erpnext /srv/bench

# INSTALL Frappe Framework
echo $'[+] Install Frappe Framework.\n'
pip install frappe-bench > /dev/null

# FIX DATABASE USER
echo $'[+] Database Switch Authentication Mode.\n'
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password; ALTER USER 'root'@'localhost' IDENTIFIED BY ''; FLUSH PRIVILEGES;"

# INSTANCE ERPNEXT
echo $'[+] Setup Instance.\n'
cd /srv/bench/
runuser -u erpnext -- bench init erpnext

cd /srv/bench/erpnext/
read -p 'Site name ex "erp.domain.com": ' uservar
runuser -u erpnext -- bench new-site $uservar
runuser -u erpnext -- bench get-app payments
runuser -u erpnext -- bench --site $uservar install-app erpnext

# REVERT ROOT DATABASE USER AUTH
echo $'[+] Database Revert Authentication Mode.\n'
echo 'Database Authentication (root) '
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password; FLUSH PRIVILEGES;" -p

# START INSTANCE
runuser -u erpnext -- bench start


