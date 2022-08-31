FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]

ENV ERLANG_ROCKSDB_OPTS "-DWITH_LZ4=ON -DWITH_SNAPPY=ON -DWITH_BZ2=ON -DWITH_ZSTD=ON"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update \
    && apt-get -qq -y install git g++ cmake clang curl wget libsodium-dev libgmp-dev \
    librocksdb-dev libsnappy-dev liblz4-dev libzstd-dev libgflags-dev libbz2-dev libssl-dev bzip2 \
    unzip inotify-tools locales\
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | /bin/bash \
    && apt-get install -y nodejs

# Install Erlang
ENV PATH /asdf/bin/:${PATH}

RUN git clone https://github.com/asdf-vm/asdf.git /asdf --branch v0.10.2 \
    && asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git \
    && asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git

RUN asdf install erlang 25.0 \
    && asdf global erlang 25.0 \
    && asdf install elixir 1.13.2 \
    && asdf global elixir 1.13.2

ENV PATH /root/.asdf/installs/elixir/1.13.2/bin/:/root/.asdf/installs/erlang/25.0/bin/:${PATH}

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ADD . /app
WORKDIR /app

# Setup the server
ENV ERL_LIBS $ERL_LIBS:/app/deps/aerepl/_build/prod/lib
ENV MIX_ENV prod

ENV SECRET_KEY_BASE $(mix phx.gen.secret)

RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && mix deps.compile

WORKDIR /app/assets
RUN NODE_ENV=production \
    && npm install \
    && npm run deploy \
    && node node_modules/webpack/bin/webpack.js --mode production \
    && cd /app \
    && mix phx.digest

WORKDIR /app

CMD SECRET_KEY_BASE=$(mix phx.gen.secret) \
    && mix phx.server

# Erl handle SIGQUIT instead of the default SIGINT
STOPSIGNAL SIGQUIT

EXPOSE 4000
