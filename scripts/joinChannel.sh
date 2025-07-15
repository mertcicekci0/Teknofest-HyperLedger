#!/bin/bash

# Kanal oluşturma ve peer'lara katılma scripti
CHANNEL_NAME=${1:-"mychannel"}
DELAY=${2:-"3"}
MAX_RETRY=${3:-"5"}

echo "Kanal oluşturuluyor ve peer'lar katılıyor: $CHANNEL_NAME"

# Environment variables ayarla
export PATH=${PWD}/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/fabric-samples/config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

echo "Kanal oluşturuluyor..."
peer channel create -o localhost:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

if [ $? -ne 0 ]; then
  echo "Kanal oluşturulamadı"
  exit 1
fi
echo "✓ Kanal başarıyla oluşturuldu"

echo "Org1 peer'ı kanala katılıyor..."
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

if [ $? -ne 0 ]; then
  echo "Org1 peer'ı kanala katılamadı"
  exit 1
fi
echo "✓ Org1 peer'ı kanala katıldı"

# Org2 için environment variables ayarla
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

echo "Org2 peer'ı kanala katılıyor..."
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

if [ $? -ne 0 ]; then
  echo "Org2 peer'ı kanala katılamadı"
  exit 1
fi
echo "✓ Org2 peer'ı kanala katıldı"

# Anchor peer güncellemeleri
echo "Anchor peer'lar güncelleniyor..."

# Org1 için
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer channel update -o localhost:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Org2 için
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

peer channel update -o localhost:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "✓ Kanal oluşturma ve katılma işlemi tamamlandı"
