#!/bin/bash

# compose-config-preload.sh
# 修改 docker compose 配置文件
# 部分参数需要动态从节点获取

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_ENV_FILE="${SCRIPT_DIR}/../config/.env"

source "${SCRIPT_DIR}/common.sh"

# config_etcd_compose_env 修改 ETCD docker compose 配置
config_etcd_compose_env() {
    local host_ip=$(ip addr show ens33 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    local new_line_ETCD1="ETCD0_ENV_ETCD_HOST_IP=${host_ip}"
    local new_line_ETCD2="ETCD1_ENV_ETCD_HOST_IP=${host_ip}"
    local new_line_ETCD3="ETCD2_ENV_ETCD_HOST_IP=${host_ip}"

    sed -i "s|^ETCD0_ENV_ETCD_HOST_IP=.*|${new_line_ETCD1}|" "$DOCKER_COMPOSE_ENV_FILE"
    sed -i "s|^ETCD1_ENV_ETCD_HOST_IP=.*|${new_line_ETCD2}|" "$DOCKER_COMPOSE_ENV_FILE"
    sed -i "s|^ETCD2_ENV_ETCD_HOST_IP=.*|${new_line_ETCD3}|" "$DOCKER_COMPOSE_ENV_FILE"
    return 0
}

main() {
    if [[ ! -f ${DOCKER_COMPOSE_ENV_FILE} ]]; then
        log "[ERROR] file not exist: ${DOCKER_COMPOSE_ENV_FILE}"
        exit 1
    fi

    config_etcd_compose_env
}

main "$@"
