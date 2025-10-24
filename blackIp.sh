#!/bin/bash

LOG_FILE="/var/log/secure*"
TEMP_IP_FILE="/tmp/blocked_ips.txt"
HOSTS_DENY="/etc/hosts.deny"

grep "Failed password" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq > "$TEMP_IP_FILE"
grep "refused connect" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq >> "$TEMP_IP_FILE"
grep "Did not receive identification string" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq >> "$TEMP_IP_FILE"
grep "Bad protocol version identification" $LOG_FILE | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq >> "$TEMP_IP_FILE"

cat $TEMP_IP_FILE |wc -l

if [ ! -f "$HOSTS_DENY" ]; then
    sudo touch "$HOSTS_DENY"
    sudo chmod 644 "$HOSTS_DENY"
fi

echo "updating ..."
while IFS= read -r ip; do
    if ! grep -q "sshd: $ip" "$HOSTS_DENY"; then
        echo "sshd: $ip" | sudo tee -a "$HOSTS_DENY" > /dev/null
        echo "Blocked New IP: $ip"
    fi
done < "$TEMP_IP_FILE"
rm -f "$TEMP_IP_FILE"
echo "done"
