#!/bin/bash

# Chaincode Deploy Script
CHANNEL_NAME=${1:-"mychannel"}
CC_NAME=${2:-"uav-tracker"}
CC_SRC_PATH=${3:-"../chaincode/uav-tracker/"}
CC_RUNTIME_LANGUAGE=${4:-"javascript"}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}

# Fabric binary'lerinin PATH'te olup olmadığını kontrol et
export PATH=${PWD}/../fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../fabric-samples/config/

echo "Chaincode deploy ediliyor..."
echo "Kanal: $CHANNEL_NAME"
echo "Chaincode: $CC_NAME"
echo "Versiyon: $CC_VERSION"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function infoln() {
  echo -e "${GREEN}✓ ${1}${NC}"
}

function errorln() {
  echo -e "${RED}✗ ${1}${NC}"
}

# Peer environment ayarlama
function setGlobals() {
  local USING_ORG=$1
  
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  fi
}

# Chaincode package oluştur
function packageChaincode() {
  echo "Chaincode packaging..."
  setGlobals 1
  
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION}
  
  if [ $? -eq 0 ]; then
    infoln "Chaincode package oluşturuldu"
  else
    errorln "Chaincode package oluşturulamadı"
    exit 1
  fi
}

# Chaincode install
function installChaincode() {
  local ORG=$1
  setGlobals $ORG
  
  echo "Org${ORG} peer'ında chaincode install ediliyor..."
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  
  if [ $? -eq 0 ]; then
    infoln "Org${ORG} chaincode install başarılı"
  else
    errorln "Org${ORG} chaincode install başarısız"
    exit 1
  fi
}

# Package ID al
function queryInstalled() {
  setGlobals 1
  peer lifecycle chaincode queryinstalled >&log.txt
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  echo "Package ID: $PACKAGE_ID"
}

# Chaincode approve
function approveForMyOrg() {
  local ORG=$1
  setGlobals $ORG
  
  echo "Org${ORG} chaincode approve ediyor..."
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION --package-id $PACKAGE_ID --sequence $CC_SEQUENCE
  
  if [ $? -eq 0 ]; then
    infoln "Org${ORG} chaincode approve başarılı"
  else
    errorln "Org${ORG} chaincode approve başarısız"
    exit 1
  fi
}

# Chaincode commit
function commitChaincodeDefinition() {
  setGlobals 1
  
  echo "Chaincode commit ediliyor..."
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID $CHANNEL_NAME --name $CC_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $PWD/../organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles $PWD/../organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --version $CC_VERSION --sequence $CC_SEQUENCE
  
  if [ $? -eq 0 ]; then
    infoln "Chaincode commit başarılı"
  else
    errorln "Chaincode commit başarısız"
    exit 1
  fi
}

# Ana deployment süreci
echo "🚀 UAV Tracker Chaincode Deploy Başlıyor..."

packageChaincode
installChaincode 1
installChaincode 2
queryInstalled
approveForMyOrg 1
approveForMyOrg 2
commitChaincodeDefinition

echo
infoln "🎉 Chaincode başarıyla deploy edildi!"
echo
echo "Test etmek için:"
echo "  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME"
export PATH=${PWD}/../fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../fabric-samples/config/

echo "✓ Chaincode package ediliyor..."
peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_1.0

if [ $? -ne 0 ]; then
  echo "Chaincode package edilemedi"
  exit 1
fi

echo "✓ Chaincode başarıyla deploy edildi (simulation)"
echo "✓ Test için hazır"
