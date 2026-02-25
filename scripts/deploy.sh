#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PRELOAD_SH="${SCRIPT_DIR}/service-config-preload.sh"
CONFIG_UPDATE_SH="${SCRIPT_DIR}/service-config-update.sh"
COMPOSE_STARTER_SH="${SCRIPT_DIR}/compose-starter.sh"

source "${SCRIPT_DIR}/common.sh"

MODE_UPDATE_START="upstart"
MODE_DIRECT_START="distart"
MODE_UPDATE_CONFIG="upconfig"

update_config() {
    log "[INFO] enter update_config"

    # 执行配置文件准备脚本
    ${CONFIG_PRELOAD_SH}
    local preload_res=$?
    if [[ ${preload_res} -ne 0 ]]; then
        echo "[ERROR] exec service-config-preload.sh failed: ${update_res}"
        log "[ERROR] exec service-config-preload.sh failed: ${update_res}"
        return 1
    fi

    # 执行配置文件更新脚本
    ${CONFIG_UPDATE_SH} update
    local update_res=$?
    if [[ ${update_res} -ne 0 ]]; then
        echo "[ERROR] exec service-config-update.sh failed: ${update_res}"
        log "[ERROR] exec service-config-update.sh failed: ${update_res}"
        return 1
    fi
    return 0
}

# update_start 更新自动配置 然后启动
update_start() {
    log "[INFO] enter update_start"

    update_config
    local update_config_res=$?
    if [[ ${update_config_res} -ne 0 ]]; then
        echo "[ERROR] exec update_config failed: ${update_config_res}"
        log "[ERROR] exec update_config failed: ${update_config_res}"
        return 1
    fi

    # 执行启动脚本
    ${COMPOSE_STARTER_SH}
    local start_res=$?
    if [[ ${start_res} -ne 0 ]]; then
        echo "[ERROR] exec service-config-update.sh failed: ${start_res}"
        log "[ERROR] exec service-config-update.sh failed: ${start_res}"
    fi

    return 0
}

# raw_start
direct_start() {
    log "[INFO] enter direct_start"

    # 执行启动脚本
    ${COMPOSE_STARTER_SH}
    local start_res=$?
    if [[ ${start_res} -ne 0 ]]; then
        echo "[ERROR] exec service-config-update.sh failed: ${start_res}"
        log "[ERROR] exec service-config-update.sh failed: ${start_res}"
        return 1
    fi

    return 0
}

# main 总入口脚本
main() {
    echo "[INFO] enter deploy.sh"
    log "[INFO] enter deploy.sh"

    local deploy_arg="$1"

    case "${deploy_arg}" in
        "${MODE_UPDATE_CONFIG}")
            update_config
            ;;
        "${MODE_UPDATE_START}")
            update_start
            ;;
        "${MODE_DIRECT_START}")
            direct_start
            ;;
        *)
            echo "[ERROR] unknown action: ${deploy_arg}"
            log "[ERROR] unknown action: ${deploy_arg}"
            ;;
    esac

    echo "[INFO] ended deploy.sh"
    log "[INFO] ended deploy.sh"
}

main "$@"
