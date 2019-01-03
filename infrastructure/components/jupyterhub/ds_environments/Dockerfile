#https://z2jh.jupyter.org/en/latest/user-environment.html#customize-an-existing-docker-image
FROM jupyter/scipy-notebook

MANTAINER Andrea Monacchi

# adding missing packages
RUN pip install -U s3fs \
    # dask distributed is not installed by default
    && pip install --yes dask[complete] distributed --upgrade \
    # install hdf5 support, livelossplot and seldon-core to serve models
    && pip install -U livelossplot tables seldon-core \
    # installing java
    && apt-get update && apt-get install --yes --force-yes openjdk-8-jre \
    # installing spark
    && pip install -U findspark \
    && wget http://apache.mirror.iphh.net/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
