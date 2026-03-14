#!/bin/bash

LOG_FILE="/var/log/apps/docker_starter/starter.log"

ETH_ENS33_NAME="ens33"
ETH_WLP2S0_NAME="wlp2s0"

# 打印日志
log() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" >> "$LOG_FILE"
}

# get_host_ip 获取 ip 字符串
get_host_ip() {
    ip link show "${ETH_ENS33_NAME}"
    local check_status=$?
    if [[ ${check_status} -ne 0 ]]; then
        log "[INFO] use ${ETH_WLP2S0_NAME}"
        echo "${ETH_WLP2S0_NAME}"
    else
        log "[INFO] use ${ETH_ENS33_NAME}"
        echo "${ETH_ENS33_NAME}"
    fi
}

# get_compose_command 获取 docker compose 命令
# 旧版本 docker-compose
# 高版本 docker compose
get_compose_command() {
    which docker-compose
    local cmd_status=$?

    if [[ ${cmd_status} -ne 0 ]]; then
        log "[INFO] do not have docker-compose, use docker compose instead"
        echo "docker compose"
    else
        log "[INFO] find docker-compose, use docker-compose"
        echo "docker-compose"
    fi
}