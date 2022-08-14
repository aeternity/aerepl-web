FROM aeternity/builder:1804 as builder
FROM ubuntu:20.04

#ENV ERLANG_ROCKSDB_OPTS "-DWITH_SYSTEM_ROCKSDB=ON -DWITH_LZ4=ON -DWITH_SNAPPY=ON -DWITH_BZ2=ON -DWITH_ZSTD=ON"
ENV ERLANG_ROCKSDB_OPTS "-DWITH_LZ4=ON -DWITH_SNAPPY=ON -DWITH_BZ2=ON -DWITH_ZSTD=ON"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update \
    && apt-get -qq -y install git g++ cmake clang curl wget libsodium-dev libgmp-dev \
    librocksdb-dev libsnappy-dev liblz4-dev libzstd-dev libgflags-dev libbz2-dev libssl-dev bzip2 \
    unzip inotify-tools\
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get -qq update \
    && apt-get -qq -y install git cmake clang curl libsodium23 libgmp10 \
    libsnappy1v5 liblz4-1 liblz4-dev libzstd1 libgflags2.2 libbz2-1.0 \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

# Install shared rocksdb code from builder container
COPY --from=builder /usr/local/lib/librocksdb.so.6.13.3 /usr/local/lib/
ENV ROCKSDB_INCLUDE_DIRS /usr/local/lib
RUN ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so.6.13 \
    && ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so.6 \
    && ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so \
    && ldconfig

# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | /bin/bash \
    && apt-get install -y nodejs

ENV PATH /asdf/bin/:$PATH

RUN git clone https://github.com/asdf-vm/asdf.git /asdf --branch v0.10.2 \
    && asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git \
    && asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git

RUN asdf install erlang 25.0 \
    && asdf global erlang 25.0 \
    && asdf install elixir 1.13.2 \
    && asdf global elixir 1.13.2

RUN ls ~/.asdf/installs/elixir/1.13.2/bin/

ENV PATH /root/.asdf/installs/elixir/1.13.2/bin/:/root/.asdf/installs/erlang/25.0/bin/:$PATH

ADD . /app

WORKDIR /app
RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get

RUN mix deps.compile

ENV ERL_LIBS $ERL_LIBS:/app/deps/aerepl/_build/prod/lib
ENV SECRET_KEY_BASE $(mix phx.gen.secret)

WORKDIR /app/assets
RUN NODE_ENV=production \
    && npm install \
    && npm run deploy \
    && cd /app && mix phx.digest

WORKDIR /app

# Once the prod release is fixed, this CMD should be replaced with the one below, using the release
CMD mix phx.server

# RUN  MIX_ENV=prod mix release
# CMD _build/prod/rel/aerepl_http/bin/aerepl_http console

# Erl handle SIGQUIT instead of the default SIGINT
STOPSIGNAL SIGQUIT

EXPOSE 4000
