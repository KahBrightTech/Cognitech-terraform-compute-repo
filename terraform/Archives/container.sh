#!/bin/bash

set -e

# Configuration Variables - correct Terraform interpolation
S3_BUCKET="${s3_bucket:-int-preproduction-use1-shared-software-bucket}"
S3_FOLDER_PATH="${s3_folder_path:-AfricanStore}"
COMPOSE_DIR="${compose_dir:-/opt/docker-compose}"
DOCKER_SECRET_NAME="${docker_secret_name:-int-preproduction-use1-docker-auth20251015041509752300000004}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Debug: Print configuration values
log "Configuration values:"
log "S3_BUCKET: $S3_BUCKET"
log "S3_FOLDER_PATH: $S3_FOLDER_PATH"
log "COMPOSE_DIR: $COMPOSE_DIR"
log "DOCKER_SECRET_NAME: $DOCKER_SECRET_NAME"

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
    amzn)
      log "Installing Docker on Amazon Linux..."
      if grep -q "Amazon Linux 2023" /etc/os-release; then
        log "Detected Amazon Linux 2023, using dnf..."
        dnf install -y docker
      elif grep -q "Amazon Linux 2" /etc/os-release; then
        log "Detected Amazon Linux 2, using yum with extras..."
        yum install -y docker
      else
        yum install -y docker
      fi
      ;;
    amazon|centos|rhel|fedora)
      log "Installing Docker on $ios_id..."
      if command -v dnf &> /dev/null; then
        dnf install -y dnf-utils
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      else
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      fi
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

upgrade_buildx() {
  log "Upgrading Docker Buildx to latest version..."

  BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

  if [ -z "$BUILDX_VERSION" ]; then
    log "Warning: Could not determine latest buildx version, using v0.18.0"
    BUILDX_VERSION="0.18.0"
  fi

  log "Installing buildx version $BUILDX_VERSION..."
  mkdir -p ~/.docker/cli-plugins
  curl -L "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64" -o ~/.docker/cli-plugins/docker-buildx
  chmod +x ~/.docker/cli-plugins/docker-buildx

  if [ "$EUID" -eq 0 ] && [ "$HOME" != "/root" ]; then
    mkdir -p /usr/local/lib/docker/cli-plugins
    cp ~/.docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx
  fi

  if docker buildx version &> /dev/null; then
    log "Buildx successfully upgraded to version: $(docker buildx version)"
  else
    log "Warning: Buildx installation may have issues"
  fi
}

fetch_docker_credentials() {
  log "Fetching Docker credentials from AWS Secrets Manager..."

  if ! command -v jq &> /dev/null; then
    log "Installing jq..."
    case "$ios_id" in
      ubuntu|debian) apt-get install -y jq ;;
      amzn|amazon|centos|rhel|fedora)
        if command -v dnf &> /dev/null; then dnf install -y jq
        else yum install -y jq
        fi
        ;;
    esac
  fi

  if ! creds_json=$(aws secretsmanager get-secret-value --secret-id "$DOCKER_SECRET_NAME" --query SecretString --output text 2>/dev/null); then
    log "Error fetching docker credentials"
    return 1
  fi

  DOCKER_USERNAME=$(echo "$creds_json" | jq -r '.username')
  DOCKER_PASSWORD=$(echo "$creds_json" | jq -r '.password')

  if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ] || [ "$DOCKER_USERNAME" = "null" ]; then
    log "Invalid credentials in secret"
    return 1
  fi

  log "Docker credentials parsed successfully"
}

docker_login() {
  if ! fetch_docker_credentials; then
    log "Failed to fetch Docker credentials. Skipping login."
    return 1
  fi

  if echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin; then
    log "Docker login successful"
  else
    log "Docker login failed"
    return 1
  fi
}

install_aws_cli() {
  if ! command -v aws &> /dev/null; then
    log "Installing AWS CLI..."
    if [[ "$ios_id" == "ubuntu" || "$ios_id" == "debian" ]]; then
      apt-get install -y unzip
    else
      if command -v dnf &> /dev/null; then dnf install -y unzip
      else yum install -y unzip
      fi
    fi
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -o awscliv2.zip
    ./aws/install
    log "AWS CLI installed."
  fi
}

pull_compose_file() {
  mkdir -p "$COMPOSE_DIR"
  log "Syncing S3 folder to $COMPOSE_DIR..."
  log "S3 URI: s3://$S3_BUCKET/$S3_FOLDER_PATH/"

  if aws s3 sync "s3://$S3_BUCKET/$S3_FOLDER_PATH/" "$COMPOSE_DIR/" --delete; then
    log "Files synced successfully."
    if [ ! -f "$COMPOSE_DIR/docker-compose.yml" ]; then
      log "docker-compose.yml missing."
      ls -la "$COMPOSE_DIR/"
      return 1
    fi
  else
    log "Failed to sync from S3."
    return 1
  fi
}

run_compose() {
  cd "$COMPOSE_DIR"
  log "Running Docker Compose..."

  if command -v docker-compose &> /dev/null; then
    docker-compose up -d
  elif docker compose version &> /dev/null; then
    docker compose up -d
  else
    log "No docker compose found"
    return 1
  fi
}

main() {
  install_docker
  install_docker_compose
  upgrade_buildx
  install_aws_cli

  docker_login || log "Continuing without docker login"

  pull_compose_file || exit 1

  run_compose
}

main "$@"
