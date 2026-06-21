#!/bin/bash

create_instance() {

echo ""
echo "===== CREATE EC2 INSTANCE ====="
echo ""

read -p "Instance Name: " INSTANCE_NAME

if [ -z "$INSTANCE_NAME" ]; then
    echo "[ERROR] Instance name required"
    return
fi

echo ""
echo "Select Instance Type"
echo "1) t2.micro"
echo "2) t3.micro"
echo ""

read -p "Choice: " TYPE_CHOICE

case "$TYPE_CHOICE" in
    1) INSTANCE_TYPE="t2.micro" ;;
    2) INSTANCE_TYPE="t3.micro" ;;
    *)
        echo "[ERROR] Invalid instance type"
        return
        ;;
esac

echo ""
echo "Available Key Pairs"
echo ""

list_keypairs

echo ""
read -p "Enter Key Pair Name: " KEY_NAME

if [ -z "$KEY_NAME" ]; then
    echo "[ERROR] Key pair required"
    return
fi

aws ec2 describe-key-pairs \
    --region "$AWS_REGION" \
    --key-names "$KEY_NAME" \
    >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "[ERROR] Key pair does not exist"
    return
fi

echo ""
echo "Select Linux Distribution"
echo "1) Amazon Linux 2023"
echo "2) Ubuntu 24.04 LTS"
echo "3) Ubuntu 22.04 LTS"
echo "4) Debian 12"
echo ""

read -p "Choice: " DISTRO_CHOICE

case "$DISTRO_CHOICE" in

    1)
        DISTRO_NAME="Amazon Linux 2023"
        SSH_USER="ec2-user"

        AMI_ID=$(
            aws ssm get-parameter \
                --region "$AWS_REGION" \
                --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64" \
                --query "Parameter.Value" \
                --output text
        )
        ;;

    2)
        DISTRO_NAME="Ubuntu 24.04"
        SSH_USER="ubuntu"

        AMI_ID=$(
            aws ec2 describe-images \
                --region "$AWS_REGION" \
                --owners 099720109477 \
                --filters \
                "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
                "Name=state,Values=available" \
                --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
                --output text
        )
        ;;

    3)
        DISTRO_NAME="Ubuntu 22.04"
        SSH_USER="ubuntu"

        AMI_ID=$(
            aws ec2 describe-images \
                --region "$AWS_REGION" \
                --owners 099720109477 \
                --filters \
                "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
                "Name=state,Values=available" \
                --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
                --output text
        )
        ;;

    4)
        DISTRO_NAME="Debian 12"
        SSH_USER="admin"

        AMI_ID=$(
            aws ec2 describe-images \
                --region "$AWS_REGION" \
                --owners 136693071363 \
                --filters \
                "Name=name,Values=debian-12-amd64-*" \
                "Name=state,Values=available" \
                --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
                --output text
        )
        ;;

    *)
        echo "[ERROR] Invalid distro choice"
        return
        ;;
esac

if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
    echo "[ERROR] Failed to fetch AMI"
    return
fi

echo ""
echo "========== SUMMARY =========="
echo "Name      : $INSTANCE_NAME"
echo "Type      : $INSTANCE_TYPE"
echo "Distro    : $DISTRO_NAME"
echo "SSH User  : $SSH_USER"
echo "Key Pair  : $KEY_NAME"
echo "Region    : $AWS_REGION"
echo "AMI       : $AMI_ID"
echo "============================="
echo ""

read -p "Launch instance? (y/n): " CONFIRM

[[ "$CONFIRM" != "y" ]] && return

echo ""
echo "[INFO] Finding default VPC..."

VPC_ID=$(
    aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --filters Name=isDefault,Values=true \
        --query "Vpcs[0].VpcId" \
        --output text
)

if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
    echo "[ERROR] No default VPC found"
    return
fi

echo "[OK] VPC: $VPC_ID"

SECURITY_GROUP_NAME="ec2-manager-sg"

SG_ID=$(
    aws ec2 describe-security-groups \
        --region "$AWS_REGION" \
        --filters Name=group-name,Values="$SECURITY_GROUP_NAME" \
        --query "SecurityGroups[0].GroupId" \
        --output text 2>/dev/null
)

if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then

    echo "[INFO] Creating security group..."

    SG_ID=$(
        aws ec2 create-security-group \
            --region "$AWS_REGION" \
            --group-name "$SECURITY_GROUP_NAME" \
            --description "AWS Manager Security Group" \
            --vpc-id "$VPC_ID" \
            --query "GroupId" \
            --output text
    )

    aws ec2 authorize-security-group-ingress \
        --region "$AWS_REGION" \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 >/dev/null
fi

echo ""
echo "[INFO] Launching instance..."

INSTANCE_ID=$(
    aws ec2 run-instances \
        --region "$AWS_REGION" \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
        --query "Instances[0].InstanceId" \
        --output text
)

echo "[OK] Instance ID: $INSTANCE_ID"

echo ""
echo "[INFO] Waiting for instance to start..."

aws ec2 wait instance-running \
    --region "$AWS_REGION" \
    --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(
    aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text
)

echo ""
echo "================================="
echo " INSTANCE CREATED SUCCESSFULLY"
echo "================================="
echo "Instance ID : $INSTANCE_ID"
echo "Public IP   : $PUBLIC_IP"
echo "SSH User    : $SSH_USER"
echo "Region      : $AWS_REGION"
echo "================================="

}
