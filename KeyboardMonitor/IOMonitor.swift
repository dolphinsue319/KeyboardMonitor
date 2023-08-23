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
            let capsLockOn = event.modifierFlags.contains(.capsLock)
            let capsLockString = capsLockOn ? "CapsLock" : ""
            let color: NSColor = capsLockOn ? .red : .blue
            self?.showPopup(title: "\(currentInput)\n\(capsLockString)", textColor: color)
        }
    }
    
    @objc func inputMethodChanged(_ notification: Notification) {
        guard let currentInput = getCurrentInputSource() else {
            return
        }
        let color: NSColor = currentInput.lowercased().contains("abc") ? .blue : .red
        showPopup(title: currentInput, textColor: color)
    }
    
    func getCurrentInputSource() -> String? {
        let inputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let currentInput = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            return currentInput.components(separatedBy: ".").last
        }
        return nil
    }
    
    func showPopup(title: String, textColor: NSColor) {
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
        
        let label = NSTextField(labelWithString: title)
        label.backgroundColor = .init(white: 0, alpha: 0.3)
        label.layer?.cornerRadius = 8
        label.font = .boldSystemFont(ofSize: 26)
        label.textColor = textColor
        
        window.contentView?.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
        
        // 顯示視窗
        self.popupWindow = window
        window.makeKeyAndOrderFront(nil)
        
        // 設定2秒後自動消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            window.close()
            self.popupWindow = nil
        }
    }

    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    private var popupWindow: NSWindow?
}
