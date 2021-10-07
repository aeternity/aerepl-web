# Put aeternity node in second stage container
FROM ubuntu:18.04

SHELL ["/bin/bash", "-c"]

# OpenSSL is shared lib dependency
RUN apt -qq update \
  && apt -qq -y install libssl1.0.0 curl libsodium23 wget gnupg git locales make gcc g++ libsodium-dev autoconf inotify-tools libssl-dev libncurses5-dev libncurses5-dev libncursesw5-dev unzip \
  && ldconfig \
  && rm -rf /var/lib/apt/lists/*

#Install asdf
RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git $HOME/.asdf && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.profile

ENV PATH="${PATH}:/root/.asdf/shims:/root/.asdf/bin"

RUN asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git

# Install Erlang, Elixir and node js
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash && \
    apt install -qq -y nodejs
    
RUN asdf install elixir master-otp-21 && \
    asdf install erlang 21.0

ENV ERL_LIBS=$ERL_LIBS:$(pwd)/deps/aerepl/_build/default/lib
# Set the locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ADD . /app
WORKDIR /app

RUN asdf local elixir master-otp-21 \
    && asdf local erlang 21.0 \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get \
    && mix deps.compile

WORKDIR /app/assets    
RUN npm install

WORKDIR /app
CMD export ERL_LIBS=$ERL_LIBS:/app/deps/aerepl/_build/default/lib \
    && mix phx.server

# Erl handle SIGQUIT instead of the default SIGINT
STOPSIGNAL SIGQUIT

EXPOSE 4000
