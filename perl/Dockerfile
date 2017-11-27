# Image name :
# pavelsr/fabkey

# Build
# docker build -t pavelsr/fabkey .

# Add tags to image
# docker tag pavelsr/fabkey:1.0 pavelsr/fabkey:latest
# docker tag 0e5574283393 pavelsr/fabkey:latest

# Publish
# docker login
# docker push pavelsr/fabkey

# Deploy && run
# docker run -v ${PWD}:/fabkey/data pavelsr/fabkey perl db.pl -a deploy_db -d data/skud.db
# docker run -d --name fabkey -e "FABKEY_BOT_TOKEN=<paste_your_token_here>" -e "FABKEY_DBI=dbi:SQLite:dbname=data/skud.db" --privileged -v ${PWD}:/fabkey/data pavelsr/fabkey
# docker run -d --name fabkey -e "FABKEY_BOT_TOKEN=<paste_your_token_here>" -e "FABKEY_DBI=dbi:SQLite:dbname=data/skud.db" --privileged -v ${PWD}:/fabkey/data pavelsr/fabkey

# Inspect running container
# docker exec -t -i fabkey /bin/sh

# Stop & remove all continers
# docker stop $(docker ps -a -q)
# docker rm $(docker ps -a -q)

# You can use following base images to build this bot
# https://hub.docker.com/r/armhf/perl/
# https://hub.docker.com/r/armhf/alpine/

FROM armhf/alpine

LABEL maintainer "Pavel Serikov <pavelsr@cpan.org>"

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
RUN cpanm Getopt::Long

COPY bot_embedded.pl /fabkey/
COPY DBUtil.pm /fabkey/
COPY db.pl /fabkey/

CMD ["perl", "bot_embedded.pl", "daemon", "-l", "http://*:8080"]
WORKDIR /fabkey

EXPOSE 8080
