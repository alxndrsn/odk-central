FROM node:16.19.1 as intermediate

COPY . .
RUN mkdir /tmp/sentry-versions
RUN git describe --tags --dirty > /tmp/sentry-versions/central
WORKDIR server
RUN git describe --tags --dirty > /tmp/sentry-versions/server
WORKDIR ../client
RUN git describe --tags --dirty > /tmp/sentry-versions/client

FROM node:16.17.0

WORKDIR /usr/odk

# Fix archived debian repos.
RUN sed -i \
        -e '/debian-security/d' \
        -e '/stretch-updates/d' \
        -e '/buster-updates/d' \
        -e 's/deb.debian.org/archive.debian.org/g' \
        /etc/apt/sources.list
RUN \
  apt-get update && \
  apt-get install -y cron gettext postgresql-client-14

COPY files/service/crontab /etc/cron.d/odk

COPY server/package*.json ./

RUN npm clean-install --omit=dev --legacy-peer-deps --no-audit --fund=false --update-notifier=false
RUN npm install pm2@5.2.2 -g

COPY server/ ./
COPY files/service/scripts/ ./
COPY files/service/pm2.config.js ./

COPY files/service/config.json.template /usr/share/odk/
COPY files/service/odk-cmd /usr/bin/

COPY --from=intermediate /tmp/sentry-versions/ ./sentry-versions

EXPOSE 8383

