import SwiftUI

struct LoginView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @State private var pin = ""
    @State private var error = false

    private let keys = ["1","2","3","4","5","6","7","8","9","","0","del"]

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Text("THE BAKERY CO.").font(theme.mono(11)).foregroundStyle(theme.rose).tracking(3)
                Text("Welcome back").font(theme.display(30)).foregroundStyle(theme.ink)
            }
            .padding(.bottom, 28)

            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < pin.count ? dotColor : Color.clear)
                        .overlay(Circle().strokeBorder(dotColor, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                }
            }
            Text(error ? "Incorrect PIN. Try again." : "Enter your 4-digit PIN")
                .font(theme.body(13)).foregroundStyle(error ? theme.roseDeep : theme.inkMuted)
                .padding(.top, 14)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(keys, id: \.self) { key in keyButton(key) }
            }
            .frame(maxWidth: 260)
            .padding(.top, 26)

            Spacer()
            Text("Forgot PIN?").font(theme.body(13)).foregroundStyle(theme.rose).padding(.bottom, 20)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.cream.ignoresSafeArea())
    }

    private var dotColor: Color { error ? theme.roseDeep : theme.rose }

    @ViewBuilder private func keyButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 64, height: 64)
        } else if key == "del" {
            Button { delete() } label: {
                IconView(icon: .chevronLeft, size: 22, color: theme.inkMuted)
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain).frame(maxWidth: .infinity)
        } else {
            Button { tap(key) } label: {
                Text(key).font(theme.display(26)).foregroundStyle(theme.ink)
                    .frame(width: 64, height: 64)
                    .background(theme.card, in: Circle())
                    .overlay(Circle().strokeBorder(theme.line, lineWidth: 1))
            }
            .buttonStyle(.plain).frame(maxWidth: .infinity)
        }
    }

    private func tap(_ digit: String) {
        guard pin.count < 4 else { return }
        error = false
        pin += digit
        if pin.count == 4 {
            if !store.signIn(pin: pin) {
                error = true
                pin = ""
            }
        }
    }
    private func delete() {
        error = false
        if !pin.isEmpty { pin.removeLast() }
    }
}

#Preview {
    LoginView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
