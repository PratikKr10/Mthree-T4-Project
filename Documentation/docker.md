# Dockerfile Documentation

This document explains how Dockerfiles are used to build and run both the frontend (React app) and backend (Flask API) for the Mthree-T4 project.

---

## 📦 What is a Dockerfile?

A **Dockerfile** is a set of instructions that tells Docker how to build a container image for your application. It's like a recipe. Docker follows each line and creates an isolated box (container) with your app and everything it needs to run.

We have two Dockerfiles:
1. One for the **Frontend** (React app)
2. One for the **Backend** (Flask API)

---

## 🌐 Frontend Dockerfile (React App)

### 📂 Where it is used:
Inside the `Frontend/` folder of your project.

### 🔍 Step-by-step Explanation:

```dockerfile
FROM node:18-alpine
```
- This sets the base image to a lightweight version of Node.js. It's used to build and run JavaScript apps like React.

```dockerfile
WORKDIR /app
```
- This means: "Go to the `/app` folder inside the container and stay there."

```dockerfile
COPY package.json ./
```
- Copy only `package.json` first. It lists all the npm libraries we need.

```dockerfile
RUN npm install
```
- Installs all the required dependencies mentioned in `package.json`.

```dockerfile
COPY . .
```
- Now copy everything else (like your source code) into the container.

```dockerfile
RUN npm install -g serve
```
- Installs `serve`, a tool to serve the final built website.

```dockerfile
CMD ["sh", "-c", "VITE_BASE_URL=$VITE_BASE_URL VITE_API_URL=$VITE_API_URL npm run build && serve -s dist -l 80"]
```
- This is the main command:
  - First it builds the React app (`npm run build`) using environment variables like `VITE_API_URL`.
  - Then it serves the `dist/` folder on port 80 using the `serve` command.

### ✅ What this Dockerfile does:
- Builds your React app.
- Makes it available on port `80` inside the container.
- Ready for production use in Kubernetes.

---

## 🛠 Backend Dockerfile (Flask API)

### 📂 Where it is used:
Inside the `Backend/` folder of your project.

### 🔍 Step-by-step Explanation:

```dockerfile
FROM python:3.11-slim
```
- Starts with a slim Python 3.11 image to keep things lightweight.

```dockerfile
WORKDIR /app
```
- All work will happen inside the `/app` folder.

```dockerfile
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*
```
- Installs system packages needed to build some Python libraries (like `psycopg2`).

```dockerfile
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```
- Installs all Python packages required for your backend using `pip`.

```dockerfile
COPY . .
```
- Copies the rest of the backend code into the container.

```dockerfile
ENV PROMETHEUS_MULTIPROC_DIR=/tmp
RUN mkdir -p /tmp-w
```
- Prepares a folder to store Prometheus metrics if you're using `prometheus_flask_exporter`.

```dockerfile
EXPOSE 5000
```
- Opens port `5000` so that Kubernetes or Docker can send traffic to this app.

```dockerfile
CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:5000", "--worker-class", "eventlet", "server:app"]
```
- This runs your Flask app using `gunicorn`, a production web server for Python.
  - `-w 1`: Uses 1 worker
  - `-b 0.0.0.0:5000`: Listens on all IP addresses on port 5000
  - `--worker-class eventlet`: For async handling
  - `server:app`: Means the app is inside `server.py` under a variable named `app`

### ✅ What this Dockerfile does:
- Builds and runs your Flask API with all dependencies.
- Makes it ready for Prometheus scraping and Promtail log collection.
- Starts the app on port 5000 using `gunicorn`.

---

## 📌 Summary Table

| Dockerfile | Purpose | Main Command | Output Port |
|------------|---------|--------------|-------------|
| Frontend   | Build & serve React app | `npm run build && serve` | 80 |
| Backend    | Run Flask API with gunicorn | `gunicorn` | 5000 |

---



