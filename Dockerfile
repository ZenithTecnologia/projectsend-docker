FROM docker.io/library/php:8.1-apache
LABEL maintainer="Leonardo Amaral"
LABEL original_mantainer="Sebastian Goetsch"

RUN apt update && \
  apt install -y libonig-dev libonig5 && \
  docker-php-ext-install -j$(nproc) mbstring && \
  apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false libonig-dev && \
  apt clean -y && \
  rm -rf /var/lib/apt/lists/*

RUN apt update && \
  apt install -y zlib1g-dev zlib1g libpng-dev libpng16-16 libfreetype6-dev libfreetype6 libjpeg62-turbo-dev libjpeg62-turbo libwebp-dev libwebp7 libxpm-dev libxpm4 && \
  docker-php-ext-configure gd --enable-gd --with-webp --with-jpeg --with-xpm --with-freetype && \
  docker-php-ext-install -j$(nproc) gd && \
  apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false zlib1g-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev libwebp-dev libxpm-dev && \
  apt clean -y && \
  rm -rf /var/lib/apt/lists/*

RUN apt update && \
  apt install -y libxml2-dev libxml2 && \
  docker-php-ext-install -j$(nproc) xml && \
  apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -y libxml2-dev && \
  apt clean -y && \
  rm -rf /var/lib/apt/lists/*

RUN apt update && \
  apt install -y libzip-dev libzip4 && \
  docker-php-ext-install -j$(nproc) zip && \
  apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false libzip-dev && \
  apt clean -y && \
  rm -rf /var/lib/apt/lists/*

RUN apt update && \
  apt install -y libcurl4-openssl-dev libcurl4 && \
  docker-php-ext-install -j$(nproc) curl && \
  apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false libcurl4-openssl-dev && \
  apt clean -y && \
  rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) mysqli
RUN docker-php-ext-install -j$(nproc) pdo 
RUN docker-php-ext-install -j$(nproc) pdo_mysql
RUN docker-php-ext-install -j$(nproc) gettext
RUN docker-php-ext-install -j$(nproc) fileinfo

RUN \
  apt update && \ 
  apt install -y jq catatonit unzip && \
\
  if [ -z ${PROJECTSEND_VERSION+x} ]; then \
    PROJECTSEND_VERSION=$(curl -s https://api.github.com/repos/projectsend/projectsend/releases/latest | jq -r '. | .tag_name'); \
  fi && \
  curl -fso \
    /tmp/projectsend.zip -L \
    "https://github.com/projectsend/projectsend/releases/download/${PROJECTSEND_VERSION}/projectsend-${PROJECTSEND_VERSION}.zip" || \
  curl -fso \
    /tmp/projectsend.zip -L \
    "https://github.com/projectsend/projectsend/releases/download/${PROJECTSEND_VERSION}/projectsend.zip" && \
  unzip \
    /tmp/projectsend.zip -d \
    /var/www/html && \
\
  for lang in zh_CN cs nl fr de it_IT pl pt_BR ru es sw tr vi_VN; do \
    curl -fso /tmp/${lang}.zip -L "https://www.projectsend.org/translations/get.php?lang=${lang}" && \
    unzip -o /tmp/${lang}.zip -d /var/www/html ; \
  done && \
\
  chown -R www-data:www-data /var/www/html/ && \
  rm -rf /tmp/* && \
  apt remove -y jq unzip && \
  apt clean -y && \
  rm -rf /var/lib/apt/lists/*

RUN a2enmod remoteip && \
  #sed -E -i 's/(LogFormat.+)%h(.+)/\1%a\2/g' /etc/apache2/apache2.conf && \
  #sed -E -i 's/(LogFormat.+)%h(.+)/\1%{X-Forwarded-For}i\2/g' /etc/apache2/apache2.conf && \
  sed -E -i 's,(Listen.+)80,\1[::]:80,g' /etc/apache2/ports.conf && \
  sed -E -i 's,(Listen.+)443,\1[::]:443,g' /etc/apache2/ports.conf && \
  sed -E -i 's,(<VirtualHost.+)\*:80(.+),\1[::]:80\2,g' /etc/apache2/sites-enabled/000-default.conf && \
  echo 'RemoteIPHeader X-Real-Ip' >> /etc/apache2/conf-available/remoteip.conf && \
  echo 'RemoteIPHeader X-Client-Ip' >> /etc/apache2/conf-available/remoteip.conf && \
  echo 'RemoteIPInternalProxy 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 fd00::/8' >> /etc/apache2/conf-available/remoteip.conf && \
  a2enconf remoteip

RUN echo 'memory_limit = 512M\npost_max_size = 4096M\nupload_max_size = 4096M\nmax_execution_time = 1800' > /usr/local/etc/php/conf.d/projectsend.ini && \
  echo '[global]\nerror_log = /proc/1/fd/2\n\nerror_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT\nlog_errors = on' > /usr/local/etc/php/conf.d/docker-log.ini

RUN mkdir -p /defaults/ && \
 mv /var/www/html/upload /defaults/

COPY --chmod=0755 start.sh /docker-entrypoint.sh

ENTRYPOINT [ "/usr/bin/catatonit", "--" ]

CMD ["/bin/bash", "/docker-entrypoint.sh"]

EXPOSE 80
