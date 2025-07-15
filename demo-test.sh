#!/bin/bash

# Teknofest İHA Blockchain Demo Test Script
echo "🚁 Teknofest İHA Blockchain Demo Başlatılıyor..."

# Environment değişkenleri
export CHANNEL_NAME="uavchannel"
export CHAINCODE_NAME="uav-tracker"
export ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
export ORG1_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"

echo ""
echo "📋 DEMO SENARYOLARI:"
echo "1. İHA Kayıt (Baykar TB2, TAI ANKA, Baykar AKINCI)"
echo "2. Uçuş Verisi Kayıt"
echo "3. Anomali Yönetimi"
echo "4. Sorgulama Testleri"
echo ""

# 1. İHA Kayıtları
echo "🏭 1. İHA KAYIT SÜRECİ"
echo "✈️ TB2 Bayraktar kaydediliyor..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"CreateUAV","Args":["TB2002","TB2","Baykar","2024-06-01"]}'

echo "✈️ ANKA-S kaydediliyor..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"CreateUAV","Args":["ANKA001","ANKA-S","TAI","2024-06-15"]}'

echo "✈️ AKINCI kaydediliyor..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"CreateUAV","Args":["AKINCI001","AKINCI","Baykar","2024-07-01"]}'

sleep 2

# 2. Uçuş Verileri
echo ""
echo "🛫 2. UÇUŞ VERİSİ KAYIT SÜRECİ"
echo "📍 TB2002 - Ankara → İstanbul uçuşu..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"RecordFlight","Args":["TB2002","39.9334,32.8597","2000","140","Normal","2025-07-15T10:00:00Z","95"]}'

echo "📍 ANKA001 - İstanbul → İzmir uçuşu..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"RecordFlight","Args":["ANKA001","41.0082,28.9784","3000","180","Normal","2025-07-15T11:00:00Z","88"]}'

echo "📍 AKINCI001 - Sınır devriyesi..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"RecordFlight","Args":["AKINCI001","37.0662,37.3833","4000","200","Normal","2025-07-15T12:00:00Z","92"]}'

sleep 2

# 3. Anomali Senaryoları
echo ""
echo "⚠️ 3. ANOMALİ YÖNETİMİ"
echo "🔋 TB2002 - Düşük batarya uyarısı..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"RecordAnomaly","Args":["TB2002","Düşük Batarya - %15","2025-07-15T10:30:00Z","40.1826,29.0665"]}'

echo "🌪️ ANKA001 - Hava durumu uyarısı..."
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $ORG1_CA -c '{"function":"RecordAnomaly","Args":["ANKA001","Kötü Hava Şartları - Rüzgar 45kt","2025-07-15T11:45:00Z","38.4237,27.1428"]}'

sleep 2

# 4. Sorgulama Testleri
echo ""
echo "🔍 4. SORGULAMA TESTLERİ"
echo "📊 TB2001 bilgileri:"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"function":"QueryUAV","Args":["TB2001"]}'

echo ""
echo "📊 TB2002 bilgileri:"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"function":"QueryUAV","Args":["TB2002"]}'

echo ""
echo "📊 ANKA001 bilgileri:"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"function":"QueryUAV","Args":["ANKA001"]}'

echo ""
echo "📊 AKINCI001 bilgileri:"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"function":"QueryUAV","Args":["AKINCI001"]}'

echo ""
echo "✅ Demo tamamlandı!"
echo "🎯 Blockchain'de şu veriler kayıtlı:"
echo "   - 4 İHA kaydı (TB2001, TB2002, ANKA001, AKINCI001)"
echo "   - 4 Uçuş verisi"
echo "   - 3 Anomali kaydı"
echo "   - Tüm veriler değiştirilemez şekilde blockchain'de saklanıyor"
echo ""
echo "🏆 Teknofest İHA Blockchain Projesi Hazır!"
