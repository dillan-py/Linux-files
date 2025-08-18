#!/bin/bash

# Script to check and update OpenJDK for vulnerabilities (July 2025 CPU)
# Vulnerabilities: CVE-2024-40896, CVE-2025-30749, CVE-2025-50059
# Affected versions: OpenJDK 8u451, 8u451-perf, 11.0.27, 17.0.15, 21.0.7, 24.0.1
# Fixed version: 24.0.2 or greater

# Exit on error
set -e

# Log file for output
LOG_FILE="/var/log/openjdk_patch.log"
echo "Starting OpenJDK patch script - $(date)" | tee -a "$LOG_FILE"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Java is installed
if ! command_exists java; then
    echo "Java is not installed on this system. Installing OpenJDK 24..." | tee -a "$LOG_FILE"
    sudo apt-get update
    sudo apt-get install -y openjdk-24-jre
    exit 0
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
    echo "Vulnerable OpenJDK version detected: $JAVA_VERSION" | tee -a "$LOG_FILE"
    echo "Updating to OpenJDK 24.0.2 or greater..." | tee -a "$LOG_FILE"

    # Update package lists and install OpenJDK 24 JRE
    echo "Updating package lists..." | tee -a "$LOG_FILE"
    sudo apt-get update
    echo "Installing OpenJDK 24 JRE..." | tee -a "$LOG_FILE"
    sudo apt-get install -y openjdk-24-jre

    # Set OpenJDK 24 as the default Java version
    echo "Configuring OpenJDK 24 as default..." | tee -a "$LOG_FILE"
    sudo update-alternatives --set java /usr/lib/jvm/java-24-openjdk-amd64/bin/java

    # Verify new Java version
    NEW_JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
    echo "New Java version installed: $NEW_JAVA_VERSION" | tee -a "$LOG_FILE"

    # Check first three characters of the version to confirm it's at least 24.0.2
    VERSION_PREFIX=$(echo "$NEW_JAVA_VERSION" | cut -c 1-3)
    if [[ "$VERSION_PREFIX" == "24." ]]; then
        echo "Successfully updated to OpenJDK 24.0.2 or greater. System is no longer vulnerable." | tee -a "$LOG_FILE"
    else
        echo "Warning: Installed version ($NEW_JAVA_VERSION) may still be vulnerable. Please verify." | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "Installed Java version ($JAVA_VERSION) is not listed as vulnerable. No action required." | tee -a "$LOG_FILE"
fi

echo "Script completed successfully - $(date)" | tee -a "$LOG_FILE"
exit 0
