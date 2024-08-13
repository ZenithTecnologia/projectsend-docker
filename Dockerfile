FROM php:8-apache
LABEL maintainer="Leonardo Amaral"
LABEL original_mantainer="Sebastian Goetsch"

RUN docker-php-ext-install -j$(nproc) mysqli
RUN docker-php-ext-install -j$(nproc) pdo 
RUN docker-php-ext-install -j$(nproc) pdo_mysql
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

RUN mkdir -p /defaults/ && \
 mv /var/www/html/upload /defaults/

COPY --chmod=0755 start.sh /docker-entrypoint.sh

ENTRYPOINT [ "/usr/bin/catatonit", "--" ]

CMD ["/bin/bash", "/docker-entrypoint.sh"]

EXPOSE 80
