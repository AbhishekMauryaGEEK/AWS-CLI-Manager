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

