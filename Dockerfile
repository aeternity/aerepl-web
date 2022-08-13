FROM aeternity/builder:1804 as builder
FROM ubuntu:22.04

#ENV ERLANG_ROCKSDB_OPTS "-DWITH_SYSTEM_ROCKSDB=ON -DWITH_LZ4=ON -DWITH_SNAPPY=ON -DWITH_BZ2=ON -DWITH_ZSTD=ON"

# OpenSSL is shared lib dependency

RUN apt-get -qq update \
    && apt-get -qq -y install git g++ cmake clang curl wget libsodium-dev libgmp10 \
    libsnappy-dev liblz4-1 liblz4-dev libzstd1 libgflags2.2 libbz2-dev bzip2 \
    unzip libssl-dev \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

# Install shared rocksdb code from builder container
#COPY --from=builder /usr/local/lib/librocksdb.so.6.13.3 /usr/local/lib/
#RUN ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so.6.13 \
#    && ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so.6 \
#    && ln -fs librocksdb.so.6.13.3 /usr/local/lib/librocksdb.so \
#    && ldconfig

# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | /bin/bash \
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

RUN cd deps/aerepl && make

RUN mix deps.compile

ENV ERL_LIBS $ERL_LIBS:/app/deps/aerepl/_build/default/lib
ENV SECRET_KEY_BASE $(mix phx.gen.secret)


WORKDIR /app/assets
RUN NODE_ENV=production \
    && npm install \
    && npm run deploy \
    && cd /app && mix phx.digest


WORKDIR /app
RUN  MIX_ENV=prod mix release

# Once the prod release is fixed, this CMD should be replaced with the one below, using the release
CMD MIX_ENV=prod mix phx.server

# CMD _build/prod/rel/aerepl_http/bin/aerepl_http console

# Erl handle SIGQUIT instead of the default SIGINT
STOPSIGNAL SIGQUIT

EXPOSE 4000
