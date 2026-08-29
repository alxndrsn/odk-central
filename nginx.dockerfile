FROM jonasal/nginx-certbot:2.4.1

EXPOSE 80
EXPOSE 443

VOLUME [ "/etc/dh", "/etc/selfsign", "/etc/nginx/conf.d" ]
ENTRYPOINT [ "/bin/bash", "/scripts/odk-setup.sh" ]

# Fix archived debian repos.
RUN sed -i \
        -e 's/deb.debian.org/archive.debian.org/g' \
        -e 's/security.debian.org/archive.debian.org/g' \
        -e '/stretch-updates/d' \
        -e '/buster-updates/d' \
        /etc/apt/sources.list
RUN apt-get update; apt-get install -y openssl netcat nginx-extras lua-zlib

RUN mkdir -p /etc/selfsign/live/local/
COPY files/nginx/odk-setup.sh /scripts/

COPY files/local/customssl/*.pem /etc/customssl/live/local/

COPY files/nginx/default /etc/nginx/sites-enabled/
COPY files/nginx/inflate_body.lua /usr/share/nginx/
COPY files/nginx/odk.conf.template /usr/share/nginx/
COPY files/nginx/common-headers.nginx.conf /usr/share/nginx/
COPY files/nginx/certbot.conf /usr/share/nginx/
COPY files/nginx/redirector.conf /usr/share/nginx/
