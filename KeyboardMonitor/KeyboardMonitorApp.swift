//
//  KeyboardMonitorApp.swift
//  KeyboardMonitor
//
//  Created by Kedia on 2023/8/22.
//

import SwiftUI

@main
struct KeyboardMonitorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        IOMonitor.shared.start()
    }
}
