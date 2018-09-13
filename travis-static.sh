#!/bin/bash

npm install -g node-static
mkdir qwe
echo qwe > qwe/index.html
static -a 127.0.0.2 qwe &

sleep 1
curl -v http://127.0.0.2/
