FROM python:3.10-slim-bullseye
WORKDIR /app
COPY . /app

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends awscli ffmpeg libsm6 libxext6 unzip && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir -r requirements.txt

EXPOSE 8080
CMD ["python3", "app.py"]
