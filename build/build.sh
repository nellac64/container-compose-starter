#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/../"
PROJECT_CONFIG_DIR="${PROJECT_DIR}/config"
PROJECT_SCRIPT_DIR="${PROJECT_DIR}/scripts"
PROJECT_SERVICE_CONFIG_DIR="${PROJECT_DIR}/service-config"

OUTPUT_FILE="container-compose-starter.tar.gz"

main() {
    echo "enter container-compose-starter"

    find "${PROJECT_DIR}" -type f -name "*.sh" -exec chmod +x {} \;

    tar -czvf "${OUTPUT_FILE}" \
        "${PROJECT_CONFIG_DIR}" "${PROJECT_SCRIPT_DIR}" "${PROJECT_SERVICE_CONFIG_DIR}"
}

main