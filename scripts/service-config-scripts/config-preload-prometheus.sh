#!/bin/bash

# config-preload-etcd.sh
# 修改环境上 prometheus 文件配置信息

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR_PROME="${SCRIPT_DIR}/../../service-config/prometheus"
TEMPLATE_FILE_PROME="${TEMPLATE_DIR_PROME}/prometheus.template.yml"
RES_FILE_PROME="${TEMPLATE_DIR_PROME}/prometheus.yml"

source "${SCRIPT_DIR}/../common.sh"
source "${SCRIPT_DIR}/common-declare"

create_single_prometheus_config() {
    local node_ip=$1

    # 之前存在 删掉后创建新的
    if [[ -f "${RES_FILE_PROME}" ]]; then
        log "[INFO] ${RES_FILE_PROME} template middle file exist, delete."
        rm -rf "${RES_FILE_PROME}"
    fi
    cp "${TEMPLATE_FILE_PROME}" "${RES_FILE_PROME}"

    # 替换 IP
    sed -i "s|\${NODE_IP}|${node_ip}|g" "${RES_FILE_PROME}"
    return 0
}

# change_chmod_prometheus_data_dir 修改数据路径权限
change_chmod_prometheus_data_dir() {
    # TODO 后续确认属主属组权限
    chmod 777 /app/prometheus/data/prometheus
}

main() {
    log "[INFO] enter preload config prometheus"

    local using_eth_name=$(get_host_ip)
    local host_ip=$(ip addr show "${using_eth_name}" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

    create_single_prometheus_config "${host_ip}"

    change_chmod_prometheus_data_dir

    log "[INFO] ended preload config prometheus"
}

main "$@"
