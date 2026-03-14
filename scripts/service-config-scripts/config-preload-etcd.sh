#!/bin/bash

# config-preload-etcd.sh
# 修改环境上 etcd 文件配置信息

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/../../service-config/etcd"
TEMPLATE_FILE="${TEMPLATE_DIR}/etcd.template.yaml"

source "${SCRIPT_DIR}/../common.sh"
source "${SCRIPT_DIR}/common-declare"

create_single_etcd_config() {
    local etcd_node_name=$1
    local listen_ip=$2
    local cluster_string=$3
    local etcd_inner_port="${NODE_INNER_PORT_MAP[${etcd_node_name}]}"
    local etcd_outer_port="${NODE_OUTER_PORT_MAP[${etcd_node_name}]}"

    local config_file_name="${CONFIG_FILE_MAP[${etcd_node_name}]}"
    local config_file_full_path="${TEMPLATE_DIR}/${config_file_name}"

    # 之前存在 删掉后创建新的
    if [[ -f "${config_file_full_path}" ]]; then
        log "[INFO] ${config_file_full_path} template middle file exist, delete."
        rm -rf "${config_file_full_path}"
    fi
    cp "${TEMPLATE_FILE}" "${config_file_full_path}"

    # 替换 node name
    sed -i "s|\${ETCD_NAME}|${etcd_node_name}|g" "${config_file_full_path}"

    # 替换 端口
    sed -i "s|\${ETCD_INNER_PORT}|${etcd_inner_port}|g" "${config_file_full_path}"
    sed -i "s|\${ETCD_OUTER_PORT}|${etcd_outer_port}|g" "${config_file_full_path}"

    # 替换 ip
    sed -i "s|\${ETCD_IP}|${listen_ip}|g" "${config_file_full_path}"

    # 替换 集群字符串
    sed -i "s|\${CLUSTER_STR}|${cluster_string}|g" "${config_file_full_path}"
    return 0
}

main() {
    log "[INFO] enter preload config etcd"

    # 使用 ens33 网口 IP
    local using_eth_name=$(get_host_ip)
    local host_ip=$(ip addr show "${using_eth_name}" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

    # 生成完整的集群信息 cluster str
    local initial_cluster_str=""
    for node in "${ALL_NODES[@]}"; do
        local port="${NODE_INNER_PORT_MAP[$node]}"
        if [[ -n "${initial_cluster_str}" ]]; then
            # 添加间隔
            initial_cluster_str="${initial_cluster_str},"
        fi
        initial_cluster_str="${initial_cluster_str}${node}=http://${host_ip}:${port}"
    done
    log "[INFO] create initial_cluster_str: ${initial_cluster_str}"

    # 遍历数组 生成配置
    for node in "${ALL_NODES[@]}"; do
        log "[INFO] exec create config: ${node}"
        create_single_etcd_config "${node}" "${host_ip}" "${initial_cluster_str}"
    done

    log "[INFO] ended preload config etcd"
}

main "$@"
