#!/bin/bash

# Apache Backup Script for Sarah
# Backs up Apache configuration and document root
# Scheduled to run every Tuesday at 12:00 AM

# Set PATH for CentOS - ensures all commands are accessible when run via cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# Function to check if required commands exist
check_dependencies() {
    local deps=("tar" "date" "du" "wc" "ls" "head" "xargs")
    local missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "ERROR: Missing required commands: ${missing[*]}" >&2
        echo "Please install the missing commands and try again." >&2
        exit 1
    fi
}

# Check dependencies first
check_dependencies

# Variables
BACKUP_DIR="/backups/apache"
LOG_FILE="/var/log/backups/apache_backup.log"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="apache_backup_${DATE}.tar.gz"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Determine Apache directory based on distribution
if [ -d "/etc/apache2" ]; then
    APACHE_CONF="/etc/apache2"
elif [ -d "/etc/httpd" ]; then
    APACHE_CONF="/etc/httpd"
else
    echo "[$TIMESTAMP] ERROR: Apache configuration directory not found" >> "$LOG_FILE"
    exit 1
fi

APACHE_WWW="/var/www/html"

# Ensure required directories exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR" 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create backup directory: $BACKUP_DIR" >&2
        exit 1
    fi
fi

if [ ! -d "$(dirname "$LOG_FILE")" ]; then
    echo "Creating log directory: $(dirname "$LOG_FILE")"
    mkdir -p "$(dirname "$LOG_FILE")" 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create log directory: $(dirname "$LOG_FILE")" >&2
        exit 1
    fi
fi

# Start backup process
echo "==========================================" >> "$LOG_FILE"
echo "[$TIMESTAMP] Starting Apache backup" >> "$LOG_FILE"

# Check if source directories exist
if [ ! -d "$APACHE_CONF" ]; then
    echo "[$TIMESTAMP] ERROR: Apache config directory not found: $APACHE_CONF" >> "$LOG_FILE"
    exit 1
fi

if [ ! -d "$APACHE_WWW" ]; then
    echo "[$TIMESTAMP] ERROR: Apache document root not found: $APACHE_WWW" >> "$LOG_FILE"
    exit 1
fi

# Create backup
echo "[$TIMESTAMP] Creating compressed backup: $BACKUP_FILE" >> "$LOG_FILE"
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" "$APACHE_CONF" "$APACHE_WWW" 2>> "$LOG_FILE"

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "[$TIMESTAMP] Backup created successfully" >> "$LOG_FILE"
    
    # Get backup file size
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
    echo "[$TIMESTAMP] Backup size: $BACKUP_SIZE" >> "$LOG_FILE"
    
    # Verify backup integrity
    echo "[$TIMESTAMP] Verifying backup integrity..." >> "$LOG_FILE"
    tar -tzf "${BACKUP_DIR}/${BACKUP_FILE}" > /tmp/apache_backup_contents.txt 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        FILE_COUNT=$(wc -l < /tmp/apache_backup_contents.txt)
        echo "[$TIMESTAMP] Backup verification successful" >> "$LOG_FILE"
        echo "[$TIMESTAMP] Total files in backup: $FILE_COUNT" >> "$LOG_FILE"
        echo "[$TIMESTAMP] Contents list saved to: ${BACKUP_DIR}/apache_backup_${DATE}_contents.txt" >> "$LOG_FILE"
        
        # Save contents list
        mv /tmp/apache_backup_contents.txt "${BACKUP_DIR}/apache_backup_${DATE}_contents.txt"
        
        # Display first 20 files from backup
        echo "[$TIMESTAMP] Sample files from backup:" >> "$LOG_FILE"
        head -20 "${BACKUP_DIR}/apache_backup_${DATE}_contents.txt" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] ERROR: Backup verification failed" >> "$LOG_FILE"
        exit 1
    fi
    
    # Clean up old backups (keep last 10)
    echo "[$TIMESTAMP] Cleaning up old backups..." >> "$LOG_FILE"
    BACKUP_COUNT=$(ls -1 ${BACKUP_DIR}/apache_backup_*.tar.gz 2>/dev/null | wc -l)
    if [ $BACKUP_COUNT -gt 10 ]; then
        ls -1t ${BACKUP_DIR}/apache_backup_*.tar.gz | tail -n +11 | xargs rm -f
        echo "[$TIMESTAMP] Removed old backups, kept last 10" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] No cleanup needed, total backups: $BACKUP_COUNT" >> "$LOG_FILE"
    fi
    
    echo "[$TIMESTAMP] Apache backup completed successfully" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
else
    echo "[$TIMESTAMP] ERROR: Backup creation failed" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    exit 1
fi

# Send notification (optional - can be email or log entry)
echo "[$TIMESTAMP] Backup notification: Apache backup completed for $DATE" >> "$LOG_FILE"

exit 0