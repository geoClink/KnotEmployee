import SwiftUI

struct AddEmployeeView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var jobTitle = ""
    @State private var email = ""
    @State private var password = ""
    @State private var hourlyRateText = ""
    @State private var isManager = false
    @State private var showConfirmAlert = false
    @State private var isLoading = false

    private var emailIsValid: Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".")
    }
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jobTitle.isEmpty && emailIsValid &&
        password.count >= 8 && hourlyRate != nil && !isLoading
    }
    private var hourlyRate: Double? { Double(hourlyRateText) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    infoCard
                    field("Full name", text: $name, placeholder: "e.g. Mia Torres")
                    field("Job title", text: $jobTitle, placeholder: "e.g. Baker, Cashier")
                    emailField
                    passwordField
                    rateField
                    managerToggle
                    signOutWarning
                    submitButton
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Add employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(theme.body(15)).foregroundStyle(theme.inkSoft)
                }
            }
        }
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 10) {
            IconView(icon: .user, size: 18, color: theme.rose)
                .frame(width: 32, height: 32)
                .background(theme.rose.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("New employee account").font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
                Text("This creates a login account and adds them to the team. They can sign in immediately with the email and password you set.")
                    .font(theme.body(13)).foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(theme.rose.opacity(0.08), in: RoundedRectangle(cornerRadius: theme.rCard))
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String,
                       keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EMAIL").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField("employee@email.com", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard)
                    .strokeBorder(!email.isEmpty && !emailIsValid ? theme.roseDeep : theme.line,
                                  lineWidth: !email.isEmpty && !emailIsValid ? 2 : 1))
            if !email.isEmpty && !emailIsValid {
                Text("Enter a valid email address")
                    .font(theme.body(12)).foregroundStyle(theme.roseDeep).padding(.leading, 4)
            }
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TEMPORARY PASSWORD").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            SecureField("Min 8 characters", text: $password)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(
                    !password.isEmpty && password.count < 8 ? theme.roseDeep : theme.line,
                    lineWidth: !password.isEmpty && password.count < 8 ? 2 : 1))
            if !password.isEmpty && password.count < 8 {
                Text("At least 8 characters required")
                    .font(theme.body(12)).foregroundStyle(theme.roseDeep).padding(.leading, 4)
            }
        }
    }

    private var rateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HOURLY RATE ($)").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField("e.g. 18.50", text: $hourlyRateText)
                .keyboardType(.decimalPad)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var managerToggle: some View {
        HStack(spacing: 12) {
            IconView(icon: .users, size: 17, color: theme.inkSoft)
                .frame(width: 30, height: 30)
                .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: 7))
            Text("Manager access").font(theme.body(15)).foregroundStyle(theme.ink)
            Spacer()
            Toggle("", isOn: $isManager).labelsHidden().tint(theme.green)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
    }

    private var signOutWarning: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13)).foregroundStyle(theme.gold)
                .padding(.top, 1)
            Text("After adding this employee you will be signed out and need to sign back in.")
                .font(theme.body(13)).foregroundStyle(theme.inkSoft)
        }
        .padding(.horizontal, 4)
    }

    private var submitButton: some View {
        Button { showConfirmAlert = true } label: {
            Group {
                if isLoading { ProgressView().tint(theme.paper) }
                else { Text("Add employee").font(theme.bodyMedium(15)).foregroundStyle(theme.paper) }
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(canSubmit ? theme.ink : theme.inkFaint, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .alert("Add \(name)?", isPresented: $showConfirmAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Add & sign out") { addEmployee() }
        } message: {
            Text("This will create their account and sign you out. Sign back in to continue.")
        }
    }

    private func addEmployee() {
        guard let rate = hourlyRate else { return }
        isLoading = true
        Task {
            let success = await store.addEmployee(
                name: name, jobTitle: jobTitle, email: email,
                password: password, hourlyRate: rate, isManager: isManager)
            isLoading = false
            if success { dismiss() }
        }
    }
}

#Preview {
    AddEmployeeView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
