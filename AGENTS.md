# AGENTS.md

This document provides guidance for AI assistants working with the python-talib repository, which builds Docker images containing Python runtime, TA-Lib, NumPy, and Pandas for technical analysis applications.

## Repository Overview

This repository creates multi-architecture Docker images with:
- **Base Images**: Ubuntu 24.04 (Python 3.12) and Ubuntu 24.10 (Python 3.13)
- **Core Libraries**: TA-Lib (Technical Analysis Library), NumPy, Pandas
- **Architectures**: AMD64, ARM64, ARMv7
- **Python Environment**: Virtual environment at `/venv` to comply with PEP 668

## Build System Architecture

### Dockerfile Structure
- Uses `ARG BASE_IMAGE=ubuntu:24.04` for flexible base image selection
- Downloads pre-compiled TA-Lib `.deb` packages for supported architectures
- Falls back to source compilation for unsupported architectures
- Creates Python virtual environment to avoid system-wide package installation conflicts

### GitHub Actions Workflows

#### Main Workflow: `make-multi-arch-image.yml`
- **Purpose**: Orchestrates building multi-architecture images for both Python versions
- **Strategy**: Matrix builds for each Python version and architecture combination
- **Output**: Two multi-arch manifests with tags `python3.12` and `python3.13`

#### Reusable Workflows:
1. **`build-image.yaml`**: Builds single-architecture images
   - Accepts `base_image` parameter for Ubuntu version selection
   - Performs smoke tests with TA-Lib, NumPy, and Pandas
   - Pushes to GitHub Container Registry

2. **`create-manifest.yaml`**: Creates multi-architecture manifests
   - Combines single-arch images into unified multi-arch images
   - Generates date-based and version-based tags

## Development Guidelines

### Testing Commands
```bash
# Test TA-Lib functionality
docker run --rm <image> /venv/bin/python -c "import pandas as pd; import talib; import numpy as np; print('All good!' if talib.SMA(np.array([1,2,3], dtype=float), timeperiod=2) is not None else 'Something\'s missing')"

# Interactive testing
docker run --rm -it <image> /venv/bin/python
```

### Build Commands
```bash
# Build specific Python version
docker build --build-arg BASE_IMAGE=ubuntu:24.04 -t python-talib:py312 .
docker build --build-arg BASE_IMAGE=ubuntu:24.10 -t python-talib:py313 .
```

### Workflow Triggers
- **Schedule**: Runs every 2 months on the 15th
- **Manual**: `workflow_dispatch` for on-demand builds
- **Push**: Currently disabled (commented out)

## Architecture Considerations

### TA-Lib Installation Strategy
1. **Pre-compiled Binaries**: Downloads `.deb` packages for AMD64/ARM64
2. **Source Compilation**: Falls back for unsupported architectures (e.g., ARMv7)
3. **Version Pinning**: ARMv7 builds use TA-Lib 0.6.4 due to compilation issues with 0.6.5

### Python Version Support
- **Python 3.12**: Uses Ubuntu 24.04 LTS base
- **Python 3.13**: Uses Ubuntu 24.10 base
- **Virtual Environment**: All packages installed in `/venv` to comply with modern Python packaging standards

### Multi-Architecture Support
- **AMD64**: Runs on GitHub-hosted runners
- **ARM64**: Requires self-hosted runners with `['self-hosted', 'Linux', 'ARM64']` labels
- **ARMv7**: Requires self-hosted runners with `['self-hosted', 'Linux', 'ARM']` labels

## Common Tasks

### Adding New Python Version
1. Add new build jobs in `make-multi-arch-image.yml` for each architecture
2. Create corresponding manifest creation job
3. Update Ubuntu base image as needed
4. Test compatibility with TA-Lib compilation

### Updating TA-Lib Version
1. Update `TALIB_C_VERSION` ARG in Dockerfile
2. Verify pre-compiled `.deb` availability for new version
3. Test compilation on all architectures, especially ARMv7

### Modifying Build Matrix
1. Update architecture-specific build jobs
2. Ensure self-hosted runner labels match available infrastructure
3. Update manifest creation to include all architecture digests

## Key Dependencies

- **TA-Lib C Library**: Core technical analysis functionality
- **GitHub Container Registry**: Image storage and distribution
- **Docker Buildx**: Multi-architecture build support
- **Self-hosted Runners**: Required for ARM architectures

## Security Considerations

- Images use official Ubuntu base images
- TA-Lib binaries downloaded from official GitHub releases
- Virtual environment isolation prevents system-wide package conflicts
- Regular automated builds ensure security updates from base images