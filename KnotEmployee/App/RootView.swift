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
        TabView(selection: Binding(get: { store.selectedTab }, set: { store.selectedTab = $0 })) {
            HomeView().tabItem { Label("Home", systemImage: "house") }.tag(0)
            ScheduleView().tabItem { Label("Schedule", systemImage: "calendar") }.tag(1)
            MessagesView().tabItem { Label("Messages", systemImage: "bubble.left") }
                .badge(store.unreadMessageCount).tag(2)
            NavigationStack { NotificationsView() }
                .tabItem { Label("Alerts", systemImage: "bell") }
                .badge(store.unreadNotificationCount).tag(3)
            StaffMoreView().tabItem { Label("More", systemImage: "ellipsis") }.tag(4)
        }
        .tint(theme.rose)
    }
}

struct ManagerTabView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    var body: some View {
        TabView(selection: Binding(get: { store.selectedTab }, set: { store.selectedTab = $0 })) {
            ManagerHomeView().tabItem { Label("Home", systemImage: "house") }.tag(0)
            ScheduleBuilderView()
                .tabItem { Label("Schedule", systemImage: "calendar") }.tag(1)
            StaffDirectoryView()
                .tabItem { Label("Team", systemImage: "person.2") }.tag(2)
            ManagerMessagesView()
                .tabItem { Label("Messages", systemImage: "bubble.left") }
                .badge(store.unreadMessageCount).tag(3)
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }.tag(4)
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
            .toolbarBackground(theme.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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



struct RootGate: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if store.isResettingPassword {
                ResetPasswordView()
            } else if store.isAuthenticated && store.isLoading {
                loadingScreen
            } else if store.isAuthenticated {
                RootView()
            } else {
                LoginView()
            }
        }
        .overlay(alignment: .top) {
            if store.isOffline {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                    Text("No internet connection").font(theme.body(13))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.9))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay {
            if scenePhase != .active && store.isAuthenticated {
                theme.cream.ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 14) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(theme.inkFaint)
                            Text(theme.name)
                                .font(theme.display(22))
                                .foregroundStyle(theme.inkMuted)
                        }
                    }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: scenePhase)
        .animation(.easeInOut(duration: 0.3), value: store.isOffline)
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
