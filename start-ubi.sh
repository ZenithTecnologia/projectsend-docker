#!/bin/bash
echo "Populating mounted upload-dir"

mkdir -p /opt/app-root/src/container_rw/data/projectsend \
         /opt/app-root/src/container_rw/config/projectsend

pushd /opt/app-root/src/defaults/upload || exit
shopt -s globstar nullglob
shopt -s dotglob
	for i in *
	do
		if [ ! -e "/opt/app-root/src/container_rw/data/projectsend/${i}" ] ; then
		cp -R "${i}" "/opt/app-root/src/container_rw/data/projectsend/${i}"
		chown 1001:0 "/opt/app-root/src/container_rw/data/projectsend/${i}"
		fi
	done

shopt -u globstar nullglob
shopt -u dotglob

popd || exit

# create symlinks
[[ ! -L /opt/app-root/src/upload ]] && \
	ln -sf /opt/app-root/src/container_rw/data/projectsend /opt/app-root/src/upload
[[ -f /opt/app-root/src/includes/sys.config.php ]] && \
	rm /opt/app-root/src/includes/sys.config.php
[[ ! -L /opt/app-root/src/includes/sys.config.php ]] && \
	ln -sf /opt/app-root/src/container_rw/config/projectsend/sys.config.php \
	/opt/app-root/src/includes/sys.config.php
