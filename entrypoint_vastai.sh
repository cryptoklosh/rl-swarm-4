#!/bin/bash

#-------------------------------------------------------------------
# FRP
#-------------------------------------------------------------------
start_tunnel() {
    mkdir /home/gensyn/frpc-tmp
    curl -L https://github.com/fatedier/frp/releases/download/v0.63.0/frp_0.63.0_linux_amd64.tar.gz | tar -xz --strip-components=1 -C /home/gensyn/frpc-tmp
    cp /home/gensyn/frpc-tmp/frpc /home/gensyn/frpc/frpc
    chmod +x /home/gensyn/frpc/frpc
    export LOCAL_IP="localhost"
    export LOCAL_PORT="3000"
    export PROXY_HASH=$(echo -n "${NODE_ID}${LOCAL_IP}${LOCAL_PORT}${NODE_PROXY_SALT}" | md5sum | cut -d ' ' -f1)
    export PROXY_URL="${PROXY_HASH}.${NODE_PROXY_URL}"
    # export NODE_PROXY_URL=${NODE_PROXY_URL}
    export NODE_PROXY_PORT=${NODE_PROXY_PORT:-7000}

    echo -n "https://${PROXY_URL}" > /home/gensyn/frpc/link
    while true; do
        /home/gensyn/frpc/entrypoint --config /home/gensyn/rl_swarm/frp/config.toml 2>&1 | tee -a /home/gensyn/frpc/log.log
    done
}

function run_node_manager() {
    MANIFEST_FILE=/home/gensyn/rl_swarm/node-manager/nodeV3.yaml \
    MODE=init \
    /home/gensyn/rl_swarm/node-manager/node-manager | tee /home/gensyn/logs/node_manager.log
    
    MANIFEST_FILE=/home/rl_swarm/gensyn/node-manager/nodeV3.yaml \
    MODE=sidecar \
    /home/gensyn/rl_swarm/node-manager/node-manager | tee -a /home/gensyn/logs/node_manager.log
}
function get_last_log {
    mkdir /home/gensyn/logs
    while true; do
        sleep 5m
        cat /home/gensyn/logs/node_log.log | tail -40 > /home/gensyn/logs/last_40.log
    done
}

get_last_log &
run_node_manager &
start_tunnel &
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

./run_rl_swarm.sh