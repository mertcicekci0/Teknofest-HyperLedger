#!/bin/bash

# Teknofest İHA/SİHA Test Scripti
# PDR dosyasındaki test senaryolarını çalıştırır

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHANNEL_NAME=${1:-"mychannel"}
CHAINCODE_NAME=${2:-"uav-tracker"}
DELAY=${3:-"3"}
MAX_RETRY=${4:-"5"}

echo
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}  TEKNOFEST İHA/SİHA TEST SCRIPT  ${NC}"
echo -e "${BLUE}=================================${NC}"
echo

# Log fonksiyonları
function infoln() {
  echo -e "${GREEN}✓ ${1}${NC}"
}

function warnln() {
  echo -e "${YELLOW}⚠ ${1}${NC}"
}

function errorln() {
  echo -e "${RED}✗ ${1}${NC}"
}

function testln() {
  echo -e "${BLUE}🧪 ${1}${NC}"
}

# Peer environment ayarlama
function setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Chaincode invoke fonksiyonu
function chaincodeInvokeInit() {
  setGlobals 1
  
  testln "Chaincode başlatılıyor ve demo verileri yükleniyor..."
  
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n ${CHAINCODE_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"initLedger","Args":[]}'
  
  if [ $? -eq 0 ]; then
    infoln "Chaincode başarıyla başlatıldı ve demo verileri yüklendi"
  else
    errorln "Chaincode başlatılamadı"
    exit 1
  fi
}

# Test 1: Yeni İHA Oluşturma (PDR Adım 1: İHA Üretimi)
function test_createUAV() {
  testln "TEST 1: Yeni İHA Oluşturma"
  setGlobals 1
  
  echo "Yeni İHA oluşturuluyor: IHA004..."
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n ${CHAINCODE_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"CreateUAV","Args":["IHA004","Bayraktar TB3","Baykar","2024-06-05"]}'
  
  if [ $? -eq 0 ]; then
    infoln "İHA004 başarıyla oluşturuldu"
  else
    errorln "İHA oluşturulamadı"
  fi
}

# Test 2: Parça Kaydı (PDR Adım 1: İHA Üretimi)
function test_registerPart() {
  testln "TEST 2: Parça Kaydı"
  setGlobals 1
  
  echo "Yeni parça kaydediliyor..."
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n ${CHAINCODE_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"RegisterPart","Args":["PARCA001","Turbofan Motor","Baykar","2024-06-01","IHA001"]}'
  
  if [ $? -eq 0 ]; then
    infoln "Parça başarıyla kaydedildi"
  else
    errorln "Parça kaydedilemedi"
  fi
}

# Test 3: Uçuş Verisi Kaydetme (PDR Adım 2: Operasyon)
function test_recordFlight() {
  testln "TEST 3: Uçuş Verisi Kaydetme"
  setGlobals 2
  
  echo "Real-time uçuş verisi kaydediliyor..."
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n ${CHAINCODE_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"RecordFlight","Args":["IHA001","39.9334,32.8597","1500","120","Uçuşta","2024-06-05T14:30:00Z","85"]}'
  
  if [ $? -eq 0 ]; then
    infoln "Uçuş verisi başarıyla kaydedildi"
  else
    errorln "Uçuş verisi kaydedilemedi"
  fi
}

# Test 4: Anomali Kaydetme (PDR Adım 2: Operasyon)
function test_recordAnomaly() {
  testln "TEST 4: Anomali Kaydetme"
  setGlobals 2
  
  echo "Anomali tespiti kaydediliyor..."
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n ${CHAINCODE_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"RecordAnomaly","Args":["IHA001","Batarya Düşük","2024-06-05T15:00:00Z","39.9334,32.8597"]}'
  
  if [ $? -eq 0 ]; then
    infoln "Anomali başarıyla kaydedildi"
  else
    errorln "Anomali kaydedilemedi"
  fi
}

# Test 5: İHA Sorgulama (PDR Adım 3: Raporlama)
function test_queryUAV() {
  testln "TEST 5: İHA Bilgilerini Sorgulama"
  setGlobals 1
  
  echo "İHA001 bilgileri sorgulanıyor..."
  peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -c '{"function":"QueryUAV","Args":["IHA001"]}'
  
  if [ $? -eq 0 ]; then
    infoln "İHA bilgileri başarıyla sorgulandı"
  else
    errorln "İHA bilgileri sorgulanamadı"
  fi
}

# Test 6: Uçuş Geçmişi Sorgulama (PDR Adım 3: Raporlama)
function test_queryFlightHistory() {
  testln "TEST 6: Uçuş Geçmişi Sorgulama"
  setGlobals 2
  
  echo "İHA001 uçuş geçmişi sorgulanıyor..."
  peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -c '{"function":"QueryFlightHistory","Args":["IHA001"]}'
  
  if [ $? -eq 0 ]; then
    infoln "Uçuş geçmişi başarıyla sorgulandı"
  else
    errorln "Uçuş geçmişi sorgulanamadı"
  fi
}

# Test 7: Parça Takibi (PDR Adım 3: Raporlama)
function test_queryParts() {
  testln "TEST 7: Parça Takibi Kontrolü"
  setGlobals 1
  
  echo "İHA001 parçaları sorgulanıyor..."
  peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -c '{"function":"QueryPartsByUAV","Args":["IHA001"]}'
  
  if [ $? -eq 0 ]; then
    infoln "Parça bilgileri başarıyla sorgulandı"
  else
    errorln "Parça bilgileri sorgulanamadı"
  fi
}

# Test 8: Anomali Raporları (PDR Adım 3: Raporlama)
function test_queryAnomalies() {
  testln "TEST 8: Anomali Raporları"
  setGlobals 2
  
  echo "İHA001 anomali raporları sorgulanıyor..."
  peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -c '{"function":"QueryAnomaliesByUAV","Args":["IHA001"]}'
  
  if [ $? -eq 0 ]; then
    infoln "Anomali raporları başarıyla sorgulandı"
  else
    errorln "Anomali raporları sorgulanamadı"
  fi
}

# Test 9: Tüm İHA'ları Listele
function test_queryAllUAVs() {
  testln "TEST 9: Tüm İHA'ları Listele"
  setGlobals 1
  
  echo "Tüm İHA'lar listeleniyor..."
  peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -c '{"function":"QueryAllUAVs","Args":[]}'
  
  if [ $? -eq 0 ]; then
    infoln "Tüm İHA'lar başarıyla listelendi"
  else
    errorln "İHA'lar listelenemedi"
  fi
}

# Test 10: İHA Durumu Güncelleme
function test_updateUAVStatus() {
  testln "TEST 10: İHA Durumu Güncelleme"
  setGlobals 1
  
  echo "İHA001 durumu güncelleniyor..."
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n ${CHAINCODE_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles $PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"UpdateUAVStatus","Args":["IHA001","Operasyonda"]}'
  
  if [ $? -eq 0 ]; then
    infoln "İHA durumu başarıyla güncellendi"
  else
    errorln "İHA durumu güncellenemedi"
  fi
}

# Ana test fonksiyonu
function runTests() {
  echo
  echo -e "${BLUE}🚀 TEKNOFEST İHA/SİHA BLOCKCHAIN TEST SENARYOSU BAŞLIYOR...${NC}"
  echo
  
  # Önce chaincode'u başlat
  chaincodeInvokeInit
  
  echo
  echo -e "${YELLOW}📋 PDR Adım 1: İHA Üretimi Testleri${NC}"
  test_createUAV
  sleep $DELAY
  test_registerPart
  sleep $DELAY
  
  echo
  echo -e "${YELLOW}📋 PDR Adım 2: Operasyon Testleri${NC}"
  test_recordFlight
  sleep $DELAY
  test_recordAnomaly
  sleep $DELAY
  
  echo
  echo -e "${YELLOW}📋 PDR Adım 3: Raporlama Testleri${NC}"
  test_queryUAV
  sleep $DELAY
  test_queryFlightHistory
  sleep $DELAY
  test_queryParts
  sleep $DELAY
  test_queryAnomalies
  sleep $DELAY
  
  echo
  echo -e "${YELLOW}📋 Ek Fonksiyon Testleri${NC}"
  test_queryAllUAVs
  sleep $DELAY
  test_updateUAVStatus
  
  echo
  echo -e "${GREEN}🎉 TÜM TESTLER TAMAMLANDI!${NC}"
  echo -e "${GREEN}✅ Teknofest İHA/SİHA Blockchain Takip Sistemi hazır!${NC}"
  echo
}

# Test scriptini çalıştır
runTests
