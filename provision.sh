#!/usr/bin/env bash

# Laravel homestead original provisioning script
# https://github.com/laravel/settler

# Update Package List
apt-get update
apt-get upgrade -y

#缺失包安装
apt-get install locales


# Force Locale
export LANG=en_US.UTF-8

cd /usr/share/locales
./install-language-pack ${LANG}
dpkg-reconfigure locales

echo "LC_ALL=${LANG}" >> /etc/default/locale
locale-gen ${LANG}

# 时间区域
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 安装 ssh server
apt-get -y install openssh-server pwgen
mkdir -p /var/run/sshd
sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config
sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

# 基本包
apt-get install -y sudo software-properties-common nano curl \
build-essential dos2unix gcc git git-flow libmcrypt4 libpcre3-dev apt-utils \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim zip unzip

# PPA 个人软件包集
apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:ondrej/php -y

# 更新包列表
apt-get update

# 创建homestead用户
adduser homestead
# Add homestead to the sudo group and www-data
#usermod -aG sudo homestead
usermod -aG www-data homestead

# PHP
apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
php7.1-cli php7.1-dev \
php7.1-pgsql php7.1-sqlite3 php7.1-gd \
php7.1-curl php7.1-memcached \
php7.1-imap php7.1-mysql php7.1-mbstring \
php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
php7.1-intl php7.1-readline php-xdebug php-pear


# 安装 Nginx & PHP-FPM
apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
nginx php7.1-fpm 

# Setup Some PHP-FPM Options

echo "xdebug.remote_enable = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php/7.1/mods-available/xdebug.ini
echo "opcache.revalidate_freq = 0" >> /etc/php/7.1/mods-available/opcache.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.1/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini


# Disable XDebug On The CLI
sudo phpdismod -s cli xdebug

# Enable mcrypt
phpenmod mcrypt

# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF


# Set The Nginx & PHP-FPM 用户
sed -i '1 idaemon off;' /etc/nginx/nginx.conf
sed -i "s/user www-data;/user homestead;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

mkdir -p /run/php
touch /run/php/php7.1-fpm.sock
sed -i "s/user = www-data/user = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.owner.*/listen.owner = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.group.*/listen.group = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.1/fpm/pool.d/www.conf

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default


# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
printf "\nPATH=\"/home/homestead/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/homestead/.profile

# Laravel Envoy
su homestead <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
EOF

# Install Node
alias curl='curl -m 20000'
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt-get install -y nodejs
/usr/bin/npm install -g gulp
/usr/bin/npm install -g bower
/usr/bin/npm install -g yarn
/usr/bin/npm install -g grunt-cli

# Install SQLite
apt-get install -y sqlite3 libsqlite3-dev

# Memcached
apt-get install -y memcached

# Beanstalkd
apt-get install -y beanstalkd
sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd

# Redis
apt-get install -y redis-server
sed -i "s/daemonize yes/daemonize no/" /etc/redis/redis.conf

# pm2 node.js 监管
npm install -g pm2

#修改用户名
usermod -p $(echo xsecret | openssl passwd -1 -stdin) root
usermod -p $(echo xsecret | openssl passwd -1 -stdin) homestead

# Configure 定时任务自启动
/lib/systemd/systemd-sysv-install enable cron
