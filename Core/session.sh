login() {

    clear

    echo "================================="
    echo "            LOGIN"
    echo "================================="
    echo ""

    #
    # Check for existing session
    #
    if [ "$CURRENT_USER" != "Guest" ]; then
        echo "[ERROR] An active AWS session already exists."
        echo ""
        echo "Current User : $CURRENT_USER"
        echo "Account ID   : $ACCOUNT_ID"
        echo ""
        echo "[INFO] Please logout before logging in with another account."
        return
    fi

    #
    # Read Credentials
    #
    read -r -p "Access Key ID     : " ACCESS_KEY

    echo ""
    read -rs -p "Secret Access Key : " SECRET_KEY
    echo ""

    #
    # Validate Input
    #
    if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
        echo ""
        echo "[ERROR] Access Key and Secret Key cannot be empty."
        return
    fi

    mkdir -p ~/.aws

    #
    # Backup Existing Credentials (if any)
    #
    if [ -f ~/.aws/credentials ]; then
        cp ~/.aws/credentials ~/.aws/credentials.bak
    fi

    #
    # Write New Credentials
    #
    cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=$ACCESS_KEY
aws_secret_access_key=$SECRET_KEY
EOF

    cat > ~/.aws/config <<EOF
[default]
region=$AWS_REGION
output=json
EOF

    echo ""
    echo "[INFO] Validating AWS Credentials..."
    echo ""

    #
    # Validate Credentials
    #
    if ! aws sts get-caller-identity >/dev/null 2>&1; then

        echo "[ERROR] Invalid AWS Credentials."

        #
        # Restore Previous Session
        #
        if [ -f ~/.aws/credentials.bak ]; then
            mv ~/.aws/credentials.bak ~/.aws/credentials
            load_session
            echo ""
            echo "[INFO] Previous session restored."
        else
            rm -f ~/.aws/credentials
            load_session
        fi

        return
    fi

    #
    # Login Successful
    #
    rm -f ~/.aws/credentials.bak

    load_session

    echo ""
    echo "[OK] Login Successful."
    echo ""
    echo "================================="
    echo "        SESSION ACTIVE"
    echo "================================="
    echo "User       : $CURRENT_USER"
    echo "Account ID : $ACCOUNT_ID"
    echo "Region     : $AWS_REGION"
    echo "================================="
}

load_session() {

    CURRENT_USER="Guest"
    ACCOUNT_ID="N/A"

    IDENTITY=$(
        aws sts get-caller-identity 2>/dev/null
    )

    if [ $? -ne 0 ]; then
        return
    fi

    ACCOUNT_ID=$(echo "$IDENTITY" | jq -r '.Account')
    ARN=$(echo "$IDENTITY" | jq -r '.Arn')

    if [[ "$ARN" == *":root" ]]; then
        CURRENT_USER="Root"
    else
        CURRENT_USER=$(basename "$ARN")
    fi
}

logout() {

    clear

    echo "================================="
    echo "           LOGOUT"
    echo "================================="
    echo ""

    #
    # Check for Active Session
    #
    if [ "$CURRENT_USER" = "Guest" ]; then
        echo "[INFO] No active AWS session found."
        return
    fi

    echo "Current User : $CURRENT_USER"
    echo "Account ID   : $ACCOUNT_ID"
    echo ""

    read -r -p "Type LOGOUT to continue: " CONFIRM

    if [ "$CONFIRM" != "LOGOUT" ]; then
        echo ""
        echo "[INFO] Logout cancelled."
        return
    fi

    echo ""
    echo "[INFO] Logging out..."

    #
    # Remove Credentials
    #
    rm -f ~/.aws/credentials

    #
    # Keep AWS Config
    #
    mkdir -p ~/.aws

    cat > ~/.aws/config <<EOF
[default]
region=$AWS_REGION
output=json
EOF

    #
    # Refresh Session
    #
    load_session

    echo ""
    echo "[OK] Logout Successful."
    echo ""
    echo "================================="
    echo "       SESSION CLOSED"
    echo "================================="
    echo "Current User : $CURRENT_USER"
    echo "================================="
}

current_identity() {
    echo "$CURRENT_USER"
}

check_session() {

    if [ "$CURRENT_USER" = "Guest" ]; then
        echo ""
        echo "[ERROR] No active AWS session."
        echo "[INFO] Please login to continue."
        return 1
    fi

    return 0
}
