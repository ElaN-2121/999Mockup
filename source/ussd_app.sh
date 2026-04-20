#!/bin/bash

source ./utils.sh


if [ ! -f "$DATA_FILE" ]; then
    echo "balance: 500" > "$DATA_FILE"
fi

current_page="main"

while true; do
    action=$(menu "$current_page")

    case "$action" in
        GO:*)
            current_page="${action#GO:}"
            ;;
        SHOW:*)
            echo -e "\n--- MESSAGE ---"
            echo "${action#SHOW:}"
            read -p "Press Enter to return..."
            ;;
        BUY:*)
            price=$(echo "$action" | cut -d':' -f2)
            desc=$(echo "$action" | cut -d':' -f3)
            if deduct_balance "$price"; then
                new_balance=$(get_balance)
                log_transaction "$price" "$desc" "$new_balance"
                echo -e "\nPurchase Successful: $desc ($price Birr)"
            else
                echo -e "\nError: Your balance is too low."
            fi
            read -p "Press Enter..."
            current_page="main"
            ;;
        BAL:check)
            echo -e "\n--- BALANCE ---"
            echo "Your current balance is: $(get_balance) Birr"
            read -p "Press Enter to return..."
            ;;
        HIST:show)
            echo -e "\n--- TRANSACTION HISTORY ---"
            show_history
            read -p "Press Enter to return..."
            ;;
        EXIT:*)
            echo "Thank you for using Ethio Telecom!"
            exit 0
            ;;
        *)
            echo -e "\nInvalid selection. Please try again."
            sleep 1
            ;;
    esac
done