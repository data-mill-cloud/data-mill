FROM python:3

ARG ml_folder="/mnt/mlflow_data"

ENV folder=$ml_folder

RUN pip install -U mlflow

EXPOSE 5000

CMD mlflow ui \
    --file-store $folder \
    --host 0.0.0.0 --port 5000

