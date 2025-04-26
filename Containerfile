FROM registry.access.redhat.com/ubi9/php-82:latest AS projectsend-source

ARG BRANCH=develop

USER 0
RUN dnf --setopt=install_weak_deps=0 --noplugins --nodocs -y install git-core
USER 1001
RUN git clone --single-branch --depth=1 --branch=${BRANCH} https://github.com/projectsend/projectsend.git /tmp/projectsend

# -- Build node modules
FROM registry.access.redhat.com/ubi9/nodejs-22-minimal:latest AS nodejs-build
COPY --from=projectsend-source --chown=1001:1001 /tmp/projectsend /tmp/projectsend

WORKDIR /tmp/projectsend

RUN npm install --include=dev

# -- Assemble built package
FROM registry.access.redhat.com/ubi9/php-82:latest AS php-prepare

USER 0
RUN dnf install -y curl-minimal unzip
USER 1001
COPY --from=nodejs-build --chown=1001:1001 /tmp/projectsend /tmp/projectsend

RUN mkdir /tmp/translations \
 && curl -fL --remote-name --remote-header-name --output-dir /tmp/translations https://www.projectsend.org/translations/get.php?lang={$(for lang in zh_CN de es tr ru it_IT pt_BR cs nl fr pl sw vi_VN pt_PT ja; do echo -n "${lang},"; done | sed 's/.$//')}

RUN for translation in /tmp/translations/*; do \
    unzip -o ${translation} -d /tmp/src ; \
  done

RUN mkdir /tmp/php.d && \
  echo -e '[global]\nmemory_limit = 512M\npost_max_size = 4096M\nupload_max_size = 4096M\nmax_execution_time = 1800' > /tmp/php.d/projectsend.ini && \
  echo -e '[global]\nerror_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT\nlog_errors = 1\ndisplay_errors = 0' > /tmp/php.d/docker-log.ini

RUN git config --global --add safe.directory /tmp/projectsend

RUN mkdir /tmp/composer_temp \
 && cd /tmp/composer_temp \
 && curl -sSLo- https://getcomposer.org/installer | php \
 && cd /tmp/projectsend \
 && php /tmp/composer_temp/composer.phar update

# -- Build gulp modules
FROM registry.access.redhat.com/ubi9/nodejs-22-minimal:latest AS gulp-build
COPY --from=php-prepare --chown=1001:1001 /tmp/projectsend /tmp/projectsend

WORKDIR /tmp/projectsend

RUN npm install --global gulp-cli gulp-clean-css postcss gulp-postcss 

RUN gulp prod

# -- PHP runtime

FROM registry.access.redhat.com/ubi9/php-82:latest AS php-assemble
COPY --from=gulp-build --chown=1001:1001 /tmp/projectsend /tmp/src
COPY --from=php-prepare --chown=1001:1001 /tmp/php.d /etc/php.d
COPY ./start.sh ./php-pre-start/projectsend_parameters.sh

RUN mkdir -p /tmp/src/defaults/ && \
 mv /tmp/src/upload /tmp/src/defaults/

RUN cat <<EOF >> /opt/app-root/src/.htaccess 
<IfModule mod_headers.c>
  Header set Strict-Transport-Security "max-age=31536000" env=HTTPS
  Header always set X-Frame-Options "SAMEORIGIN"
  Header setifempty Referrer-Policy: same-origin
  Header set X-XSS-Protection "1; mode=block"
  Header set X-Permitted-Cross-Domain-Policies "none"
  Header set Referrer-Policy "no-referrer"
  Header set X-Content-Type-Options: nosniff
  ServerSignature Off
</IfModule>
EOF

RUN /usr/libexec/s2i/assemble

FROM registry.access.redhat.com/ubi9/php-82:latest AS runtime
COPY --from=php-assemble /opt /opt

CMD [ "/usr/libexec/s2i/run" ]
