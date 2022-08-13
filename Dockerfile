# Put aeternity node in second stage container
FROM ubuntu:18.04


# OpenSSL is shared lib dependency
RUN apt -qq update \
  && apt -qq -y install libssl1.0.0 curl libsodium23 wget gnupg git locales make gcc g++ libsodium-dev autoconf inotify-tools \
  && ldconfig \
  && rm -rf /var/lib/apt/lists/*

# Install Erlang, Elixir and cancer
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb \
  && curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN yes | dpkg -i erlang-solutions_2.0_all.deb \
  && apt -qq update \
  && apt install --fix-missing \
  && apt install -qq -y esl-erlang elixir nodejs

# Set the locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV SHELL /bin/bash

ADD . /app

WORKDIR /app
RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && mix deps.compile

WORKDIR /app/assets
RUN NODE_ENV=production \
    && npm install \
    && npm run deploy \
    && cd /app && mix phx.digest

WORKDIR /app
RUN export ERL_LIBS=$ERL_LIBS:/app/deps/aerepl/_build/default/lib \
    && export SECRET_KEY_BASE=$(mix phx.gen.secret) \
    && MIX_ENV=prod mix release

# Once the prod release is fixed, this CMD should be replaced with the one below, using the release
WORKDIR /app
CMD export ERL_LIBS=$ERL_LIBS:/app/deps/aerepl/_build/prod/lib \
    && export SECRET_KEY_BASE=$(mix phx.gen.secret) \
    && MIX_ENV=prod mix phx.server

# CMD _build/prod/rel/aerepl_http/bin/aerepl_http console

# Erl handle SIGQUIT instead of the default SIGINT
STOPSIGNAL SIGQUIT

EXPOSE 4000
