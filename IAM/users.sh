#!/bin/bash

select_user() {

    mapfile -t USERS < <(
        aws iam list-users \
        --query 'Users[].UserName' \
        --output text | tr '\t' '\n'
    )

    if [ ${#USERS[@]} -eq 0 ]; then
        echo ""
        echo "[INFO] No users found"
        return 1
    fi

    echo ""
    echo "================================="
    echo "        AVAILABLE USERS"
    echo "================================="
    echo ""

    for i in "${!USERS[@]}"
    do
        echo "$((i+1))). ${USERS[$i]}"
    done

    echo ""

    read -r -p "Choose User: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#USERS[@]}" ]
    then
        echo "[ERROR] Invalid choice"
        return 1
    fi

    SELECTED_USER="${USERS[$((CHOICE-1))]}"

    echo ""
    echo "[INFO] Selected: $SELECTED_USER"

    return 0
}

create_user() {

    echo ""

    read -r -p "User Name: " USER_NAME

    if aws iam create-user \
        --user-name "$USER_NAME" >/dev/null 2>&1
    then
        echo ""
        echo "================================="
        echo "         USER CREATED"
        echo "================================="
        echo ""
        echo "User Name : $USER_NAME"
    else
        echo ""
        echo "[ERROR] Failed to create user"
    fi
}

list_users() {

    mapfile -t USERS < <(
        aws iam list-users \
        --query 'Users[].UserName' \
        --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "         IAM USERS"
    echo "================================="
    echo ""

    if [ ${#USERS[@]} -eq 0 ]; then
        echo "[INFO] No users found"
        return
    fi

    for i in "${!USERS[@]}"
    do
        echo "$((i+1))). ${USERS[$i]}"
    done

    echo ""
    echo "Total Users : ${#USERS[@]}"
}

delete_user() {

    select_user || return

    echo ""
    echo "User: $SELECTED_USER"

    read -r -p "Type DELETE to continue: " CONFIRM

    if [[ "$CONFIRM" != "DELETE" ]]; then
        echo "[INFO] Cancelled"
        return
    fi

    if aws iam delete-user \
        --user-name "$SELECTED_USER"
    then
        echo ""
        echo "================================="
        echo "         USER DELETED"
        echo "================================="
        echo ""
        echo "User : $SELECTED_USER"
    else
        echo ""
        echo "[ERROR] Failed to delete user"
    fi
}

create_access_key() {

    select_user || return

    echo ""

    ACCESS_KEY_OUTPUT=$(
        aws iam create-access-key \
            --user-name "$SELECTED_USER" \
            --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
            --output text
    )

    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to create access key"
        return 1
    fi

    ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | awk '{print $1}')
    SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY_OUTPUT" | awk '{print $2}')

    echo ""
    echo "================================="
    echo "      ACCESS KEY CREATED"
    echo "================================="
    echo ""
    echo "User              : $SELECTED_USER"
    echo "Access Key ID     : $ACCESS_KEY_ID"
    echo "Secret Access Key : $SECRET_ACCESS_KEY"
    echo ""
    echo "[WARNING] Save this secret key now."
    echo "[WARNING] AWS will not show it again."
}

list_access_keys() {

    select_user || return

    echo ""
    echo "================================="
    echo "       ACCESS KEYS"
    echo "================================="
    echo ""

    aws iam list-access-keys \
        --user-name "$SELECTED_USER" \
        --query 'AccessKeyMetadata[].AccessKeyId' \
        --output text | tr '\t' '\n'
}

select_access_key() {

    mapfile -t ACCESS_KEYS < <(
        aws iam list-access-keys \
            --user-name "$SELECTED_USER" \
            --query 'AccessKeyMetadata[].AccessKeyId' \
            --output text | tr '\t' '\n'
    )

    if [ ${#ACCESS_KEYS[@]} -eq 0 ]; then
        echo ""
        echo "[INFO] No access keys found"
        return 1
    fi

    echo ""
    echo "================================="
    echo "       ACCESS KEYS"
    echo "================================="
    echo ""

    for i in "${!ACCESS_KEYS[@]}"
    do
        echo "$((i+1))). ${ACCESS_KEYS[$i]}"
    done

    echo ""

    read -r -p "Choose Key: " CHOICE

    SELECTED_KEY="${ACCESS_KEYS[$((CHOICE-1))]}"
}

delete_access_key() {

    select_user || return
    select_access_key || return

    echo ""
    echo "Access Key: $SELECTED_KEY"

    read -r -p "Type DELETE to continue: " CONFIRM

    if [[ "$CONFIRM" != "DELETE" ]]; then
        echo "[INFO] Cancelled"
        return
    fi

    if aws iam delete-access-key \
        --user-name "$SELECTED_USER" \
        --access-key-id "$SELECTED_KEY"
    then
        echo ""
        echo "[OK] Access key deleted"
    else
        echo ""
        echo "[ERROR] Failed to delete access key"
    fi
}

select_group() {

    mapfile -t IAM_GROUPS < <(
        aws iam list-groups \
            --query 'Groups[].GroupName' \
            --output text | tr '\t' '\n'
    )

    if [ ${#IAM_GROUPS[@]} -eq 0 ]; then
        echo ""
        echo "[INFO] No groups found"
        return 1
    fi

    echo ""
    echo "================================="
    echo "      AVAILABLE IAM_GROUPS"
    echo "================================="
    echo ""

    for i in "${!IAM_GROUPS[@]}"
    do
        echo "$((i+1))). ${IAM_GROUPS[$i]}"
    done

    echo ""

    read -r -p "Choose Group: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#IAM_GROUPS[@]}" ]
    then
        echo "[ERROR] Invalid choice"
        return 1
    fi

    SELECTED_GROUP="${IAM_GROUPS[$((CHOICE-1))]}"

    echo ""
    echo "[INFO] Selected: $SELECTED_GROUP"

    return 0
}

create_group() {

    echo ""

    read -r -p "Group Name: " GROUP_NAME

    if aws iam create-group \
        --group-name "$GROUP_NAME" >/dev/null 2>&1
    then
        echo ""
        echo "================================="
        echo "        GROUP CREATED"
        echo "================================="
        echo ""
        echo "Group : $GROUP_NAME"
    else
        echo ""
        echo "[ERROR] Failed to create group"
    fi
}

list_groups() {

    mapfile -t IAM_GROUPS < <(
        aws iam list-groups \
            --query 'Groups[].GroupName' \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "      AVAILABLE IAM_GROUPS"
    echo "================================="
    echo ""

    if [ ${#IAM_GROUPS[@]} -eq 0 ]; then
        echo "[INFO] No groups found"
        return
    fi

    for i in "${!IAM_GROUPS[@]}"
    do
        echo "$((i+1))). ${IAM_GROUPS[$i]}"
    done

    echo ""
    echo "Total Groups : ${#IAM_GROUPS[@]}"
}

delete_group() {

    select_group || return

    echo ""
    echo "Group : $SELECTED_GROUP"

    read -r -p "Type DELETE to continue: " CONFIRM

    if [[ "$CONFIRM" != "DELETE" ]]; then
        echo "[INFO] Cancelled"
        return
    fi

    if aws iam delete-group \
        --group-name "$SELECTED_GROUP"
    then
        echo ""
        echo "================================="
        echo "        GROUP DELETED"
        echo "================================="
        echo ""
        echo "Group : $SELECTED_GROUP"
    else
        echo ""
        echo "[ERROR] Failed to delete group"
    fi
}

add_user_to_group() {

    select_user || return
    select_group || return

    if aws iam add-user-to-group \
        --user-name "$SELECTED_USER" \
        --group-name "$SELECTED_GROUP"
    then
        echo ""
        echo "================================="
        echo "      USER ADDED TO GROUP"
        echo "================================="
        echo ""
        echo "User  : $SELECTED_USER"
        echo "Group : $SELECTED_GROUP"
    else
        echo ""
        echo "[ERROR] Failed to add user to group"
    fi
}

remove_user_from_group() {

    select_user || return
    select_group || return

    if aws iam remove-user-from-group \
        --user-name "$SELECTED_USER" \
        --group-name "$SELECTED_GROUP"
    then
        echo ""
        echo "================================="
        echo "   USER REMOVED FROM GROUP"
        echo "================================="
        echo ""
        echo "User  : $SELECTED_USER"
        echo "Group : $SELECTED_GROUP"
    else
        echo ""
        echo "[ERROR] Failed to remove user from group"
    fi
}

attach_policy() {

    select_group || return

    POLICIES=(
        "AdministratorAccess"
        "AmazonS3FullAccess"
        "AmazonS3ReadOnlyAccess"
        "AmazonEC2FullAccess"
        "AmazonEC2ReadOnlyAccess"
        "IAMFullAccess"
        "IAMReadOnlyAccess"
    )

    POLICY_ARNS=(
        "arn:aws:iam::aws:policy/AdministratorAccess"
        "arn:aws:iam::aws:policy/AmazonS3FullAccess"
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
        "arn:aws:iam::aws:policy/IAMFullAccess"
        "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
    )

    SELECTED_POLICY_ARNS=()
    SELECTED_POLICY_NAMES=()

    while true
    do
        clear

        echo "================================="
        echo "       ATTACH POLICIES"
        echo "================================="
        echo ""
        echo "Group : $SELECTED_GROUP"
        echo ""

        for i in "${!POLICIES[@]}"
        do
            MARK=" "

            for ARN in "${SELECTED_POLICY_ARNS[@]}"
            do
                if [[ "$ARN" == "${POLICY_ARNS[$i]}" ]]; then
                    MARK="x"
                    break
                fi
            done

            echo "[$MARK] $((i+1))). ${POLICIES[$i]}"
        done

        echo ""
        echo "0). Apply Selected Policies"
        echo ""

        read -r -p "Select Policy: " CHOICE

        if [[ "$CHOICE" == "0" ]]; then
            break
        fi

        if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
           [ "$CHOICE" -lt 1 ] ||
           [ "$CHOICE" -gt "${#POLICIES[@]}" ]
        then
            echo "[ERROR] Invalid choice"
            sleep 1
            continue
        fi

        INDEX=$((CHOICE-1))

        DUPLICATE=false

        for ARN in "${SELECTED_POLICY_ARNS[@]}"
        do
            if [[ "$ARN" == "${POLICY_ARNS[$INDEX]}" ]]; then
                DUPLICATE=true
                break
            fi
        done

        if $DUPLICATE; then
            echo ""
            echo "[INFO] Policy already selected."
            sleep 1
            continue
        fi

        SELECTED_POLICY_ARNS+=("${POLICY_ARNS[$INDEX]}")
        SELECTED_POLICY_NAMES+=("${POLICIES[$INDEX]}")

    done

    if [ ${#SELECTED_POLICY_ARNS[@]} -eq 0 ]; then
        echo ""
        echo "[INFO] No policies selected."
        return
    fi

    echo ""
    echo "Applying Policies..."
    echo ""

    for i in "${!SELECTED_POLICY_ARNS[@]}"
    do
        if aws iam attach-group-policy \
            --group-name "$SELECTED_GROUP" \
            --policy-arn "${SELECTED_POLICY_ARNS[$i]}"
        then
            echo "[OK] ${SELECTED_POLICY_NAMES[$i]}"
        else
            echo "[ERROR] ${SELECTED_POLICY_NAMES[$i]}"
        fi
    done

    echo ""
    echo "================================="
    echo "      OPERATION COMPLETE"
    echo "================================="
}

list_policies() {

    select_group || return

    mapfile -t ATTACHED_POLICIES < <(
        aws iam list-attached-group-policies \
            --group-name "$SELECTED_GROUP" \
            --query 'AttachedPolicies[].PolicyName' \
            --output text | tr '\t' '\n'
    )

    echo ""
    echo "================================="
    echo "     ATTACHED POLICIES"
    echo "================================="
    echo ""
    echo "Group : $SELECTED_GROUP"
    echo ""

    if [ ${#ATTACHED_POLICIES[@]} -eq 0 ]; then
        echo "[INFO] No policies attached."
        return
    fi

    for i in "${!ATTACHED_POLICIES[@]}"
    do
        echo "$((i+1))). ${ATTACHED_POLICIES[$i]}"
    done

    echo ""
    echo "Total Policies : ${#ATTACHED_POLICIES[@]}"
}

detach_policy() {

    select_group || return

    mapfile -t POLICY_NAMES < <(
        aws iam list-attached-group-policies \
            --group-name "$SELECTED_GROUP" \
            --query 'AttachedPolicies[].PolicyName' \
            --output text | tr '\t' '\n'
    )

    mapfile -t POLICY_ARNS < <(
        aws iam list-attached-group-policies \
            --group-name "$SELECTED_GROUP" \
            --query 'AttachedPolicies[].PolicyArn' \
            --output text | tr '\t' '\n'
    )

    if [ ${#POLICY_NAMES[@]} -eq 0 ]; then
        echo ""
        echo "[INFO] No policies attached."
        return
    fi

    while true
    do
        clear

        echo "================================="
        echo "      DETACH POLICIES"
        echo "================================="
        echo ""
        echo "Group : $SELECTED_GROUP"
        echo ""

        for i in "${!POLICY_NAMES[@]}"
        do
            echo "$((i+1))). ${POLICY_NAMES[$i]}"
        done

        echo ""
        echo "0). Finish"
        echo ""

        read -r -p "Select Policy: " CHOICE

        if [[ "$CHOICE" == "0" ]]; then
            break
        fi

        if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
           [ "$CHOICE" -lt 1 ] ||
           [ "$CHOICE" -gt "${#POLICY_NAMES[@]}" ]
        then
            echo "[ERROR] Invalid choice"
            sleep 1
            continue
        fi

        INDEX=$((CHOICE-1))

        if aws iam detach-group-policy \
            --group-name "$SELECTED_GROUP" \
            --policy-arn "${POLICY_ARNS[$INDEX]}"
        then
            echo ""
            echo "[OK] ${POLICY_NAMES[$INDEX]} detached."

            unset 'POLICY_NAMES[$INDEX]'
            unset 'POLICY_ARNS[$INDEX]'

            POLICY_NAMES=("${POLICY_NAMES[@]}")
            POLICY_ARNS=("${POLICY_ARNS[@]}")
        else
            echo ""
            echo "[ERROR] Failed."
        fi

        if [ ${#POLICY_NAMES[@]} -eq 0 ]; then
            echo ""
            echo "[INFO] No policies remaining."
            break
        fi

        sleep 1
    done
}
