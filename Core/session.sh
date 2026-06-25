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

    if aws sts get-caller-identity >/dev/null 2>&1
    then
        echo ""
        echo "[OK] Login Successful"
    else
        echo ""
        echo "[ERROR] Invalid Credentials"
    fi
}

logout() {

    rm -f ~/.aws/credentials

    cat > ~/.aws/config <<EOF
[default]
region=$AWS_REGION
output=json
EOF

    echo ""
    echo "[OK] Logged Out"
}

current_identity() {

    ARN=$(aws sts get-caller-identity \
        --query Arn \
        --output text 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "Guest"
        return
    fi

    if [[ "$ARN" == *":root" ]]; then
        echo "Root"
    else
        basename "$ARN"
    fi
}

check_session() {

    if aws sts get-caller-identity >/dev/null 2>&1
    then
        return
    fi

    echo ""
    echo "[INFO] No Active Session"
}

