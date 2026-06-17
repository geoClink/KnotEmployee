import SwiftUI

struct LoginView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("THE BAKERY CO.").font(theme.mono(11)).foregroundStyle(theme.rose).tracking(3)
                Text("Welcome back").font(theme.display(30)).foregroundStyle(theme.ink)
            }
            .padding(.bottom, 36)

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

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .font(theme.body(16))
                    .padding(14)
                    .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                    .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
            }

            if let err = store.authError {
                Text(err)
                    .font(theme.body(13))
                    .foregroundStyle(theme.roseDeep)
                    .padding(.top, 12)
            }

            Button("Forgot password?") { showForgotPassword = true }
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .padding(.top, 4)

            Button(action: signIn) {
                Group {
                    if store.isLoading {
                        ProgressView().tint(theme.paper)
                    } else {
                        Text("Sign in").font(theme.bodyMedium(16)).foregroundStyle(theme.paper)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(canSubmit ? theme.ink : theme.inkFaint, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || store.isLoading)
            .padding(.top, 22)

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.cream.ignoresSafeArea())
        .sheet(isPresented: $showForgotPassword) { ForgotPasswordView() }
    }

    private var canSubmit: Bool { !email.isEmpty && !password.isEmpty }

    private func signIn() {
        Task { await store.signIn(email: email, password: password) }
    }
}

#Preview {
    LoginView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
