#!/bin/bash

main_menu() {

while true
do
    clear

    echo "=============================="
    echo "   AWS MANAGEMENT CONSOLE"
    echo "=============================="
    echo ""
    echo "Current User : $(current_identity)"
    echo "Region       : $AWS_REGION"
    echo ""
    echo "1. EC2"
    echo "2. S3"
    echo "3. IAM"
    echo "4. VPC"
    echo ""
    echo "5. Login"
    echo "6. Logout"
    echo "7. Change Region"
    echo ""
    echo "0. Exit"
    echo ""

    read -r -p "Select: " choice

    case "$choice" in
        1) ec2_menu ;;
        2) s3_menu ;;
        3) iam_menu ;;
        4) vpc_menu ;;
        5) login ;;
        6) logout ;;
        7) select_region ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac

done

}

ec2_menu() {

while true
do
    clear

    echo "=============================="
    echo "          EC2 MENU"
    echo "=============================="
    echo ""

    echo "1. Create Instance"
    echo "2. List Instances"
    echo "3. Instance Details"
    echo "4. Start Instance"
    echo "5. Stop Instance"
    echo "6. Reboot Instance"
    echo "7. Terminate Instance"
    echo ""
    echo "------------------------------------------"
    echo "KEY PAIRS"
    echo "------------------------------------------"
    echo "8. Create Key Pair"
    echo "9. List Key Pairs"
    echo ""
    echo "------------------------------------------"
    echo "SETTINGS"
    echo "------------------------------------------"
    echo "10. SSH Into Instance"
    echo ""

    echo "0. Exit"
    echo ""

    read -r -p "Select: " choice

    case "$choice" in

        1) create_instance ;;
        2) list_instances ;;
        3) instance_details ;;
        4) start_instance ;;
        5) stop_instance ;;
        6) reboot_instance ;;
        7) terminate_instance ;;
        8) create_keypair ;;
        9) list_keypairs ;;
        10) ssh_instance ;;

        0) break ;;

        *) echo "Invalid option" ;;

    esac

    echo ""
    read -r -p "Press Enter to continue..."

done

}

s3_menu() {

while true
do
    clear

    echo "=============================="
    echo "          S3 MENU"
    echo "=============================="
    echo ""

    echo "1. Create Bucket"
    echo "2. List Buckets"
    echo "3. Delete Bucket"
    echo ""
    echo "4. Upload Objects"
    echo "5. Download Objects"
    echo "6. Delete Objects"
    echo "7. List Objects"

    echo ""
    echo "0. Back"
    echo ""

    read -r -p "Select: " choice

    case "$choice" in

        1) create_bucket ;;
        2) list_buckets ;;
        3) delete_bucket ;;
        4) upload_file ;;
        5) download_file ;;
        6) delete_object ;;
        7) list_objects ;;
        0) break ;;

        *) echo "Invalid option" ;;

    esac

    echo ""
    read -r -p "Press Enter to continue..."

done

}

iam_menu() {

while true
do
    clear

    echo "=============================="
    echo "          IAM MENU"
    echo "=============================="
    echo ""
    echo "-----USERS-------"
    echo "1. Create User"
    echo "2. List User"
    echo "3. Delete User"
    echo ""
    echo "----ACCESS KEY----"
    echo "4. Create Access Key"
    echo "5. List  Access Key"
    echo "6. Delete Access Key"
    echo ""
    echo "----IAM_GROUPS----"
    echo "7. Create Group"
    echo "8. List Group"
    echo "9. Delete Group"
    echo ""
    echo "----MEMBERSHIP----"
    echo "10. Add User to Group"
    echo "11. Remove User from Group"
    echo ""
    echo "----POLICIES----"
    echo "12. Attach Policies"
    echo "13. List Attached Policies"
    echo "14. Detach Policies"

    echo "0. Back"
    echo ""

    read -r -p "Select: " choice

    case "$choice" in

        1) create_user ;;
        2) list_users ;;
        3) delete_user ;;
        4) create_access_key ;;
        5) list_access_keys ;;
        6) delete_access_key ;;
        7) create_group ;;
        8) list_groups ;;
        9) delete_group ;;

        10) add_user_to_group ;;
        11) remove_user_from_group ;;
        12) attach_policy ;;
        13) list_policies ;;
        14) detach_policy ;;
        0) break ;;

        *) echo "Invalid option" ;;

    esac

    echo ""
    read -r -p "Press Enter to continue..."

done
}

