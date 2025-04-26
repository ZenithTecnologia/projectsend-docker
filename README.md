# projectsend-docker

[![Container Build - Upstream Last Stable](https://github.com/ZenithTecnologia/projectsend-docker/actions/workflows/docker-publish-laststable.yml/badge.svg)](https://github.com/ZenithTecnologia/projectsend-docker/actions/workflows/docker-publish-laststable.yml) [![Container Build - Upstream develop](https://github.com/ZenithTecnologia/projectsend-docker/actions/workflows/docker-publish-develop.yml/badge.svg)](https://github.com/ZenithTecnologia/projectsend-docker/actions/workflows/docker-publish-develop.yml)

Creates a docker image for [projectsend](https://www.projectsend.org/).

Influenced by https://github.com/terrestris/projectsend-docker.

# Features

* Image features [UBI](https://catalog.redhat.com/software/base-images) base images, turning it compliance for business environment.
* Builds develop and latest stable release weekly to update codebase and UBI platform.
* Hosted on Github registry.

# Usage

You can use the supplied `docker-compose.yml` as base and write you own `docker-compose.override.yml` to adapt to you environment. Database credentials and environment variables must be respectively in `db_env` and `projectsend_env` files and you must use their respective `.example` as model. An example of `docker-compose.override.yml` that unpublish the ports to allow host it behind a reverse proxy with 4 replicas and [Ofelia](https://github.com/mcuadros/ofelia) as cron executor:

```yaml
services:
  web:
    ports: !reset
    deploy:
      replicas: 4
    labels:
      - "autoheal=true"
      - "ofelia.enabled=true"
      - "ofelia.job-exec.projectsend-cron.schedule=@every 5m"
      - "ofelia.job-exec.projectsend-cron.command=/usr/bin/php /opt/app-root/src/cron.php key=<YOUR_KEY_HERE>"

      - "traefik.enable=true"
```

If you have your own MySQL-DB you can of course use that as well.

On first access, you should see the install-script where you have to enter the database-credentials etc.  After that, you're good to go. 
