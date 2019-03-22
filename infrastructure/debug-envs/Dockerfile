FROM ubuntu:latest

# mirror: us, eu
ARG mirror=eu
ARG v_kafka=2.1.1
# suggested scala version is 2.12
ARG v_scala=2.12

ENV SCALA_VERSION=$v_scala \
    KAFKA_VERSION=$v_kafka \
    KAFKA_HOME="/opt/kafka" \
    KAFKA_MIRROR=$mirror

RUN apt-get update \
    # basic shell tools
    && apt-get -y install busybox-static \
    # network utilities
    && apt-get -y install tcpdump tcpflow wget curl git inetutils-ping \
    # java JRE
    && apt-get install --yes --force-yes openjdk-8-jre \
    # python
    && apt-get install --yes python3 python3-pip \
    # kafka client
    && cd $(dirname ${KAFKA_HOME}) \
    && curl https://raw.githubusercontent.com/infinimesh/kaf/master/godownloader.sh | BINDIR=${KAFKA_HOME}/bin bash
    #&& wget https://www-${KAFKA_MIRROR}.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O kafka.tgz && tar -xvzf kafka.tgz && rm kafka.tgz && mv kafka* kafka

# append kafka bin folder
ENV PATH=$KAFKA_HOME/bin:$PATH

ENTRYPOINT ["/bin/bash"]
