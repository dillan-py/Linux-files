#!/bin/bash

# Script to patch Apache Log4j 1.2.16 to Log4j 2.20.0
# Target path: /usr/share/javasnoop/lib/log4j-1.2.16.jar
# Run with sudo if required for file permissions
# Patches:
# IAVA:  2021-A-0573
# CEA-ID:  CEA-2021-0004, CEA-2021-0025
# CVE:  CVE-2019-17571, CVE-2020-9488, CVE-2022-23302, CVE-2022-23305, CVE-2022-23307, CVE-2023-26464
# IAVA:  2021-A-0573, 0001-A-0650
# CVE:  CVE-2021-4104

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
mkdir -p "$BACKUP_DIR" || {
    echo "Error: Failed to create backup directory $BACKUP_DIR"
    exit 1
}
BACKUP_DIRS="$LIB_DIR"
if check_dir "$CONFIG_DIR"; then
    BACKUP_DIRS="$BACKUP_DIRS $CONFIG_DIR"
else
    echo "Note: Config directory $CONFIG_DIR not found, skipping its backup"
fi
tar -czvf "$BACKUP_DIR/javasnoop_backup_$(date +%F).tar.gz" $BACKUP_DIRS || {
    echo "Error: Backup failed. Check permissions, disk space, or directory existence."
    echo "Run 'df -h /usr/share/javasnoop' to check disk space."
    echo "Run 'ls -ld /usr/share/javasnoop /usr/share/javasnoop/lib /usr/share/javasnoop/config' to check permissions."
    exit 1
}
echo "Backup created at $BACKUP_DIR/javasnoop_backup_$(date +%F).tar.gz"

# Step 3: Download Log4j 2.x
echo "Downloading Log4j $LOG4J_VERSION..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
wget -q "$DOWNLOAD_URL" || {
    echo "Error: Failed to download Log4j $LOG4J_VERSION"
    exit 1
}
tar -xzf "apache-log4j-${LOG4J_VERSION}-bin.tar.gz" || {
    echo "Error: Failed to extract Log4j archive"
    exit 1
}

# Step 4: Replace Log4j JARs
echo "Replacing Log4j 1.2.16 with Log4j $LOG4J_VERSION..."
mv "$LOG4J_OLD_JAR" "${LOG4J_OLD_JAR}.bak" || {
    echo "Error: Failed to back up old Log4j JAR"
    exit 1
}
cp "apache-log4j-${LOG4J_VERSION}-bin/log4j-core-${LOG4J_VERSION}.jar" "$LIB_DIR/" || {
    echo "Error: Failed to copy log4j-core"
    exit 1
}
cp "apache-log4j-${LOG4J_VERSION}-bin/log4j-api-${LOG4J_VERSION}.jar" "$LIB_DIR/" || {
    echo "Error: Failed to copy log4j-api"
    exit 1
}
cp "apache-log4j-${LOG4J_VERSION}-bin/log4j-1.2-api-${LOG4J_VERSION}.jar" "$LIB_DIR/" || {
    echo "Error: Failed to copy log4j-1.2-api"
    exit 1
}

# Step 5: Update configuration
echo "Updating Log4j configuration..."
mkdir -p "$CONFIG_DIR" || {
    echo "Error: Failed to create config directory $CONFIG_DIR"
    exit 1
}
cat << EOF > "$CONFIG_DIR/log4j2.xml"
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="WARN">
    <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n"/>
        </Console>
        <File name="File" fileName="logs/app.log">
            <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n"/>
        </File>
    </Appenders>
    <Loggers>
        <Root level="info">
            <AppenderRef ref="Console"/>
            <AppenderRef ref="File"/>
        </Root>
    </Loggers>
</Configuration>
EOF

# Step 6: Restart the application
echo "Restarting $SERVICE_NAME service..."
if systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl restart "$SERVICE_NAME" || {
        echo "Error: Failed to restart $SERVICE_NAME"
        exit 1
    }
else
    echo "Warning: $SERVICE_NAME service not found or not running. Please restart the application manually."
fi

# Step 7: Verify the upgrade
echo "Verifying Log4j upgrade..."
ls "$LIB_DIR/log4j-core-${LOG4J_VERSION}.jar" "$LIB_DIR/log4j-api-${LOG4J_VERSION}.jar" >/dev/null 2>&1 || {
    echo "Error: Log4j $LOG4J_VERSION JARs not found in $LIB_DIR"
    exit 1
}
echo "Log4j $LOG4J_VERSION JARs successfully installed"

# Step 8: Clean up
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Step 9: Final instructions
echo "Upgrade complete! Please:"
echo "1. Verify application functionality."
echo "2. Check logs in $CONFIG_DIR/logs/app.log for errors."
echo "3. Run a vulnerability scan to confirm the fix."
echo "4. Monitor https://logging.apache.org/ for future Log4j updates."

exit 0
         
