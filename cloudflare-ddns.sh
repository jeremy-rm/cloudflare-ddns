#!/bin/bash

# Make certain this script is chmod 700.

# API Token - Requires DNS:Edit permission for the zone, nothing else.
TOKEN=""

# Zone
ZONE="example.com"

# Name/IP Pairs
typeset -A RECORDS=(
	["subdomain1.example.com"]="10.10.10.1"
	["subdomain2.example.com"]="$(curl https://ifconfig.me/ip)"
)

# --- END OF CONFIG

# Step 1: Get ID for $ZONE. This is shown in the dashboard, but it's better to retrieve via API.
ZONEID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE&status=active" \
	-H "Authorization: Bearer $TOKEN" \
	-H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

# Step 2: For each name/ip pair in RECORDS, do the following:
for RECORD in "${!RECORDS[@]}"
do

	echo "$RECORD -> ${RECORDS[$RECORD]}"

	# Step 2.1: Get ID for $RECORD. This is not shown in the dashboard and must be retrieved via API.
	RECORDID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records?type=A&name=$RECORD" \
		-H "Authorization: Bearer $TOKEN" \
		-H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

	# Step 2.2: API request to update $RECORD.
	curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$RECORDID" \
		-H "Authorization: Bearer $TOKEN" \
		-H "Content-Type: application/json" \
		--data "{\"type\":\"A\",\"name\":\"$RECORD\",\"content\":\"${RECORDS[$RECORD]}\",\"ttl\":1,\"proxied\":false}" | jq

done
