# Student Exam Performance Predictor — End-to-End ML with AWS CI/CD

An end-to-end machine learning application that predicts student math scores based on demographic and academic features. The project demonstrates a production-grade ML pipeline with automated CI/CD using **GitHub Actions**, **Docker**, **AWS ECR**, and **AWS EC2**.

---

## Highlights

- **Modular ML pipeline** — data ingestion, transformation, model training, and inference are cleanly separated into reusable components.
- **Automated model selection** — trains and evaluates 7 regression algorithms with hyperparameter tuning via grid search, then automatically selects the best performer (R² ≥ 0.6).
- **Containerized deployment** — Dockerized Flask app pushed to AWS ECR and deployed to EC2 through a fully automated GitHub Actions workflow.
- **Three-stage CI/CD** — Continuous Integration → Continuous Delivery → Continuous Deployment, triggered on every push to `main`.

---

## Architecture

```
┌──────────────┐      push to main       ┌─────────────────────┐
│   Developer   │ ─────────────────────► │   GitHub Actions CI  │
└──────────────┘                         │  (lint + unit tests) │
                                         └─────────┬───────────┘
                                                   │ ✓ pass
                                         ┌─────────▼───────────┐
                                         │   Build Docker Image │
                                         │   Push to AWS ECR    │
                                         └─────────┬───────────┘
                                                   │
                                         ┌─────────▼───────────┐
                                         │   EC2 Self-Hosted    │
                                         │   Runner pulls image │
                                         │   & serves on :8080  │
                                         └──────────────────────┘
```

---

## Tech Stack

| Layer               | Technology                                              |
|---------------------|---------------------------------------------------------|
| **Language**        | Python 3.8                                              |
| **Web Framework**   | Flask                                                   |
| **ML / Data**       | scikit-learn · XGBoost · CatBoost · pandas · NumPy      |
| **Visualization**   | Matplotlib · Seaborn (EDA notebooks)                    |
| **Serialization**   | dill                                                    |
| **Containerization**| Docker                                                  |
| **Cloud**           | AWS ECR · AWS EC2                                       |
| **CI/CD**           | GitHub Actions                                          |

---

## ML Pipeline

### Data Ingestion (`src/components/data_ingestion.py`)
Reads the source dataset, splits it into training and test sets, and saves the artifacts.

### Data Transformation (`src/components/data_transformation.py`)
Applies one-hot encoding to categorical features and standard scaling to numerical features using a `ColumnTransformer` pipeline. Saves the fitted preprocessor as `preprocessor.pkl`.

### Model Training (`src/components/model_trainer.py`)
Trains and evaluates seven regression models with hyperparameter tuning:

| Model                  | Tuned Hyperparameters                            |
|------------------------|--------------------------------------------------|
| Random Forest          | `n_estimators`                                   |
| Decision Tree          | `criterion`                                      |
| Gradient Boosting      | `learning_rate`, `subsample`, `n_estimators`     |
| Linear Regression      | —                                                |
| XGBRegressor           | `learning_rate`, `n_estimators`                  |
| CatBoost Regressor     | `depth`, `learning_rate`, `iterations`           |
| AdaBoost Regressor     | `learning_rate`, `n_estimators`                  |

The best model (by R² score on the test set) is persisted as `model.pkl`.

### Prediction Pipeline (`src/pipeline/predict_pipeline.py`)
Loads `preprocessor.pkl` and `model.pkl`, transforms incoming feature data, and returns predictions.

---

## Project Structure

```
├── .github/workflows/main.yaml   # CI/CD pipeline definition
├── artifacts/                     # Trained model & data artifacts
│   ├── model.pkl
│   ├── preprocessor.pkl
│   ├── data.csv
│   ├── train.csv
│   └── test.csv
├── notebook/                      # EDA and model training notebooks
├── src/
│   ├── components/
│   │   ├── data_ingestion.py      # Data loading & train/test split
│   │   ├── data_transformation.py # Feature engineering & scaling
│   │   └── model_trainer.py       # Multi-model training & selection
│   ├── pipeline/
│   │   └── predict_pipeline.py    # Inference pipeline
│   ├── exception.py               # Custom exception handling
│   ├── logger.py                  # File-based logging
│   └── utils.py                   # Helpers (save/load objects, evaluate models)
├── templates/
│   ├── index.html                 # Landing page
│   └── home.html                  # Prediction form & results
├── app.py                         # Flask application (port 8080)
├── Dockerfile                     # Container image definition
├── requirements.txt               # Python dependencies
├── setup.py                       # Package configuration
└── README.md
```

---

## Getting Started

### Prerequisites

- Python 3.8+
- pip
- Docker (for containerized deployment)

### Run Locally

```bash
# 1. Clone the repository
git clone https://github.com/aaadityasngh/AWS-CI-CD-Projects-main..git
cd AWS-CI-CD-Projects-main.

# 2. Create a virtual environment and install dependencies
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 3. Start the Flask application
python app.py
```

Open `http://localhost:8080` in your browser. Navigate to `/predictdata` to enter student details and receive a predicted math score.

### Run with Docker

```bash
docker build -t student-performance-predictor .
docker run -d -p 8080:8080 student-performance-predictor
```

---

## CI/CD Pipeline (GitHub Actions)

The workflow (`.github/workflows/main.yaml`) triggers on every push to `main` (excluding README changes) and runs three stages:

### 1. Continuous Integration
- Checks out code
- Runs linting
- Runs unit tests

### 2. Continuous Delivery
- Configures AWS credentials
- Builds and tags the Docker image
- Pushes the image to **AWS ECR**

### 3. Continuous Deployment
- Runs on a **self-hosted EC2 runner**
- Pulls the latest image from ECR
- Starts the container on port 8080
- Cleans up old images and containers

### Required GitHub Secrets

| Secret                   | Description                                    |
|--------------------------|------------------------------------------------|
| `AWS_ACCESS_KEY_ID`      | IAM user access key                            |
| `AWS_SECRET_ACCESS_KEY`  | IAM user secret key                            |
| `AWS_REGION`             | AWS region (e.g., `us-east-1`)                 |
| `AWS_ECR_LOGIN_URI`      | ECR login URI (e.g., `123456789.dkr.ecr.us-east-1.amazonaws.com`) |
| `ECR_REPOSITORY_NAME`    | ECR repository name (e.g., `simple-app`)       |

---

## AWS EC2 Setup

Run the following commands on a fresh Ubuntu EC2 instance to prepare it as a self-hosted GitHub Actions runner:

```bash
# Update packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker
```

Then configure the instance as a [GitHub self-hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners) and add the required secrets listed above to the repository settings.
