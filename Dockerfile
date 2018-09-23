FROM php:7.2-apache
MAINTAINER wish@baffedu.com

RUN apt-get update && apt-get -y install git curl zip libmagickwand-dev \
    && apt-get -y install supervisor cron \
    && apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pecl install imagick
RUN docker-php-ext-install bcmath pdo_mysql mbstring gd zip
RUN docker-php-ext-enable imagick gd zip

RUN /usr/sbin/a2enmod rewrite

ADD 000-laravel.conf /etc/apache2/sites-available/
# ADD 001-laravel-ssl.conf /etc/apache2/sites-available/
RUN /usr/sbin/a2dissite '*' && /usr/sbin/a2ensite 000-laravel

RUN /usr/bin/curl -sS https://getcomposer.org/installer | php
RUN /bin/mv composer.phar /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://packagist.laravel-china.org
RUN /usr/local/bin/composer create-project laravel/laravel /var/www/laravel --prefer-dist
RUN /bin/chown www-data:www-data -R /var/www/laravel/storage /var/www/laravel/bootstrap/cache

ADD 000-cron.conf /etc/supervisor/conf.d/
ADD 000-apache.conf /etc/supervisor/conf.d/
RUN echo "* * * * * /usr/local/bin/php /var/www/laravel/artisan schedule:run >> /dev/null 2>&1" | crontab

WORKDIR /var/www/laravel

CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
