#!/bin/bash

check_credentials() {

    if aws sts get-caller-identity >/dev/null 2>&1; then
        echo "[OK] AWS credentials configured"
        echo "==============================================================="
        echo "                     IMPORTANT NOTICE"
        echo "==============================================================="
        echo "[INFO] Please read the README before using AWS CLI Manager."
        echo "[INFO] Review the project's security guidelines and limitations."
        echo "[INFO] This tool creates and manages real AWS resources."
        echo "[INFO] You are responsible for AWS charges and resource usage."
        echo "==============================================================="
        echo ""
        return
    fi

    echo ""
    echo "AWS credentials not configured."
    echo ""

    aws configure

    aws sts get-caller-identity >/dev/null 2>&1 \
        || error_exit "Invalid AWS credentials"

    echo "[OK] AWS credentials configured"
}
