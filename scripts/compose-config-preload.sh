#!/bin/bash

# compose-config-preload.sh
# 修改 docker compose 配置文件
# 部分参数需要动态从节点获取

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_ENV_FILE="${SCRIPT_DIR}/../config/.env"

source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/image-declare"

# check_and_pull_image 检查本地仓库是否存在镜像 如果不存在 拉取
check_and_pull_image() {
    local image_name=$1
    local image_version=$2
    local full_image_name="${image_name}:${image_version}"

    docker image inspect "${full_image_name}"
    check_res=$?

    if [[ ${check_res} -ne 0 ]]; then
        log "[INFO] do not exist, start pull: ${full_image_name}"
        docker pull "${full_image_name}"

        local pull_res=$?
        if [[ ${pull_res} -ne 0 ]]; then
            log "[INFO] pull failed: ${full_image_name}"
            return 1
        else
            log "[INFO] pull finish: ${full_image_name}"
            return 0
        fi

    else
        # 检查结果为 0，镜像存在
        log "[INFO] exist: ${full_image_name}"
        return 0
    fi
}

# config_depend_image_version 下载依赖镜像 修改 env 配置中镜像版本
config_depend_image_version() {
    local image_num=${#DEPEND_IMAGE_NAME_PARAM[@]}
    local normal_image_count=0
    local abnormal_image_count=0

    for (( i = 0; i < image_num; i++ )); do
        local image_param_name=${DEPEND_IMAGE_NAME_PARAM[$i]}
        local version_param_name=${DEPEND_IMAGE_VERSION_PARAM[$i]}
        local image_val=${DEPEND_IMAGE_NAME[$i]}
        local version_val=${DEPEND_IMAGE_VERSION[$i]}

        check_and_pull_image "${image_val}" "${version_val}"
        check_res=$?
        if [[ ${check_res} -ne 0 ]]; then
            log "[ERROR] image not found: ${image_val} ${version_val}"
            ((abnormal_image_count++))
        else
            ((normal_image_count++))
        fi

        sed -i "s|^${image_param_name}=.*|${image_param_name}=${image_val}|" "$DOCKER_COMPOSE_ENV_FILE"
        sed -i "s|^${version_param_name}=.*|${version_param_name}=${version_val}|" "$DOCKER_COMPOSE_ENV_FILE"

        log "[INFO] update: ${image_val} ${version_val}"

    done
    log "[INFO] [SUMMARY] update image success: ${normal_image_count}, failed: ${abnormal_image_count}"
}

# config_etcd_compose_env 修改 ETCD docker compose 配置
config_etcd_compose_env() {
    local using_eth_name=$(get_host_ip)
    local host_ip=$(ip addr show "${using_eth_name}" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
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

    # 拉取配置中的镜像版本 修改 env 使用的镜像
    config_depend_image_version

    # env etcd 配置单独修改
    config_etcd_compose_env
}

main "$@"
