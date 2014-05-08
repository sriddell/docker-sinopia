# DOCKER-VERSION 0.10.0

FROM ubuntu:12.04

RUN apt-get update
RUN apt-get -y install git
RUN apt-get -y install build-essential libssl-dev curl wget python
RUN wget -N http://nodejs.org/dist/node-latest.tar.gz
RUN tar xzvf node-latest.tar.gz && cd node-v* && ./configure && make install 

RUN npm install -g sinopia

ADD config.yaml config.yaml
RUN mkdir private_storage
RUN mkdir public_storage
RUN adduser --disabled-password --gecos "" sinopia
RUN chown sinopia private_storage
RUN chown sinopia public_storage
USER sinopia
EXPOSE 4873
CMD ["/usr/local/bin/sinopia"]


