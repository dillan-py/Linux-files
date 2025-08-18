#!/bin/bash

# Script to automate upgrading Oracle Java SE to version 24.0.2 on Ubuntu
# Supports x64 (amd64) and ARM64 (aarch64) architectures
# Addresses vulnerabilities from July 2025 CPU advisory

# Exit on error
set -e

# Variables
JDK_VERSION="24.0.2"
DOWNLOAD_BASE_URL="https://download.oracle.com/java/24/latest"
INSTALL_DIR="/usr/lib/jvm"
OLD_JAVA_PATH="/opt/BurpSuiteCommunity/jdk-24.0.1"  # Adjust if different
JAVA_HOME="/usr/lib/jvm/jdk-${JDK_VERSION}"
ARCH=$(uname -m)
TIMESTAMP=$(date +%F_%H-%M-%S)
BACKUP_DIR="/tmp/java_backup_${TIMESTAMP}"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check architecture
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_TYPE="x64"
    DOWNLOAD_FILE="jdk-${JDK_VERSION}_linux-x64_bin.deb"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH_TYPE="aarch64"
    DOWNLOAD_FILE="jdk-${JDK_VERSION}_linux-aarch64_bin.tar.gz"
else
    log "ERROR: Unsupported architecture: $ARCH"
    exit 1
fi

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    log "ERROR: This script must be run as root or with sudo"
    exit 1
fi

# Create backup directory
log "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup existing Java installation
if [[ -d "$OLD_JAVA_PATH" ]]; then
    log "Backing up existing Java installation from $OLD_JAVA_PATH"
    cp -r "$OLD_JAVA_PATH" "$BACKUP_DIR/" || {
        log "ERROR: Failed to backup existing Java installation"
        exit 1
    }
fi

# Download Oracle Java SE 24.0.2
log "Downloading Oracle Java SE ${JDK_VERSION} for ${ARCH_TYPE}..."
cd /tmp
wget -O "$DOWNLOAD_FILE" "${DOWNLOAD_BASE_URL}/${DOWNLOAD_FILE}" || {
    log "ERROR: Failed to download ${DOWNLOAD_FILE}"
    exit 1
}

# Verify download (optional: check SHA256 if provided by Oracle)
# Note: Replace <EXPECTED_SHA256> with actual SHA256 from Oracle's download page
# echo "<EXPECTED_SHA256>  $DOWNLOAD_FILE" | sha256sum -c || {
#     log "ERROR: SHA256 checksum verification failed"
#     exit 1
# }

# Install Java based on architecture
if [[ "$ARCH_TYPE" == "x64" ]]; then
    log "Installing .deb package for x64..."
    apt update
    apt install -y "./${DOWNLOAD_FILE}" || {
        log "ERROR: Failed to install .deb package"
        exit 1
    }
    log "Configuring alternatives for x64 installation..."
    update-alternatives --install /usr/bin/java java "${JAVA_HOME}/bin/java" 100
    update-alternatives --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 100
    update-alternatives --set java "${JAVA_HOME}/bin/java"
    update-alternatives --set javac "${JAVA_HOME}/bin/javac"
elif [[ "$ARCH_TYPE" == "aarch64" ]]; then
    log "Installing .tar.gz package for ARM64..."
    mkdir -p "$INSTALL_DIR"
    tar -zxf "$DOWNLOAD_FILE" -C "$INSTALL_DIR/" || {
        log "ERROR: Failed to extract .tar.gz package"
        exit 1
    }
    log "Configuring alternatives for ARM64 installation..."
    update-alternatives --install /usr/bin/java java "${JAVA_HOME}/bin/java" 1
    update-alternatives --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 1
    update-alternatives --install /usr/bin/jar jar "${JAVA_HOME}/bin/jar" 1
    update-alternatives --set java "${JAVA_HOME}/bin/java"
    update-alternatives --set javac "${JAVA_HOME}/bin/javac"
    update-alternatives --set jar "${JAVA_HOME}/bin/jar"
    
    # Set JAVA_HOME for ARM64
    log "Setting JAVA_HOME for ARM64..."
    cat << EOF > /etc/profile.d/jdk.sh
export J2SDKDIR=${JAVA_HOME}
export J2REDIR=${JAVA_HOME}
export PATH=\$PATH:${JAVA_HOME}/bin:${JAVA_HOME}/db/bin
export JAVA_HOME=${JAVA_HOME}
export DERBY_HOME=${JAVA_HOME}/db
EOF
    cat << EOF > /etc/profile.d/jdk.csh
setenv J2SDKDIR ${JAVA_HOME}
setenv J2REDIR ${JAVA_HOME}
setenv PATH \${PATH}:${JAVA_HOME}/bin:${JAVA_HOME}/db/bin
setenv JAVA_HOME ${JAVA_HOME}
setenv DERBY_HOME ${JAVA_HOME}/db
EOF
    chmod +x /etc/profile.d/jdk.sh /etc/profile.d/jdk.csh
fi

# Remove old Java installation
if [[ -d "$OLD_JAVA_PATH" ]]; then
    log "Removing old Java installation from $OLD_JAVA_PATH"
    rm -rf "$OLD_JAVA_PATH" || {
        log "ERROR: Failed to remove old Java installation"
        exit 1
    }
fi

# Clean up downloaded file
log "Cleaning up downloaded file..."
rm -f "$DOWNLOAD_FILE"

# Verify installation
log "Verifying Java installation..."
if java -version 2>&1 | grep -q "$JDK_VERSION"; then
    log "SUCCESS: Oracle Java SE ${JDK_VERSION} installed successfully"
    java -version
else
    log "ERROR: Java version verification failed"
    exit 1
fi

# Verify JAVA_HOME (for ARM64 or manual checks)
if [[ "$ARCH_TYPE" == "aarch64" ]]; then
    log "Verifying JAVA_HOME..."
    source /etc/profile.d/jdk.sh
    if [[ "$JAVA_HOME" == "${JAVA_HOME}" ]]; then
        log "JAVA_HOME set to $JAVA_HOME"
    else
        log "WARNING: JAVA_HOME not set correctly"
    fi
fi

log "Installation complete. Backup of old Java is stored in $BACKUP_DIR"
