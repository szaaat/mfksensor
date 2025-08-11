import CoreBluetooth

class BLEManager: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    var onDataReceived: ((String) -> Void)?
    var onDisconnected: (() -> Void)?
    
    // UUID-k az SEN66 szenzorhoz
    private let sen66ServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    private let sen66CharacteristicUUID = CBUUID(string: "87654321-4321-4321-4321-cba987654321")
    
    // Az SEN55 service UUID-ja (környezeti szenzorokhoz, feltételezem, hogy ez a szabványos UUID)
    private let sen55ServiceUUID = CBUUID(string: "181A") // Environmental Sensing Service UUID
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "SEN55BLEManager"])
    }

    func startScanning() {
        print("BLEManager: startScanning called")
        if centralManager.state == .poweredOn {
            print("BLEManager: Bluetooth bekapcsolva, szkennelés indítása")
            // Szkennelés mindkét service UUID-ra
            centralManager.scanForPeripherals(withServices: [sen55ServiceUUID, sen66ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            print("BLEManager: Bluetooth nem elérhető: \(centralManager.state.rawValue)")
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("BLEManager: Bluetooth bekapcsolva, szkennelés indítása")
            centralManager.scanForPeripherals(withServices: [sen55ServiceUUID, sen66ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            print("BLEManager: Bluetooth nem elérhető: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("BLEManager: Eszköz megtalálva: \(peripheral.name ?? "N/A"), RSSI: \(RSSI)")
        // Ellenőrizzük, hogy az eszköz neve alapján SEN55 vagy SEN66
        let peripheralName = peripheral.name ?? "N/A"
        if peripheralName.contains("SEN55") || peripheralName.contains("SEN66") {
            print("BLEManager: Célzott eszköz: \(peripheralName)")
            self.peripheral = peripheral
            peripheral.delegate = self
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BLEManager: Csatlakozva a következőhöz: \(peripheral.name ?? "N/A")")
        peripheral.discoverServices([sen55ServiceUUID, sen66ServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("BLEManager: Eszköz lecsatlakozott: \(peripheral.name ?? "N/A")")
        onDisconnected?()
        self.peripheral = nil
        centralManager.scanForPeripherals(withServices: [sen55ServiceUUID, sen66ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScanning() {
        centralManager.stopScan()
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        self.peripheral = nil
        print("BLEManager: Szkennelés leállítva")
    }

    // Háttér mód támogatása
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        print("BLEManager: willRestoreState called")
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            if let restoredPeripheral = peripherals.first {
                self.peripheral = restoredPeripheral
                restoredPeripheral.delegate = self
                centralManager.connect(restoredPeripheral, options: nil)
            }
        }
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("BLEManager: Szolgáltatások keresési hiba: \(error)")
            return
        }
        peripheral.services?.forEach { service in
            print("BLEManager: Szolgáltatás megtalálva: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("BLEManager: Jellemzők keresési hiba: \(error)")
            return
        }
        service.characteristics?.forEach { characteristic in
            print("BLEManager: Jellemző megtalálva: \(characteristic.uuid)")
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BLEManager: Értékfrissítési hiba: \(error)")
            return
        }
        if let value = characteristic.value, let dataString = String(data: value, encoding: .utf8) {
            print("BLEManager: Adat érkezett: \(dataString)")
            // Előtag hozzáadása az adatokhoz a szenzor azonosításához
            let peripheralName = peripheral.name ?? "Unknown"
            let taggedData = "\(peripheralName): \(dataString)"
            onDataReceived?(taggedData)
        }
    }
}
