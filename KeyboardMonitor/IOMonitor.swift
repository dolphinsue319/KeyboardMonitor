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
            self.showPopup(title: message)
        }
    }
    
    @objc func inputMethodChanged(_ notification: Notification) {
        guard let currentInput = getCurrentInputSource() else {
            return
        }
        showPopup(title: currentInput)
    }
    
    func getCurrentInputSource() -> String? {
        let inputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let currentInput = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            return currentInput.components(separatedBy: ".").last
        }
        return nil
    }
    
    func showPopup(title: String) {
        if popupWindow != nil {
            popupWindow?.close()
            self.popupWindow = nil
        }
        
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) else {
            return
        }
        
        // 'screen' 是用戶目前正在使用的螢幕
        let screenFrame = screen.frame
        let x = screenFrame.origin.x + (screenFrame.size.width - 300) / 4
        let y = screenFrame.origin.y + (screenFrame.size.height - 200) / 4 * 3
        
        let window = NSWindow(contentRect: NSMakeRect(x, y, 300, 200), styleMask: [], backing: .buffered, defer: false)
        window.backgroundColor = .clear
        
        guard let contentView = window.contentView else {
            return
        }
        window.level = .floating // 設定視窗總是出現在最前面
        window.isReleasedWhenClosed = false
        
        let label = NSTextField()
        label.stringValue = title
        label.wantsLayer = true
        label.layer?.cornerRadius = 10
        label.layer?.masksToBounds = true
        label.isEditable = false
        label.isSelectable = false
        label.isBezeled = false
        label.isBordered = false
        label.drawsBackground = true
        label.backgroundColor = NSColor(white: 0, alpha: 0.3)
        label.font = .boldSystemFont(ofSize: 26)
        label.textColor = textColor
        
        contentView.addSubview(label)
        
        // 顯示視窗
        self.popupWindow = window
        window.makeKeyAndOrderFront(nil)
        label.sizeToFit()
        
        // 設定2秒後自動消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let popupWindow = self?.popupWindow else {
                return
            }
            popupWindow.close()
            self?.popupWindow = nil
        }
    }

    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    private var popupWindow: NSWindow?
    private var isCapsLockOn: Bool = false
    var textColor: NSColor {
        return isCapsLockOn ? .red : .blue
    }
}
