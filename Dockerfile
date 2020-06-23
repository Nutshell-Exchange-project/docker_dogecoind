FROM alpine:3.8 as builder

ENV DOGECOIN_ROOT=/dogecoin
ENV BDB_PREFIX="${DOGECOIN_ROOT}/db4" DOGECOIN_REPO="${DOGECOIN_ROOT}/repo" PATH="${DOGECOIN_ROOT}/bin:$PATH" DOGECOIN_DATA="${DOGECOIN_ROOT}/data"

RUN mkdir -p $DOGECOIN_ROOT && mkdir -p $BDB_PREFIX

WORKDIR /dogecoin

RUN apk update && \
    apk upgrade && \
    apk add --no-cache libressl boost libevent libtool libzmq boost-dev libressl-dev libevent-dev zeromq-dev

RUN apk add --no-cache git autoconf automake g++ make file

RUN git clone https://github.com/dogecoin/dogecoin.git $DOGECOIN_REPO
RUN cd $DOGECOIN_REPO && git checkout tags/v0.19.1 && cd ..

RUN  wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz' && \
    echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c

RUN tar -xzf db-4.8.30.NC.tar.gz
RUN cd db-4.8.30.NC/build_unix/ && \
    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX && \
    make -j4 && \
    make install
RUN cd $DOGECOIN_REPO && \
    ./autogen.sh && \
    ./configure \
        LDFLAGS="-L${BDB_PREFIX}/lib/" \
        CPPFLAGS="-I${BDB_PREFIX}/include/" \
        --disable-tests \
        --disable-bench \
        --disable-ccache \
        --with-gui=no \
        --with-utils \
        --with-libs \
        --with-daemon \
        --prefix=$DOGECOIN_ROOT && \
    make -j4 && \
    make install && \
    rm -rf $DOGECOIN_ROOT/db-4.8.30.NC* && \
    rm -rf $BDB_PREFIX/docs && \
    rm -rf $DOGECOIN_REPO && \
    strip $DOGECOIN_ROOT/bin/dogecoin-cli && \
    strip $DOGECOIN_ROOT/bin/dogecoin-tx && \
    strip $DOGECOIN_ROOT/bin/dogecoind && \
    strip $DOGECOIN_ROOT/lib/libdogecoinconsensus.a && \
    strip $DOGECOIN_ROOT/lib/libdogecoinconsensus.so.0.0.0 && \
    apk del git autoconf automake g++ make file

FROM alpine:3.8

LABEL maintainer="Harold Whistler <harold.whistler@nutshell.exchange>"

ENV DOGECOIN_ROOT=/dogecoin
ENV DOGECOIN_DATA="${DOGECOIN_ROOT}/data" PATH="${DOGECOIN_ROOT}/bin:$PATH"

RUN apk update && \
    apk upgrade && \
    apk add --no-cache libressl boost libevent libtool libzmq

COPY --from=builder ${DOGECOIN_ROOT}/bin ${DOGECOIN_ROOT}/bin
COPY --from=builder ${DOGECOIN_ROOT}/lib ${DOGECOIN_ROOT}/lib
COPY --from=builder ${DOGECOIN_ROOT}/include ${DOGECOIN_ROOT}/include

WORKDIR ${DOGECOIN_DATA}
VOLUME ["${DOGECOIN_DATA}"]

COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod u+x /entrypoint.sh

EXPOSE 8332 8333 18332 18333 18444

ENTRYPOINT ["/entrypoint.sh"]

CMD ["dogecoind"]
