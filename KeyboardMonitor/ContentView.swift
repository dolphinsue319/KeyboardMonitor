//
//  ContentView.swift
//  KeyboardMonitor
//
//  Created by Kedia on 2023/8/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("英文輸入法: 綠燈🟢")
            Text("非英文輸入法: 藍燈🔵")
            Text("大寫鎖定: 閃爍🚨")
        }
        .padding()
    }
}
