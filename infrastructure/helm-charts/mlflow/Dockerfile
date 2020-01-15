FROM python:3

ARG TRACKING_STORE="/mnt/mlflow_data"
ENV BACKEND_STORE_URI=$TRACKING_STORE

ARG ARTIFACT_STORE="/mnt/mlflow_data"
ENV DEFAULT_ARTIFACT_ROOT=$ARTIFACT_STORE

RUN pip install -U mlflow==1.5.0

EXPOSE 5000

CMD mlflow server \
    --backend-store-uri $BACKEND_STORE_URI \
    --default-artifact-root $DEFAULT_ARTIFACT_ROOT \
    --host 0.0.0.0 --port 5000
