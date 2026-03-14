#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/file-path-declare"

FUNC_SUCCESS=0

COPY_STATUS_SUCCESS=0
COPY_STATUS_ERR=1
COPY_STATUS_SKIP=2

ACTION=""
ACTION_UPDATE="update"
ACTION_ROLLBACK="rollback"

# parse_args 参数检查
parse_args() {
    ACTION="${1:-}"

    # 检查是否为空
    if [[ -z "${ACTION}" ]]; then
        log "[ERROR] action arg is empty"
        return 1
    fi

    return ${FUNC_SUCCESS}
}

# check_arrays_length 文件数组长度校验
check_arrays_length() {
    local src_len=${#SRC_PATHS[@]}
    local dst_len=${#DST_PATHS[@]}
    local bak_len=${#BAK_PATHS[@]}

    if [[ "${src_len}" -ne "${dst_len}" ]] || [[ "${src_len}" -ne "${bak_len}" ]]; then
        log "[ERROR] array len is not same, exit. SRC:${src_len}, DST:${dst_len}, BAK:${bak_len}"
        return 1
    fi

    log "[INFO] ${src_len} files need to update"
    return ${FUNC_SUCCESS}
}

# create_service_dirs 创建需要的数据路径、日志路径、配置路径
create_service_dirs() {
    local dir_count=${#LOCAL_SERVICE_BASE_PATHS[@]}

    log "[INFO] start create_service_dirs"
    for (( i = 0; i < dir_count; i++ )); do
        local dir_need_create="${LOCAL_SERVICE_BASE_PATHS[$i]}"
        if [[ ! -d "${dir_need_create}" ]]; then
            log "[INFO] need create: ${dir_need_create}"
            mkdir -p "${dir_need_create}"
        fi

        # TODO 服务 用户 权限定义
        chmod 777 "${dir_need_create}"
    done
    log "[INFO] ended create_service_dirs"
    return 0
}

# copy_file 拷贝替换文件
copy_file() {
    local src="$1"
    local dst="$2"

    if [[ ! -f "${src}" ]]; then
        log "[WARN] do not exist file: ${src}"
        return ${COPY_STATUS_SKIP}
    fi

    local dst_dir
    dst_dir="$(dirname "${dst}")"
    if [[ ! -d "${dst_dir}" ]]; then
        log "[WARN] dst_dir is not exist, create bak dir: ${dst_dir}"
        mkdir -p "${dst_dir}"
    fi

    cp -f "${src}" "${dst}"
    local cp_status=$?
    if [[ ${cp_status} -eq 0 ]]; then
        log "[INFO] replace success: ${src} -> ${dst}"
        return ${COPY_STATUS_SUCCESS}
    else
        log "[ERROR] replace failed: ${src} -> ${dst}"
        return ${COPY_STATUS_ERR}
    fi
}

# update_all_files 更新所有文件
update_all_files() {
    local count=${#SRC_PATHS[@]}
    local failed=0
    local success=0
    local skipped=0

    log "[INFO] start update_all_files"

    create_service_dirs

    for (( i = 0; i < count; i++ )); do
        local src="${SRC_PATHS[$i]}"
        local dst="${DST_PATHS[$i]}"
        local bak="${BAK_PATHS[$i]}"

        # 备份文件 拷贝源文件 -> 备份路径
        copy_file "${dst}" "${bak}"
        local backup_status=$?

        if [[ ${backup_status} -ne 0 ]]; then
            # 备份失败：源文件为空 或 备份拷贝失败 执行后续逻辑
            log "[WARN] bak skipped: ${backup_status} when backup: ${dst} -> ${bak}"
            ((skipped++))
        fi

        # 更新文件 拷贝项目文件 -> 源文件路径
        copy_file "${src}" "${dst}"
        local update_status=$?
        if [[ ${update_status} -ne 0 ]]; then
            # 更新失败：项目源文件为空 或 备份拷贝失败 执行后续逻辑
            log "[ERROR] update failed: ${update_status} when update: ${src} -> ${dst}"
            ((failed++))
            continue
        fi

        # 备份、拷贝均成功
        ((success++))
    done

    log "[INFO] end update, success: ${success}, failed: ${failed}, skipped: ${skipped}"
    return ${FUNC_SUCCESS}
}

# main 主流程
main() {
    log "[INFO] enter config update"

    parse_args "$1"
    local parse_check_res=$?
    if [[ ${parse_check_res} -ne 0 ]]; then
        log "[ERROR] check arg failed: $1"
        exit 1
    fi

    check_arrays_length
    local len_check_res=$?
    if [[ ${len_check_res} -ne 0 ]]; then
        log "[ERROR] check array len failed"
        exit 1
    fi

    case "${ACTION}" in
        "${ACTION_UPDATE}")
            update_all_files
            ;;
        *)
            log "[ERROR] unknown action: ${ACTION}"
            exit 1
            ;;
    esac
    log "[INFO] ended config update"

}

main "$1"