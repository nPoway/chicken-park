//
//  ChikenParkApp.swift
//  ChikenPark
//
//  Created by Nikita on 21.07.2026.
//

import SwiftUI

@main
@MainActor
struct ChikenParkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
