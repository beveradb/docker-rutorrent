FROM lsiobase/nginx:3.10

# set version label
ARG BUILD_DATE
ARG VERSION
ARG RUTORRENT_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="alex-phillips"

# copy patches
COPY patches/ /defaults/patches/

# Add alpine edge package repo to get latest rtorrent and working xmlrpc
COPY repositories /etc/apk/repositories
RUN apk update
RUN apk add xmlrpc-c rtorrent

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	g++ \
	libffi-dev \
	openssl-dev \
	python3-dev && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache --upgrade \
	bind-tools \
	curl \
	fcgi \
	ffmpeg \
	geoip \
	gzip \
	libffi \
	mediainfo \
	openssl \
	php7 \
	php7-cgi \
	php7-curl \
	php7-pear \
	php7-zip \
	procps \
	python3 \
	screen \
	sox \
	unrar \
	zip && \
echo "**** install pip ****" && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
 echo "**** install pip packages ****" && \
 pip3 install --no-cache-dir -U \
	cfscrape \
	cloudscraper && \
 echo "**** install rutorrent ****" && \
 if [ -z ${RUTORRENT_RELEASE+x} ]; then \
	RUTORRENT_RELEASE=$(curl -sX GET "https://api.github.com/repos/Novik/ruTorrent/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 RUTORRENT_RELEASE="v3.10-beta" && \
 curl -o \
 /tmp/rutorrent.tar.gz -L \
	"https://github.com/Novik/rutorrent/archive/${RUTORRENT_RELEASE}.tar.gz" && \
 mkdir -p \
	/app/rutorrent \
	/defaults/rutorrent-conf && \
 tar xf \
 /tmp/rutorrent.tar.gz -C \
	/app/rutorrent --strip-components=1 && \
 mv /app/rutorrent/conf/* \
	/defaults/rutorrent-conf/ && \
 rm -rf \
	/defaults/rutorrent-conf/users && \
 echo "**** patch snoopy.inc for rss fix ****" && \
 cd /app/rutorrent/php && \
 patch < /defaults/patches/snoopy.patch && \
 echo "**** cleanup ****" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/etc/nginx/conf.d/default.conf \
	/root/.cache \
	/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 80
VOLUME /config /downloads
