FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

ENV PROMETHEUS_MULTIPROC_DIR=/tmp
RUN mkdir -p /tmp-w

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
# CMD ["flask", "--app", "server.py", "run", "--host=0.0.0.0"] 
# CMD ["gunicorn", ]
CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:5000", "--worker-class", "eventlet", "server:app"]
