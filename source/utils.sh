#!/bin/bash

DATA_FILE="./data.txt"
PAGES_FILE="./pages.txt"

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

menu() {
    local page_name="$1"

    # Use awk with state machine: toggle block capture on each "###"
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

    # ---- Display goes to stderr (>&2) ----
    echo "--------------------------" >&2
    echo "      ETHIO TELECOM       " >&2
    echo "  Balance: $(get_balance) Br. " >&2
    echo "--------------------------" >&2

    for i in "${!opt_array[@]}"; do
        echo "$((i+1)). $(echo "${opt_array[$i]}" | xargs)" >&2
    done
    echo "--------------------------" >&2
    
    read -p "Selection: " choice >&2
    
    choice=$(echo "$choice" | xargs)
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#opt_array[@]}" ]; then
        # ---- Only the action is printed to stdout ----
        echo "${act_array[$((choice-1))]}" | xargs
    else
        echo "INVALID"
    fi
}