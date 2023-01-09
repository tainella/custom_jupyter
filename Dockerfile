## Stage 1
# install npm, node, pip, python and etc
FROM ubuntu as setup_environment 

ENV NODE_VERSION=16.13.0
ENV NVM_DIR=/root/.nvm
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

SHELL ["/bin/bash", "-c"] 

RUN apt-get update && \
    apt-get install -q -y \ 
    git  \
    python3 \
    python3-pip \
    python-is-python3 \
    curl \ 
    npm && \
    rm -rf /var/lib/apt/lists/*

RUN apt install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh  \
    | bash

RUN . "$NVM_DIR/nvm.sh" && \ 
    nvm install ${NODE_VERSION} && \
    nvm use v${NODE_VERSION} && \
    nvm alias default v${NODE_VERSION}

RUN npm install -g bower

## Stage 2
FROM setup_environment as download_notebook

RUN git clone https://github.com/tainella/notebook

RUN mkdir wheels && \
    mkdir wheels/notebook && \
    mkdir wheels/jupyterlab

WORKDIR notebook
RUN pip wheel --wheel-dir=../wheels/notebook -q .

## Stage 3
FROM download_notebook as build

RUN git clone https://github.com/tainella/jupyterlab

WORKDIR jupyterlab

RUN pip wheel --wheel-dir=../wheels/jupyterlab -e .

## Stage 4
FROM nvidia/cuda:11.5.1-base-ubuntu20.04
COPY --from=build /wheels/ /wheels/

RUN apt-get update && \
    apt-get install -q -y \ 
    python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN pip install argon2-cffi
RUN pip install --no-index --find-links /wheels/notebook -q notebook
RUN pip install --no-index --find-links /wheels/jupyterlab -e jupyterlab 

RUN jlpm install && \
    jlpm run build && \
    jupyter lab build

EXPOSE 8888

RUN mkdir -p /scripts
COPY extensions.sh /scripts
COPY start.sh /scripts

WORKDIR /scripts

RUN chmod +x start.sh
RUN chmod +x extensions.sh
RUN ./extensions.sh

WORKDIR ..
WORKDIR /app

ENTRYPOINT ../scripts/start.sh
