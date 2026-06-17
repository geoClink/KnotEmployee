//
//  KnotEmployeeApp.swift
//  KnotEmployee
//
//  Created by George Clinkscales on 6/13/26.
//

import SwiftUI

@main
struct KnotEmployeeApp: App {
    @State private var store = AppStore()

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        let ink = UIColor(red: 0x2A/255, green: 0x18/255, blue: 0x10/255, alpha: 1)
        if let large = UIFont(name: "CormorantGaramond-Medium", size: 36) {
            appearance.largeTitleTextAttributes = [.font: large, .foregroundColor: ink]
        }
        if let inline = UIFont(name: "CormorantGaramond-Medium", size: 20) {
            appearance.titleTextAttributes = [.font: inline, .foregroundColor: ink]
        }
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootGate()
                .environment(\.knotTheme, BakeryCoTheme())
                .environment(store)
                .task { await store.restoreSession() }
        }
    }
}
