#!/bin/bash

target/debug/mm2 '{"myipaddr": "127.0.0.2", "gui": "nogui", "client": 1, "passphrase": "SPATsRps3dhEtXwtnpRCKF", "coins": [{"coin": "BEER","asset": "BEER", "rpcport": 8923}, {"coin": "PIZZA","asset": "PIZZA", "rpcport": 11116}]}' &
sleep 10
curl -v --url "http://127.0.0.2:7783" --data '{"userpass": "aa503e7d7426ba8ce7f6627e066b04bf06004a41fd281e70690b3dbc6e066f69", "method": "electrum", "coin": "BEER", "ipaddr": "electrum1.cipig.net", "port": 10022}'
