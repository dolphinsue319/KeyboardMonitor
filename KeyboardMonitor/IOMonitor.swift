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

            guard let self, let currentInput = self.getCurrentInputSource() else {
                return
            }
            self.isCapsLockOn = event.modifierFlags.contains(.capsLock)
            let message = self.isCapsLockOn ? "\(currentInput)\nCapsLock" : currentInput
            KDAlertWindow.shared.showPopup(title: message, textColor: self.textColor)
        }
    }
    
    @objc func inputMethodChanged(_ notification: Notification) {
        guard let currentInput = getCurrentInputSource() else {
            return
        }
        KDAlertWindow.shared.showPopup(title: currentInput, textColor: textColor)
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
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    private var isCapsLockOn: Bool = false
    var textColor: NSColor {
        return isCapsLockOn ? .red : .blue
    }
}
