#!/bin/bash

api_domain="bash.ws"

status_code=$(curl -s -I -X GET -o /dev/null -w "%{http_code}\n" "https://${api_domain}")
if [ "$status_code" -ne 200 ]; then
    echo_error "No internet connection."
    exit 1
fi

test_id=$(curl -s "https://${api_domain}/id")

echo "Test ID: $test_id"

echo ""
for i in $(seq 1 20); do
    echo "Sending request to ex.${i}.${test_id}.${api_domain}..."
    curl -s --connect-timeout 0.5 "https://ex.${i}.${test_id}.${api_domain}/css/z.css?_=$(date +%s%3N)" &> /dev/null
done

sleep 1
results=$(curl -s "https://${api_domain}/dnsleak/test/${test_id}?txt")

function print_servers {
    while IFS= read -r line; do
        if [[ "$line" != *${1} ]]; then
            continue
        fi

        ip=$(echo "$line" | cut -d'|' -f 1)
        country=$(echo "$line" | cut -d'|' -f 3)
        asn=$(echo "$line" | cut -d'|' -f 4)

        if [ -z "${ip// }" ]; then
             continue
        fi

        if [ -z "${country// }" ]; then
             echo "$ip"
        else
             if [ -z "${asn// }" ]; then
                 echo "$ip [$country]"
             else
                 echo "$ip [$country, $asn]"
             fi
        fi
    done <<< "$results"
}

echo ""
echo "Your IP:"
print_servers "ip"

echo ""
dns_count=$(print_servers "dns" | wc -l)
if [ "$dns_count" -eq "0" ];then
    echo "No DNS servers found"
else
    if [ "$dns_count" -eq "1" ];then
        echo "You use ${dns_count} DNS server:"
    else
        echo "You use ${dns_count} DNS servers:"
    fi
    print_servers "dns"
fi

echo ""
echo "Conclusion:"
print_servers "conclusion"
