#!/bin/bash

# service-config-preload.sh
# 对服务配置 config 文件做预处理 调用各服务自身脚本 生成 config 文件中配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_CONFIG_SCRIPTS_DIR="${SCRIPT_DIR}/service-config-scripts"

source "${SCRIPT_DIR}/common.sh"

# pre_exec 脚本预处理
pre_exec() {
    log "[INFO] enter pre_exec"

    if [[ ! -d "${SERVICE_CONFIG_SCRIPTS_DIR}" ]]; then
        log "[ERROR] do not exist: ${SERVICE_CONFIG_SCRIPTS_DIR}"
        return 1
    fi

    chmod +x "${SERVICE_CONFIG_SCRIPTS_DIR}"/*.sh
    return 0
}

exec_single_script() {
    local script_full_path="$1"

    if [[ ! -f "${script_full_path}" ]]; then
        log "[ERROR] do not exist: ${script_full_path}"
        return 1
    fi

    # exec script
    "${script_full_path}"
    local exec_status=$?
    if [[ ${exec_status} -ne 0 ]]; then
        log "[ERROR] exec failed: ${script_full_path}"
        return 1
    fi
    return 0
}

# exec_scripts 脚本执行
exec_scripts() {
    log "[INFO] enter exec_scripts"

    local success_count=0
    local fail_count=0
    local total_count=0

    while IFS= read -r -d '' script_path; do
        ((total_count++))

        log "[INFO] executing ${script_path}"

        # 执行脚本
        exec_single_script "${script_path}"
        local status=$?
        if [[ ${status} -ne 0 ]]; then
            log "[ERROR] exec failed, script: ${script_path}, error code: ${status}"
            ((fail_count++))
        else
            log "[INFO] exec success, script: ${script_path}"
            ((success_count++))
        fi

    done < <(find "${SERVICE_CONFIG_SCRIPTS_DIR}" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)

    log "[INFO] exec summary: success: ${success_count}, fail: ${fail_count}, total: ${total_count}"
}

main() {
    log "[INFO] enter service-config-preload.sh"

    pre_exec
    local pre_exec_status=$?
    if [[ ${pre_exec_status} -ne 0 ]]; then
        log "[ERROR] pre_exec failed, error code: ${pre_exec_status}"
        exit 1
    fi

    exec_scripts
    return 0
}

main "$@"
