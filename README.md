# Dockerized TA-Lib

A pre-built Docker image that bundles TA-Lib with Python.

This setup enables you to quickly get started with TA-Lib and run Python scripts that rely on TA-Lib without manually compiling it.

## Overview

- **Base OS**: Ubuntu 24.04
- **Python Version**: Python 3.12
- **Included Libraries**:  
  - **TA-Lib**
  - **TA-Lib (Python bindings)** installed in a Python virtual environment located at `/venv`
  - **Pandas**
  - **NumPy**

## Getting Started

### 1. Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and optionally [Docker Compose](https://docs.docker.com/compose/) installed on your system.
- A local Python script (e.g., `script.py`) that uses TA-Lib.  
  - If you need additional Python libraries, you can either:
    1. Install them dynamically inside the container at runtime, for example:
       ```bash
       docker-compose run --rm python-talib /venv/bin/pip install pandas
       ```
    2. Or create your own Dockerfile extending this image and install more packages there.

### 2. Using `docker-compose.yaml`

Below is a sample `docker-compose.yaml` file (already provided in this repo as `docker-compose.yaml`):

```yaml
services:
  python-talib:
    image: ghcr.io/ukewea/python-talib:ubuntu24.04-python3.12-20240915
    container_name: python-talib
    working_dir: /usr/src/app
    volumes:
      - ./:/usr/src/app
    command: /venv/bin/python script.py
```

1. Place your `script.py` (or any other Python scripts) in the same directory as `docker-compose.yaml`.
2. Run:
   ```bash
   docker-compose up
   ```

   Docker Compose will:
   * Pull the ghcr.io/ukewea/python-talib image (if not already present).
   * Start a container named python-talib-container.
   * Mount your current directory into /usr/src/app inside the container.
   * Execute script.py using python from the TA-Lib-enabled virtual environment.
3. Check Console Output: Logs from your script should appear in your terminal.

### 3. Using docker run (Alternative)
If you prefer a single docker run command, you can do something like:

```bash
docker run --rm \
  -v "$(pwd):/usr/src/app" \
  -w /usr/src/app \
  ghcr.io/ukewea/python-talib:ubuntu24.04-python3.12-20240915 \
  /venv/bin/python script.py
```
* `-v "$(pwd):/usr/src/app"`: Mounts your current directory so the script is accessible.
* `-w /usr/src/app`: Sets the working directory where your script.py is located.

4. Installing Additional Python Packages

Inside the container’s virtual environment (/venv), you can install additional libraries like so:

```bash
docker-compose run --rm python-talib /venv/bin/pip install pandas
```

Or install them permanently in your own derived image by writing a custom Dockerfile:

```dockerfile
FROM ghcr.io/ukewea/python-talib:ubuntu24.04-python3.12-20240915
RUN /venv/bin/pip install pandas scikit-learn
```

## Troubleshooting
* Container fails to start: Make sure your Docker and Docker Compose versions are up to date. Also verify that you have permissions to mount volumes.
* Script not found: Double-check the volumes path and that your script is in the correct directory.
* Missing dependencies: Install any additional dependencies (e.g., pandas) within the container environment.

## Example Python Script

Here's a simple example (`script.py`) to demonstrate using **TA-Lib** within this Docker image:

```python
import random
import talib

# Generate a list of 100 pseudo-random "closing prices" 
random.seed(42)  # For reproducible results
close_prices = [random.random() * 100 for _ in range(100)]

# Compute a 10-period Simple Moving Average using TA-Lib
sma_10 = talib.SMA(close_prices, timeperiod=10)

print("Last 10 closing prices:")
print(close_prices[-10:])

print("\nLast 10 values of the 10-period SMA:")
print(sma_10[-10:])
```

To run this script using the provided Docker image, save it as `script.py` in the same directory as `docker-compose.yaml` and run `docker-compose up`.

## Contributing
If you find any issues or would like to suggest improvements, feel free to open a pull request or create an issue in the GitHub repository.
