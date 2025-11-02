#!/bin/bash

# Nginx Backup Script for Mike
# Backs up Nginx configuration and document root
# Scheduled to run every Tuesday at 12:00 AM

# Variables
BACKUP_DIR="/backups/nginx"
LOG_FILE="/var/log/backups/nginx_backup.log"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="nginx_backup_${DATE}.tar.gz"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

NGINX_CONF="/etc/nginx"
NGINX_WWW="/usr/share/nginx/html"

# Start backup process
echo "==========================================" >> "$LOG_FILE"
echo "[$TIMESTAMP] Starting Nginx backup" >> "$LOG_FILE"

# Check if source directories exist
if [ ! -d "$NGINX_CONF" ]; then
    echo "[$TIMESTAMP] ERROR: Nginx config directory not found: $NGINX_CONF" >> "$LOG_FILE"
    exit 1
fi

if [ ! -d "$NGINX_WWW" ]; then
    echo "[$TIMESTAMP] ERROR: Nginx document root not found: $NGINX_WWW" >> "$LOG_FILE"
    exit 1
fi

# Create backup
echo "[$TIMESTAMP] Creating compressed backup: $BACKUP_FILE" >> "$LOG_FILE"
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" "$NGINX_CONF" "$NGINX_WWW" 2>> "$LOG_FILE"

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "[$TIMESTAMP] Backup created successfully" >> "$LOG_FILE"
    
    # Get backup file size
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
    echo "[$TIMESTAMP] Backup size: $BACKUP_SIZE" >> "$LOG_FILE"
    
    # Verify backup integrity
    echo "[$TIMESTAMP] Verifying backup integrity..." >> "$LOG_FILE"
    tar -tzf "${BACKUP_DIR}/${BACKUP_FILE}" > /tmp/nginx_backup_contents.txt 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        FILE_COUNT=$(wc -l < /tmp/nginx_backup_contents.txt)
        echo "[$TIMESTAMP] Backup verification successful" >> "$LOG_FILE"
        echo "[$TIMESTAMP] Total files in backup: $FILE_COUNT" >> "$LOG_FILE"
        echo "[$TIMESTAMP] Contents list saved to: ${BACKUP_DIR}/nginx_backup_${DATE}_contents.txt" >> "$LOG_FILE"
        
        # Save contents list
        mv /tmp/nginx_backup_contents.txt "${BACKUP_DIR}/nginx_backup_${DATE}_contents.txt"
        
        # Display first 20 files from backup
        echo "[$TIMESTAMP] Sample files from backup:" >> "$LOG_FILE"
        head -20 "${BACKUP_DIR}/nginx_backup_${DATE}_contents.txt" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] ERROR: Backup verification failed" >> "$LOG_FILE"
        exit 1
    fi
    
    # Clean up old backups (keep last 10)
    echo "[$TIMESTAMP] Cleaning up old backups..." >> "$LOG_FILE"
    BACKUP_COUNT=$(ls -1 ${BACKUP_DIR}/nginx_backup_*.tar.gz 2>/dev/null | wc -l)
    if [ $BACKUP_COUNT -gt 10 ]; then
        ls -1t ${BACKUP_DIR}/nginx_backup_*.tar.gz | tail -n +11 | xargs rm -f
        echo "[$TIMESTAMP] Removed old backups, kept last 10" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] No cleanup needed, total backups: $BACKUP_COUNT" >> "$LOG_FILE"
    fi
    
    echo "[$TIMESTAMP] Nginx backup completed successfully" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
else
    echo "[$TIMESTAMP] ERROR: Backup creation failed" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    exit 1
fi

# Send notification (optional - can be email or log entry)
echo "[$TIMESTAMP] Backup notification: Nginx backup completed for $DATE" >> "$LOG_FILE"

exit 0