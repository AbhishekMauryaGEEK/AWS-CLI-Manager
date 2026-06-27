CURRENT_USER="Guest"
ACCOUNT_ID="N/A"
login() {

    echo ""
    read -r -p "Access Key ID: " ACCESS_KEY

    echo ""
    read -rs -p "Secret Access Key: " SECRET_KEY
    echo ""

    mkdir -p ~/.aws

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
IDENTITY=$(
    aws sts get-caller-identity 2>/dev/null
)

if [ $? -eq 0 ]; then

    ACCOUNT_ID=$(echo "$IDENTITY" | jq -r '.Account')
    ARN=$(echo "$IDENTITY" | jq -r '.Arn')

    if [[ "$ARN" == *":root" ]]; then
        CURRENT_USER="Root"
    else
        CURRENT_USER=$(basename "$ARN")
    fi

    echo ""
    echo "[OK] Login Successful"

else

    CURRENT_USER="Guest"
    ACCOUNT_ID="N/A"

    echo ""
    echo "[ERROR] Invalid Credentials"

fi

}
load_session() {

    IDENTITY=$(
        aws sts get-caller-identity 2>/dev/null
    )

    if [ $? -ne 0 ]; then
        CURRENT_USER="Guest"
        ACCOUNT_ID="N/A"
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

    if [ "$CURRENT_USER" = "Guest" ]; then
        echo ""
        echo "[INFO] No active session."
        return
    fi

    echo ""
    echo "================================="
    echo "          LOGOUT"
    echo "================================="
    echo ""
    echo "Current User : $CURRENT_USER"
    echo ""
    read -r -p "Type LOGOUT to continue: " CONFIRM

    if [ "$CONFIRM" != "LOGOUT" ]; then
        echo ""
        echo "[INFO] Logout cancelled."
        return
    fi

    rm -f ~/.aws/credentials

    cat > ~/.aws/config <<EOF
[default]
region=$AWS_REGION
output=json
EOF

    CURRENT_USER="Guest"
    ACCOUNT_ID="N/A"

    echo ""
    echo "[OK] Logged out successfully."
}
current_identity() {
 echo "$CURRENT_USER"
}

check_session() {

    if aws sts get-caller-identity >/dev/null 2>&1
    then
        return
    fi

    echo ""
    echo "[INFO] No Active Session"
}

