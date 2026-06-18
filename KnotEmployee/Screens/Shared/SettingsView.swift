import SwiftUI

struct SettingsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @AppStorage("notifShifts") private var notifShifts = true
    @AppStorage("notifSwaps") private var notifSwaps = true
    @AppStorage("notifMessages") private var notifMessages = true
    @AppStorage("notifPay") private var notifPay = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    profileCard

                    group("Notifications") {
                        toggleRow(.calendar, "Shift reminders", $notifShifts)
                            .onChange(of: notifShifts) { store.scheduleShiftReminders() }
                        divider
                        toggleRow(.swap, "Swap requests", $notifSwaps)
                        divider
                        toggleRow(.message, "Messages", $notifMessages)
                        divider
                        toggleRow(.dollar, "Pay & earnings", $notifPay)
                    }

                    group("App") {
                        NavigationLink { AccountView() } label: { navRowContent(.user, "Account") }
                            .buttonStyle(.plain)
                        divider
                        NavigationLink { AvailabilityView() } label: { navRowContent(.calendar, "My availability") }
                            .buttonStyle(.plain)
                        divider
                        NavigationLink { ChangePINView() } label: { navRowContent(.lock, "Change password") }
                            .buttonStyle(.plain)
                        divider
                        valueRow(.bell, "Version", "1.0.0 (Phase 0)")
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
        NavigationLink { AccountView() } label: {
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
        .buttonStyle(.plain)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
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

    private func navRowContent(_ icon: KnotIcon, _ label: String) -> some View {
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
        .accessibilityElement(children: .combine)
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

struct AccountView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Avatar(name: store.currentUser.name, size: 72)
                    .padding(.top, 8)

                VStack(spacing: 4) {
                    Text(store.currentUser.name).font(theme.display(26)).foregroundStyle(theme.ink)
                    Text(store.currentUser.jobTitle).font(theme.body(15)).foregroundStyle(theme.inkMuted)
                }

                VStack(spacing: 0) {
                    infoRow("Role", store.currentUser.role.rawValue.capitalized)
                    Rectangle().fill(theme.lineSoft).frame(height: 1).padding(.leading, 16)
                    infoRow("Hours this week", "\(String(format: "%.1f", store.currentUser.hoursThisWeek)) hrs")
                    Rectangle().fill(theme.lineSoft).frame(height: 1).padding(.leading, 16)
                    infoRow("Hourly rate", "$\(String(format: "%.2f", store.currentUser.hourlyRate))/hr")
                }
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
            }
            .padding(20)
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(theme.body(15)).foregroundStyle(theme.inkMuted)
            Spacer()
            Text(value).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}

struct ChangePINView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var saved = false
    @State private var isLoading = false

    private var passwordsMatch: Bool { newPassword == confirmPassword }
    private var canSave: Bool { newPassword.count >= 8 && passwordsMatch && !isLoading }
    private var mismatch: Bool { !confirmPassword.isEmpty && !passwordsMatch }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                pinField("New password", text: $newPassword)
                pinField("Confirm new password", text: $confirmPassword, isConfirm: true)

                if saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.green)
                        Text("Password updated").font(theme.body(14)).foregroundStyle(theme.green)
                    }
                    .padding(.top, 4)
                }

                Button {
                    isLoading = true
                    Task {
                        await store.updatePassword(newPassword)
                        isLoading = false
                        if store.authError == nil {
                            saved = true
                            newPassword = ""; confirmPassword = ""
                        }
                    }
                } label: {
                    Group {
                        if isLoading { ProgressView().tint(theme.paper) }
                        else { Text("Update password").font(theme.bodyMedium(15)).foregroundStyle(theme.paper) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(canSave ? theme.ink : theme.inkFaint, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pinField(_ label: String, text: Binding<String>, isConfirm: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                .padding(.leading, 4)
            SecureField(label, text: text)
                .font(.system(size: 15)).padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.rCard)
                        .strokeBorder(isConfirm && mismatch ? theme.roseDeep : theme.line, lineWidth: isConfirm && mismatch ? 2 : 1)
                )
        }
    }
}
