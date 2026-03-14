#!/bin/bash

# change_chmod_prometheus_data_dir 修改数据路径权限
change_chmod_grafana_data_dir() {
    # TODO 后续确认属主属组权限
    chmod 777 /app/grafana/data/grafana
}

main() {
    log "[INFO] enter preload config prometheus"
    change_chmod_grafana_data_dir
    log "[INFO] ended preload config prometheus"
}

main "$@"
