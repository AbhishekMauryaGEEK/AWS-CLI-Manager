#!/bin/bash

source ./config.sh
source ./install.sh
source ./auth.sh
source ./regions.sh
source ./keypairs.sh
source ./instances.sh
source ./create_instance.sh
source ./menu.sh

check_aws_cli
check_credentials
select_region

main_menu
