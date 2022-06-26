FROM node:16-alpine

WORKDIR /usr/odk

RUN npm install pm2 -g

COPY start-odk.sh ./
COPY demo-double-logging.js ./
COPY pm2.config.js ./

EXPOSE 8383
