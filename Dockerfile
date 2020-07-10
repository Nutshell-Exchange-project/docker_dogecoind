FROM ubuntu:bionic

ARG VERSION

ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}
ENV DOGECOIN_DATA=/home/dogecoin/.dogecoin

RUN groupadd -g ${GROUP_ID} dogecoin \
	&& useradd -u ${USER_ID} -g dogecoin -s /bin/bash -m -d /dogecoin dogecoin

RUN apt-get update -y

RUN apt-get upgrade -y

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get install -y dialog apt-utils git curl nano wget

RUN curl -o /usr/local/bin/gosu -L https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$(dpkg --print-architecture) \
&& chmod +x /usr/local/bin/gosu

RUN apt-get install -y -q build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils default-jdk default-jre

RUN apt-get install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev

RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/d/db/libdb5.1_5.1.29-7ubuntu1_amd64.deb && wget http://mirrors.kernel.org/ubuntu/pool/universe/d/db/libdb5.1++_5.1.29-7ubuntu1_amd64.deb && dpkg -i libdb5.1*.deb

RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/d/db/libdb5.1-dev_5.1.29-7ubuntu1_amd64.deb && wget http://mirrors.kernel.org/ubuntu/pool/universe/d/db/libdb5.1++-dev_5.1.29-7ubuntu1_amd64.deb && dpkg -i libdb5.1*-dev*.deb

RUN apt-get install -y libminiupnpc-dev

RUN apt-get install -y libzmq3-dev

RUN cd /tmp && git clone https://github.com/dogecoin/dogecoin.git && cd ./dogecoin && git checkout tags/v1.14.2

RUN cd /tmp/dogecoin && ./autogen.sh && ./configure --without-gui && make && make install

RUN rm -rf ./dogecoin

EXPOSE 22555 22556

VOLUME ["/home/dogecoin/.dogecoin"]

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["dogecoind"]
