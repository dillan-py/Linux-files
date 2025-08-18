#!/bin/bash

# Script to check and patch Oracle Java SE vulnerabilities (July 2025 CPU)
# Vulnerabilities: CVE-2024-40896, CVE-2025-30749, CVE-2025-50059
# Affected versions: Oracle Java SE 8u451, 8u451-perf, 11.0.27, 17.0.15, 21.0.7, 24.0.1
# Fixed version: 24.0.2 or greater

# Exit on error
set -e

# Log file for output
LOG_FILE="/var/log/oracle_java_patch.log"
echo "Starting Oracle Java SE patch script - $(date)" | tee -a "$LOG_FILE"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Java is installed
if ! command_exists java; then
    echo "Java is not installed on this system. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

# Get installed Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
echo "Detected Java version: $JAVA_VERSION" | tee -a "$LOG_FILE"

# List of vulnerable versions
VULNERABLE_VERSIONS=("8u451" "8u451-perf" "11.0.27" "17.0.15" "21.0.7" "24.0.1")

# Check if the installed version is vulnerable
VULNERABLE=false
for VERSION in "${VULNERABLE_VERSIONS[@]}"; do
    if [[ "$JAVA_VERSION" == "$VERSION" ]]; then
        VULNERABLE=true
        break
    fi
done

if [ "$VULNERABLE" = true ]; then
    echo "Vulnerable Java version detected: $JAVA_VERSION" | tee -a "$LOG_FILE"
    echo "Applying patch by upgrading to Java SE 24.0.2 or greater..." | tee -a "$LOG_FILE"

    # Check if wget is installed
    if ! command_exists wget; then
        echo "Installing wget..." | tee -a "$LOG_FILE"
        sudo apt-get update
        sudo apt-get install -y wget
    fi

    # Download Oracle JDK 24.0.2 (adjust URL for your architecture)
    JDK_URL="https://download.oracle.com/java/24/archive/jdk-24.0.2_linux-x64_bin.tar.gz"
    JDK_FILE="jdk-24.0.2_linux-x64_bin.tar.gz"
    echo "Downloading Oracle JDK 24.0.2..." | tee -a "$LOG_FILE"
    wget -O "$JDK_FILE" "$JDK_URL" 2>&1 | tee -a "$LOG_FILE"

    # Verify download
    if [ ! -f "$JDK_FILE" ]; then
        echo "Failed to download JDK 24.0.2. Please check the URL or network connection." | tee -a "$LOG_FILE"
        exit 1
    fi

    # Install the new JDK
    echo "Installing Oracle JDK 24.0.2..." | tee -a "$LOG_FILE"
    sudo mkdir -p /opt/jdk
    sudo tar -xzf "$JDK_FILE" -C /opt/jdk
    JDK_DIR=$(tar -tzf "$JDK_FILE" | head -1 | cut -f1 -d"/")
    sudo mv "/opt/jdk/$JDK_DIR" /opt/jdk/jdk-24.0.2

    # Update alternatives to use the new Java version
    echo "Updating system alternatives to use JDK 24.0.2..." | tee -a "$LOG_FILE"
    sudo update-alternatives --install /usr/bin/java java /opt/jdk/jdk-24.0.2/bin/java 1
    sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/jdk-24.0.2/bin/javac 1
    sudo update-alternatives --set java /opt/jdk/jdk-24.0.2/bin/java
    sudo update-alternatives --set javac /opt/jdk/jdk-24.0.2/bin/javac

    # Verify new Java version
    NEW_JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
    echo "New Java version installed: $NEW_JAVA_VERSION" | tee -a "$LOG_FILE"

    # Clean up
    rm "$JDK_FILE"
    echo "Cleaned up downloaded tarball." | tee -a "$LOG_FILE"

    # Check if the new version is fixed
    if [[ "$NEW_JAVA_VERSION" == "24.0.2" ]]; then
        echo "Successfully upgraded to Java SE 24.0.2. System is no longer vulnerable." | tee -a "$LOG_FILE"
    else
        echo "Warning: Installed version ($NEW_JAVA_VERSION) may still be vulnerable. Please verify." | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "Installed Java version ($JAVA_VERSION) is not listed as vulnerable. No action required." | tee -a "$LOG_FILE"
fi

echo "Script completed successfully - $(date)" | tee -a "$LOG_FILE"
exit 0
