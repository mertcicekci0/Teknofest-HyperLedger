# Teknofest İHA/SİHA Blockchain Takip Sistemi - PDR

## 1. PROJE ÖZETİ

### Proje Adı
Blockchain Destekli İHA/SİHA Takip Sistemi

### Amaç
İHA/SİHA'ların üretimden operasyona kadar tüm süreçlerinin HyperLedger Fabric ile güvenli şekilde takip edilmesi.

## 2. HYPERLEDGER FABRIC YAPILANDIRMASI

### 2.1 Basit Ağ Yapısı

#### Organizasyonlar (2 Adet)
- **Org1**: Üretici Kuruluş
- **Org2**: Operatör Kuruluş

#### Peer Düğümleri
```
Org1:
  - peer0.org1.example.com

Org2:
  - peer0.org2.example.com
```

#### Orderer
- **Tip**: Solo (Test için)
- **1 Orderer Node**: orderer.example.com

#### Kanal
- **mychannel**: Tüm veriler bu kanalda paylaşılacak

### 2.2 Chaincode (Smart Contract)

#### Ana Fonksiyonlar
```javascript
// İHA Kayıt
CreateUAV(id, model, marka, üretimTarihi)

// Parça Kayıt  
RegisterPart(parçaId, parçaIsmi, marka, üretimTarihi, uavId)

// Uçuş Verisi Kayıt
RecordFlight(uavId, koordinat, irtifa, hız, durum, zaman, batarya)

// Anomali Kayıt
RecordAnomaly(uavId, anomaliTürü, zaman, konum)

// Sorgulama
QueryUAV(id)
QueryFlightHistory(uavId)
```

## 3. VERİ MODELİ

### 3.1 İHA Kayıt Yapısı
```json
{
  "uavId": "IHA001",
  "model": "Bayraktar TB2",
  "marka": "Baykar",
  "üretimTarihi": "2024-01-15",
  "durum": "Aktif"
}
```

### 3.2 Uçuş Verisi Yapısı
```json
{
  "flightId": "FLIGHT001",
  "uavId": "IHA001",
  "koordinat": "39.9334,32.8597",
  "irtifa": 1500,
  "hız": 120,
  "durum": "Uçuşta",
  "zaman": "2024-06-05T14:30:00Z",
  "batarya": 85
}
```

### 3.3 Parça Yapısı
```json
{
  "parçaId": "PARCA001", 
  "parçaIsmi": "Motor",
  "marka": "XYZ Teknoloji",
  "üretimTarihi": "2024-01-10",
  "uavId": "IHA001"
}
```

### 3.4 Anomali Yapısı
```json
{
  "anomaliId": "ANOM001",
  "uavId": "IHA001", 
  "anomaliTürü": "Batarya Düşük",
  "zaman": "2024-06-05T15:00:00Z",
  "koordinat": "39.9334,32.8597"
}
```

## 4. KURULUM REHBERİ

### 4.1 Gereksinimler
- Docker & Docker Compose
- Node.js 14+
- HyperLedger Fabric 2.x
- Go 1.17+

### 4.2 Hızlı Kurulum
```bash
# 1. Fabric örneklerini indir
curl -sSL https://bit.ly/2ysbOFE | bash -s

# 2. Test ağını başlat
cd fabric-samples/test-network
./network.sh up createChannel

# 3. Chaincode deploy et
./network.sh deployCC -ccn uav-tracker -ccp ../chaincode/uav/ -ccl javascript
```

## 5. CHAINCODE GELİŞTİRME

### 5.1 Basit Chaincode Yapısı
```javascript
const { Contract } = require('fabric-contract-api');

class UAVContract extends Contract {
    
    async CreateUAV(ctx, uavId, model, marka, üretimTarihi) {
        const uav = {
            uavId,
            model, 
            marka,
            üretimTarihi,
            durum: 'Üretildi'
        };
        
        await ctx.stub.putState(uavId, Buffer.from(JSON.stringify(uav)));
        return JSON.stringify(uav);
    }
    
    async RecordFlight(ctx, uavId, koordinat, irtifa, hız, durum, zaman, batarya) {
        const flightId = `FLIGHT_${uavId}_${Date.now()}`;
        const flight = {
            flightId,
            uavId,
            koordinat,
            irtifa: parseInt(irtifa),
            hız: parseInt(hız), 
            durum,
            zaman,
            batarya: parseInt(batarya)
        };
        
        await ctx.stub.putState(flightId, Buffer.from(JSON.stringify(flight)));
        return JSON.stringify(flight);
    }
    
    async QueryUAV(ctx, uavId) {
        const uavJSON = await ctx.stub.getState(uavId);
        return uavJSON.toString();
    }
}

module.exports = UAVContract;
```

## 6. TEST PLANI

### 6.1 Temel Testler
- İHA kaydı oluşturma
- Uçuş verisi kaydetme  
- Parça takibi
- Veri sorgulama

### 6.2 Test Komutları
```bash
# İHA oluştur
peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n uav-tracker -c '{"function":"CreateUAV","Args":["IHA001","TB2","Baykar","2024-01-15"]}'

# Uçuş verisi kaydet
peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n uav-tracker -c '{"function":"RecordFlight","Args":["IHA001","39.9334,32.8597","1500","120","Uçuşta","2024-06-05T14:30:00Z","85"]}'

# Sorgula
peer chaincode query -C mychannel -n uav-tracker -c '{"function":"QueryUAV","Args":["IHA001"]}'
```

## 7. DEMO SENARYOSU

### Adım 1: İHA Üretimi
- Yeni İHA kaydı oluştur
- Parçaları kaydet ve İHA'ya ata

### Adım 2: Operasyon
- Uçuş öncesi kontroller
- Real-time uçuş verisi kaydet
- Anomali tespiti durumunda kayıt

### Adım 3: Raporlama
- İHA geçmişini sorgula
- Parça takibi kontrolü
- Anomali raporları

## 8. BASIT WEB ARAYÜZÜ

### 8.1 Ana Sayfalar
- İHA Listesi
- Uçuş Takibi (Harita)  
- Parça Yönetimi
- Anomali Raporları

### 8.2 Teknoloji Stack
- Frontend: React.js
- Backend: Node.js + Express
- Blockchain: HyperLedger Fabric SDK

## 9. SUNUM İÇİN HAZIRLIK

### 9.1 Demo Verileri
- 3-5 örnek İHA
- 10-15 uçuş kaydı
- 5-10 parça kaydı
- 2-3 anomali örneği

### 9.2 Gösterim Senaryosu
1. **Live Demo**: Yeni uçuş verisi ekleme
2. **Visualization**: Harita üzerinde İHA konumları
3. **Traceability**: Parça geçmişi sorgulama
4. **Security**: Blockchain veri bütünlüğü gösterimi

---

**Teknofest 2025**  
**Basit ve Etkili Blockchain Çözümü**