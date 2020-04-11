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

RUN useradd --shell /bin/bash aeternity -m \
    && chown -R aeternity:aeternity /home/aeternity
# Switch to non-root user
USER aeternity
ENV SHELL /bin/bash

WORKDIR /home/aeternity/
RUN git clone https://github.com/aeternity/aerepl_http.git
WORKDIR /home/aeternity/aerepl_http

WORKDIR /home/aeternity/aerepl_http
ENV ERL_LIBS=$ERL_LIBS:/home/aeternity/aerepl_http/deps/aerepl/_build/default/lib

RUN mix local.rebar --force
RUN yes | mix deps.get
RUN CXXFLAGS="-Wno-error=shadow -Wno-deprecated-copy -Wno-redundant-move -Wno-pessimizing-move" mix deps.compile

WORKDIR /home/aeternity/aerepl_http/assets
RUN npm install
WORKDIR /home/aeternity/aerepl_http

CMD export ERL_LIBS=$ERL_LIBS:/home/aeternity/aerepl_http/deps/aerepl/_build/default/lib
CMD mix phx.server

# Erl handle SIGQUIT instead of the default SIGINT
STOPSIGNAL SIGQUIT

EXPOSE 4000
EXPOSE 22