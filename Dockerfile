FROM php:7.0-apache

# wordpress Dockerfile
# https://github.com/docker-library/wordpress/blob/master/php7.0/apache/Dockerfile

# install the PHP extensions we need
RUN set -ex; \
  \
  apt-get update; \
  apt-get install -y \
    libjpeg-dev \
    libpng12-dev \
    git \
    zip \
    unzip\
  ; \
  rm -rf /var/lib/apt/lists/*; \
  \
  docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
  docker-php-ext-install gd mysqli opcache

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# set php-redis.ini settings
RUN { \
    echo 'extension=redis.so'; \
  } > /usr/local/etc/php/conf.d/php-redis.ini

RUN a2enmod rewrite expires

# Install phpredis
RUN curl -L -o /usr/local/src/phpredis.tar.gz https://github.com/phpredis/phpredis/archive/php7.tar.gz \
  && cd /usr/local/src \
  && tar xfz /usr/local/src/phpredis.tar.gz \
  && rm -r /usr/local/src/phpredis.tar.gz \
  && mv /usr/local/src/phpredis-* /usr/local/src/phpredis \
  && cd /usr/local/src/phpredis \
  && phpize \
  && ./configure \
  && make \
  && make install

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install WordPress
RUN set -ex; \
  curl -o wordpress.tar.gz -fSL "https://ja.wordpress.org/wordpress-4.7.5-ja.tar.gz"; \
  tar -xzf wordpress.tar.gz -C /var/www/; \
  rm wordpress.tar.gz; \
  rm -fr /var/www/html; \
  mv /var/www/wordpress /var/www/html; \
#  rm -fr /var/www/html/wp-content; \
#  rm -f /var/www/html/license.txt; \
#  rm -f /var/www/html/readme.html; \
#  rm -f /var/www/html/wp-config-sample.php; \
#  rm -f /var/www/html/xmlrpc.php; \
#  rm -f /var/www/html/wp-links-opml.php; \
#  rm -f /var/www/html/wp-admin/install.php; \
#  rm -f /var/www/html/wp-admin/upgrade.php; \
#  rm -f /var/www/html/wp-includes/wlwmanifest.xml; \
  mkdir /var/www/conf

# Apply php.ini
COPY conf/php.ini /usr/local/etc/php/php.ini

# Install wordpress and confs
COPY conf /var/www/conf/