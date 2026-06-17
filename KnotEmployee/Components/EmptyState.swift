import SwiftUI

struct EmptyState: View {
    @Environment(\.knotTheme) private var theme
    let icon: KnotIcon
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            IconView(icon: icon, size: 28, color: theme.inkFaint)
                .frame(width: 64, height: 64)
                .background(theme.creamDeep, in: Circle())
                .accessibilityHidden(true)
            Text(title).font(theme.display(21)).foregroundStyle(theme.ink)
            Text(message)
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

#Preview {
    EmptyState(icon: .calendar, title: "Nothing here", message: "When something appears, you'll see it here.")
        .background(BakeryCoTheme().cream)
        .environment(\.knotTheme, BakeryCoTheme())
}
