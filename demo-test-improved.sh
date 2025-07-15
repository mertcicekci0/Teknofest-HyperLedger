#!/bin/bash

# Teknofest İHA Blockchain Demo Test (Geliştirilmiş Versiyon)
# Bu script blockchain transaction'larının tamamlanması için bekler

echo "🚁 Teknofest İHA Blockchain Demo (Geliştirilmiş) Başlatılıyor..."
echo ""
echo "📋 DEMO SENARYOLARI:"
echo "1. İHA Kayıt (Baykar TB2, TAI ANKA, Baykar AKINCI)"
echo "2. Uçuş Verisi Kayıt"
echo "3. Anomali Yönetimi"
echo "4. Sorgulama Testleri"
echo ""

# CLI container'ına bağlan
function invoke_chaincode() {
    docker exec cli peer chaincode invoke \
        -o orderer.example.com:7050 \
        --tls true \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
        -C uavchannel \
        -n uav-tracker \
        "$@"
}

function query_chaincode() {
    docker exec cli peer chaincode query \
        -C uavchannel \
        -n uav-tracker \
        "$@"
}

# 1. İHA KAYIT SÜRECİ
echo "🏭 1. İHA KAYIT SÜRECİ"

echo "✈️ TB2002 Bayraktar kaydediliyor..."
invoke_chaincode -c '{"function":"CreateUAV","Args":["TB2002","TB2","Baykar","2024-06-01"]}'
echo "Bekliyor... (2 saniye)"
sleep 2

echo "✈️ ANKA001 kaydediliyor..."
invoke_chaincode -c '{"function":"CreateUAV","Args":["ANKA001","ANKA-S","TAI","2024-06-15"]}'
echo "Bekliyor... (2 saniye)"
sleep 2

echo "✈️ AKINCI001 kaydediliyor..."
invoke_chaincode -c '{"function":"CreateUAV","Args":["AKINCI001","AKINCI","Baykar","2024-07-01"]}'
echo "Bekliyor... (2 saniye)"
sleep 2

echo "✈️ KIZILELMA001 kaydediliyor..."
invoke_chaincode -c '{"function":"CreateUAV","Args":["KIZILELMA001","KIZILELMA","Baykar","2024-08-01"]}'
echo "Bekliyor... (2 saniye)"
sleep 2

echo ""

# 2. UÇUŞ VERİSİ KAYIT
echo "🛫 2. UÇUŞ VERİSİ KAYIT SÜRECİ"

echo "📍 TB2002 - Ankara → İstanbul uçuşu..."
invoke_chaincode -c '{"function":"RecordFlight","Args":["TB2002","39.9334,32.8597","2000","140","Normal","2025-07-15T10:00:00Z","95"]}'
sleep 1

echo "📍 ANKA001 - İstanbul → İzmir uçuşu..."
invoke_chaincode -c '{"function":"RecordFlight","Args":["ANKA001","41.0082,28.9784","3000","180","Normal","2025-07-15T11:00:00Z","88"]}'
sleep 1

echo "📍 AKINCI001 - Sınır devriyesi..."
invoke_chaincode -c '{"function":"RecordFlight","Args":["AKINCI001","37.0662,37.3833","4000","200","Normal","2025-07-15T12:00:00Z","92"]}'
sleep 1

echo "📍 KIZILELMA001 - Test uçuşu..."
invoke_chaincode -c '{"function":"RecordFlight","Args":["KIZILELMA001","39.1667,35.6667","5000","220","Test","2025-07-15T13:00:00Z","98"]}'
sleep 1

echo ""

# 3. ANOMALİ YÖNETİMİ
echo "⚠️ 3. ANOMALİ YÖNETİMİ"

echo "🔋 TB2002 - Düşük batarya uyarısı..."
invoke_chaincode -c '{"function":"RecordAnomaly","Args":["TB2002","Düşük Batarya - %15","2025-07-15T10:30:00Z","40.1826,29.0665"]}'
sleep 1

echo "🌪️ ANKA001 - Hava durumu uyarısı..."
invoke_chaincode -c '{"function":"RecordAnomaly","Args":["ANKA001","Kötü Hava Şartları - Rüzgar 45kt","2025-07-15T11:45:00Z","38.4237,27.1428"]}'
sleep 1

echo "⚡ AKINCI001 - Sistem uyarısı..."
invoke_chaincode -c '{"function":"RecordAnomaly","Args":["AKINCI001","Radar Sistemi Arızası","2025-07-15T12:15:00Z","37.0662,37.3833"]}'
sleep 1

echo ""

# 4. SORGULAMA TESTLERİ
echo "🔍 4. SORGULAMA TESTLERİ"
echo "Blockchain state'inin güncellenmesi için bekliyor... (3 saniye)"
sleep 3

echo "📊 Tüm İHA'ları listele:"
query_chaincode -c '{"function":"QueryAllUAVs","Args":[]}'
echo ""

echo "📊 TB2002 bilgileri:"
query_chaincode -c '{"function":"QueryUAV","Args":["TB2002"]}'
echo ""

echo "📊 ANKA001 bilgileri:"
query_chaincode -c '{"function":"QueryUAV","Args":["ANKA001"]}'
echo ""

echo "📊 AKINCI001 bilgileri:"
query_chaincode -c '{"function":"QueryUAV","Args":["AKINCI001"]}'
echo ""

echo "📊 KIZILELMA001 bilgileri:"
query_chaincode -c '{"function":"QueryUAV","Args":["KIZILELMA001"]}'
echo ""

echo "📊 TB2002 uçuş geçmişi:"
query_chaincode -c '{"function":"QueryFlightHistory","Args":["TB2002"]}'
echo ""

echo "📊 ANKA001 anomali geçmişi:"
query_chaincode -c '{"function":"QueryAnomaliesByUAV","Args":["ANKA001"]}'
echo ""

echo ""
echo "✅ Geliştirilmiş Demo tamamlandı!"
echo "🎯 Blockchain'de şu veriler kayıtlı:"
echo "   - 4 İHA kaydı (TB2002, ANKA001, AKINCI001, KIZILELMA001)"
echo "   - 4 Uçuş verisi"
echo "   - 3 Anomali kaydı"
echo "   - Tüm veriler değiştirilemez şekilde blockchain'de saklanıyor"
echo ""
echo "🏆 Teknofest İHA Blockchain Projesi Hazır!"
