#!/usr/bin/bash

proxy_path="$HOME/.cache/proxy"

proxy_now=$(curl http://127.0.0.1:9090/proxies/Proxies | jq -r '.now')

echo "$proxy_now" > "$proxy_path"
