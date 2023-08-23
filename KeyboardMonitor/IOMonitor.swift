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
            let capsLockString = capsLockOn ? "CapsLock" : "Lowercase"
            self?.showPopup(title: "\(currentInput)\n\(capsLockString)")
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
        // ask: 我有兩個螢幕，我要如何讓 window 出現在 keywindow 的正中間？
        let window = NSWindow(contentRect: NSMakeRect(200, 200, 300, 200), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        guard let contentView = window.contentView else {
            return
        }
        window.level = .floating // 設定視窗總是出現在最前面
        window.isReleasedWhenClosed = false
        
        let label = NSTextField(labelWithString: title)
        label.backgroundColor = .clear
        
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
