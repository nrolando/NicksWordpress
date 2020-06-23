# Current Version 2.1
FROM ubuntu:18.04

RUN apt-get upgrade; apt-get update -y;

ENV DEBIAN_FRONTEND=noninteractive

# Install Helpers
RUN apt-get install -y curl zsh nano git htop vim unzip sudo; \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"; \
    sed -i s^robbyrussell^example^g ~/.zshrc;

# Install SSH deps
RUN apt-get install -y openssh-server; \
    mkdir -p /root/.ssh; \
    touch /root/.ssh/authorized_keys

# Install Apache
RUN apt-get install -y apache2; \
    a2enmod actions alias ssl rewrite headers setenvif; \
    rm -rf /var/www/html/*; \
    echo "ServerName localhost\n$(cat /etc/apache2/apache2.conf)" > /etc/apache2/apache2.conf;

### This was taken from magento dockerfile. This is not using /var/www/html/pub
#RUN tmp=$(mktemp); \
#    def=/etc/apache2/sites-enabled/000-default.conf; \
#    head -n 12 $def > $tmp; \
#    echo "" >> $tmp; \
#    echo "        <Directory /var/www/html/pub>" >> $tmp; \
#    echo "            RewriteEngine On" >> $tmp; \
#    echo "            Options +FollowSymlinks" >> $tmp; \
#    echo "            AllowOverride All" >> $tmp; \
#    echo "            Require all granted" >> $tmp; \
#    echo "        </Directory>" >> $tmp; \
#    tail -n +13 $def >> $tmp; \
#    cat $tmp > $def;

# Doing copy web files here after apache stuff
COPY . /var/www/html/

# Install PHP
RUN apt-get install -y software-properties-common zip; \
    add-apt-repository -y ppa:ondrej/php; \
    apt-get update -y; \
    apt-get install -y php7.3 php7.3-cli php7.3-common php7.3-dev php7.3-curl \
        php7.3-mbstring php7.3-zip php7.3-mysql php7.3-xml php7.3-intl \
        php7.3-json libapache2-mod-php7.3 php7.3-bcmath php7.3-gd php7.3-soap; \
    a2enmod php7.3; \
    curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/local/bin --filename=composer; \
    sed -i "s^memory_limit = -1^memory_limit=1024M^g" /etc/php/7.3/cli/php.ini; \
    sed -i "s^memory_limit = 128M^memory_limit=1024M^g" /etc/php/7.3/apache2/php.ini; \
    sed -i "s^max_execution_time = 30^max_execution_time = 300^g" /etc/php/7.3/apache2/php.ini;

# Install MySQL Server. Create user, password, database.
RUN apt-get install -y mariadb-server mariadb-client; \
    sed -i "s^bind-address		= 127.0.0.1^bind-address = 0.0.0.0^g" /etc/mysql/mariadb.conf.d/50-server.cnf; \
    service mysql start; \
    mysql -e "CREATE USER 'nicks_wp_user'@'%' IDENTIFIED BY 'easypw123';"; \
    mysql -e "CREATE DATABASE nickswp;"; \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'web_user'@'%';"; \
    mysql -e "FLUSH PRIVILEGES;"; \
    mkdir /var/www/db_backups;

COPY C:/www/db_backups/nickswp_bu.sql /var/www/db_backups/nickswp_bu.sql

# Restore database from backup file

# Create web-user and add to group www-data, and set permssions
RUN useradd -d /home/web-user -m web-user -p easypw123; \
	usermod -a -G www-data web-user; \
	chown -R web-user:web-user /var/www/html/*; \
	find /var/www/html/ -type f -exec chmod 644 {} \; \
	find /var/www/html/ -type d -exec chmod 755 {} \;

# Runs mysql, apache processes
CMD apachectl -D FOREGROUND;
