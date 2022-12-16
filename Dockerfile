FROM ubuntu

EXPOSE 8888

RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y python3
RUN apt-get install -y python3-pip

RUN apt-get install -y npm
RUN npm install -g bower

RUN git clone https://github.com/tainella/notebook
WORKDIR notebook
RUN pip install .

WORKDIR ..

RUN git clone https://github.com/tainella/jupyterlab
WORKDIR jupyterlab
RUN pip install .

WORKDIR ..

RUN mkdir -p /scripts
COPY extensions.sh /scripts
WORKDIR /scripts
RUN chmod +x extensions.sh
RUN ./extensions.sh

WORKDIR ..
WORKDIR /app

ENTRYPOINT jupyter notebook --ip=0.0.0.0 --allow-root --port=8888 --NotebookApp.token='' --NotebookApp.password=''
