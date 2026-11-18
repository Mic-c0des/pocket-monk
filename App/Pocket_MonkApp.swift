//
//  Pocket_MonkApp.swift
//  Pocket Monk
//
//  Created by Mic on 11/13/26.
//

import SwiftUI
import SwiftData

@main
struct Pocket_MonkApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [FriendRecord.self, DuelRecord.self])
        }
    }
}
