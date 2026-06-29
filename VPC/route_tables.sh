create_route_table() {

    clear

    echo "================================="
    echo "      CREATE ROUTE TABLE"
    echo "================================="
    echo ""
    echo "A Route Table contains routing"
    echo "rules that determine where"
    echo "network traffic is directed."
    echo ""
    echo "Every Route Table belongs"
    echo "to exactly one VPC."
    echo ""

    echo "[INFO] Fetching available VPCs..."
    echo ""

    mapfile -t VPCS < <(
        aws ec2 describe-vpcs \
            --region "$AWS_REGION" \
            --query "Vpcs[].VpcId" \
            --output text | tr '\t' '\n'
    )

    if [ ${#VPCS[@]} -eq 0 ]; then
        echo "[INFO] No VPCs found."
        return
    fi

    echo "================================="
    echo "        AVAILABLE VPCS"
    echo "================================="
    echo ""

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
    echo "[OK] Selected VPC : $SELECTED_VPC"

    echo ""
    read -r -p "Route Table Name: " ROUTE_TABLE_NAME

    if [ -z "$ROUTE_TABLE_NAME" ]; then
        echo "[ERROR] Route Table name is required."
        return
    fi

    echo ""
    echo "========== SUMMARY =========="
    echo "Route Table : $ROUTE_TABLE_NAME"
    echo "VPC         : $SELECTED_VPC"
    echo "Region      : $AWS_REGION"
    echo "============================="
    echo ""

    read -r -p "Create Route Table? (y/n): " CONFIRM

    [ "$CONFIRM" != "y" ] && return

    echo ""
    echo "[INFO] Creating Route Table..."
    echo ""

    ROUTE_TABLE_ID=$(
        aws ec2 create-route-table \
            --region "$AWS_REGION" \
            --vpc-id "$SELECTED_VPC" \
            --query "RouteTable.RouteTableId" \
            --output text
    )

    if [ $? -ne 0 ] || [ -z "$ROUTE_TABLE_ID" ]; then
        echo "[ERROR] Failed to create Route Table."
        return
    fi

    echo "[OK] Route Table Created"
    echo "     ID : $ROUTE_TABLE_ID"

    echo ""
    echo "[INFO] Applying Name tag..."

    aws ec2 create-tags \
        --region "$AWS_REGION" \
        --resources "$ROUTE_TABLE_ID" \
        --tags Key=Name,Value="$ROUTE_TABLE_NAME" \
        >/dev/null

    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to apply Name tag."
        return
    fi

    echo "[OK] Name Tag Applied"

    echo ""
    echo "[INFO] Verifying Route Table..."

    aws ec2 describe-route-tables \
        --region "$AWS_REGION" \
        --route-table-ids "$ROUTE_TABLE_ID" \
        >/dev/null

    if [ $? -ne 0 ]; then
        echo "[ERROR] Route Table verification failed."
        return
    fi

    echo "[OK] Verification Successful"

    echo ""
    echo "================================="
    echo "     ROUTE TABLE CREATED"
    echo "================================="
    echo "Route Table ID : $ROUTE_TABLE_ID"
    echo "Name           : $ROUTE_TABLE_NAME"
    echo "VPC            : $SELECTED_VPC"
    echo "Region         : $AWS_REGION"
    echo "Status         : Available"
    echo "================================="
}

list_route_tables() {

    echo ""
    echo "[INFO] Please wait, fetching Route Tables..."
    echo ""

    mapfile -t ROUTE_TABLES < <(
        aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --query "RouteTables[].RouteTableId" \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "      ROUTE TABLES"
    echo "================================="
    echo ""

    if [ ${#ROUTE_TABLES[@]} -eq 0 ]; then
        echo "[INFO] No Route Tables found."
        return
    fi

    for i in "${!ROUTE_TABLES[@]}"
    do
        ROUTE_TABLE_ID="${ROUTE_TABLES[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$ROUTE_TABLE_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        VPC_ID=$(
            aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --route-table-ids "$ROUTE_TABLE_ID" \
                --query "RouteTables[0].VpcId" \
                --output text
        )

        ROUTE_COUNT=$(
            aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --route-table-ids "$ROUTE_TABLE_ID" \
                --query "length(RouteTables[0].Routes)" \
                --output text
        )

        MAIN=$(
            aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --route-table-ids "$ROUTE_TABLE_ID" \
                --query "RouteTables[0].Associations[0].Main" \
                --output text
        )

        [ "$MAIN" = "None" ] && MAIN="False"

        echo "$((i+1))). $NAME"
        echo "    ID      : $ROUTE_TABLE_ID"
        echo "    VPC     : $VPC_ID"
        echo "    Routes  : $ROUTE_COUNT"
        echo "    Main    : $MAIN"
        echo ""
    done

    echo "Total Route Tables : ${#ROUTE_TABLES[@]}"
}

associate_route_table() {

    clear

    echo "================================="
    echo "    ASSOCIATE ROUTE TABLE"
    echo "================================="
    echo ""
    echo "A Route Table must be associated"
    echo "with a subnet before it can"
    echo "control network routing."
    echo ""

    echo "[INFO] Fetching Route Tables..."
    echo ""

    mapfile -t ROUTE_TABLES < <(
        aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --query "RouteTables[].RouteTableId" \
            --output text | tr '\t' '\n'
    )

    if [ ${#ROUTE_TABLES[@]} -eq 0 ]; then
        echo "[INFO] No Route Tables found."
        return
    fi

    echo "================================="
    echo "     AVAILABLE ROUTE TABLES"
    echo "================================="
    echo ""

    for i in "${!ROUTE_TABLES[@]}"
    do
        RT_ID="${ROUTE_TABLES[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$RT_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        echo "$((i+1))). $NAME ($RT_ID)"
    done

    echo ""
    read -r -p "Choose Route Table: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#ROUTE_TABLES[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_RT="${ROUTE_TABLES[$((CHOICE-1))]}"

    echo ""
    echo "[INFO] Selected Route Table : $SELECTED_RT"

    echo ""
    echo "[INFO] Fetching Subnets..."
    echo ""

    mapfile -t SUBNETS < <(
        aws ec2 describe-subnets \
            --region "$AWS_REGION" \
            --query "Subnets[].SubnetId" \
            --output text | tr '\t' '\n'
    )

    if [ ${#SUBNETS[@]} -eq 0 ]; then
        echo "[INFO] No Subnets found."
        return
    fi

    echo "================================="
    echo "      AVAILABLE SUBNETS"
    echo "================================="
    echo ""

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
    echo "========== SUMMARY =========="
    echo "Route Table : $SELECTED_RT"
    echo "Subnet      : $SELECTED_SUBNET"
    echo "Region      : $AWS_REGION"
    echo "============================="
    echo ""

    read -r -p "Associate Route Table? (y/n): " CONFIRM

    [ "$CONFIRM" != "y" ] && return

    echo ""
    echo "[INFO] Associating Route Table..."

    ASSOCIATION_ID=$(
        aws ec2 associate-route-table \
            --region "$AWS_REGION" \
            --route-table-id "$SELECTED_RT" \
            --subnet-id "$SELECTED_SUBNET" \
            --query "AssociationId" \
            --output text
    )

    if [ $? -ne 0 ] || [ -z "$ASSOCIATION_ID" ]; then
        echo "[ERROR] Failed to associate Route Table."
        return
    fi

    echo ""
    echo "[OK] Route Table Associated Successfully"

    echo ""
    echo "================================="
    echo " ASSOCIATION COMPLETE"
    echo "================================="
    echo "Association ID : $ASSOCIATION_ID"
    echo "Route Table    : $SELECTED_RT"
    echo "Subnet         : $SELECTED_SUBNET"
    echo "================================="
}

disassociate_route_table() {

    clear

    echo "================================="
    echo " DISASSOCIATE ROUTE TABLE"
    echo "================================="
    echo ""
    echo "This operation removes the"
    echo "association between a Route"
    echo "Table and a Subnet."
    echo ""

    echo "[INFO] Fetching Route Table Associations..."
    echo ""

    mapfile -t ASSOCIATIONS < <(
        aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --query "RouteTables[].Associations[?Main==\`false\`].RouteTableAssociationId" \
            --output text | tr '\t' '\n'
    )

    if [ ${#ASSOCIATIONS[@]} -eq 0 ]; then
        echo "[INFO] No Route Table associations found."
        return
    fi

    echo "================================="
    echo "    ROUTE ASSOCIATIONS"
    echo "================================="
    echo ""

    for i in "${!ASSOCIATIONS[@]}"
    do
        ASSOC_ID="${ASSOCIATIONS[$i]}"

        ROUTE_TABLE_ID=$(
            aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --query "RouteTables[?Associations[?RouteTableAssociationId=='$ASSOC_ID']].RouteTableId | [0]" \
                --output text
        )

        SUBNET_ID=$(
            aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --query "RouteTables[?Associations[?RouteTableAssociationId=='$ASSOC_ID']].Associations[?RouteTableAssociationId=='$ASSOC_ID'].SubnetId | [0]" \
                --output text
        )

        echo "$((i+1))). Association : $ASSOC_ID"
        echo "    Route Table : $ROUTE_TABLE_ID"
        echo "    Subnet      : $SUBNET_ID"
        echo ""
    done

    read -r -p "Choose Association: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#ASSOCIATIONS[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_ASSOC="${ASSOCIATIONS[$((CHOICE-1))]}"

    echo ""
    echo "========== SUMMARY =========="
    echo "Association : $SELECTED_ASSOC"
    echo "============================="
    echo ""

    read -r -p "Type DISASSOCIATE to confirm: " CONFIRM

    if [ "$CONFIRM" != "DISASSOCIATE" ]; then
        echo "[INFO] Operation cancelled."
        return
    fi

    echo ""
    echo "[INFO] Disassociating Route Table..."

    if ! aws ec2 disassociate-route-table \
        --region "$AWS_REGION" \
        --association-id "$SELECTED_ASSOC" \
        >/dev/null
    then
        echo "[ERROR] Failed to disassociate Route Table."
        return
    fi

    echo ""
    echo "================================="
    echo " ROUTE TABLE DISASSOCIATED"
    echo "================================="
    echo "Association : $SELECTED_ASSOC"
    echo "================================="
}

add_route() {

    clear

    echo "================================="
    echo "         ADD ROUTE"
    echo "================================="
    echo ""
    echo "A Route defines where network"
    echo "traffic should be forwarded."
    echo ""
    echo "This operation will create an"
    echo "Internet route (0.0.0.0/0)"
    echo "through an Internet Gateway."
    echo ""

    echo "[INFO] Fetching Route Tables..."
    echo ""

    mapfile -t ROUTE_TABLES < <(
        aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --query "RouteTables[].RouteTableId" \
            --output text | tr '\t' '\n'
    )

    if [ ${#ROUTE_TABLES[@]} -eq 0 ]; then
        echo "[INFO] No Route Tables found."
        return
    fi

    echo "================================="
    echo "     AVAILABLE ROUTE TABLES"
    echo "================================="
    echo ""

    for i in "${!ROUTE_TABLES[@]}"
    do
        RT_ID="${ROUTE_TABLES[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$RT_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        echo "$((i+1))). $NAME ($RT_ID)"
    done

    echo ""
    read -r -p "Choose Route Table: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#ROUTE_TABLES[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_RT="${ROUTE_TABLES[$((CHOICE-1))]}"

    echo ""
    echo "[INFO] Fetching Internet Gateways..."
    echo ""

    mapfile -t GATEWAYS < <(
        aws ec2 describe-internet-gateways \
            --region "$AWS_REGION" \
            --query "InternetGateways[].InternetGatewayId" \
            --output text | tr '\t' '\n'
    )

    if [ ${#GATEWAYS[@]} -eq 0 ]; then
        echo "[INFO] No Internet Gateways found."
        return
    fi

    echo "================================="
    echo " AVAILABLE INTERNET GATEWAYS"
    echo "================================="
    echo ""

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

        echo "$((i+1))). $NAME ($GATEWAY_ID)"
    done

    echo ""
    read -r -p "Choose Internet Gateway: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#GATEWAYS[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_GATEWAY="${GATEWAYS[$((CHOICE-1))]}"

    DESTINATION="0.0.0.0/0"

    echo ""
    echo "========== SUMMARY =========="
    echo "Route Table : $SELECTED_RT"
    echo "Gateway     : $SELECTED_GATEWAY"
    echo "Destination : $DESTINATION"
    echo "============================="
    echo ""

    read -r -p "Create Route? (y/n): " CONFIRM

    [ "$CONFIRM" != "y" ] && return

    echo ""
    echo "[INFO] Creating Route..."

    if ! aws ec2 create-route \
        --region "$AWS_REGION" \
        --route-table-id "$SELECTED_RT" \
        --destination-cidr-block "$DESTINATION" \
        --gateway-id "$SELECTED_GATEWAY"
    then
        echo "[ERROR] Failed to create Route."
        return
    fi

    echo ""
    echo "[OK] Route Created Successfully"

    echo ""
    echo "================================="
    echo "        ROUTE CREATED"
    echo "================================="
    echo "Route Table : $SELECTED_RT"
    echo "Destination : $DESTINATION"
    echo "Gateway     : $SELECTED_GATEWAY"
    echo "================================="
}

delete_route_table() {

    clear

    echo "================================="
    echo "      DELETE ROUTE TABLE"
    echo "================================="
    echo ""

    echo "[INFO] Fetching Route Tables..."
    echo ""

    mapfile -t ROUTE_TABLES < <(
        aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --query "RouteTables[].RouteTableId" \
            --output text | tr '\t' '\n'
    )

    if [ ${#ROUTE_TABLES[@]} -eq 0 ]; then
        echo "[INFO] No Route Tables found."
        return
    fi

    echo "================================="
    echo "      ROUTE TABLES"
    echo "================================="
    echo ""

    for i in "${!ROUTE_TABLES[@]}"
    do
        RT_ID="${ROUTE_TABLES[$i]}"

        NAME=$(
            aws ec2 describe-tags \
                --region "$AWS_REGION" \
                --filters \
                    Name=resource-id,Values="$RT_ID" \
                    Name=key,Values=Name \
                --query "Tags[0].Value" \
                --output text
        )

        [ "$NAME" = "None" ] && NAME="-"

        VPC_ID=$(
            aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --route-table-ids "$RT_ID" \
                --query "RouteTables[0].VpcId" \
                --output text
        )

        MAIN=$(
            aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --route-table-ids "$RT_ID" \
                --query "RouteTables[0].Associations[0].Main" \
                --output text
        )

        [ "$MAIN" = "None" ] && MAIN="False"

        echo "$((i+1))). $NAME"
        echo "    ID      : $RT_ID"
        echo "    VPC     : $VPC_ID"
        echo "    Main    : $MAIN"
        echo ""
    done

    read -r -p "Choose Route Table: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#ROUTE_TABLES[@]}" ]; then
        echo "[ERROR] Invalid selection."
        return
    fi

    SELECTED_RT="${ROUTE_TABLES[$((CHOICE-1))]}"

    MAIN=$(
        aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --route-table-ids "$SELECTED_RT" \
            --query "RouteTables[0].Associations[0].Main" \
            --output text
    )

    if [ "$MAIN" = "True" ]; then
        echo ""
        echo "[ERROR] Cannot delete the Main Route Table."
        echo "[INFO] Every VPC must have one Main Route Table."
        return
    fi

    ASSOCIATED_SUBNETS=$(
        aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --route-table-ids "$SELECTED_RT" \
            --query "length(RouteTables[0].Associations[?Main==\`false\`])" \
            --output text
    )

    if [ "$ASSOCIATED_SUBNETS" -gt 0 ]; then
        echo ""
        echo "[ERROR] Route Table is associated with one or more subnets."
        echo "[INFO] Disassociate the Route Table before deleting it."
        return
    fi

    echo ""
    echo "========== SUMMARY =========="
    echo "Route Table : $SELECTED_RT"
    echo "============================="
    echo ""

    read -r -p "Type DELETE to confirm: " CONFIRM

    if [ "$CONFIRM" != "DELETE" ]; then
        echo "[INFO] Deletion cancelled."
        return
    fi

    echo ""
    echo "[INFO] Deleting Route Table..."

    if ! aws ec2 delete-route-table \
        --region "$AWS_REGION" \
        --route-table-id "$SELECTED_RT" \
        >/dev/null
    then
        echo "[ERROR] Failed to delete Route Table."
        return
    fi

    echo ""
    echo "================================="
    echo "     ROUTE TABLE DELETED"
    echo "================================="
    echo "Route Table : $SELECTED_RT"
    echo "================================="
}
