#!/bin/bash

# Basit kanal oluşturma scripti
CHANNEL_NAME=${1:-"mychannel"}
DELAY=${2:-"3"}
MAX_RETRY=${3:-"5"}

echo "Kanal oluşturuluyor: $CHANNEL_NAME"

# Fabric binary'lerinin PATH'te olup olmadığını kontrol et
export PATH=${PWD}/../fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../fabric-samples/config/

# Genesis blok oluştur (orderer için)
configtxgen -profile SampleMultiNodeEtcdRaft -outputBlock ./system-genesis-block/genesis.block -channelID system-channel

if [ $? -ne 0 ]; then
  echo "Genesis blok oluşturulamadı"
  exit 1
fi

echo "✓ Genesis blok oluşturuldu"

# Kanal transaction oluştur
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

if [ $? -ne 0 ]; then
  echo "Kanal transaction oluşturulamadı"
  exit 1
fi

echo "✓ Kanal transaction oluşturuldu"

# Anchor peer transaction'ları oluştur
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP

echo "✓ Anchor peer transaction'ları oluşturuldu"
echo "✓ Kanal hazırlıkları tamamlandı"
