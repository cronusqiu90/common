#!/bin/bash

LOG_FILE="/var/log/secure*"
IPSET_NAME="blacklist"
BLACKLIST_FILE="/opt/blacklist.txt"

update_black_ips(){
        echo ">> Updating blacklist"
        grep "Failed password" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq > $BLACKLIST_FILE
        grep "refused connect" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq >> $BLACKLIST_FILE
        grep "Did not receive identification string" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq >> $BLACKLIST_FILE
        grep "Bad protocol version identification" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq >> $BLACKLIST_FILE
        grep "Invalid user" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq >> $BLACKLIST_FILE
}

cmd_init() {
    echo ">> Initializing blacklist rules"
    firewall-cmd --permanent --delete-ipset="$IPSET_NAME" 2>/dev/null
    firewall-cmd --permanent --new-ipset="$IPSET_NAME" --type=hash:ip
    grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$BLACKLIST_FILE" | sort -u > /tmp/fw_ips_clean.txt
    if [ -s /tmp/fw_ips_clean.txt ]; then
        firewall-cmd --permanent --ipset="$IPSET_NAME" --add-entries-from-file=/tmp/fw_ips_clean.txt
        echo ">> Imported $(wc -l < /tmp/fw_ips_clean.txt) IPs."
    fi
    rm -rf /tmp/fw_ips_clean.txt
    RULE='rule family="ipv4" source ipset="'"$IPSET_NAME"'" drop'
    if ! firewall-cmd --permanent --list-rich-rules | grep -q "$RULE"; then
        firewall-cmd --permanent --add-rich-rule="$RULE"
        echo ">> Added drop rule."
    fi
    firewall-cmd --reload
    echo ">> Completed"
}

cmd_update() {
    echo ">> Updating blacklist (Add only)..."
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    firewall-cmd --info-ipset="$IPSET_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u > "$TEMP_DIR/current.txt" || touch "$TEMP_DIR/current.txt"
    grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$BLACKLIST_FILE" | sort -u > "$TEMP_DIR/file.txt"
    comm -13 "$TEMP_DIR/current.txt" "$TEMP_DIR/file.txt" > "$TEMP_DIR/to_add.txt"
    ADD_COUNT=$(wc -l < "$TEMP_DIR/to_add.txt")
    if [ "$ADD_COUNT" -eq 0 ]; then
        echo ">> No new IPs to add."
        return
    fi
    echo ">> Adding $ADD_COUNT new IPs..."
    while read -r ip; do
        firewall-cmd --ipset="$IPSET_NAME" --add-entry="$ip" 2>/dev/null
    done < "$TEMP_DIR/to_add.txt"
    firewall-cmd --runtime-to-permanent
    echo ">> Completed"
}

update_black_ips
case "$1" in
    init)
        cmd_init
        ;;
    update)
        cmd_update
        ;;
    *)
        echo "Usage: $0 {init|update}"
        exit 1
        ;;
esac
