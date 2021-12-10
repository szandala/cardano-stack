FROM cardano AS base

ENV NODE_CONFIG=testnet
ENV NODE_HOME=/testnet

RUN apt update && apt install -y wget

RUN mkdir -p "${NODE_HOME}"
WORKDIR "${NODE_HOME}"
RUN wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-config.json && \
    wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-byron-genesis.json && \
    wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-shelley-genesis.json && \
    wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-alonzo-genesis.json && \
    wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-topology.json

RUN sed -i ${NODE_CONFIG}-config.json \
    -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"

ENV CARDANO_NODE_SOCKET_PATH="${NODE_HOME}/db/socket"

##############################################################3
FROM base AS relay

COPY relay-node/topology.json ${NODE_HOME}/${NODE_CONFIG}-topology.json

ENV DIRECTORY="${NODE_HOME}"
ENV PORT=6000
ENV HOSTADDR=0.0.0.0
ENV TOPOLOGY=${DIRECTORY}/${NODE_CONFIG}-topology.json
ENV DB_PATH=/db
ENV SOCKET_PATH=/db/socket
ENV CONFIG=${DIRECTORY}/${NODE_CONFIG}-config.json
ENV KES=${DIRECTORY}/kes.skey
ENV VRF=${DIRECTORY}/vrf.skey
ENV CERT=${DIRECTORY}/node.cert

RUN apt install -y bc tcptraceroute curl lsof net-tools jq

RUN curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
RUN curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh && \
    chmod +x gLiveView.sh

# RUN cardano-cli node key-gen-KES \
#     --verification-key-file kes.vkey \
#     --signing-key-file kes.skey

# RUN cardano-cli node key-gen-VRF \
#     --verification-key-file vrf.vkey \
#     --signing-key-file vrf.skey

ENTRYPOINT cardano-node run +RTS -N -A16m -qg -qb -RTS \
    --topology ${TOPOLOGY} \
    --database-path ${DB_PATH} \
    --socket-path ${SOCKET_PATH} \
    --host-addr ${HOSTADDR} \
    --port ${PORT} \
    --config ${CONFIG}



# ENTRYPOINT "cardano-node" "run" "+RTS" "-N" "-A16m" "-qg" "-qb" "-RTS" \
#     "--topology" "${TOPOLOGY}" \
#     "--database-path" "${DB_PATH}" \
#     "--socket-path" "${SOCKET_PATH}" \
#     "--host-addr" "${HOSTADDR}" \
#     "--port" "${PORT}" \
#     "--config" "${CONFIG}" \
#     "--shelley-kes-key" "${KES}" \
#     "--shelley-vrf-key" "${VRF}" \
#     "--shelley-operational-certificate" "${CERT}"

# TODO: why this doesnt work?
# ENTRYPOINT ["/root/.local/bin/cardano-node" , "run", "+RTS", "-N", "-A16m", "-qg", "-qb", "-RTS", \
#     "--topology", "\${TOPOLOGY}", \
#     "--database-path", "\${DB_PATH}", \
#     "--socket-path", "\${SOCKET_PATH}", \
#     "--host-addr", "\${HOSTADDR}", \
#     "--port", "\${PORT}", \
#     "--config", "\${CONFIG}", \
#     "--shelley-kes-key", "\${KES}", \
#     "--shelley-vrf-key", "\${VRF}", \
#     "--shelley-operational-certificate", "\${CERT}"]
