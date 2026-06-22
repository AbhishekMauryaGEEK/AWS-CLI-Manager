#!/bin/bash

select_region() {

    echo ""
    echo "Select AWS Region"
    echo "1) ap-south-1 (Mumbai)"
    echo "2) us-east-1 (N. Virginia)"
    echo "3) us-west-2 (Oregon)"
    echo "4) eu-west-1 (Ireland)"
    echo ""

    read -r -p "Choice: " choice

    case "$choice" in
        1) AWS_REGION="ap-south-1" ;;
        2) AWS_REGION="us-east-1" ;;
        3) AWS_REGION="us-west-2" ;;
        4) AWS_REGION="eu-west-1" ;;
        *) AWS_REGION="ap-south-1" ;;
    esac

    echo ""
    aws configure set region "$AWS_REGION"
    echo "[OK] Region set to: $AWS_REGION"
}
