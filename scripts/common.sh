#!/bin/bash

LOG_FILE="/var/log/apps/docker_starter/starter.log"

# 打印日志
log() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" >> "$LOG_FILE"
}
