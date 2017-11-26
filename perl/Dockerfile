# Image name :
# pavelsr/fabkey

# Build
# docker build -t pavelsr/fabkey .

# Add tags like
# docker tag pavelsr/alpine-perl-libxml2:1.0 pavelsr/alpine-perl-libxml2:latest
# docker tag 0e5574283393 pavelsr/alpine-perl-libxml2:latest
# docker tag httpd fedora/httpd:version1.0

# Publish
# docker login
# docker push pavelsr/fabkey

# Run for inspection
# docker run -t -i pavelsr/alpine-perl-libxml2 /bin/sh


# https://hub.docker.com/r/armhf/perl/
# https://hub.docker.com/r/armhf/alpine/

FROM armhf/alpine

LABEL maintainer "Pavel Serikov <pavelsr@cpan.org>"

COPY cpanfile ./
COPY bot_embedded.pl /fabkey

RUN apk update && \
    apk add perl perl-dev g++ make wget curl wiringpi && \
    curl -L https://cpanmin.us | perl - App::cpanminus && \
    rm -rf /root/.cpanm/* /usr/local/share/man/*

RUN cpanm --verbose --installdeps . && rm cpanfile

CMD ["perl", "bot_embedded.pl", "daemon", "-l", "http://*:8080"]
WORKDIR /fabkey

EXPOSE 8080
