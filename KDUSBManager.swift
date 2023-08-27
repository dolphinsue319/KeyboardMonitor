//
//  KDUSBManager.swift
//  KeyboardMonitor
//
//  Created by Kedia on 2023/8/27.
//

import IOKit.usb
import IOKit.serial
import Foundation
import ORSSerial

class KDUSBManager {

    enum ConnectionStatus {
        case disconnect
        case connected
    }

    enum Command: String {
        case red = "c"
        case blue = "e"
        case blink = "l"
    }

    static let shared = KDUSBManager()

    private(set) var connectionStatus: ConnectionStatus = .disconnect
    private(set) var serialPort: ORSSerialPort?

    func connect() {
        guard let portPath = findSerialNodeMCU32S() else {
            connectionStatus = .disconnect
            serialPort = nil
            return
        }
        let port = ORSSerialPort(path: portPath)
        port?.baudRate = 9600
        port?.open()
        connectionStatus = .connected
        serialPort = port
    }

    func disconnect() {
        serialPort?.close()
    }

    deinit {
        disconnect()
    }

    func sendCommand(_ c: Command) {
        guard let d = c.rawValue.data(using: .ascii) else {
            return
        }
        serialPort?.send(d)
    }

    private func findSerialNodeMCU32S() -> String? {
        var port: String?
        let matchingDict = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
        matchingDict[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes

        var iterator: io_iterator_t = 0
        let kernResult = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)

        if kernResult == KERN_SUCCESS {
            var next: io_object_t

            repeat {
                next = IOIteratorNext(iterator)
                if next != 0 {
                    let serialService: io_object_t = next
                    let key: CFString = "IOCalloutDevice" as CFString

                    if let pathAsCFString = IORegistryEntryCreateCFProperty(serialService, key, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String,
                       let path = pathAsCFString as String? {

                        let deviceInfo = IORegistryEntryCreateCFProperty(serialService, "idProduct" as CFString, kCFAllocatorDefault, 0)
                        let vendorInfo = IORegistryEntryCreateCFProperty(serialService, "idVendor" as CFString, kCFAllocatorDefault, 0)

                        if let deviceData = deviceInfo?.takeRetainedValue() as? Data,
                           let vendorData = vendorInfo?.takeRetainedValue() as? Data {

                            var deviceID: Int = 0
                            var vendorID: Int = 0

                            (deviceData as NSData).getBytes(&deviceID, length: MemoryLayout<UInt32>.size)
                            (vendorData as NSData).getBytes(&vendorID, length: MemoryLayout<UInt32>.size)

                            if vendorID == vendorID && deviceID == productID {
                                port = path
                            }
                        }
                    }

                    IOObjectRelease(serialService)
                }
            } while next != 0

            IOObjectRelease(iterator)
        }

        return port
    }

    private let vendorID = 0x1A86
    private let productID = 0x7523

}

