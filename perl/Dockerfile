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

RUN apk update && \
    apk add perl perl-dev g++ make wget curl wiringpi openssl openssl-dev && \
    curl -L https://cpanmin.us | perl - App::cpanminus && \
    rm -rf /root/.cpanm/* /usr/local/share/man/* && \
    mkdir /fabkey

RUN cpanm Device::SerialPort
RUN cpanm DBI
RUN cpanm DBD::SQLite
RUN cpanm Data::Dumper
RUN cpanm JSON::MaybeXS
RUN cpanm WWW::Telegram::BotAPI
RUN cpanm Telegram::Bot::Message
RUN cpanm Telegram::BotKit::Sessions
RUN cpanm Telegram::BotKit::Keyboards

COPY . /fabkey/

CMD ["perl", "bot_embedded.pl", "daemon", "-l", "http://*:8080"]
WORKDIR /fabkey

EXPOSE 8080
