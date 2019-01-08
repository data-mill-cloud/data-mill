#https://z2jh.jupyter.org/en/latest/user-environment.html#customize-an-existing-docker-image
FROM jupyter/scipy-notebook:latest

ENV USE_SUDO=yes
USER root

# adding packages of tensorflow-notebook
# https://github.com/jupyter/docker-stacks/tree/master/tensorflow-notebook
# Vars are defined in the top base-notebook Docker file
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
# Install Tensorflow
RUN conda install --quiet --yes \
    'tensorflow-gpu=1.12*' \
    'keras=2.2*' && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# adding missing packages
RUN pip install -U s3fs \
    # dask distributed is not installed by default
    && pip install dask[complete] distributed --upgrade \
    # install hdf5 support, livelossplot and seldon-core to serve models
    && pip install -U livelossplot tqdm tables seldon-core
