FROM php:7.4-fpm

# Install system deps and PHP extensions
RUN apt-get update && apt-get install -y \
    libicu-dev libxml2-dev libzip-dev libpng-dev unzip git zip libonig-dev \
    && docker-php-ext-install pdo_mysql intl mbstring xml zip gd \
    && rm -rf /var/lib/apt/lists/*

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy composer files first for better caching
COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-progress || true

# Copy rest of app
COPY . .

# Copy entrypoint and scripts (entrypoint will run generate script if present)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/generate-parameters.sh /var/www/html/scripts/generate-parameters.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /var/www/html/scripts/generate-parameters.sh || true

# Ensure permissions for Symfony runtime directories
RUN mkdir -p var web/app_dev.php || true
RUN chown -R www-data:www-data var/ web/ app/cache app/logs || true

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php-fpm"]
