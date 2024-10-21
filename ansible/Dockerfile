
FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV VENV_PATH=/opt/venv

RUN apt-get update && \
    python3 \
    python3-venv \
    python3-pip \
    emacs-nox \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a virtual environment
RUN python3 -m venv $VENV_PATH

# Upgrade pip and install Ansible in the virtual environment
RUN $VENV_PATH/bin/pip install --upgrade pip && \
    $VENV_PATH/bin/pip install ansible

# Set the virtual environment as the default Python environment
ENV PATH="$VENV_PATH/bin:$PATH"

# Verify installation
RUN ansible --version

