#!/bin/bash

create_keypair() {

    echo ""
    read -p "Enter Key Pair Name: " KEY_NAME

    if [ -z "$KEY_NAME" ]; then
        echo "[ERROR] Key name cannot be empty"
        return
    fi

    if [ -f "${KEY_NAME}.pem" ]; then
        echo "[ERROR] ${KEY_NAME}.pem already exists locally"
        return
    fi

    aws ec2 create-key-pair \
        --region "$AWS_REGION" \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "${KEY_NAME}.pem"

    chmod 400 "${KEY_NAME}.pem"

    echo ""
    echo "[OK] Key Pair Created"
    echo "[OK] Saved as ${KEY_NAME}.pem"
}

list_keypairs() {

    echo ""

    aws ec2 describe-key-pairs \
        --region "$AWS_REGION" \
        --query 'KeyPairs[*].[KeyName]' \
        --output table
}

choose_keypair() {

    echo ""
    echo "Available Key Pairs:"
    echo ""

    list_keypairs

    echo ""
    read -p "Enter Key Pair Name: " KEY_NAME

    if [ -z "$KEY_NAME" ]; then
        echo "[ERROR] Invalid key pair"
        return 1
    fi

    return 0
}
