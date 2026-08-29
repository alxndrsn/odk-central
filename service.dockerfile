FROM node:14.19.3

WORKDIR /usr/odk

# Fix archived debian repos.
RUN sed -i \
        -e 's/deb.debian.org/archive.debian.org/g' \
        -e 's/security.debian.org/archive.debian.org/g' \
        -e '/stretch-updates/d' \
        -e '/buster-updates/d' \
        /etc/apt/sources.list
RUN \
  apt-get update; \
  apt-get install -y cron gettext

COPY files/service/crontab /etc/cron.d/odk

COPY server/package*.json ./
RUN npm install --production
RUN npm install pm2 -g

COPY server/ ./
COPY files/service/scripts/ ./
COPY files/service/pm2.config.js ./

COPY files/service/config.json.template /usr/share/odk/
COPY files/service/odk-cmd /usr/bin/

EXPOSE 8383

