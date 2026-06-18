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
    @Environment(AppStore.self) private var store
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Home", systemImage: "house") }
            ScheduleView().tabItem { Label("Schedule", systemImage: "calendar") }
            MessagesView().tabItem { Label("Messages", systemImage: "bubble.left") }
                .badge(store.unreadMessageCount)
            NavigationStack { NotificationsView() }
                .tabItem { Label("Alerts", systemImage: "bell") }
                .badge(store.unreadNotificationCount)
            StaffMoreView().tabItem { Label("More", systemImage: "ellipsis") }
        }
        .tint(theme.rose)
    }
}

struct ManagerTabView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    var body: some View {
        TabView {
            ManagerHomeView().tabItem { Label("Home", systemImage: "house") }
            ScheduleBuilderView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
            StaffDirectoryView()
                .tabItem { Label("Team", systemImage: "person.2") }
            ManagerMessagesView()
                .tabItem { Label("Messages", systemImage: "bubble.left") }
                .badge(store.unreadMessageCount)
            SettingsView().tabItem { Label("More", systemImage: "ellipsis") }
        }
        .tint(theme.rose)
    }
}

struct StaffMoreView: View {
    @Environment(\.knotTheme) private var theme
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    moreLink(icon: .handoff, title: "Open shifts") { OpenShiftsView() }
                    moreLink(icon: .swap, title: "Swap requests") { SwapRequestsView() }
                    moreLink(icon: .calendar, title: "Time off") { TimeOffView() }
                    moreLink(icon: .dollar, title: "Earnings") { EarningsView() }
                    moreLink(icon: .gear, title: "Settings") { SettingsView() }
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("More")
        }
    }

    private func moreLink<D: View>(icon: KnotIcon, title: String, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                IconView(icon: icon, size: 20, color: theme.inkSoft)
                    .frame(width: 40, height: 40)
                    .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
                Text(title).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                Spacer()
                IconView(icon: .chevronRight, size: 16, color: theme.inkFaint)
            }
            .knotCard(padding: 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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

struct RootGate: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    var body: some View {
        Group {
            if store.isResettingPassword {
                ResetPasswordView()
            } else if store.isAuthenticated && store.isLoading {
                loadingScreen
            } else if store.isAuthenticated {
                RootView()
            } else {
                LoginView()
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var loadingScreen: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(theme.ink)
                .scaleEffect(1.2)
            Text("Loading…")
                .font(theme.body(14))
                .foregroundStyle(theme.inkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.cream.ignoresSafeArea())
    }
}

#Preview {
    RootView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
