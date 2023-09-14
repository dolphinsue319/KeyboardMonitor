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
        // 監聽輸入法的變化
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(inputMethodChanged), name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil)
        
        // 監聽 CapsLock 的變化
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] (event) in

            guard let self, let currentInput = self.getCurrentInputSource() else {
                return
            }
            self.isCapsLockOn = event.modifierFlags.contains(.capsLock)
            
            let message = self.isCapsLockOn ? "\(currentInput)\nCapsLock" : currentInput
            if KDUSBManager.shared.connectionStatus == .disconnect {
                KDAlertWindow.shared.showPopup(title: message, textColor: self.textColor)
                return
            }
            let command: KDUSBManager.Command = self.isCapsLockOn ? .blinkOn : .blinkOff
            KDUSBManager.shared.sendCommand(command)
        }

        // 建立與 NodeMCU-32S 之間的連線
        KDUSBManager.shared.connect()
    }
    
    @objc func inputMethodChanged() {
        guard let currentInput = getCurrentInputSource() else {
            return
        }
        if KDUSBManager.shared.connectionStatus == .disconnect {
            KDAlertWindow.shared.showPopup(title: currentInput, textColor: textColor)
            return
        }

        var colorCommand: KDUSBManager.Command = .green
        
        if !currentInput.lowercased().contains("abc") {
            colorCommand = .blue
        }
        
        KDUSBManager.shared.sendCommand(colorCommand)
    }
    
    func getCurrentInputSource() -> String? {
        let inputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let currentInput = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            return currentInput.components(separatedBy: ".").last
        }
        return nil
    }

    deinit {
        KDUSBManager.shared.disconnect()
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    private var isCapsLockOn: Bool = false
    private var textColor: NSColor {
        return isCapsLockOn ? .red : .blue
    }
}
