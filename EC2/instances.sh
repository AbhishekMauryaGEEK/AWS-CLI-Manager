#!/bin/bash

list_instances() {

    echo ""

    aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --query 'Reservations[].Instances[].[
            InstanceId,
            State.Name,
            InstanceType,
            PublicIpAddress
        ]' \
        --output table
}

select_instance() {

    list_instances

    echo ""
    read -p "Enter Instance ID: " INSTANCE_ID

    if [ -z "$INSTANCE_ID" ]; then
        echo "[ERROR] Instance ID required"
        return 1
    fi

    return 0
}

start_instance() {

    select_instance || return

    aws ec2 start-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID"

    echo ""
    echo "[OK] Start requested"
}

stop_instance() {

    select_instance || return

    aws ec2 stop-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID"

    echo ""
    echo "[OK] Stop requested"
}

terminate_instance() {

    select_instance || return

    echo ""
    echo "WARNING: This will permanently delete the instance."
    echo ""

    read -p "Type DELETE to continue: " confirm

    [[ "$confirm" != "DELETE" ]] && return

    aws ec2 terminate-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID"

    echo ""
    echo "[OK] Termination requested"
}

ssh_instance() {


echo ""
echo "===== SSH INTO INSTANCE ====="
echo ""

list_instances

echo ""
read -p "Enter Instance ID: " INSTANCE_ID

if [ -z "$INSTANCE_ID" ]; then
    echo "[ERROR] Instance ID required"
    return
fi

PUBLIC_IP=$(
    aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text
)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "[ERROR] Could not determine public IP"
    return
fi

echo ""
echo "Select SSH User"
echo "1) ec2-user (Amazon Linux)"
echo "2) ubuntu (Ubuntu)"
echo "3) admin (Debian)"
echo ""

read -p "Choice: " USER_CHOICE

case "$USER_CHOICE" in
    1) SSH_USER="ec2-user" ;;
    2) SSH_USER="ubuntu" ;;
    3) SSH_USER="admin" ;;
    *)
        echo "[ERROR] Invalid choice"
        return
        ;;
esac

echo ""
read -p "PEM File Path: " PEM_FILE

if [ ! -f "$PEM_FILE" ]; then
    echo "[ERROR] PEM file not found"
    return
fi

chmod 400 "$PEM_FILE" 2>/dev/null

echo ""
echo "[INFO] Connecting to $PUBLIC_IP ..."
echo ""

ssh -i "$PEM_FILE" "$SSH_USER@$PUBLIC_IP"


}

reboot_instance() {

    echo ""
    echo "===== REBOOT INSTANCE ====="
    echo ""

    list_instances

    echo ""
    read -p "Enter Instance ID: " INSTANCE_ID

    if [ -z "$INSTANCE_ID" ]; then
        echo "[ERROR] Instance ID required"
        return
    fi

    echo ""
    read -p "Are you sure? (y/n): " CONFIRM

    [[ "$CONFIRM" != "y" ]] && return

    aws ec2 reboot-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID"

    echo ""
    echo "[OK] Reboot command sent."
}

instance_details() {

    echo ""
    echo "===== INSTANCE DETAILS ====="
    echo ""

    list_instances

    echo ""
    read -p "Enter Instance ID: " INSTANCE_ID

    if [ -z "$INSTANCE_ID" ]; then
        echo "[ERROR] Instance ID required"
        return
    fi

    echo ""

    aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query '
Reservations[0].Instances[0].{
Name:Tags[?Key==`Name`]|[0].Value,
State:State.Name,
Type:InstanceType,
PublicIP:PublicIpAddress,
PrivateIP:PrivateIpAddress,
LaunchTime:LaunchTime,
ImageId:ImageId
}' \
        --output table
}
