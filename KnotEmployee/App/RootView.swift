import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if store.isManager {
            ManagerTabView()
        } else {
            StaffTabView()
        }
    }
}

struct StaffTabView: View {
    @Environment(\.knotTheme) private var theme
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Home", systemImage: "house") }
            ScheduleView().tabItem { Label("Schedule", systemImage: "calendar") }
            NavigationStack { OpenShiftsView() }
                .tabItem { Label("Swaps", systemImage: "arrow.left.arrow.right") }
            SettingsView().tabItem { Label("More", systemImage: "ellipsis") }
        }
        .tint(theme.rose)
    }
}

struct ManagerTabView: View {
    @Environment(\.knotTheme) private var theme
    var body: some View {
        TabView {
            ManagerHomeView().tabItem { Label("Home", systemImage: "house") }
            PlaceholderView(title: "Schedule").tabItem { Label("Schedule", systemImage: "calendar") }
            PlaceholderView(title: "Team").tabItem { Label("Team", systemImage: "person.2") }
            SettingsView().tabItem { Label("More", systemImage: "ellipsis") }
        }
        .tint(theme.rose)
    }
}

struct PlaceholderView: View {
    @Environment(\.knotTheme) private var theme
    let title: String
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text(title).font(theme.display(28)).foregroundStyle(theme.ink)
                Text("Coming soon").font(theme.body(14)).foregroundStyle(theme.inkMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle(title)
        }
    }
}

#Preview {
    RootView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
