#!/bin/bash

BOOTSTRAP=false
QRL_DATA_DIR=./qrlData
BOOTSTRAP_DEST=$QRL_DATA_DIR/data
BOOTSTRAP_URL=https://cdn.qrl.co.in/mainnet/QRL_Mainnet_State.tar.gz
BOOTSTRAP_URL_CHECKSUM=https://cdn.qrl.co.in/mainnet/Mainnet_State_Checksums.txt

# Create qrlData folder
if [ ! -d $BOOTSTRAP_DEST ]; then
  mkdir -p $BOOTSTRAP_DEST
fi

# Bootstrap parameter
if [[ $1 == --bootstrap ]]; then
    BOOTSTRAP=true
fi


# Install packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install docker.io docker-compose -y

# Bootstrap
if $BOOTSTRAP ; then
  wget $BOOTSTRAP_URL_CHECKSUM
  wget $BOOTSTRAP_URL
  SHA3_CHECKSUM=`sed -n '/SHA3-512/{n;p}' Mainnet_State_Checksums.txt`
  SHA3=($(openssl dgst -sha3-512 QRL_Mainnet_State.tar.gz))
  if [ "$SHA3_CHECKSUM" = "${SHA3[1]}" ]; then
    tar -xzf QRL_Mainnet_State.tar.gz -C $BOOTSTRAP_DEST  
  else
    echo "Bootstrap verification failed. Expected $SHA3_CHECKSUM got ${SHA3[1]}."
    exit 1
  fi
fi

# QRL node configuration
cat << EOF > $QRL_DATA_DIR/config.yml
public_api_host: '0.0.0.0'
mining_api_enabled: True
mining_api_host: '0.0.0.0'
EOF

# Start qrl node with Grafana and portainer
sudo docker-compose -f docker-compose-qrl.yaml up -d

