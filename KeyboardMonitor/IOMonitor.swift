//
//  IOMonitor.swift
//  KeyboardMonitor
//
//  Created by Kedia on 2023/8/22.
//

import Foundation
import AppKit
import Carbon


// 監聽 Caps Lock 狀態
final class IOMonitor {
    
    static let shared = IOMonitor()
    
    func start() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(inputMethodChanged(_:)), name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil)
                
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] (event) in

            guard let currentInput = self?.getCurrentInputSource() else {
                return
            }
            debugPrint("Current input method: \(currentInput)")
            
            let capsLockOn = event.modifierFlags.contains(.capsLock)
            if capsLockOn {
                //                serialPort.send("1") // 傳送 '1' 到 Arduino 表示 Caps Lock 已開啟
                debugPrint("1")
            } else {
                //                serialPort.send("0") // 傳送 '0' 到 Arduino 表示 Caps Lock 已關閉
                debugPrint("0")
            }
        }
    }
    
    @objc func inputMethodChanged(_ notification: Notification) {
        guard let currentInput = getCurrentInputSource() else {
            return
        }
        print("Current input method: \(currentInput)")
    }
    
    func getCurrentInputSource() -> String? {
        let inputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let currentInput = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            return currentInput
        }
        return nil
    }


    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
}
