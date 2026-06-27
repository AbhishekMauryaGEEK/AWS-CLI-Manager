#!/bin/bash

source ./Core/config.sh
source ./Core/install.sh
source ./Core/auth.sh
source ./Core/regions.sh
source ./Core/session.sh

source ./EC2/keypairs.sh
source ./EC2/instances.sh
source ./EC2/create_instance.sh

source ./S3/buckets.sh

source ./IAM/users.sh

source ./VPC/vpcs.sh
source ./VPC/subnets.sh
source ./VPC/internet_gateway.sh
source ./VPC/route_tables.sh

source ./menu.sh

check_aws_cli
check_credentials
load_session
select_region

main_menu
