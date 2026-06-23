#!/bin/bash

check_credentials() {

    if aws sts get-caller-identity >/dev/null 2>&1; then
        echo "[OK] AWS credentials configured"
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
