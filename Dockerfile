FROM php:7.4-apache

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Extensiones PHP para openSIS
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mysqli pdo pdo_mysql zip opcache

# Configuración PHP + AUMENTO DE TIEMPOS (solución Opción B)
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/opensis.ini \
    && echo "upload_max_filesize=50M" >> /usr/local/etc/php/conf.d/opensis.ini \
    && echo "post_max_size=50M" >> /usr/local/etc/php/conf.d/opensis.ini \
    && echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/opensis.ini \
    && echo "max_input_time=300" >> /usr/local/etc/php/conf.d/opensis.ini

# Habilitar mod_rewrite
RUN a2enmod rewrite

# Copiar openSIS
COPY . /var/www/html/

# Permisos
RUN chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/assets 2>/dev/null || true \
    && chmod -R 777 /var/www/html/modules 2>/dev/null || true \
    && chown -R www-data:www-data /var/www/html

# Script de arranque que configura el puerto dinámico de Railway
RUN echo '#!/bin/bash\n\
if [ -z "$PORT" ]; then PORT=8080; fi\n\
sed -i "s/Listen 80/Listen ${PORT}/g" /etc/apache2/ports.conf\n\
sed -i "s/:80/:${PORT}/g" /etc/apache2/sites-available/000-default.conf\n\
apache2-foreground' > /start.sh \
    && chmod +x /start.sh

CMD ["/start.sh"]
