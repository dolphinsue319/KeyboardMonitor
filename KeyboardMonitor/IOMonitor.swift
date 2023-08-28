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
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(inputMethodChanged), name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil)
                
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
            inputMethodChanged()
        }

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
        var blinkCommand: KDUSBManager.Command = isCapsLockOn ? .blinkOn : .blinkOff
        
        if currentInput.lowercased().contains("abc") {
            colorCommand = .green
            if isCapsLockOn {
                blinkCommand = .blinkOn
            }
            else {
                blinkCommand = .blinkOff
            }
        } 
        else {
            blinkCommand = .blinkOff
            if isCapsLockOn {
                colorCommand = .green
            }
            else {
                colorCommand = .blue
            }
        }
        
        KDUSBManager.shared.sendCommand(colorCommand)
        KDUSBManager.shared.sendCommand(blinkCommand)
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
    var textColor: NSColor {
        return isCapsLockOn ? .red : .blue
    }
}
