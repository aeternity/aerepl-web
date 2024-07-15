FROM aeternity/builder:focal-otp26 as builder

SHELL ["/bin/bash", "-l", "-c"]

ENV ERLANG_ROCKSDB_OPTS "-DWITH_SYSTEM_ROCKSDB=ON -DWITH_LZ4=ON -DWITH_SNAPPY=ON -DWITH_BZ2=ON -DWITH_ZSTD=ON"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update \
    && apt-get -qq -y install git g++ cmake autoconf clang curl wget \
    libsodium23 libsodium-dev \
    libgmp10 libgmp-dev \
    librocksdb-dev \
    libsnappy1v5 libsnappy-dev \
    liblz4-1 liblz4-dev \
    libzstd1 libzstd-dev \
    libgflags2.2 libgflags-dev \
    libbz2-1.0 libbz2-dev \
    libssl-dev \
    bzip2 unzip inotify-tools locales \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

RUN ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so.6.13 \
    && ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so.6 \
    && ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so \
    && ldconfig

# Install nodejs
RUN apt-get update && apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings/
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install nodejs -y

RUN curl -sSL https://raw.githubusercontent.com/taylor/kiex/master/install | bash -s
ENV PATH /root/.kiex/bin/:${PATH}
RUN kiex install v1.16- && kiex use v1.16-

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ADD . /app
WORKDIR /app

# Setup the server

ENV MIX_ENV prod
RUN mkdir -p /etc/profile.d \
    && KEY_BASE="$(openssl rand -hex 64)" \
    && echo export SECRET_KEY_BASE=$KEY_BASE >> /etc/profile.d/aerepl-web.sh
ENV CXXFLAGS "-Wno-error=shadow -Wno-deprecated-copy -Wno-redundant-move -Wno-pessimizing-move"

ENV PATH /root/.kiex/elixirs/elixir-1.16/lib/elixir/bin/:${PATH}
RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get

RUN source /etc/profile.d/aerepl-web.sh \
    && (mix deps.compile || mix deps.compile)

WORKDIR /app/assets
RUN source /etc/profile.d/aerepl-web.sh \
    && npm install \
    && npm run deploy \
    && node node_modules/webpack/bin/webpack.js --mode production

WORKDIR /app
RUN mix phx.digest
RUN mix release

RUN rm -rf deps/aerepl/_build/default
RUN rm -rf deps/aerepl/node/_build/default
RUN rm -rf assets/node_modules/

FROM ubuntu:20.04

RUN apt-get -qq update \
    && apt-get -qq -y install libssl1.1 libsodium23 \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app /repl

WORKDIR /repl

CMD _build/prod/rel/app/bin/app start

# Erl handle SIGQUIT instead of the default SIGINT
STOPSIGNAL SIGQUIT

EXPOSE 4000
