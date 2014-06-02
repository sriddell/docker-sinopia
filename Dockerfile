# DOCKER-VERSION 0.10.0

FROM ubuntu:14.04

RUN apt-get update
RUN apt-get -y install git
RUN apt-get -y install build-essential libssl-dev curl wget python
RUN wget -N http://nodejs.org/dist/node-latest.tar.gz
RUN tar xzvf node-latest.tar.gz && cd node-v* && ./configure && make install

RUN npm install -g sinopia

EXPOSE 4873
VOLUME ["/storage"]
VOLUME ["/config"]

CMD cd config && "/usr/local/bin/sinopia"


