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

class KDUSBManager: NSObject {

    enum ConnectionStatus {
        case disconnect
        case connected
    }

    enum Command: String {
        case blue = "b"
        case green = "g"
        case blinkOn = "L"
        case blinkOff = "l"
    }

    static let shared = KDUSBManager()

    var connectionStatus: ConnectionStatus {
        return (serialPort?.isOpen ?? false) ? .connected : .disconnect
    }
    private var serialPort: ORSSerialPort?

    private var retryTimes = 0
    
    /// 建立與 MCU32S 之間的連線
    func connect() {
        guard let portPath = findSerialNodeMCU32S() else {
            serialPort = nil
            return
        }
        let port = ORSSerialPort(path: portPath)
        port?.baudRate = 9600
        port?.delegate = self
        port?.open()
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
        // 用 ls /dev/{cu,tty}.* 找出來的
//        return "/dev/tty.usbserial-110"
        return "/dev/cu.usbserial-110"
    }
    
    private let vendorID = 0x1A86
    private let productID = 0x7523

}

extension KDUSBManager: ORSSerialPortDelegate {
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("\(#function)")
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        print("\(#function)")
        if retryTimes > 2 {
            return
        }
        retryTimes += 1
        self.serialPort?.open()
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        print("\(#function)")
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("\(#function), error: \(error.localizedDescription)")
    }
}
