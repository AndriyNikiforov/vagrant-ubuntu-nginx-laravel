#!/usr/bin/env bash

# Set up mysql root password
debconf-set-selections <<< 'mariadb-server mysql-server/root_password password root'
debconf-set-selections <<< 'mariadb-server mysql-server/root_password_again password root'

# Install apache, php, mysql
APTSOURCES=$(cat <<EOF
deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx
EOF
)
echo "${APTSOURCES}" >> /etc/apt/sources.list

curl -sL https://deb.nodesource.com/setup_7.x | bash -

apt-get install -y mariadb-server git unzip nginx php-fpm php-cli php-common php-curl php-gd php-imap php-memcache php-mysql php-mbstring php-xml php-mcrypt sqlite php-sqlite3 nodejs --allow-unauthenticated

# PHP and nginx config setup
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini
sed -i "s/user .*;/user www-data;/" /etc/nginx/nginx.conf
echo "cgi.fix_pathinfo = 0" >> /etc/php/7.0/fpm/php.ini
echo "date.timezone = \"Europe/London\"" >> /etc/php/7.0/fpm/php.ini

cp /vagrant/vagrant/nginx-vhost.conf /etc/nginx/conf.d/default.conf

# Set timezone
echo "Europe/London" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Set up mysql - not secure at all but its fine for dev
#sed -i -e 's/^\(bind-address\)/#\1/g' /etc/mysql/my.cnf
sed -i -e 's/^\(bind-address\)/#\1/g' /etc/mysql/mariadb.conf.d/50-server.cnf
echo "GRANT ALL on *.* TO root@'%' identified by 'root'" | mysql -uroot -proot
echo "FLUSH PRIVILEGES" | mysql -uroot -proot

service nginx restart
service php7.0-fpm restart
service mysql restart

# Install composer
wget https://getcomposer.org/composer.phar
chmod +x composer.phar
mv composer.phar /usr/bin/composer

# Create a laravel project called 'testapp' and create a database
cd /vagrant/web/
composer create-project --prefer-dist laravel/laravel testapp
cd testapp
php artisan key:generate

echo "CREATE DATABASE IF NOT EXISTS testapp" | mysql -uroot -proot
echo "CREATE USER 'testapp'@'localhost' IDENTIFIED BY 'testapp'" | mysql -uroot -proot
echo "GRANT ALL PRIVILEGES ON testapp.* TO 'testapp'@'localhost' IDENTIFIED BY 'testapp'" | mysql -uroot -proot
