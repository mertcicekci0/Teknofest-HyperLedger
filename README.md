# Teknofest İHA/SİHA Blockchain Takip Sistemi

Bu proje, PDR dosyasında belirtilen şekilde HyperLedger Fabric kullanarak İHA/SİHA takip sistemi oluşturur.

## Proje Yapısı

```
├── docker-compose.yml          # Docker container konfigürasyonu
├── configtx.yaml              # Fabric ağ konfigürasyonu  
├── network.sh                 # Ağ yönetim scripti
├── test-uav.sh                # Test scripti
├── chaincode/
│   └── uav-tracker/           # Smart Contract
│       ├── index.js
│       ├── package.json
│       └── lib/
│           └── uav-contract.js
└── README.md
```

## Özellikler

### 1. İHA Yönetimi
- İHA kaydı oluşturma
- İHA durumu güncelleme
- Tüm İHA'ları listeleme

### 2. Parça Takibi
- Parça kaydı
- İHA-parça ilişkisi
- Parça geçmişi

### 3. Uçuş Verisi
- Real-time uçuş verisi kaydetme
- Koordinat, irtifa, hız, batarya bilgileri
- Uçuş geçmişi sorgulama

### 4. Anomali Yönetimi
- Anomali tespiti kaydetme
- Anomali raporları
- Güvenlik takibi

## Kurulum

### Gereksinimler
- Docker & Docker Compose
- Node.js 14+
- HyperLedger Fabric 2.x (fabric-samples)

### 1. Fabric Samples Mevcut
✅ Fabric samples zaten workspace'de mevcut

### 2. Proje Klasörüne Git
```bash
cd "Hyper Ledger Fabric Teknofest"
```

### 3. Script'leri Çalıştırılabilir Yap
```bash
chmod +x network.sh
chmod +x test-uav.sh
chmod +x scripts/*.sh
```

### 4. Organizasyon Sertifikalarını Oluştur
```bash
export PATH=${PWD}/fabric-samples/bin:$PATH
cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations" 
cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
```

## Kullanım

### 1. Ağı Başlat
```bash
./network.sh up
```

### 2. Kanal Oluştur
```bash
./network.sh createChannel
```

### 3. Chaincode Deploy Et
```bash
./network.sh deployCC
```

### 4. Test Scriptini Çalıştır
```bash
./test-uav.sh
```

### 5. Ağı Durdur
```bash
./network.sh down
```

## Test Senaryoları

Test scripti PDR'deki 3 adımlı senaryoyu takip eder:

### Adım 1: İHA Üretimi
- ✅ Yeni İHA kaydı
- ✅ Parça kaydı ve atama

### Adım 2: Operasyon  
- ✅ Real-time uçuş verisi
- ✅ Anomali tespiti

### Adım 3: Raporlama
- ✅ İHA geçmişi sorgulama
- ✅ Parça takibi
- ✅ Anomali raporları

## Chaincode Fonksiyonları

```javascript
// İHA İşlemleri
CreateUAV(id, model, marka, üretimTarihi)
QueryUAV(id)
QueryAllUAVs()
UpdateUAVStatus(id, yeniDurum)

// Parça İşlemleri
RegisterPart(parçaId, parçaIsmi, marka, üretimTarihi, uavId)
QueryPartsByUAV(uavId)

// Uçuş İşlemleri
RecordFlight(uavId, koordinat, irtifa, hız, durum, zaman, batarya)
QueryFlightHistory(uavId)

// Anomali İşlemleri
RecordAnomaly(uavId, anomaliTürü, zaman, konum)
QueryAnomaliesByUAV(uavId)
```

## Örnek Kullanım

### Manuel Test (CLI ile)
```bash
# İHA oluştur
peer chaincode invoke -C mychannel -n uav-tracker -c '{"function":"CreateUAV","Args":["IHA005","TB2","Baykar","2024-06-05"]}'

# Uçuş verisi kaydet
peer chaincode invoke -C mychannel -n uav-tracker -c '{"function":"RecordFlight","Args":["IHA005","40.7128,-74.0060","2000","150","Görevde","2024-06-05T16:00:00Z","75"]}'

# İHA sorgula
peer chaincode query -C mychannel -n uav-tracker -c '{"function":"QueryUAV","Args":["IHA005"]}'
```

## Veri Modeli

### İHA
```json
{
  "uavId": "IHA001",
  "model": "Bayraktar TB2", 
  "marka": "Baykar",
  "üretimTarihi": "2024-01-15",
  "durum": "Aktif"
}
```

### Uçuş Verisi
```json
{
  "flightId": "FLIGHT_IHA001_1234567890",
  "uavId": "IHA001",
  "koordinat": "39.9334,32.8597",
  "irtifa": 1500,
  "hız": 120,
  "durum": "Uçuşta", 
  "zaman": "2024-06-05T14:30:00Z",
  "batarya": 85
}
```

### Parça
```json
{
  "parçaId": "PARCA001",
  "parçaIsmi": "Motor",
  "marka": "XYZ Teknoloji",
  "üretimTarihi": "2024-01-10",
  "uavId": "IHA001"
}
```

### Anomali
```json
{
  "anomaliId": "ANOM_IHA001_1234567890",
  "uavId": "IHA001",
  "anomaliTürü": "Batarya Düşük",
  "zaman": "2024-06-05T15:00:00Z", 
  "koordinat": "39.9334,32.8597"
}
```

## Troubleshooting

### Port Çakışması
Eğer port çakışması yaşarsanız:
```bash
./network.sh down
docker system prune -f
./network.sh up
```

### Container Problemleri
```bash
docker ps -a  # Tüm container'ları görüntüle
docker logs <container_name>  # Log'ları kontrol et
```

### Chaincode Güncelleme
```bash
./network.sh deployCC  # Chaincode'u yeniden deploy et
```

## Teknofest Demo

Bu sistem Teknofest sunumu için hazır haldedir:

1. **Live Demo**: Test scriptinin çalışması
2. **Visualization**: Blockchain'de kayıtlı veriler
3. **Traceability**: Parça ve uçuş geçmişi
4. **Security**: Blockchain veri bütünlüğü

---

**Teknofest 2025 - İHA/SİHA Blockchain Takip Sistemi**
