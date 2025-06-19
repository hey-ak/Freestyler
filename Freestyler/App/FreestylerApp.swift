//
//  FreestylerApp.swift
//  Freestyler
//
//  Created by Akshay Jha on 17/06/25.
//

import SwiftUI

@main
struct FreestylerApp: App {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var sessionManager = UserSessionManager()
    var body: some Scene {
        WindowGroup {
            Group {
                if sessionManager.isAuthenticated {
            ContentView()
                } else {
                    LoginView(sessionManager: sessionManager)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .environmentObject(sessionManager)
        }
    }
}
