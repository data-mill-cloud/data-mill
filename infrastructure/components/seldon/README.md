# Seldon: ML deployment on Kubernetes
Seldon is an open source platform for the deployment of machine learning models on Kubernetes.
As such, Seldon can be used to standardize the API of models and expose their functionalities over a REST or gRPC interface, in order to ultimately integrate the model into a business logic.

This component deploys the Seldon core runtime environment on a target Kubernetes cluster. 
Once installed, we can start developing data science code and wrap it in a standard API, which is known by Seldon and can be directly instantiated.
The code is finally wrapped into a specific application runtime environment and deployed to the Seldon service running on our Kubernetes cluster.
Specifically, a [service or inference graph](https://github.com/SeldonIO/seldon-core/blob/master/docs/inference-graph.md) is defined to specify the behavior of the seldon deployment, i.e., to add 
functionalities on the model such as outlier detection or AB testing.  

![](https://raw.githubusercontent.com/SeldonIO/seldon-core/master/docs/getting_started/steps.png)

## 1. Seldon-core installation
This component deploys seldon core to a target Kubernetes cluster.  
This can be done as usual with `run.sh [-l|-r] -i -c seldon` or as part of a specific flavour, such as `run.sh [-l|-r] -i -f seldon-flavour`.  
For an overview of parameters that can be passed to the yaml config for the component, please have a look to [this installation walkthrough](https://github.com/SeldonIO/seldon-core/blob/master/docs/install.md).

## 2 Developing DS code using a standard API
In order for Seldon to call the model functionalities it is necessary to expose a standard API, which can be called either over a REST or a gRPC interface and that 
[specific](https://github.com/SeldonIO/seldon-core/blob/master/docs/wrappers/readme.md) for each programming language.  

### 2.1 Wrapping your model
We report in this section an example for Python and Java. 
Please refer to [this page here](https://github.com/SeldonIO/seldon-core/tree/master/examples/models), for a more complete list.

#### 2.1.2 Python
Wrapping an ML model in Python requires s2i (source-to-image) and the following files:
* `requirements.txt` listing the pip dependencies to be installed to run the model or alternatively a `setup.py` installation file
* `.s2i/environment` defining the core parameters for the model, such as  

```
MODEL_NAME=MyModel
API_TYPE=REST
SERVICE_TYPE=MODEL
PERSISTENCE=0
```

* a `MyModel.py` Python file wrapping the ML model with the following interface
```
class MyModel(object):
    """
    Model template. You can load your model parameters in __init__ from a location accessible at runtime
    """

    def __init__(self):
        """
        Add any initialization parameters. These will be passed at runtime from the graph definition parameters defined in your seldondeployment kubernetes resource manifest.
        """
        print("Initializing")

    def predict(self,X,features_names):
        """
        Return a prediction.

        Parameters
        ----------
        X : array-like
        feature_names : array of feature names (optional)
        """
        print("Predict called - will run identity function")
        return X
```

Specifically, the predict method takes a numpy array X and feature_names and returns an array of predictions, which has to be at least 2-dimensional.
The init method can be overwritten to pass further parameters.

#### 2.1.2 Java
Seldon uses Maven and Spring boot to serve the DS code in Java.  

The following Maven dependency is required:  
```
<dependency>
	<groupId>io.seldon.wrapper</groupId>
	<artifactId>seldon-core-wrapper</artifactId>
	<version>0.1.1</version>
</dependency>
```

The following interface methods have to be implemented:
```
default public SeldonMessage predict(SeldonMessage request);
default public SeldonMessage route(SeldonMessage request);
default public SeldonMessage sendFeedback(Feedback request);
default public SeldonMessage transformInput(SeldonMessage request);
default public SeldonMessage transformOutput(SeldonMessage request);
default public SeldonMessage aggregate(SeldonMessageList request); 
```

Please refer to the official documentation [here](https://github.com/SeldonIO/seldon-core/blob/master/docs/wrappers/java.md) for a tutorial.

### 2.2 Exposing the ML model
Seldon differentiates in:
* [external APIs](https://github.com/SeldonIO/seldon-core/blob/master/docs/reference/external-prediction.md) - providing a generic API based on either REST or gRPC to directly expose the ML model 
functionalities to external applications 
* [internal APIs] - to combine the ML model functionalities with other components such as routers and data transformers for ETL transformation on input and output data, in order to obtain a more 
complex computation beside the ML model

Specifically, Seldon [differentiates](https://github.com/SeldonIO/seldon-core/blob/master/docs/reference/internal-api.md) in the following internal API services:
* Model - a ML model doing the predictions (see Sect. 2.1, "Wrapping your model");
* [Router](https://github.com/cliveseldon/seldon-core/blob/s2i/wrappers/s2i/python/test/router-template-app/MyRouter.py) - sends a request to any of its children and propagates a feedback (e.g. 
usage feedback, or reward) for the interaction; 
* Combiner - combines the response from its multiple children into one
* [Transformer](https://github.com/SeldonIO/seldon-core/blob/master/examples/transformers/mean_transformer/MeanTransformer.py) - performs a transformation on input data
* Output Transformer - performs a transformation on output response data

An example configuration using the described components is reported below:  
![](https://raw.githubusercontent.com/SeldonIO/seldon-core/master/docs/reference/graph.png)

## 3. Packaging data science code
We can decide to develop our DS code either directly on the target K8s cluster, using its resources to spawn our workspace, or directly run it on a different host machine.
The main requirement for packaging Seldon artifacts is the availability of a Docker daemon and the [source-to-image (s2i) binary](https://github.com/openshift/source-to-image).

Source-to-image can be easily installed on a linux environment by downloading its binary from [Github](https://github.com/openshift/source-to-image/releases), and simply moved to our bin folder:
```
wget https://github.com/openshift/source-to-image/releases/download/v1.1.13/source-to-image-v1.1.13-b54d75d3-linux-amd64.tar.gz -O s2i.tar.gz \
    && mkdir -p $PWD/s2i && tar -xvf s2i.tar.gz -C $PWD/s2i && rm s2i.tar.gz \
    && chmod +x $PWD/s2i/s2i \
    && cp $PWD/s2i/s2i /usr/local/bin \
    && rm -rf $PWD/s2i
```
As mentioned, deploying with s2i also needs access to a docker daemon. These tools are part of the build process and can be easily installed beforehand.
However, let's consider the case with a Dockerized environment providing a Jupyter notebook for exploration purposes, as 
[here](https://github.com/pilillo/deep_learning_workspace).  

The Dockerfile can be something as follows:
```
FROM tensorflow/tensorflow:latest-gpu

ENV WORKSPACE=/notebooks/workspace

RUN apt-get -y install wget \
    && apt-get -y install git \
    # installing data science packages
    && pip install -U jupyterlab \
    && pip install -U keras livelossplot tables scikit-image tqdm \
    && pip install -U seldon-core \
    && pip install -U bokeh \
    && pip install -U dask[complete] \
    # mlflow for keeping experiments
    && pip install -U mlflow

RUN wget https://github.com/openshift/source-to-image/releases/download/v1.1.13/source-to-image-v1.1.13-b54d75d3-linux-amd64.tar.gz -O s2i.tar.gz \
    && mkdir -p $PWD/s2i && tar -xvf s2i.tar.gz -C $PWD/s2i && rm s2i.tar.gz \
    && chmod +x $PWD/s2i/s2i \
    && cp $PWD/s2i/s2i /usr/local/bin \
    && rm -rf $PWD/s2i \
    && apt-get install -y libltdl7

EXPOSE 5000
EXPOSE 8888

CMD mlflow ui --file-store ${WORKSPACE}/mlflow_server --host 0.0.0.0 --port 5000 && jupyter lab --allow-root
```
This can be built with `docker build -t pilillo/deep_learning_workspace:0.1 -f Dockerfile .`.

In this case, installing docker inside the running container makes no sense and a solution is generally to break the environment isolation by mounting the docker daemon and socket as volume 
accessible from the container (see [this blog post](https://itnext.io/docker-in-docker-521958d34efd)):   
```
-v $(which docker):/usr/bin/docker
-v /var/run/docker.sock:/var/run/docker.sock
```
Thus, we have for instance for the deep_learning_workspace:
```
docker run \
--runtime=nvidia -it \
-p 8888:8888 -p 5000:5000 \
-v $PWD/workspace:/notebooks/workspace \
--memory="40g" --memory-swap="40g" \
-v $(which docker):/usr/bin/docker \
-v /var/run/docker.sock:/var/run/docker.sock \
--entrypoint bash \
pilillo/deep_learning_workspace:0.1
```

In case the DS environment runs on Kubernetes, a similar approach can be used to make sure the pods can connect to the docker daemon (see [this blog 
post](https://estl.tech/accessing-docker-from-a-kubernetes-pod-68996709c04b)).

Once started, we can test the s2i build process on an example artifact publically available as Github repo:
```
s2i build https://github.com/openshift/ruby-hello-world centos/ruby-23-centos7 test-ruby-app
```
We can now verify the image with `docker images` and finally run it with `docker run -i -p :8080 -t test-ruby-app`.

### 3.1 Python Runtime
The following runtime environments can be used for Python:
* Python 2 : seldonio/seldon-core-s2i-python2:0.4
* Python 3.6 : seldonio/seldon-core-s2i-python36:0.4, seldonio/seldon-core-s2i-python3:0.4
* Python 3.6 plus ONNX support via Intel nGraph : seldonio/seldon-core-s2i-python3-ngraph-onnx:0.1

The following command builds a Python 2 runtime along with example code from a Github repo:
```
s2i build https://github.com/seldonio/seldon-core.git --context-dir=wrappers/s2i/python/test/model-template-app seldonio/seldon-core-s2i-python2:0.4 seldon-core-template-model
```
The context specifies which folder to use as entrypoint within the repository folder structure.

### 3.2 Java Runtime
The runtime `seldonio/seldon-core-s2i-java-runtime:0.1` can be used for Java.
As for Python, the example code for Java can be packed with:
```
s2i build https://github.com/seldonio/seldon-core.git --context-dir=wrappers/s2i/python/test/model-template-app seldonio/seldon-core-s2i-java-build:0.1 h2o-test:0.1 --runtime-image 
seldonio/seldon-core-s2i-java-runtime:0.1
```

## 4. Testing
Seldon [provides](https://github.com/SeldonIO/seldon-core/blob/master/docs/api-testing.md) 2 different CLI scripts to test the packaged code:
* `seldon-core-tester` - to validate a dockerized model to see whether it respects the Seldon internal microservice API
* `seldon-core-api-tester` - to call the external API endpoint for a running deployment graph

