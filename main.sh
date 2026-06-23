#!/bin/bash

source ./Core/config.sh
source ./Core/install.sh
source ./Core/auth.sh
source ./Core/regions.sh

source ./EC2/keypairs.sh
source ./EC2/instances.sh
source ./EC2/create_instance.sh

source ./S3/buckets.sh

source ./menu.sh

check_aws_cli
check_credentials
select_region

main_menu
