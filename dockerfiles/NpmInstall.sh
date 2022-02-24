#!/bin/bash

until cd /opt/qrl_stats && npm install
do
    echo "Retrying npm install"
done
node index.js
