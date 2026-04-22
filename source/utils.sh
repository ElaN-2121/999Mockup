#!/bin/bash

DATA_FILE="./data.txt"
PAGES_FILE="./pages.txt"
HISTORY_FILE="./history.txt"

get_balance() {
    if [ ! -f "$DATA_FILE" ]; then
        echo "500"
        return
    fi
    grep "balance:" "$DATA_FILE" | awk '{print $2}' | tr -d '\r'
}

deduct_balance() {
    local amount=$1
    local current=$(get_balance)
    if (( current < amount )); then
        return 2
    fi
    local new_bal=$((current - amount))
    echo "balance: $new_bal" > "$DATA_FILE"
    return 0
}

log_transaction() {
    local price="$1"
    local desc="$2"
    local balance_after="$3"

    local pkg_type=""
    if [[ "$desc" =~ _Daily$ || "$desc" =~ Daily$ ]]; then
        pkg_type="Daily"
    elif [[ "$desc" =~ _Weekly$ || "$desc" =~ Weekly$ ]]; then
        pkg_type="Weekly"
    elif [[ "$desc" =~ _Monthly$ || "$desc" =~ Monthly$ ]]; then
        pkg_type="Monthly"
    else
        pkg_type="Other"
    fi

    local pkg_name="${desc%_Daily}"
    pkg_name="${pkg_name%_Weekly}"
    pkg_name="${pkg_name%_Monthly}"

    local datetime=$(date "+%Y-%m-%d %H:%M:%S")
    local line="[$datetime, $pkg_type, $pkg_name, $price, $balance_after]"
    echo "$line" >> "$HISTORY_FILE"
}

show_history() {
    if [ ! -f "$HISTORY_FILE" ]; then
        echo "No transactions yet."
        return
    fi

    echo "Date                 | Time     | Type    | Package         | Price | Balance"
    echo "---------------------|----------|---------|-----------------|-------|--------"

    while IFS= read -r line; do
        line="${line#[}"
        line="${line%]}"

        IFS=',' read -r datetime type name price balance <<< "$line"

        datetime=$(echo "$datetime" | xargs)
        type=$(echo "$type" | xargs)
        name=$(echo "$name" | xargs)
        price=$(echo "$price" | xargs)
        balance=$(echo "$balance" | xargs)

        date=$(echo "$datetime" | cut -d' ' -f1)
        time=$(echo "$datetime" | cut -d' ' -f2)
        printf "%-19s | %-8s | %-7s | %-15s | %5s | %7s\n" "$date" "$time" "$type" "$name" "$price" "$balance"
    done < "$HISTORY_FILE"

    echo "---------------------|----------|---------|-----------------|-------|--------"
}

confirm_purchase() {
    local price="$1"
    local desc="$2"
    local current_bal="$3"

    echo -e "\n--- CONFIRM PURCHASE ---"
    echo "Package : $desc"
    echo "Price   : $price Birr"
    echo "Balance : $current_bal Birr"
    read -p "Press 1 to confirm, any other key to cancel: " choice
    [ "$choice" = "1" ]
}


menu() {
    local page_name="$1"

    local block=$(awk -v name="$page_name" '
        /^###$/ { in_block = !in_block; if (!in_block && block ~ "name: "name) print block; block=""; next }
        in_block { block = block $0 "\n" }
    ' "$PAGES_FILE")

    if [ -z "$block" ]; then
        echo "ERROR: Could not find page '$page_name' in $PAGES_FILE" >&2
        exit 1
    fi

    local opt_str=$(echo "$block" | grep "options =" | cut -d'[' -f2 | cut -d']' -f1 | tr -d '\r')
    local act_str=$(echo "$block" | grep "actions =" | cut -d'[' -f2 | cut -d']' -f1 | tr -d '\r')

    IFS=',' read -r -a opt_array <<< "$opt_str"
    IFS=',' read -r -a act_array <<< "$act_str"

    if [ ${#opt_array[@]} -eq 0 ]; then
        echo "ERROR: Page '$page_name' has no options." >&2
        exit 1
    fi

    echo "--------------------------" >&2
    echo "      ETHIO TELECOM       " >&2
    echo "--------------------------" >&2

    for i in "${!opt_array[@]}"; do
        echo "$((i+1)). $(echo "${opt_array[$i]}" | xargs)" >&2
    done
    echo "--------------------------" >&2
    
    read -p "Choice: " choice >&2
    
    choice=$(echo "$choice" | xargs)
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#opt_array[@]}" ]; then
        echo "${act_array[$((choice-1))]}" | xargs
    else
        echo "INVALID"
    fi
}