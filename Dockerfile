FROM php:8.2-apache

# Instalar dependencias del sistema y extensiones de PHP obligatorias para Moodle
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl mysqli pdo_mysql soap xml zip opcache

# Configurar Apache para que el DocumentRoot apunte correctamente
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -s "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf
RUN sed -ri -s "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Habilitar mod_rewrite de Apache (necesario para URLs amigables)
RUN a2enmod rewrite

# Copiar el código fuente de Moodle al contenedor
COPY . /var/www/html/

# Crear la carpeta de datos de Moodle fuera del HTML público por seguridad
RUN mkdir -p /var/moodledata && chown -R www-data:www-data /var/moodledata /var/www/html \
    && chmod -R 755 /var/moodledata

EXPOSE 80
