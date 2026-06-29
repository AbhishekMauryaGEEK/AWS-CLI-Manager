create_internet_gateway() {

    clear

    echo "================================="
    echo "   CREATE INTERNET GATEWAY"
    echo "================================="
    echo ""
    echo "An Internet Gateway allows"
    echo "resources inside a VPC to"
    echo "communicate with the Internet."
    echo ""

    read -r -p "Gateway Name: " GATEWAY_NAME

    if [ -z "$GATEWAY_NAME" ]; then
        echo "[ERROR] Gateway name is required."
        return
    fi

    echo ""
    echo "========== SUMMARY =========="
    echo "Gateway Name : $GATEWAY_NAME"
    echo "Region       : $AWS_REGION"
    echo "============================="
    echo ""

    read -r -p "Create Internet Gateway? (y/n): " CONFIRM

    [ "$CONFIRM" != "y" ] && return

    echo ""
    echo "[INFO] Creating Internet Gateway..."

    GATEWAY_ID=$(
        aws ec2 create-internet-gateway \
            --region "$AWS_REGION" \
            --query "InternetGateway.InternetGatewayId" \
            --output text
    )

    if [ $? -ne 0 ] || [ -z "$GATEWAY_ID" ]; then
        echo "[ERROR] Failed to create Internet Gateway."
        return
    fi

    echo "[OK] Internet Gateway Created : $GATEWAY_ID"

    echo ""
    echo "[INFO] Creating Name Tag..."

    aws ec2 create-tags \
        --region "$AWS_REGION" \
        --resources "$GATEWAY_ID" \
        --tags Key=Name,Value="$GATEWAY_NAME" \
        >/dev/null

    echo "[OK] Name Tag Added"

    echo ""
    echo "================================="
    echo "   INTERNET GATEWAY CREATED"
    echo "================================="
    echo "Gateway ID : $GATEWAY_ID"
    echo "Name       : $GATEWAY_NAME"
    echo "Region     : $AWS_REGION"
    echo "================================="
}

list_internet_gateways() {

    echo ""
    echo "[INFO] Please wait, fetching Internet Gateways..."
    echo ""

    mapfile -t GATEWAYS < <(
        aws ec2 describe-internet-gateways \
            --region "$AWS_REGION" \
            --query "InternetGateways[].InternetGatewayId" \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo " AVAILABLE INTERNET GATEWAYS"
    echo "================================="
    echo ""

    if [ ${#GATEWAYS[@]} -eq 0 ]; then
        echo "[INFO] No Internet Gateways found."
        return
    fi

    for i in "${!GATEWAYS[@]}"
    do
        GATEWAY_ID="${GATEWAYS[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$GATEWAY_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        VPC_ID=$(
            aws ec2 describe-internet-gateways \
                --region "$AWS_REGION" \
                --internet-gateway-ids "$GATEWAY_ID" \
                --query "InternetGateways[0].Attachments[0].VpcId" \
                --output text
        )

        [ "$VPC_ID" = "None" ] && VPC_ID="Not Attached"

        echo "$((i+1))). $NAME"
        echo "    ID       : $GATEWAY_ID"
        echo "    Attached : $VPC_ID"
        echo ""
    done

    echo "Total Gateways : ${#GATEWAYS[@]}"
}

attach_internet_gateway() {

   mapfile -t GATEWAYS < <(
       aws ec2 describe-internet-gateways \
         --region "$AWS_REGION" \
         --query "InternetGateways[].InternetGatewayId" \
         --output text | tr '\t' '\n'
   )
    echo ""
    echo "================================="
    echo " AVAILABLE INTERNET GATEWAYS"
    echo "================================="
    echo ""

    if [ ${#GATEWAYS[@]} -eq 0 ]; then
        echo "[INFO] No unattached Internet Gateways found."
        return
    fi

    for i in "${!GATEWAYS[@]}"
    do
        echo "$((i+1))). ${GATEWAYS[$i]}"
    done

    echo ""
    read -r -p "Choose Gateway: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#GATEWAYS[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_GATEWAY="${GATEWAYS[$((CHOICE-1))]}"

    echo ""

    mapfile -t VPCS < <(
        aws ec2 describe-vpcs \
            --region "$AWS_REGION" \
            --query "Vpcs[].VpcId" \
            --output text | tr '\t' '\n'
    )

    echo "================================="
    echo "        AVAILABLE VPCS"
    echo "================================="
    echo ""

    for i in "${!VPCS[@]}"
    do
        echo "$((i+1))). ${VPCS[$i]}"
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
    echo "========== SUMMARY =========="
    echo "Gateway : $SELECTED_GATEWAY"
    echo "VPC     : $SELECTED_VPC"
    echo "============================="
    echo ""

    read -r -p "Attach Gateway? (y/n): " CONFIRM

    [ "$CONFIRM" != "y" ] && return

    echo ""
    echo "[INFO] Attaching Internet Gateway..."

    if ! aws ec2 attach-internet-gateway \
        --region "$AWS_REGION" \
        --internet-gateway-id "$SELECTED_GATEWAY" \
        --vpc-id "$SELECTED_VPC"
    then
        echo "[ERROR] Failed to attach Internet Gateway."
        return
    fi

    echo ""
    echo "[OK] Internet Gateway attached successfully."
}

detach_internet_gateway() {

   mapfile -t GATEWAYS < <(
      aws ec2 describe-internet-gateways \
         --region "$AWS_REGION" \
         --query "InternetGateways[].InternetGatewayId" \
         --output text | tr '\t' '\n'
   )
    echo ""
    echo "================================="
    echo " ATTACHED INTERNET GATEWAYS"
    echo "================================="
    echo ""

    if [ ${#GATEWAYS[@]} -eq 0 ]; then
        echo "[INFO] No attached Internet Gateways found."
        return
    fi

    for i in "${!GATEWAYS[@]}"
    do
        GATEWAY="${GATEWAYS[$i]}"

        VPC_ID=$(
            aws ec2 describe-internet-gateways \
                --region "$AWS_REGION" \
                --internet-gateway-ids "$GATEWAY" \
                --query "InternetGateways[0].Attachments[0].VpcId" \
                --output text
        )

        echo "$((i+1))). $GATEWAY"
        echo "    Attached to : $VPC_ID"
        echo ""
    done

    read -r -p "Choose Gateway: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#GATEWAYS[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_GATEWAY="${GATEWAYS[$((CHOICE-1))]}"

    VPC_ID=$(
        aws ec2 describe-internet-gateways \
            --region "$AWS_REGION" \
            --internet-gateway-ids "$SELECTED_GATEWAY" \
            --query "InternetGateways[0].Attachments[0].VpcId" \
            --output text
    )

    echo ""
    read -r -p "Type DETACH to confirm: " CONFIRM

    [ "$CONFIRM" != "DETACH" ] && return

    echo ""
    echo "[INFO] Detaching Internet Gateway..."

    if ! aws ec2 detach-internet-gateway \
        --region "$AWS_REGION" \
        --internet-gateway-id "$SELECTED_GATEWAY" \
        --vpc-id "$VPC_ID"
    then
        echo "[ERROR] Failed to detach Internet Gateway."
        return
    fi

    echo ""
    echo "[OK] Internet Gateway detached successfully."
}

delete_internet_gateway() {

    mapfile -t GATEWAYS < <(
        aws ec2 describe-internet-gateways \
            --region "$AWS_REGION" \
            --query "InternetGateways[].InternetGatewayId" \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo " AVAILABLE INTERNET GATEWAYS"
    echo "================================="
    echo ""

    if [ ${#GATEWAYS[@]} -eq 0 ]; then
        echo "[INFO] No Internet Gateways found."
        return
    fi

    for i in "${!GATEWAYS[@]}"
    do
        GATEWAY_ID="${GATEWAYS[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$GATEWAY_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        VPC_ID=$(
            aws ec2 describe-internet-gateways \
                --region "$AWS_REGION" \
                --internet-gateway-ids "$GATEWAY_ID" \
                --query "InternetGateways[0].Attachments[0].VpcId" \
                --output text
        )

        [ "$VPC_ID" = "None" ] && VPC_ID="Not Attached"

        echo "$((i+1))). $NAME"
        echo "    ID       : $GATEWAY_ID"
        echo "    Attached : $VPC_ID"
        echo ""
    done

    read -r -p "Choose Internet Gateway: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#GATEWAYS[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_GATEWAY="${GATEWAYS[$((CHOICE-1))]}"

    ATTACHED_VPC=$(
        aws ec2 describe-internet-gateways \
            --region "$AWS_REGION" \
            --internet-gateway-ids "$SELECTED_GATEWAY" \
            --query "InternetGateways[0].Attachments[0].VpcId" \
            --output text
    )

    if [ "$ATTACHED_VPC" != "None" ]; then
        echo ""
        echo "[ERROR] Internet Gateway is attached to:"
        echo "        $ATTACHED_VPC"
        echo ""
        echo "[INFO] Detach the Internet Gateway before deleting it."
        return
    fi

    echo ""
    read -r -p "Type DELETE to confirm: " CONFIRM

    if [ "$CONFIRM" != "DELETE" ]; then
        echo "[INFO] Deletion cancelled."
        return
    fi

    echo ""
    echo "[INFO] Deleting Internet Gateway..."

    if ! aws ec2 delete-internet-gateway \
        --region "$AWS_REGION" \
        --internet-gateway-id "$SELECTED_GATEWAY" \
        >/dev/null 2>&1
    then
        echo "[ERROR] Failed to delete Internet Gateway."
        return
    fi

    echo ""
    echo "================================="
    echo " INTERNET GATEWAY DELETED"
    echo "================================="
    echo "Gateway ID : $SELECTED_GATEWAY"
    echo "================================="
}
