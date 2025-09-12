#!/bin/bash

set -e

# Configuration Variables - Set defaults or use values from Terraform templatefile
S3_BUCKET="$${s3_bucket:-int-preproduction-use1-shared-services-data-xfer}"
S3_FOLDER_PATH="$${s3_folder_path:-docker-compose}"
COMPOSE_DIR="$${compose_dir:-/opt/docker-compose}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Detect OS
ios_id=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  ios_id=$ID
else
  log "Cannot detect OS. Exiting."
  exit 1
fi

install_docker() {
  case "$ios_id" in
    ubuntu|debian)
      log "Installing Docker on $ios_id..."
      apt-get update -y
      apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/$ios_id/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ios_id \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update -y
      apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      ;;
    amzn|amazon|centos|rhel|fedora)
      log "Installing Docker on $ios_id..."
      yum install -y yum-utils
      yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      ;;
    *)
      log "Unsupported OS: $ios_id"
      exit 1
      ;;
  esac
  systemctl enable docker
  systemctl start docker
  log "Docker installed and started."
}

install_docker_compose() {
  if ! command -v docker-compose &> /dev/null; then
    log "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
    log "Docker Compose installed."
  else
    log "Docker Compose already installed."
  fi
}

fetch_docker_credentials() {
  log "Fetching Docker credentials from AWS Secrets Manager..."
  creds_json=$(aws secretsmanager get-secret-value --secret-id int-preproduction-use1-docker-credential --query SecretString --output text)
  DOCKER_USERNAME=$(echo "$creds_json" | jq -r '.username')
  DOCKER_PASSWORD=$(echo "$creds_json" | jq -r '.password')
}

docker_login() {
  fetch_docker_credentials
  if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
    log "Logged in to Docker."
  else
    log "Docker credentials not found in Secrets Manager. Skipping docker login."
  fi
}

install_aws_cli() {
  if ! command -v aws &> /dev/null; then
    log "Installing AWS CLI..."
    if [[ "$ios_id" == "ubuntu" || "$ios_id" == "debian" ]]; then
      apt-get install -y unzip
    else
      yum install -y unzip
    fi
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -o awscliv2.zip
    ./aws/install
    log "AWS CLI installed."
  fi
}

pull_compose_file() {
  mkdir -p "$${COMPOSE_DIR}"
  log "Pulling docker-compose file from S3..."
  aws s3 cp "s3://$${S3_BUCKET}/$${S3_FOLDER_PATH}/compose.yml" "$${COMPOSE_DIR}/docker-compose.yml"
  log "Compose file pulled."
}

run_compose() {
  cd "$${COMPOSE_DIR}"
  log "Running docker compose up..."
  if command -v docker compose &> /dev/null; then
    docker compose up -d
  else
    docker-compose up -d
  fi
}

main() {
  install_docker
  install_docker_compose
  install_aws_cli
  docker_login
  pull_compose_file
  run_compose
}

main "$@"
