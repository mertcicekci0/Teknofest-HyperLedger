'use strict';

const { Contract } = require('fabric-contract-api');

class UAVContract extends Contract {

    async initLedger(ctx) {
        console.info('============= START : Initialize Ledger ===========');
        
        // Demo verileri - PDR'de belirtilen örnek veriler
        const uavs = [
            {
                uavId: 'IHA001',
                model: 'Bayraktar TB2',
                marka: 'Baykar',
                uretimTarihi: '2024-01-15',
                durum: 'Aktif'
            },
            {
                uavId: 'IHA002',
                model: 'ANKA-S',
                marka: 'TAI',
                uretimTarihi: '2024-02-10',
                durum: 'Aktif'
            },
            {
                uavId: 'IHA003',
                model: 'Bayraktar AKINCI',
                marka: 'Baykar',
                uretimTarihi: '2024-03-05',
                durum: 'Bakımda'
            }
        ];

        for (let i = 0; i < uavs.length; i++) {
            uavs[i].docType = 'uav';
            await ctx.stub.putState(uavs[i].uavId, Buffer.from(JSON.stringify(uavs[i])));
            console.info('Added <--> ', uavs[i]);
        }
        
        console.info('============= END : Initialize Ledger ===========');
    }

    // İHA Kayıt
    async CreateUAV(ctx, uavId, model, marka, uretimTarihi) {
        console.info('============= START : Create UAV ===========');

        const uav = {
            docType: 'uav',
            uavId,
            model,
            marka,
            uretimTarihi,
            durum: 'Üretildi'
        };

        await ctx.stub.putState(uavId, Buffer.from(JSON.stringify(uav)));
        console.info('============= END : Create UAV ===========');
        return JSON.stringify(uav);
    }

    // Parça Kayıt
    async RegisterPart(ctx, parcaId, parcaIsmi, marka, uretimTarihi, uavId) {
        console.info('============= START : Register Part ===========');

        const part = {
            docType: 'part',
            parcaId,
            parcaIsmi,
            marka,
            uretimTarihi,
            uavId
        };

        await ctx.stub.putState(parcaId, Buffer.from(JSON.stringify(part)));
        console.info('============= END : Register Part ===========');
        return JSON.stringify(part);
    }

    // Uçuş Verisi Kayıt
    async RecordFlight(ctx, uavId, koordinat, irtifa, hiz, durum, zaman, batarya) {
        console.info('============= START : Record Flight ===========');

        const flightId = `FLIGHT_${uavId}_${Date.now()}`;
        const flight = {
            docType: 'flight',
            flightId,
            uavId,
            koordinat,
            irtifa: parseInt(irtifa),
            hiz: parseInt(hiz),
            durum,
            zaman,
            batarya: parseInt(batarya)
        };

        await ctx.stub.putState(flightId, Buffer.from(JSON.stringify(flight)));
        console.info('============= END : Record Flight ===========');
        return JSON.stringify(flight);
    }

    // Anomali Kayıt
    async RecordAnomaly(ctx, uavId, anomaliTuru, zaman, koordinat) {
        console.info('============= START : Record Anomaly ===========');

        const anomaliId = `ANOM_${uavId}_${Date.now()}`;
        const anomaly = {
            docType: 'anomaly',
            anomaliId,
            uavId,
            anomaliTuru,
            zaman,
            koordinat
        };

        await ctx.stub.putState(anomaliId, Buffer.from(JSON.stringify(anomaly)));
        console.info('============= END : Record Anomaly ===========');
        return JSON.stringify(anomaly);
    }

    // İHA Sorgulama
    async QueryUAV(ctx, uavId) {
        const uavAsBytes = await ctx.stub.getState(uavId);
        if (!uavAsBytes || uavAsBytes.length === 0) {
            throw new Error(`${uavId} does not exist`);
        }
        console.log(uavAsBytes.toString());
        return uavAsBytes.toString();
    }

    // Uçuş Geçmişi Sorgulama
    async QueryFlightHistory(ctx, uavId) {
        console.info('============= START : Query Flight History ===========');

        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            if (record.docType === 'flight' && record.uavId === uavId) {
                allResults.push({ Key: key, Record: record });
            }
        }
        
        console.info('============= END : Query Flight History ===========');
        return JSON.stringify(allResults);
    }

    // Parça Sorgulama
    async QueryPartsByUAV(ctx, uavId) {
        console.info('============= START : Query Parts by UAV ===========');

        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            if (record.docType === 'part' && record.uavId === uavId) {
                allResults.push({ Key: key, Record: record });
            }
        }
        
        console.info('============= END : Query Parts by UAV ===========');
        return JSON.stringify(allResults);
    }

    // Anomali Sorgulama
    async QueryAnomaliesByUAV(ctx, uavId) {
        console.info('============= START : Query Anomalies by UAV ===========');

        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            if (record.docType === 'anomaly' && record.uavId === uavId) {
                allResults.push({ Key: key, Record: record });
            }
        }
        
        console.info('============= END : Query Anomalies by UAV ===========');
        return JSON.stringify(allResults);
    }

    // Tüm İHA'ları Listele
    async QueryAllUAVs(ctx) {
        console.info('============= START : Query All UAVs ===========');

        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            if (record.docType === 'uav') {
                allResults.push({ Key: key, Record: record });
            }
        }
        
        console.info('============= END : Query All UAVs ===========');
        return JSON.stringify(allResults);
    }

    // İHA Durumu Güncelle
    async UpdateUAVStatus(ctx, uavId, yeniDurum) {
        console.info('============= START : Update UAV Status ===========');

        const uavAsBytes = await ctx.stub.getState(uavId);
        if (!uavAsBytes || uavAsBytes.length === 0) {
            throw new Error(`${uavId} does not exist`);
        }
        
        const uav = JSON.parse(uavAsBytes.toString());
        uav.durum = yeniDurum;

        await ctx.stub.putState(uavId, Buffer.from(JSON.stringify(uav)));
        console.info('============= END : Update UAV Status ===========');
        return JSON.stringify(uav);
    }
}

module.exports = UAVContract;
