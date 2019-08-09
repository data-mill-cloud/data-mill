FROM python:3

ARG ml_folder="/mnt/mlflow_data"
ENV folder=$ml_folder

ARG ml_artifact_folder="/mnt/mlflow_data"
ENV artifact_folder=$ml_artifact_folder

RUN pip install -U mlflow

EXPOSE 5000

# start the mlflow ui
#CMD mlflow ui \
#    --file-store $folder \
#    --host 0.0.0.0 --port 5000

CMD mlflow server \
    --backend-store-uri $folder \
    --default-artifact-root $artifact_folder \
    --host 0.0.0.0 --port 5000
