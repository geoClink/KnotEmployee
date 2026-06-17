import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Reset password").font(theme.display(30)).foregroundStyle(theme.ink)
                    Text("We'll send a reset link to your email address.")
                        .font(theme.body(14)).foregroundStyle(theme.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 36)

                if store.resetEmailSent {
                    sentConfirmation
                } else {
                    emailForm
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(theme.body(15)).foregroundStyle(theme.inkSoft)
                }
            }
            .onDisappear { store.resetEmailSent = false; store.authError = nil }
        }
    }

    private var emailForm: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(theme.body(16))
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))

            if let err = store.authError {
                Text(err).font(theme.body(13)).foregroundStyle(theme.roseDeep)
            }

            Button(action: { Task { await store.sendPasswordReset(email: email) } }) {
                Group {
                    if store.isLoading {
                        ProgressView().tint(theme.paper)
                    } else {
                        Text("Send reset link").font(theme.bodyMedium(16)).foregroundStyle(theme.paper)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(email.isEmpty ? theme.inkFaint : theme.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(email.isEmpty || store.isLoading)
        }
    }

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.checkmark.fill")
                .font(.system(size: 48))
                .foregroundStyle(theme.green)
                .accessibilityHidden(true)
            Text("Check your inbox").font(theme.display(22)).foregroundStyle(theme.ink)
            Text("We sent a reset link to **\(email)**. Tap the link in the email to set a new password.")
                .font(theme.body(14)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center)
            Button("Done") { dismiss() }
                .font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(theme.ink, in: Capsule())
                .buttonStyle(.plain)
                .padding(.top, 8)
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
