#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_UPDATE_SH="${SCRIPT_DIR}/service-config-update.sh"
COMPOSE_STARTER_SH="${SCRIPT_DIR}/compose-starter.sh"

source "${SCRIPT_DIR}/common.sh"

MODE_UPDATE_START="upstart"
MODE_DIRECT_START="distart"

# update_start 更新自动配置 然后启动
update_start() {
    log "[INFO] enter update_start"

    # 执行更新脚本
    ${CONFIG_UPDATE_SH} update
    local update_res=$?
    if [[ ${update_res} -ne 0 ]]; then
        echo "[ERROR] exec service-config-update.sh failed: ${update_res}"
        log "[ERROR] exec service-config-update.sh failed: ${update_res}"
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
