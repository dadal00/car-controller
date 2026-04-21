//
//  BluetoothManager.swift
//  CarController
//
//  Created by Dylan Adal on 2/23/26.
//

import CoreBluetooth

class BluetoothCentral: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var manager: CBCentralManager!
    
    @Published var carPeripheral: CBPeripheral?
    var controlCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        
        if isPeripheral {
            return
        }
        
        manager = CBCentralManager(delegate: self, queue: nil)
        print("Initializing central...")
    }
    
    // callback once bluetooth on then scan for peripherals
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // check if bluetooth
        if central.state == .poweredOn {
            print("Bluetooth is ON")
            
            manager.scanForPeripherals(withServices: [IDs.car])
            print("Scanning for peripherals...")
        } else {
            print("Bluetooth not available")
        }
    }
    
    // found a peripheral, save and connect to it
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        //        print("Peripheral: \(peripheral.name ?? "Unknown"), UUID: \(peripheral.identifier)")
        //        print("Advertisement Data: \(advertisementData)")
        
        print("Found peripheral: \(peripheral.name ?? "Unknown")")
        
        // save and connect to device
        self.carPeripheral = peripheral
        manager.stopScan()
        manager.connect(peripheral)
    }
    
    // connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral")
        
        // once connected, probe for list of actual characteristics
        peripheral.delegate = self
        peripheral.discoverServices([IDs.car])
    }
    
    // called when a peripheral disconnects (or fails)
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        
        if let error = error {
            print("Disconnected from peripheral with error: \(error.localizedDescription)")
        } else {
            print("Peripheral disconnected normally")
        }
        
        // Clear previous references
        if self.carPeripheral == peripheral {
            self.carPeripheral = nil
            self.controlCharacteristic = nil
        }
        
        // Restart scanning
        print("Restarting scan...")
        manager.scanForPeripherals(withServices: [IDs.car])
    }
    
    
    /* Peripherals */
    
    // discover characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics([IDs.control], for: service)
        }
    }
    
    // identify and assign characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics, self.controlCharacteristic == nil else {
            return
        }
        
        for characteric in characteristics {
            switch characteric.uuid {
            case IDs.control:
                self.controlCharacteristic = characteric
                print("Found control!")
            default:
                print("Unknown characteristic: \(characteric.uuid)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("Peripheral services modified or lost: \(invalidatedServices.map { $0.uuid.uuidString })")
        
        // If this is the peripheral we care about, treat it as disconnected
        if peripheral == carPeripheral {
            print("Services invalidated — clearing peripheral and restarting scan")
            carPeripheral = nil
            controlCharacteristic = nil
            
            // Stop any ongoing connection attempts
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to write to \(characteristic.uuid.uuidString): \(error.localizedDescription)")
            print("Characteristic \(characteristic.uuid) properties: \(characteristic.properties)")
            if characteristic.properties.contains(.write) {
                print("Can write with response")
            }
            print("past")
            if characteristic.properties.contains(.writeWithoutResponse) {
                print("Can write without response")
            }
            print("past")
        } else {
            print("Successfully wrote to \(characteristic.uuid.uuidString)")
        }
    }
    
    func updateCar(magnitude: UInt8, angle: UInt16) {
        if carPeripheral == nil {
            print("peripheral not found!")
            return
        }
        
        if controlCharacteristic == nil {
            print("control not found!")
            return
        }
        
        var angleLE = angle.littleEndian
        let bytes = withUnsafeBytes(of: &angleLE) { Array($0) }

        let command: [UInt8] = [magnitude] + bytes
        let data = Data(command)
        carPeripheral!.writeValue(data, for: controlCharacteristic!, type: .withoutResponse)
    }
    
    func lightOn() {
        print("Light turning on!")
    }
    
    func lightOff() {
        print("Light turning off!")
    }
}
