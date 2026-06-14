import SwiftUI

struct SettingsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @State private var notifShifts = true
    @State private var notifSwaps = true
    @State private var notifMessages = true
    @State private var notifPay = false
    
    private var managerBinding: Binding<Bool> {
            Binding(
                get: { store.currentUser.role == .manager },
                set: { store.currentUser.role = $0 ? .manager : .staff }
            )
        }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    profileCard

                    group("Notifications") {
                        toggleRow(.calendar, "Shift reminders", $notifShifts)
                        divider
                        toggleRow(.swap, "Swap requests", $notifSwaps)
                        divider
                        toggleRow(.message, "Messages", $notifMessages)
                        divider
                        toggleRow(.dollar, "Pay & earnings", $notifPay)
                    }

                    group("App") {
                        navRow(.user, "Account")
                        divider
                        navRow(.lock, "Change PIN")
                        divider
                        valueRow(.bell, "Version", "1.0.0 (Phase 0)")
                    }
                    
                    group("Role (demo)") {
                                            HStack(spacing: 12) {
                                                iconTile(.users)
                                                Text("Manager mode").font(theme.body(15)).foregroundStyle(theme.ink)
                                                Spacer()
                                                Toggle("", isOn: managerBinding).labelsHidden().tint(theme.green)
                                            }
                                            .padding(.horizontal, 14).padding(.vertical, 11)
                                        }

                    Button { store.signOut() } label: {
                                            Text("Sign out")
                                                .font(theme.bodyMedium(15)).foregroundStyle(theme.roseDeep)
                                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                        }
                                        .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            Avatar(name: store.currentUser.name, size: 54)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.currentUser.name).font(theme.display(20)).foregroundStyle(theme.ink)
                Text("\(store.currentUser.jobTitle) · The Bakery Co.")
                    .font(theme.body(13)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            IconView(icon: .chevronRight, size: 18, color: theme.inkFaint)
        }
        .knotCard(padding: 16)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private func iconTile(_ icon: KnotIcon) -> some View {
        IconView(icon: icon, size: 17, color: theme.inkSoft)
            .frame(width: 30, height: 30)
            .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: 7))
    }

    private func toggleRow(_ icon: KnotIcon, _ label: String, _ isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconTile(icon)
            Text(label).font(theme.body(15)).foregroundStyle(theme.ink)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(theme.green)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    private func navRow(_ icon: KnotIcon, _ label: String) -> some View {
        HStack(spacing: 12) {
            iconTile(icon)
            Text(label).font(theme.body(15)).foregroundStyle(theme.ink)
            Spacer()
            IconView(icon: .chevronRight, size: 18, color: theme.inkFaint)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    private func valueRow(_ icon: KnotIcon, _ label: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            iconTile(icon)
            Text(label).font(theme.body(15)).foregroundStyle(theme.ink)
            Spacer()
            Text(value).font(theme.body(13)).foregroundStyle(theme.inkMuted)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    private var divider: some View {
        Rectangle().fill(theme.lineSoft).frame(height: 1).padding(.leading, 56)
    }
}

#Preview {
    SettingsView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
