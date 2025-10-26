#!/bin/bash

# System Monitoring Script
# This script captures system metrics and saves them to a log file

LOGDIR="/var/log/system-monitoring"
LOGFILE="$LOGDIR/system_metrics_$(date +%Y-%m-%d).log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "=======================================" >> "$LOGFILE"
echo "System Monitoring Report - $TIMESTAMP" >> "$LOGFILE"
echo "=======================================" >> "$LOGFILE"

# CPU Usage
echo -e "\n--- CPU Usage ---" >> "$LOGFILE"
top -bn1 | grep "Cpu(s)" >> "$LOGFILE"
mpstat 2>&1 >> "$LOGFILE" || echo "mpstat not available" >> "$LOGFILE"

# Memory Usage
echo -e "\n--- Memory Usage ---" >> "$LOGFILE"
free -h >> "$LOGFILE"

# Top 10 Processes by CPU
echo -e "\n--- Top 10 Processes by CPU ---" >> "$LOGFILE"
ps aux --sort=-%cpu | head -11 >> "$LOGFILE"

# Top 10 Processes by Memory
echo -e "\n--- Top 10 Processes by Memory ---" >> "$LOGFILE"
ps aux --sort=-%mem | head -11 >> "$LOGFILE"

# Disk Usage Summary
echo -e "\n--- Disk Usage Summary ---" >> "$LOGFILE"
df -h >> "$LOGFILE"

# Directory Size Analysis
echo -e "\n--- Directory Size Analysis (Top 10) ---" >> "$LOGFILE"
du -sh /home/* /var/* /opt/* 2>/dev/null | sort -hr | head -10 >> "$LOGFILE"

echo -e "\n=======================================" >> "$LOGFILE"
echo "Monitoring completed at $(date +"%Y-%m-%d %H:%M:%S")" >> "$LOGFILE"
echo -e "=======================================\n" >> "$LOGFILE"