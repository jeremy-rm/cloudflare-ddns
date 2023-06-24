#!/bin/bash

# Make certain this script is chmod 700.

# API Token - Requires DNS:Edit permission for applicable zones, nothing else.
TOKEN=""

# System IP Address
IP="$(curl -s https://ifconfig.me/ip)"

echo
echo "--- cloudflare-ddns, ${IP}: $(date)"

# DNS Records
# Tab-delimited, including ZONE, TYPE, NAME, CONTENT and PROXY status.
declare -a RECORDS

#          ZONE                 TYPE    NAME                    CONTENT         PROXY
RECORDS+=("example1.com         A       example1.com            $IP             true")
RECORDS+=("example1.com         CNAME   www.example1.com        $IP             true")

#
# -- END OF CONFIGURATION
#

for RECORDIDX in "${RECORDS[@]}"
do

        IFS=$'\t' read -r -a RECORD <<< "${RECORDIDX}"
        ZONE="${RECORD[0]}"
        TYPE="${RECORD[1]}"
        NAME="${RECORD[2]}"
        CONTENT="${RECORD[3]}"
        PROXIED="${RECORD[4]}"

        # Step 1: Get ID for record $ZONE.
        ZONEID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE&status=active" \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

        echo "  * zone: ${ZONE}, id: ${ZONEID}"

        # Step 2: Get ID for record $NAME.
        NAMEID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records?type=$TYPE&name=$NAME" \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

        echo "  * name: ${NAME}, id: ${NAMEID}"

        # Step 3: API request to update record $NAME.
        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$NAMEID" \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"$TYPE\",\"name\":\"$NAME\",\"content\":\"$CONTENT\",\"ttl\":1,\"proxied\":$PROXIED}" | jq

        # Whew, rest.
        sleep 1

done

echo "--- update complete"
echo
