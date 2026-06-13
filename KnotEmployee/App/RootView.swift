import SwiftUI

struct RootView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.s4) {
                Text("Good morning, \(store.currentUser.name.components(separatedBy: " ").first ?? "")")
                    .font(theme.display(30)).foregroundStyle(theme.ink)
                ForEach(store.shift) { ShiftCard(shift: $0) }
            }
            .padding(Layout.s5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.cream.ignoresSafeArea())
    }
}

#Preview {
    RootView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
