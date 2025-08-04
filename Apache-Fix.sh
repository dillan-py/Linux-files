#!/bin/bash

# Script to patch Apache Log4j 1.2.16 to Log4j 2.20.0
# Target path: /usr/share/javasnoop/lib/log4j-1.2.16.jar
# Run with sudo if required for file permissions

set -e

# Variables
LOG4J_OLD_JAR="/usr/share/javasnoop/lib/log4j-1.2.16.jar"
LIB_DIR="/usr/share/javasnoop/lib"
BACKUP_DIR="/usr/share/javasnoop/backup"
CONFIG_DIR="/usr/share/javasnoop/config"
LOG4J_VERSION="2.20.0"
DOWNLOAD_URL="https://archive.apache.org/dist/logging/log4j/${LOG4J_VERSION}/apache-log4j-${LOG4J_VERSION}-bin.tar.gz"
TEMP_DIR="/tmp/log4j_upgrade"
SERVICE_NAME="javasnoop" # Adjust if the service name differs

# Function to check if a directory exists
check_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Warning: Directory $dir does not exist"
        return 1
    fi
    return 0
}

# Step 1: Verify the current Log4j version
echo "Verifying current Log4j version..."
if [ ! -f "$LOG4J_OLD_JAR" ]; then
    echo "Error: Log4j 1.2.16 JAR not found at $LOG4J_OLD_JAR"
    exit 1
fi
unzip -p "$LOG4J_OLD_JAR" META-INF/MANIFEST.MF | grep "Implementation-Version" || echo "Version check failed"

# Step 2: Create backup
echo "Creating backup..."
if ! check_dir "$LIB_DIR"; then
    echo "Error: Library directory $LIB_DIR missing"
    exit 1
fi
