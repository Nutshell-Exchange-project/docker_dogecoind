FROM ubuntu:bionic

ARG VERSION

ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

RUN groupadd -g ${GROUP_ID} dogecoin \
	&& useradd -u ${USER_ID} -g dogecoin -s /bin/bash -m -d /dogecoin dogecoin
	# Install required system packages
	RUN apt-get update && apt-get install -y \
	    automake \
	    bsdmainutils \
	    curl \
	    g++ \
	    libboost-all-dev \
	    libevent-dev \
	    libssl-dev \
	    libtool \
	    libzmq3-dev \
	    make \
	    openjdk-8-jdk \
	    pkg-config \
	    zlib1g-dev \
			apt-utils

	# Install Berkeley DB 4.8
	RUN curl -L http://download.oracle.com/berkeley-db/db-4.8.30.tar.gz | tar -xz -C /tmp && \
	    cd /tmp/db-4.8.30/build_unix && \
	    ../dist/configure --enable-cxx --includedir=/usr/include/bdb4.8 --libdir=/usr/lib && \
	    make -j$(nproc) && make install && \
	    cd / && rm -rf /tmp/db-4.8.30

	# Install minizip from source (unavailable from apt on Ubuntu 14.04)
	RUN curl -L https://www.zlib.net/zlib-1.2.11.tar.gz | tar -xz -C /tmp && \
	    cd /tmp/zlib-1.2.11/contrib/minizip && \
	    autoreconf -fi && \
	    ./configure --enable-shared=no --with-pic && \
	    make -j$(nproc) install && \
	    cd / && rm -rf /tmp/zlib-1.2.11

	# Install zmq from source (outdated version from apt on Ubuntu 14.04)
	RUN curl -L https://github.com/zeromq/libzmq/releases/download/v4.3.1/zeromq-4.3.1.tar.gz | tar -xz -C /tmp && \
	    cd /tmp/zeromq-4.3.1/ && ./configure --disable-shared --without-libsodium --with-pic && \
	    make -j$(nproc) install && \
	    cd / && rm -rf /tmp/zeromq-4.3.1/

RUN apt-get update && apt-get -y upgrade && apt-get install -y wget ca-certificates gpg && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY checksum.sha256 /root

RUN set -x && \
	cd /root && \
    wget -q https://github.com/dogecoin/dogecoin/releases/download/v${VERSION}/dogecoin-${VERSION}-x86_64-linux-gnu.tar.gz && \
	cat checksum.sha256 | grep ${VERSION} | sha256sum -c  && \
    tar xvf dogecoin-${VERSION}-x86_64-linux-gnu.tar.gz && \
    cd dogecoin-${VERSION} && \
    mv bin/* /usr/bin/ && \
    mv lib/* /usr/bin/ && \
    mv include/* /usr/bin/ && \
    mv share/* /usr/bin/ && \
    cd /root && \
    rm -Rf dogecoin-${VERSION} dogecoin-${VERSION}-x86_64-linux-gnu.tar.gz

ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true


VOLUME ["/home/dogecoin/.dogecoin"]
EXPOSE 8332 8333 18332 18333

COPY scripts/docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
