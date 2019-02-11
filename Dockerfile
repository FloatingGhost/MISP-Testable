# We are based on Ubuntu:latest
FROM ubuntu:xenial
MAINTAINER Hannah Ward <hannah@coffee-and-dreams.uk>

# Install core components
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get dist-upgrade -y && apt-get autoremove -y && apt-get clean
RUN apt-get install -y software-properties-common locales

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

RUN add-apt-repository -y ppa:ondrej/php && apt-get update
RUN apt-get install -y curl gcc git make python openssl redis-server sudo vim zip mariadb-client mariadb-server expect libapache2-mod-php php7.2 php7.2-cli php-crypt-gpg php7.2-dev php7.2-json php7.2-mysql php7.2-opcache php7.2-readline php7.2-redis php7.2-xml php-pear pkg-config libbson-1.0 libmongoc-1.0-0 php-xml php-dev python-dev python-pip libxml2-dev libxslt1-dev zlib1g-dev python-setuptools libfuzzy-dev supervisor

ADD mysql_setup.sh /mysql_setup.sh
RUN service mysql start && /bin/sh /mysql_setup.sh
RUN rm /mysql_setup.sh

# Apache
RUN apt-get install -y apache2 apache2-doc apache2-utils
RUN a2dismod status
RUN a2dissite 000-default

# Fix php.ini with recommended settings
RUN sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.2/apache2/php.ini
RUN sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.2/apache2/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 50M/" /etc/php/7.2/apache2/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = 50M/" /etc/php/7.2/apache2/php.ini

WORKDIR /var/www
RUN chown www-data:www-data /var/www
USER www-data
RUN git clone https://github.com/MISP/MISP.git
WORKDIR /var/www/MISP
RUN git checkout tags/$(git describe --tags `git rev-list --tags --max-count=1`)
RUN git config core.filemode false

WORKDIR /var/www/MISP/app/files/scripts
RUN git clone https://github.com/CybOXProject/python-cybox.git
RUN git clone https://github.com/STIXProject/python-stix.git

WORKDIR /var/www/MISP/app/files/scripts/python-cybox
RUN git checkout v2.1.0.12
USER root
RUN python setup.py install

USER www-data
WORKDIR /var/www/MISP/app/files/scripts/python-stix
RUN git checkout v1.1.1.4
USER root
RUN python setup.py install

USER www-data
WORKDIR /var/www/MISP
RUN git submodule init
RUN git submodule update
WORKDIR /var/www/MISP/app
RUN php composer.phar config vendor-dir Vendor
RUN php composer.phar install --ignore-platform-reqs
USER root
RUN phpenmod redis
USER www-data
RUN cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php

# Fix permissions
USER root
RUN chown -R www-data:www-data /var/www/MISP
RUN chmod -R 750 /var/www/MISP
RUN chmod -R g+ws /var/www/MISP/app/tmp
RUN chmod -R g+ws /var/www/MISP/app/files
RUN chmod -R g+ws /var/www/MISP/app/files/scripts/tmp

RUN cp /var/www/MISP/INSTALL/misp.logrotate /etc/logrotate.d/misp

# Redis Setup
RUN sed -i 's/^\(daemonize\s*\)yes\s*$/\1no/g' /etc/redis/redis.conf

# Apache Setup
RUN cp /var/www/MISP/INSTALL/apache.misp.ubuntu /etc/apache2/sites-available/misp.conf
RUN a2dissite 000-default
RUN a2ensite misp
RUN a2enmod rewrite
RUN a2enmod headers

# MISP base configuration
RUN sudo -u www-data cp -a /var/www/MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php
RUN sudo -u www-data cp -a /var/www/MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php
RUN sudo -u www-data cp -a /var/www/MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php
RUN sudo -u www-data cp -a /var/www/MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php
RUN chown -R www-data:www-data /var/www/MISP/app/Config
RUN chmod -R 750 /var/www/MISP/app/Config

# Install templates & stuff
WORKDIR /var/www/MISP/app/files
RUN rm -rf misp-objects && git clone https://github.com/MISP/misp-objects.git
RUN rm -rf misp-galaxy && git clone https://github.com/MISP/misp-galaxy.git
RUN rm -rf warninglists && git clone https://github.com/MISP/misp-warninglists.git ./warninglists
RUN rm -rf taxonomies && git clone https://github.com/MISP/misp-taxonomies.git ./taxonomies
RUN chown -R www-data:www-data misp-objects misp-galaxy warninglists taxonomies

ADD supervisor.conf /etc/supervisor/conf.d/supervisord.conf


ADD edit_apikey.sql /edit_apikey.sql
ADD setup_database.sql /setup_database.sql
RUN service mysql start && mysql -u root --password=misp < /setup_database.sql
RUN service mysql start && mysql -u root --password=misp misp 2>&1 < /var/www/MISP/INSTALL/MYSQL.sql

# Add run script
ADD run.sh /run.sh
RUN chmod 0755 /run.sh

# Trigger to perform first boot operations
WORKDIR /var/www/MISP/app/Config
RUN cp -a database.default.php database.php && \
    sed -i "s/db\s*login/misp/" database.php && \
    sed -i "s/8889/3306/" database.php && \
    sed -i "s/db\s*password/misp/" database.php

WORKDIR /var/www/MISP

EXPOSE 80
ENTRYPOINT ["/run.sh"]
