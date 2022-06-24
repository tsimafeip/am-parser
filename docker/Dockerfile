# Dockerfile to setup JAVA_11 container with custom user and some dependecies (gcc, vim) installed
FROM openjdk:11

ARG user=tprakap
LABEL maintainer="tprakap@coli.uni-saarland.de"


RUN apt-get update
RUN apt-get -y install screen
RUN apt-get -y install python2
RUN apt-get -y install vim
RUN apt-get -y install g++
RUN apt-get -y install gcc
RUN useradd -ms /bin/bash $user

USER $user

CMD [ "bash" ]
