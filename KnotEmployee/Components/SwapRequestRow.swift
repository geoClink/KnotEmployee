import SwiftUI

struct SwapRequestRow: View {
    @Environment(\.knotTheme) private var theme
    let swap: Swap

    var body: some View {
        HStack(spacing: 12) {
            Avatar(name: swap.withName, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(swap.direction == .outgoing ? "To \(swap.withName)" : "From \(swap.withName)")
                    .font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                Text(swap.direction == .outgoing ? "You requested a swap" : "Wants to swap with you")
                    .font(theme.body(13)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            StatusBadge(status: badge, small: true)
        }
        .knotCard(padding: 13)
        .accessibilityElement(children: .combine)
    }

    private var badge: BadgeStatus {
        switch swap.status {
        case .pending:  .pending
        case .approved: .approved
        case .denied:   .denied
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SwapRequestRow(swap: Swap(direction: .outgoing, status: .pending, withName: "Aisha Bello"))
        SwapRequestRow(swap: Swap(direction: .incoming, status: .approved, withName: "Devon Hale"))
        SwapRequestRow(swap: Swap(direction: .outgoing, status: .denied, withName: "Theo Brandt"))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
