#!/bin/bash

# Teknofest İHA Blockchain Performance Test
# Bu script sistem performansını ve güvenilirliğini test eder

echo "🚀 Teknofest İHA Blockchain Performance Test Başlatılıyor..."
echo ""

# Performans metrikleri
START_TIME=$(date +%s)
SUCCESS_COUNT=0
FAIL_COUNT=0

function invoke_chaincode() {
    docker exec cli peer chaincode invoke \
        -o orderer.example.com:7050 \
        --tls true \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
        -C uavchannel \
        -n uav-tracker \
        "$@" 2>/dev/null
}

function query_chaincode() {
    docker exec cli peer chaincode query \
        -C uavchannel \
        -n uav-tracker \
        "$@" 2>/dev/null
}

function test_operation() {
    local operation_name="$1"
    local command="$2"
    
    echo -n "  Testing $operation_name... "
    if eval "$command" > /dev/null; then
        echo "✅ SUCCESS"
        ((SUCCESS_COUNT++))
    else
        echo "❌ FAILED"
        ((FAIL_COUNT++))
    fi
}

echo "📊 1. CHAINCODE FUNCTION TESTLERİ"

# Test 1: İHA Kayıt
test_operation "İHA Kayıt" "invoke_chaincode -c '{\"function\":\"CreateUAV\",\"Args\":[\"PERF001\",\"Performance Test UAV\",\"Test Marka\",\"2024-07-15\"]}'"

# Test 2: İHA Sorgulama  
sleep 1
test_operation "İHA Sorgulama" "query_chaincode -c '{\"function\":\"QueryUAV\",\"Args\":[\"PERF001\"]}'"

# Test 3: Uçuş Verisi Kayıt
test_operation "Uçuş Verisi Kayıt" "invoke_chaincode -c '{\"function\":\"RecordFlight\",\"Args\":[\"PERF001\",\"39.9334,32.8597\",\"2000\",\"140\",\"Normal\",\"2025-07-15T10:00:00Z\",\"95\"]}'"

# Test 4: Anomali Kayıt
test_operation "Anomali Kayıt" "invoke_chaincode -c '{\"function\":\"RecordAnomaly\",\"Args\":[\"PERF001\",\"Test Anomali\",\"2025-07-15T10:30:00Z\",\"39.9334,32.8597\"]}'"

# Test 5: Tüm İHA Sorgulama
test_operation "Tüm İHA Sorgulama" "query_chaincode -c '{\"function\":\"QueryAllUAVs\",\"Args\":[]}'"

# Test 6: Uçuş Geçmişi
sleep 1
test_operation "Uçuş Geçmişi" "query_chaincode -c '{\"function\":\"QueryFlightHistory\",\"Args\":[\"PERF001\"]}'"

# Test 7: Anomali Geçmişi
test_operation "Anomali Geçmişi" "query_chaincode -c '{\"function\":\"QueryAnomaliesByUAV\",\"Args\":[\"PERF001\"]}'"

echo ""
echo "⚡ 2. PERFORMANS STRESİ TESTİ"

echo "  Çoklu İHA kaydı (10 adet)..."
for i in {1..10}; do
    invoke_chaincode -c "{\"function\":\"CreateUAV\",\"Args\":[\"STRESS$i\",\"Stress Test UAV $i\",\"Test Marka\",\"2024-07-15\"]}" > /dev/null
    if [ $? -eq 0 ]; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done
echo "  ✅ Çoklu İHA kaydı tamamlandı"

echo "  Çoklu uçuş verisi (20 adet)..."
for i in {1..10}; do
    for j in {1..2}; do
        invoke_chaincode -c "{\"function\":\"RecordFlight\",\"Args\":[\"STRESS$i\",\"39.$((RANDOM%9999)),32.$((RANDOM%9999))\",\"$((2000+RANDOM%3000))\",\"$((100+RANDOM%100))\",\"Normal\",\"2025-07-15T1$j:00:00Z\",\"$((80+RANDOM%20))\"]}" > /dev/null
        if [ $? -eq 0 ]; then
            ((SUCCESS_COUNT++))
        else
            ((FAIL_COUNT++))
        fi
    done
done
echo "  ✅ Çoklu uçuş verisi tamamlandı"

echo ""
echo "🔍 3. VERİ TUTARLILIK TESTİ"

sleep 2
echo "  Blockchain state kontrolü..."
ALL_UAVS=$(query_chaincode -c '{"function":"QueryAllUAVs","Args":[]}')
UAV_COUNT=$(echo "$ALL_UAVS" | grep -o '"Key"' | wc -l | tr -d ' ')

echo "  📊 Toplam kayıtlı İHA sayısı: $UAV_COUNT"

if [ "$UAV_COUNT" -gt 10 ]; then
    echo "  ✅ Veri tutarlılığı kontrolü BAŞARILI"
    ((SUCCESS_COUNT++))
else
    echo "  ❌ Veri tutarlılığı kontrolü BAŞARISIZ"
    ((FAIL_COUNT++))
fi

echo ""
echo "🏥 4. SİSTEM SAĞLIK KONTROL"

# Container durumları
echo "  Docker container durumları:"
RUNNING_CONTAINERS=$(docker ps --filter "name=peer\|orderer\|cli" --format "table {{.Names}}\t{{.Status}}" | grep -c "Up")
echo "    Çalışan container sayısı: $RUNNING_CONTAINERS"

if [ "$RUNNING_CONTAINERS" -ge 3 ]; then
    echo "  ✅ Tüm gerekli containerlar çalışıyor"
    ((SUCCESS_COUNT++))
else
    echo "  ❌ Bazı containerlar çalışmıyor"
    ((FAIL_COUNT++))
fi

# Chaincode durumu
echo "  Chaincode durumu:"
CC_STATUS=$(docker exec cli peer chaincode query -C uavchannel -n uav-tracker -c '{"function":"QueryAllUAVs","Args":[]}' 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  ✅ Chaincode erişilebilir"
    ((SUCCESS_COUNT++))
else
    echo "  ❌ Chaincode erişilemiyor"
    ((FAIL_COUNT++))
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "📊 PERFORMANS RAPORU"
echo "=================================="
echo "🕒 Test süresi: $DURATION saniye"
echo "✅ Başarılı işlem: $SUCCESS_COUNT"
echo "❌ Başarısız işlem: $FAIL_COUNT"
echo "📈 Başarı oranı: $(( SUCCESS_COUNT * 100 / (SUCCESS_COUNT + FAIL_COUNT) ))%"

if [ $FAIL_COUNT -eq 0 ]; then
    echo ""
    echo "🏆 TÜM TESTLER BAŞARILI!"
    echo "💡 Sistem Teknofest için hazır!"
else
    echo ""
    echo "⚠️  Bazı testler başarısız oldu"
    echo "🔧 Sistem optimizasyonu gerekli"
fi

echo ""
echo "✅ Performance Test Tamamlandı!"
