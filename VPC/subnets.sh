create_subnet() {

    clear

    echo "================================="
    echo "         CREATE SUBNET"
    echo "================================="
    echo ""
    echo "A subnet is a smaller network"
    echo "inside a VPC."
    echo ""
    echo "Recommended CIDR : 10.0.1.0/24"
    echo ""

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

    read -r -p "Subnet Name: " SUBNET_NAME

    if [ -z "$SUBNET_NAME" ]; then
        echo "[ERROR] Subnet name is required."
        return
    fi

    echo ""
    read -r -p "CIDR Block [10.0.1.0/24]: " CIDR_BLOCK

    CIDR_BLOCK="${CIDR_BLOCK:-10.0.1.0/24}"

    echo ""
    echo "Select Availability Zone"
    echo "1) ${AWS_REGION}a"
    echo "2) ${AWS_REGION}b"
    echo "3) ${AWS_REGION}c"
    echo "4) ${AWS_REGION}d"
    echo ""

    read -r -p "Choice: " choice

    case "$choice" in
        1) AZ="${AWS_REGION}a" ;;
        2) AZ="${AWS_REGION}b" ;;
        3) AZ="${AWS_REGION}c" ;;
        4) AZ="${AWS_REGION}d" ;;
        *)
            echo "[ERROR] Invalid Availability Zone."
            return
            ;;
    esac

    echo ""
    echo "========== SUMMARY =========="
    echo "VPC       : $SELECTED_VPC"
    echo "Subnet    : $SUBNET_NAME"
    echo "CIDR      : $CIDR_BLOCK"
    echo "AZ        : $AZ"
    echo "Region    : $AWS_REGION"
    echo "============================="
    echo ""

    read -r -p "Create Subnet? (y/n): " CONFIRM

    [ "$CONFIRM" != "y" ] && return

    echo ""
    echo "[INFO] Creating Subnet..."

    SUBNET_ID=$(
        aws ec2 create-subnet \
            --region "$AWS_REGION" \
            --vpc-id "$SELECTED_VPC" \
            --cidr-block "$CIDR_BLOCK" \
            --availability-zone "$AZ" \
            --query "Subnet.SubnetId" \
            --output text
    )

    if [ $? -ne 0 ] || [ -z "$SUBNET_ID" ]; then
        echo "[ERROR] Failed to create subnet."
        return
    fi

    echo "[OK] Subnet Created : $SUBNET_ID"

    echo ""
    echo "[INFO] Creating Name Tag..."

    aws ec2 create-tags \
        --region "$AWS_REGION" \
        --resources "$SUBNET_ID" \
        --tags Key=Name,Value="$SUBNET_NAME" \
        >/dev/null

    echo "[OK] Name Tag Added"

    echo ""
    echo "================================="
    echo "        SUBNET CREATED"
    echo "================================="
    echo "Subnet ID : $SUBNET_ID"
    echo "Name      : $SUBNET_NAME"
    echo "VPC ID    : $SELECTED_VPC"
    echo "CIDR      : $CIDR_BLOCK"
    echo "AZ        : $AZ"
    echo "Region    : $AWS_REGION"
    echo "================================="
}

list_subnets() {

    echo ""
    echo "[INFO] Please wait, fetching subnet information..."
    echo ""

    mapfile -t SUBNETS < <(
        aws ec2 describe-subnets \
            --region "$AWS_REGION" \
            --query "Subnets[].SubnetId" \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "      AVAILABLE SUBNETS"
    echo "================================="
    echo ""

    if [ ${#SUBNETS[@]} -eq 0 ]; then
        echo "[INFO] No subnets found."
        return
    fi

    for i in "${!SUBNETS[@]}"
    do
        SUBNET_ID="${SUBNETS[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$SUBNET_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        CIDR=$(
            aws ec2 describe-subnets \
                --region "$AWS_REGION" \
                --subnet-ids "$SUBNET_ID" \
                --query "Subnets[0].CidrBlock" \
                --output text
        )

        AZ=$(
            aws ec2 describe-subnets \
                --region "$AWS_REGION" \
                --subnet-ids "$SUBNET_ID" \
                --query "Subnets[0].AvailabilityZone" \
                --output text
        )

        VPC_ID=$(
            aws ec2 describe-subnets \
                --region "$AWS_REGION" \
                --subnet-ids "$SUBNET_ID" \
                --query "Subnets[0].VpcId" \
                --output text
        )

        echo "$((i+1))). $NAME"
        echo "    ID      : $SUBNET_ID"
        echo "    VPC     : $VPC_ID"
        echo "    CIDR    : $CIDR"
        echo "    AZ      : $AZ"
        echo ""
    done

    echo "Total Subnets : ${#SUBNETS[@]}"
}

delete_subnet() {

    mapfile -t SUBNETS < <(
        aws ec2 describe-subnets \
            --region "$AWS_REGION" \
            --query "Subnets[].SubnetId" \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "      AVAILABLE SUBNETS"
    echo "================================="
    echo ""

    if [ ${#SUBNETS[@]} -eq 0 ]; then
        echo "[INFO] No subnets found."
        return
    fi

    for i in "${!SUBNETS[@]}"
    do
        SUBNET_ID="${SUBNETS[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$SUBNET_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        echo "$((i+1))). $NAME ($SUBNET_ID)"
    done

    echo ""
    read -r -p "Choose Subnet: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#SUBNETS[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_SUBNET="${SUBNETS[$((CHOICE-1))]}"

    echo ""
    echo "[INFO] Selected: $SELECTED_SUBNET"
    echo ""

    read -r -p "Type DELETE to confirm: " CONFIRM

    if [ "$CONFIRM" != "DELETE" ]; then
        echo "[INFO] Deletion cancelled."
        return
    fi

    echo ""
    echo "[INFO] Deleting Subnet..."

    if ! aws ec2 delete-subnet \
        --region "$AWS_REGION" \
        --subnet-id "$SELECTED_SUBNET" \
        >/dev/null 2>&1
    then
        echo "[ERROR] Failed to delete subnet."
        return
    fi

    echo ""
    echo "================================="
    echo "      SUBNET DELETED"
    echo "================================="
    echo "Subnet ID : $SELECTED_SUBNET"
    echo "================================="
}
