FROM debian:stretch-slim

COPY php-docker-script/* /usr/local/bin/

# Debian Aliyun Mirror
RUN set -eux; \
	{ \
		echo 'deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib'; \
		echo 'deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib'; \
		echo 'deb http://mirrors.aliyun.com/debian-security stretch/updates main'; \
		echo 'deb-src http://mirrors.aliyun.com/debian-security stretch/updates main'; \
		echo 'deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib'; \
		echo 'deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib'; \
		echo 'deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib'; \
		echo 'deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib'; \
	} > /etc/apt/sources.list

RUN apt-get update \
	&& apt-get install -y apt-transport-https \
	&& apt-get install -y apt-utils \
	&& apt-get install -y openssl \
			curl \
			xz-utils \
			zip unzip \
			procps net-tools \
			vim \
			git

RUN apt-get install ca-certificates

########### Install PHP 7.3.8 ###########

# prevent Debian's PHP packages from being installed
# https://github.com/docker-library/php/pull/542
RUN set -eux; \
	{ \
		echo 'Package: php*'; \
		echo 'Pin: release *'; \
		echo 'Pin-Priority: -1'; \
	} > /etc/apt/preferences.d/no-debian-php

# dependencies required for running "phpize"
# (see persistent deps below)
ENV PHPIZE_DEPS autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c

# persistent / runtime deps
RUN apt-get update \
	&& apt-get install -y $PHPIZE_DEPS --no-install-recommends \
	&& rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
	[ ! -d /www ]; \
	mkdir -p /www; \
	chown www-data:www-data /www; \
	chmod 777 /www

##<autogenerated>##
ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi
##</autogenerated>##

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 B1B44D8F021E4E2D6021E995DC9FF8D3EE5AF27F

ENV PHP_VERSION 7.3.8
ENV PHP_URL="https://www.php.net/get/php-7.3.8.tar.xz/from/this/mirror" PHP_ASC_URL="https://www.php.net/get/php-7.3.8.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="de06aff019d8f5079115795bd7d8eedd4cd03daecb62d58abb18f492dd995c95" PHP_MD5=""

RUN mkdir -p /usr/src
COPY php.tar.xz /usr/src
COPY php.tar.xz.asc /usr/src

RUN set -xe; \
	\
	fetchDeps=' \
		wget \
	'; \
	if ! command -v gpg > /dev/null; then \
		fetchDeps="$fetchDeps \
			dirmngr \
			gnupg \
		"; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
#	\
#	mkdir -p /usr/src; \
#	cd /usr/src; \
#	\
#	wget -O php.tar.xz "$PHP_URL"; \
#	\
#	if [ -n "$PHP_SHA256" ]; then \
#		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
#	fi; \
#	if [ -n "$PHP_MD5" ]; then \
#		echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
#	fi; \
#	\
#	if [ -n "$PHP_ASC_URL" ]; then \
#		wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
#		export GNUPGHOME="$(mktemp -d)"; \
#		for key in $GPG_KEYS; do \
#			gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#		done; \
#		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
#		command -v gpgconf > /dev/null && gpgconf --kill all; \
#		rm -rf "$GNUPGHOME"; \
#	fi; \
#	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps

#COPY docker-php-source /usr/local/bin/

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libcurl4-openssl-dev \
		libedit-dev \
		libsodium-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		zlib1g-dev \
		libzip-dev \
		${PHP_EXTRA_BUILD_DEPS:-} \
	; \
##<argon2>##
	sed -e 's/stretch/buster/g' /etc/apt/sources.list > /etc/apt/sources.list.d/buster.list; \
	{ \
		echo 'Package: *'; \
		echo 'Pin: release n=buster'; \
		echo 'Pin-Priority: -10'; \
		echo; \
		echo 'Package: libargon2*'; \
		echo 'Pin: release n=buster'; \
		echo 'Pin-Priority: 990'; \
	} > /etc/apt/preferences.d/argon2-buster; \
	apt-get update; \
	apt-get install -y --no-install-recommends libargon2-dev; \
##</argon2>##
	#rm -rf /var/lib/apt/lists/*; \
	\
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
# https://bugs.php.net/bug.php?id=74125
	if [ ! -d /usr/include/curl ]; then \
		ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
	fi; \
	./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
# make sure invalid --configure-flags are fatal errors intead of just warnings
		--enable-option-checking=fatal \
		\
# https://github.com/docker-library/php/issues/439
		--with-mhash \
		\
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash (7.2+)
		--with-password-argon2 \
# https://wiki.php.net/rfc/libsodium
		--with-sodium=shared \
		\
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		\
# bundled pcre does not support JIT on s390x
# https://manpages.debian.org/stretch/libpcre3-dev/pcrejit.3.en.html#AVAILABILITY_OF_JIT_SUPPORT
		$(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
		--with-libdir="lib/$debMultiarch" \
		\
		${PHP_EXTRA_CONFIGURE_ARGS:-} \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; \
	make clean; \
	\
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	cd /; \
	docker-php-source delete; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	php --version; \
	\
# https://github.com/docker-library/php/issues/443
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc

#COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/

# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
RUN docker-php-ext-enable sodium

#ENTRYPOINT ["docker-php-entrypoint"]
##<autogenerated>##
WORKDIR /www

RUN set -ex \
	&& cd /usr/local/etc \
	&& if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi \
	&& { \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; \
		echo '[www]'; \
		echo '; if we send this to /proc/self/fd/1, it never appears'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
	} | tee php-fpm.d/docker.conf \
	&& { \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/zz-docker.conf

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 9000


########### Install Some php extension ###########

RUN apt-get update && apt-get -y install \
		libzip-dev \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
		libmemcached-dev zlib1g-dev \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) gd  \
	&& docker-php-ext-install pdo_mysql \
	&& docker-php-ext-install zip \
	&& pecl install memcached redis \
	&& docker-php-ext-enable memcached redis


RUN echo "alias ll='ls -l'" >> $HOME/.bashrc

COPY docker-web-entrypoint.sh /usr/local/bin/



########### Install Composer ###########

RUN curl -sS https://getcomposer.org/installer | php \
	&& mv composer.phar /usr/local/bin/composer \
	&& composer config -g repo.packagist composer https://packagist.phpcomposer.com


########### Install Nginx ###########

ENV NGINX_VERSION   1.16.0
ENV NJS_VERSION     0.3.1
ENV PKG_RELEASE     1~stretch

RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y gnupg1 apt-transport-https ca-certificates \
	&& \
	NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
	found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
		apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
	apt-get remove --purge --auto-remove -y gnupg1 && rm -rf /var/lib/apt/lists/* \
	&& dpkgArch="$(dpkg --print-architecture)" \
	&& nginxPackages=" \
		nginx=${NGINX_VERSION}-${PKG_RELEASE} \
		nginx-module-xslt=${NGINX_VERSION}-${PKG_RELEASE} \
		nginx-module-geoip=${NGINX_VERSION}-${PKG_RELEASE} \
		nginx-module-image-filter=${NGINX_VERSION}-${PKG_RELEASE} \
		nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-${PKG_RELEASE} \
	" \
	&& case "$dpkgArch" in \
		amd64|i386) \
# arches officialy built by upstream
			echo "deb https://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
			&& apt-get update \
			;; \
		*) \
# we're on an architecture upstream doesn't officially build for
# let's build binaries from the published source packages
			echo "deb-src https://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
			\
# new directory for storing sources and .deb files
			&& tempDir="$(mktemp -d)" \
			&& chmod 777 "$tempDir" \
# (777 to ensure APT's "_apt" user can access it too)
			\
# save list of currently-installed packages so build dependencies can be cleanly removed later
			&& savedAptMark="$(apt-mark showmanual)" \
			\
# build .deb files from upstream's source packages (which are verified by apt-get)
			&& apt-get update \
			&& apt-get build-dep -y $nginxPackages \
			&& ( \
				cd "$tempDir" \
				&& DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" \
					apt-get source --compile $nginxPackages \
			) \
# we don't remove APT lists here because they get re-downloaded and removed later
			\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
			&& apt-mark showmanual | xargs apt-mark auto > /dev/null \
			&& { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
			\
# create a temporary local APT repo to install from (so that dependency resolution can be handled by APT, as it should be)
			&& ls -lAFh "$tempDir" \
			&& ( cd "$tempDir" && dpkg-scanpackages . > Packages ) \
			&& grep '^Package: ' "$tempDir/Packages" \
			&& echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list \
# work around the following APT issue by using "Acquire::GzipIndexes=false" (overriding "/etc/apt/apt.conf.d/docker-gzip-indexes")
#   Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
#   ...
#   E: Failed to fetch store:/var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages  Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
			&& apt-get -o Acquire::GzipIndexes=false update \
			;; \
	esac \
	\
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						$nginxPackages \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list \
	\
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
	&& if [ -n "$tempDir" ]; then \
		apt-get purge -y --auto-remove \
		&& rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
	fi

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["docker-web-entrypoint.sh"]
