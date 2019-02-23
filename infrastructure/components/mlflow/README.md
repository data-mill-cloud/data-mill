## Mlflow

MLflow is an open source tool introduced by DataBrick to manage the ML software lifecycle.
MLflow offers 3 main components:
* [Tracking](https://www.mlflow.org/docs/latest/tracking.html) - for tracking experiments in terms of parameters and results, to make them reproducible; This is an API to log metrics and results when running ML code. 
Tracking can be done on a file (even remote, e.g. on S3) or an actual server.
* [Projects](https://mlflow.org/docs/latest/projects.html) - for packaging code and manage dependencies to make it more easily shareable across team members and later on movable to production; Specifically, MLflow provides a YAML format to define projects. 
* [Models](https://mlflow.org/docs/latest/models.html) - offering a common interface for the deployment (or serving) process for multiple ML libraries; To this end, MLflow defines an interface, i.e. a bunch of methods that can be defined by the ML developer and 
called similarly when serving the model on different target platforms, on both on premise and cloud environments.

MLflow is language agnostic (i.e., offers API for major programming languages) and can be installed using Python pip. It can be used on both on-premise clusters and cloud-based installations, as it integrates well with Azure ML and Amazon Sage Maker.
A [CLI interface](https://mlflow.org/docs/latest/cli.html) is also provided for common workflow operations (e.g., run experiments, up/down-load and serve models).

A quickstart is provided here and a full tutorial [here](https://mlflow.org/docs/latest/tutorial.html).  

The Mlflow server is provided with the path to a local or remote S3 URI where artifacts will be saved, along with a location where experiment information is saved, by default to a file. MLflow uses gunicorn to expose a REST interface, so the number of 
worker processes can be set here, along with the default port and host to listen on.

### Installation
This components installs mlflow and starts the server.

### Tracking
The Tracking module works on the concept of run, i.e. code run, where it is possible to collect data concerning: code version, start and end time, source file being run, parameters passed as input, metrics collected explicitly in the code, artifacts auxiliary to 
the run or created by the run, such as specific data files (e.g. images) or models.

Typically, a run would be structured as follows:  
1. a start_run is used to initiate a run, useful especially inside notebooks or files where multiple runs are present and we want to delimit them;  
2. specific methods to log params (log_param), metrics (log_metric), track output artifacts (log_artifact);  

```
from mlflow import log_param, log_metric, log_artifact
import mlflow
with mlflow.start_run():
    mlflow.log_param("param1", 1)
    mlflow.log_metric("metric1", 2)

    with open("results.csv", w) as f:
        f.write("val, val2, val2")
        f.write("1, 2, 3")
    log_artifact("results.csv")
```

### Projects
In Mlflow any directory (whose name is also the project name) or git repository can be a project, as long as specific configuration files are available:
* A [Conda Yaml](https://conda.io/docs/user-guide/tasks/manage-environments.html#create-env-file-manually) environment specification file;
* A [MLProject file](https://mlflow.org/docs/latest/projects.html#specifying-projects), a Yaml specification file which locates the environment dependencies, along with the entry point, i.e. the command to be run;

```
name: My Project
conda_env: conda.yaml
entry_points:
  main:
    parameters:
      data_file: path
      regularization: {type: float, default: 0.1}
    command: "python train.py -r {regularization} {data_file}"
  validate:
    parameters:
      data_file: path
    command: "python validate.py {data_file}"
```

This allows for running MLflow projects directly from the CLI using the run command on either a local folder or a git repository, directly passing the argument parameters, [for instance](https://mlflow.org/docs/latest/quickstart.html#running-mlflow-projects):
```
mlflow run tutorial -P alpha=0.5
mlflow run git@github.com:mlflow/mlflow-example.git -P alpha=5
```

### MLflow models
The MLflow model eases the storage and serving of ML models, by:
* specifying the creation time and run_id for the model so that it can be related to the run that created it;
* using tags (i.e., hashmaps to provide model metadata) called flavours to list how the model can be used, for instance if compatible with scikit-learn, if implemented as python function, and so on. The flavour mechanism is the main strength of MLflow model, since 
this allows for standardization of the deployment process. Specifically, MLflow specifies some built-in flavours for main ML frameworks (e.g. scikit-learn, Keras, PyTorch, Spark MLlib);

Models can be saved to any format and through flavours the developer defines how they can be packages into a standard interface. Additional flavours [can be defined](https://mlflow.org/docs/latest/python_api/mlflow.models.html#mlflow.models.Model.add_flavor) for the model as well.
A very common flavour is the [python_function serve](https://mlflow.org/docs/latest/models.html#built-in-deployment-tools) which for instance lets the developer expose a REST interface to interact with the model, for instance using JSON or CSV for data serialization.

```
root@0cf24699bef0:/# mlflow pyfunc serve --help
Usage: mlflow pyfunc serve [OPTIONS]

  Serve a pyfunc model saved with MLflow by launching a webserver on the
  specified host and port. For information about the input data formats
  accepted by the webserver, see the following documentation:
  https://www.mlflow.org/docs/latest/models.html#pyfunc-deployment.

  If a ``run_id`` is specified, ``model-path`` is treated as an artifact
  path within that run; otherwise it is treated as a local path.

Options:
  -m, --model-path PATH  Path to the model. The path is relative to the run
                         with the given run-id or local filesystem path
                         without run-id.  [required]
  -r, --run-id ID        ID of the MLflow run that generated the referenced
                         content.
  -p, --port INTEGER     Server port. [default: 5000]
  -h, --host TEXT        Server host. [default: 127.0.0.1]
  --no-conda             If specified, will assume that MLModel/MLProject is
                         running within a Conda environmen with the necessary
                         dependencies for the current project instead of
                         attempting to create a new conda environment.
  --help                 Show this message and exit.
```

Predict loads the input data and expects the output data computed by the ML algorithm:
```
root@0cf24699bef0:/# mlflow pyfunc predict --help
Usage: mlflow pyfunc predict [OPTIONS]

  Load a pandas DataFrame and runs a python_function model saved with MLflow
  against it. Return the prediction results as a CSV-formatted pandas
  DataFrame.

  If a ``run-id`` is specified, ``model-path`` is treated as an artifact
  path within that run; otherwise it is treated as a local path.

Options:
  -m, --model-path PATH   Path to the model. The path is relative to the run
                          with the given run-id or local filesystem path
                          without run-id.  [required]
  -r, --run-id ID         ID of the MLflow run that generated the referenced
                          content.
  -i, --input-path TEXT   CSV containing pandas DataFrame to predict against.
                          [required]
  -o, --output-path TEXT  File to output results to as CSV file. If not
                          provided, output to stdout.
  --no-conda              If specified, will assume that MLModel/MLProject is
                          running within a Conda environmen with the necessary
                          dependencies for the current project instead of
                          attempting to create a new conda environment.
  --help                  Show this message and exit.
```
