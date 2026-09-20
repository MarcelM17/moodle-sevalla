FROM php:8.2-apache

# Instalar dependencias del sistema y extensiones de PHP obligatorias para Moodle
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    libexif-dev \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl mysqli pdo_mysql soap xml zip opcache exif

# Configuración de PHP optimizada para Moodle
RUN echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "zend.exception_ignore_args = On" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "opcache.enable = 1" >> /usr/local/etc/php/conf.d/moodle.ini

# Configurar Apache para que el DocumentRoot apunte correctamente a /public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -s "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf
RUN sed -ri -s "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Habilitar mod_rewrite de Apache
RUN a2enmod rewrite

# Copiar el código fuente de Moodle al contenedor
COPY . /var/www/html/

# Método oficial y seguro para instalar Composer en Docker
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Ejecutar la instalación de dependencias en la raíz de Moodle
RUN cd /var/www/html && composer install --no-dev --classmap-authoritative

# Crear la carpeta de datos de Moodle fuera del HTML público por seguridad
RUN mkdir -p /var/moodledata \
    && chown -R www-data:www-data /var/moodledata /var/www/html \
    && chmod -R 777 /var/moodledata \
    && chmod -R 755 /var/www/html

# Forzar la configuración de PHP para aumentar los límites de subida
RUN echo "upload_max_filesize = 100M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini

RUN mkdir -p /var/moodledata/custom_themes

# 2. Eliminar la carpeta de temas del contenedor inmutable para poder reemplazarla
# NOTA: Si tu Moodle está en /app usa la línea A. Si está en /var/www/html usa la línea B.
# Línea A:
# Línea B (Descoméntala quitando el '#' si tu Moodle usa la ruta clásica de Apache):
RUN rm -rf /var/www/html/public/theme && ln -s /var/moodledata/custom_themes /var/www/html/public/theme

EXPOSE 80
