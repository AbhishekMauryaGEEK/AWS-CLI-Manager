#!/bin/bash

select_bucket() {

    mapfile -t BUCKETS < <(
        aws s3api list-buckets \
        --query 'Buckets[].Name' \
        --output text | tr '\t' '\n'
    )

    if [ ${#BUCKETS[@]} -eq 0 ]; then
        echo ""
        echo "[INFO] No buckets found"
        return 1
    fi

    echo ""
    echo "================================="
    echo "      AVAILABLE BUCKETS"
    echo "================================="
    echo ""

    for i in "${!BUCKETS[@]}"
    do
        echo "$((i+1))). ${BUCKETS[$i]}"
    done

    echo ""

    read -r -p "Choose Bucket: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#BUCKETS[@]}" ]
    then
       echo "[ERROR] Invalid choice"
       return 1
    fi

    SELECTED_BUCKET="${BUCKETS[$((CHOICE-1))]}"

    echo ""
    echo "[INFO] Selected: $SELECTED_BUCKET"

    return 0
}

list_bucket_objects() {

    if ! aws s3 ls "s3://$SELECTED_BUCKET" | grep -q .
    then
        echo "[INFO] Bucket is empty"
        return 1
    fi

    aws s3 ls "s3://$SELECTED_BUCKET"
}

select_object() {

    mapfile -t OBJECTS < <(
        aws s3api list-objects-v2 \
        --bucket "$SELECTED_BUCKET" \
        --query 'Contents[].Key' \
        --output text
    )

    if [ ${#OBJECTS[@]} -eq 0 ]; then
        echo "[INFO] Bucket is empty"
        return 1
    fi

    echo ""
    echo "================================="
    echo "      OBJECTS IN BUCKET"
    echo "================================="
    echo ""

    for i in "${!OBJECTS[@]}"
    do
        echo "$((i+1))). ${OBJECTS[$i]}"
    done

    echo ""

    read -r -p "Choose Object: " CHOICE

    SELECTED_OBJECT="${OBJECTS[$((CHOICE-1))]}"
}

create_bucket() {

    echo ""
    read -r -p "Bucket Name Prefix: " BUCKET_PREFIX

    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
    BUCKET_NAME="${BUCKET_PREFIX}-${TIMESTAMP}"

    echo ""
    echo "[INFO] Creating bucket: $BUCKET_NAME"

    if aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" >/dev/null 2>&1
    then
      echo ""
      echo "================================="
      echo "       BUCKET CREATED"
      echo "================================="
      echo ""
      echo "Bucket Name : $BUCKET_NAME"
      echo "Region      : $AWS_REGION"
      echo "Created At  : $TIMESTAMP"
    else
        echo "[ERROR] Failed to create bucket"
    fi
}

list_buckets() {

    echo ""
    echo "================================="
    echo "      AVAILABLE BUCKETS"
    echo "================================="
    echo ""

    aws s3 ls

    echo ""
    echo "Region: $AWS_REGION"
    echo ""
}

delete_bucket() {

    select_bucket || return

    echo ""
    echo "Bucket: $SELECTED_BUCKET"

    read -r -p "Type DELETE to continue: " CONFIRM

    if [[ "$CONFIRM" != "DELETE" ]]; then
        echo "[INFO] Cancelled"
        return
    fi

    if aws s3 rb "s3://$SELECTED_BUCKET"
    then
       echo ""
       echo "================================="
       echo "       BUCKET DELETED"
       echo "================================="
       echo ""
       echo "Bucket : $SELECTED_BUCKET"
    else
        echo "[ERROR] Bucket not empty or delete failed"
    fi
}

upload_file() {

    select_bucket || return

    echo ""

    read -r -p "Local File Path: " FILE_PATH

    echo ""
    echo "[INFO] Uploading to: $SELECTED_BUCKET"
    if [ ! -f "$FILE_PATH" ]; then
      echo "[ERROR] File not found"
      return 1
    fi
    if aws s3 cp "$FILE_PATH" "s3://$SELECTED_BUCKET/"
    then
        echo ""
        echo "================================="
        echo "       UPLOAD COMPLETE"
        echo "================================="
        echo ""
        echo "Bucket : $SELECTED_BUCKET"
        echo "File   : $(basename "$FILE_PATH")" 
    else
        echo ""
        echo "[ERROR] Upload failed"
    fi
}

download_file() {

    select_bucket || return

    echo ""
    echo "================================="
    echo "      OBJECTS IN BUCKET"
    echo "================================="
    echo ""

    list_bucket_objects || return

    echo ""

    read -r -p "Object Key: " OBJECT_KEY
    if [ -z "$OBJECT_KEY" ]; then
        echo "[ERROR] Object key required"
        return 1
    fi
    read -r -p "Download Path: " DOWNLOAD_PATH

    if aws s3 cp \
        "s3://$SELECTED_BUCKET/$OBJECT_KEY" \
        "$DOWNLOAD_PATH"
    then
        echo ""
        echo "[OK] Download completed"
    else
        echo ""
        echo "[ERROR] Download failed"
    fi
}

list_objects() {

    select_bucket || return

    echo ""
    echo "================================="
    echo "      OBJECTS IN BUCKET"
    echo "================================="
    echo ""

    list_bucket_objects || return

    echo ""
    echo "[INFO] Bucket: $SELECTED_BUCKET"
}

delete_object() {

    select_bucket || return
    select_object || return

    echo ""
    echo "Object: $SELECTED_OBJECT"

    read -r -p "Delete object? (y/n): " CONFIRM

    [[ "$CONFIRM" != "y" ]] && return

    aws s3 rm \
      "s3://$SELECTED_BUCKET/$SELECTED_OBJECT"
}
