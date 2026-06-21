#!/bin/bash

main_menu() {

while true
do
    clear

    echo "=============================="
    echo "  →_→  AWS EC2 MANAGER "
    echo "=============================="
    echo ""
    echo "ENTER THE NUMBER TO GET THE SERVICE"
    echo ""
    echo "------------------------------------------"
    echo "EC2 MANAGEMENT"
    echo "------------------------------------------"
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
    echo "10. Change Region"
    echo "11. SSH Into Instance"
    echo ""

    echo "0. Exit"
    echo ""

    read -p "Select: " choice

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

        10) select_region ;;
        11) ssh_instance ;;

        0) exit 0 ;;

        *) echo "Invalid option" ;;

    esac

    echo ""
    read -p "Press Enter to continue..."
done

}
