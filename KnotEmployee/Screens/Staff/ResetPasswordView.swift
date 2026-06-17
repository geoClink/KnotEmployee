import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @State private var password = ""
    @State private var confirm = ""

    private var mismatch: Bool { !confirm.isEmpty && password != confirm }
    private var canSubmit: Bool { password.count >= 8 && password == confirm }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("New password").font(theme.display(30)).foregroundStyle(theme.ink)
                Text("Choose a password with at least 8 characters.")
                    .font(theme.body(14)).foregroundStyle(theme.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 36)

            VStack(spacing: 14) {
                SecureField("New password", text: $password)
                    .textContentType(.newPassword)
                    .font(theme.body(16))
                    .padding(14)
                    .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                    .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))

                SecureField("Confirm password", text: $confirm)
                    .textContentType(.newPassword)
                    .font(theme.body(16))
                    .padding(14)
                    .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.rCard)
                            .strokeBorder(mismatch ? theme.roseDeep : theme.line, lineWidth: 1)
                    )

                if mismatch {
                    Text("Passwords don't match")
                        .font(theme.body(13)).foregroundStyle(theme.roseDeep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)
                }

                if let err = store.authError {
                    Text(err).font(theme.body(13)).foregroundStyle(theme.roseDeep)
                }

                Button(action: { Task { await store.updatePassword(password) } }) {
                    Group {
                        if store.isLoading {
                            ProgressView().tint(theme.paper)
                        } else {
                            Text("Update password").font(theme.bodyMedium(16)).foregroundStyle(theme.paper)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(canSubmit ? theme.ink : theme.inkFaint, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit || store.isLoading)
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.cream.ignoresSafeArea())
    }
}

#Preview {
    ResetPasswordView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
