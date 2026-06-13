//
//  KnotEmployeeApp.swift
//  KnotEmployee
//
//  Created by George Clinkscales on 6/13/26.
//

import SwiftUI

@main
struct KnotEmployeeApp: App {
    @State private var store = AppStore.sample
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.knotTheme, BakeryCoTheme())
                .environment(store)
        }
    }
}
