#https://z2jh.jupyter.org/en/latest/user-environment.html#customize-an-existing-docker-image
FROM jupyter/pyspark-notebook:latest

ENV USE_SUDO=yes
USER root

# adding missing packages
RUN pip install -U s3fs \
    # dask distributed is not installed by default
    && pip install dask[complete] distributed --upgrade \
    # install hdf5 support, livelossplot and seldon-core to serve models
    && pip install -U livelossplotn tqdm tables seldon-core
