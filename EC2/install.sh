#!/bin/bash

error_exit() {
    echo ""
    echo "[ERROR] $1"
    exit 1
}

pause() {
    echo ""
    read -p "Press Enter to continue..."
}

detect_os() {

    case "$(uname -s)" in
        Linux*)
            OS="linux"
            ;;
        Darwin*)
            OS="macos"
            ;;
        *)
            OS="unknown"
            ;;
    esac
}

install_aws_linux() {

    echo "[INFO] Installing AWS CLI..."

    sudo apt update || true
    sudo apt install -y curl unzip

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        -o "awscliv2.zip"

    unzip -o awscliv2.zip

    sudo ./aws/install --update
}

install_aws_macos() {

    echo "[INFO] Installing AWS CLI..."

    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" \
        -o AWSCLIV2.pkg

    sudo installer -pkg AWSCLIV2.pkg -target /
}

check_aws_cli() {

    if command -v aws >/dev/null 2>&1; then
        echo "[OK] AWS CLI found"
        return
    fi

    echo ""
    echo "AWS CLI not found."
    read -p "Install AWS CLI? (y/n): " ans

    [[ "$ans" != "y" ]] && error_exit "AWS CLI required"

    detect_os

    case "$OS" in

        linux)
            install_aws_linux
            ;;

        macos)
            install_aws_macos
            ;;

        *)
            error_exit "Unsupported operating system"
            ;;
    esac

    command -v aws >/dev/null 2>&1 \
        || error_exit "AWS CLI installation failed"

    echo "[OK] AWS CLI installed"
}
