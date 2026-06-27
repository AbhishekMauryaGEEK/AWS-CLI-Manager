create_vpc() {

    clear

    echo "================================="
    echo "         CREATE VPC"
    echo "================================="
    echo ""
    echo "A VPC (Virtual Private Cloud) is"
    echo "your own isolated network in AWS."
    echo ""
    echo "Recommended CIDR : 10.0.0.0/16"
    echo ""

    read -r -p "VPC Name: " VPC_NAME

    if [ -z "$VPC_NAME" ]; then
        echo "[ERROR] VPC name is required."
        return
    fi

    echo ""
    read -r -p "CIDR Block [10.0.0.0/16]: " CIDR_BLOCK

    CIDR_BLOCK="${CIDR_BLOCK:-10.0.0.0/16}"

    echo ""
    echo "========== SUMMARY =========="
    echo "Name   : $VPC_NAME"
    echo "CIDR   : $CIDR_BLOCK"
    echo "Region : $AWS_REGION"
    echo "============================="
    echo ""

    read -r -p "Create VPC? (y/n): " CONFIRM

    [ "$CONFIRM" != "y" ] && return

    echo ""
    echo "[INFO] Creating VPC..."

    VPC_ID=$(
        aws ec2 create-vpc \
            --region "$AWS_REGION" \
            --cidr-block "$CIDR_BLOCK" \
            --query "Vpc.VpcId" \
            --output text
    )

    if [ $? -ne 0 ] || [ -z "$VPC_ID" ]; then
        echo "[ERROR] Failed to create VPC."
        return
    fi

    echo "[OK] VPC Created : $VPC_ID"

    echo ""
    echo "[INFO] Enabling DNS Support..."

    aws ec2 modify-vpc-attribute \
        --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" \
        --enable-dns-support '{"Value":true}' \
        >/dev/null

    echo "[OK] DNS Support Enabled"

    echo ""
    echo "[INFO] Enabling DNS Hostnames..."

    aws ec2 modify-vpc-attribute \
        --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" \
        --enable-dns-hostnames '{"Value":true}' \
        >/dev/null

    echo "[OK] DNS Hostnames Enabled"

    echo ""
    echo "[INFO] Adding Name tag..."

    aws ec2 create-tags \
        --region "$AWS_REGION" \
        --resources "$VPC_ID" \
        --tags Key=Name,Value="$VPC_NAME" \
        >/dev/null

    echo "[OK] Name Tag Added"

    echo ""
    echo "================================="
    echo "        VPC CREATED"
    echo "================================="
    echo "VPC ID      : $VPC_ID"
    echo "Name        : $VPC_NAME"
    echo "CIDR Block  : $CIDR_BLOCK"
    echo "DNS Support : Enabled"
    echo "Region      : $AWS_REGION"
    echo "================================="
}

list_vpcs() {

    mapfile -t VPCS < <(
        aws ec2 describe-vpcs \
            --region "$AWS_REGION" \
            --query "Vpcs[].VpcId" \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "        AVAILABLE VPCS"
    echo "================================="
    echo ""
    echo "[INFO] Please Wait Fetching VPCs Metadata..."
    if [ ${#VPCS[@]} -eq 0 ]; then
        echo "[INFO] No VPCs found."
        return
    fi

    for i in "${!VPCS[@]}"
    do
        VPC_ID="${VPCS[$i]}"

        CIDR=$(
            aws ec2 describe-vpcs \
                --region "$AWS_REGION" \
                --vpc-ids "$VPC_ID" \
                --query "Vpcs[0].CidrBlock" \
                --output text
        )

        DEFAULT=$(
            aws ec2 describe-vpcs \
                --region "$AWS_REGION" \
                --vpc-ids "$VPC_ID" \
                --query "Vpcs[0].IsDefault" \
                --output text
        )

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$VPC_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        echo "$((i+1))). $NAME"
        echo "    ID      : $VPC_ID"
        echo "    CIDR    : $CIDR"
        echo "    Default : $DEFAULT"
        echo ""
    done

    echo "Total VPCs : ${#VPCS[@]}"
}

delete_vpc() {

    mapfile -t VPCS < <(
        aws ec2 describe-vpcs \
            --region "$AWS_REGION" \
            --query "Vpcs[].VpcId" \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "        AVAILABLE VPCS"
    echo "================================="
    echo ""

    if [ ${#VPCS[@]} -eq 0 ]; then
        echo "[INFO] No VPCs found."
        return
    fi

    for i in "${!VPCS[@]}"
    do
        VPC_ID="${VPCS[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$VPC_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        echo "$((i+1))). $NAME ($VPC_ID)"
    done

    echo ""
    read -r -p "Choose VPC: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#VPCS[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_VPC="${VPCS[$((CHOICE-1))]}"

    echo ""
    echo "[INFO] Selected: $SELECTED_VPC"
    echo ""

    read -r -p "Type DELETE to confirm: " CONFIRM

    if [ "$CONFIRM" != "DELETE" ]; then
        echo "[INFO] Deletion cancelled."
        return
    fi

    echo ""
    echo "[INFO] Deleting VPC..."

    if ! aws ec2 delete-vpc \
        --region "$AWS_REGION" \
        --vpc-id "$SELECTED_VPC" \
        >/dev/null 2>&1
    then
        echo "[ERROR] Failed to delete VPC."
        echo "Make sure the VPC has no subnets, gateways, route tables, or other resources attached."
        return
    fi

    echo ""
    echo "================================="
    echo "        VPC DELETED"
    echo "================================="
    echo "VPC ID : $SELECTED_VPC"
    echo "================================="
}
