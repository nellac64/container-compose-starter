#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
COMPOSE_CONFIG_DIR="/app/compose/config"
COMPOSE_CONFIG_MAIN_FILE="/app/compose/config/docker-compose.yml"
COMPOSE_CONFIG_PRELOAD_SCRIPT="${SCRIPT_DIR}/compose-config-preload.sh"

source "${SCRIPT_DIR}/common.sh"

# preload_compose_config 预修改 compose 配置文件
preload_compose_config() {
    ${COMPOSE_CONFIG_PRELOAD_SCRIPT}
}

# copy_compose_config 拷贝 compose 配置文件
copy_compose_config() {
    log "enter copy_compose_config"

    if [[ ! -d "${COMPOSE_CONFIG_DIR}" ]]; then
        log "create compose dir"
        mkdir -p "${COMPOSE_CONFIG_DIR}"
    else
        log "recreate compose dir"
        rm -rf "${COMPOSE_CONFIG_DIR}"
        mkdir -p "${COMPOSE_CONFIG_DIR}"
    fi
    cp "${CONFIG_DIR}"/* "${COMPOSE_CONFIG_DIR}"
    cp "${CONFIG_DIR}"/.env "${COMPOSE_CONFIG_DIR}"

}

# start_docker_service 启动 docker 服务 删除旧的 stop 状态容器
start_docker_service() {
    log "enter start_docker_service"

    systemctl is-active --quiet docker
    if [[ "$?" -eq 0 ]]; then
        log "exit  do not need to restart docker service"
    else
        log "restart docker service"
        systemctl start docker
        sleep 1
    fi

    stopped_containers=$(docker ps -aq -f status=exited 2>/dev/null)
    if [ -n "${stopped_containers}" ]; then
        deleted_ids=$(docker rm -v $(docker ps -aq -f status=exited) 2>/dev/null)
        if [ -n "$deleted_ids" ]; then
            log "delete: $deleted_ids"
        fi
    else
        log "no stopped containers to clean"
    fi

}

# 启动 docker compose 服务
start_docker_compose() {
    log "enter start_docker_compose"
    if [ ! -f "${COMPOSE_CONFIG_MAIN_FILE}" ]; then
        log "ERROR: Compose file not found"
        exit 1
    fi
    docker-compose -f "${COMPOSE_CONFIG_MAIN_FILE}" up -d
}

main() {
    # 预修改 docker compose 配置文件
    preload_compose_config

    # 拷贝 docker compose 配置文件
    copy_compose_config

    # 启动 docker 服务
    # 删除已停止的容器
    start_docker_service

    # 启动 docker compose
    start_docker_compose
}

main "$@"