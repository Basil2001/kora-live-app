# ============================================
# Kora Backend — Production Dockerfile
# PHP 8.2 FPM + Laravel 10 + Filament
# ============================================

FROM php:8.2-fpm-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    mysql-client \
    supervisor

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        intl \
        opcache

# Install Redis extension
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# ============================================
# Composer Dependencies Layer (cached)
# ============================================
FROM base AS vendor

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader

# ============================================
# Application Layer
# ============================================
FROM base AS app

# Copy vendor from cache layer
COPY --from=vendor /var/www/vendor /var/www/vendor

# Copy application code
COPY . /var/www

# Post-install scripts
RUN composer dump-autoload --optimize --no-dev

# PHP production config
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-production.ini

# Set permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Supervisor config for queue worker
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port for PHP-FPM
EXPOSE 9000

# Start supervisor (manages php-fpm + queue worker)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
