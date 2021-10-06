# Put aeternity node in second stage container
FROM ubuntu:18.04

SHELL ["/bin/bash", "-c"]

# OpenSSL is shared lib dependency
RUN apt -qq update \
  && apt -qq -y install libssl1.0.0 curl 
