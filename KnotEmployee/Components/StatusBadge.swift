import SwiftUI

enum BadgeStatus {
    case pending, approved, denied
    case clockedIn, clockedOut, onBreak
}

struct StatusBadge: View {
    @Environment(\.knotTheme) private var theme
    let status: BadgeStatus
    var small: Bool = false
    
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(theme.bodyMedium(small ? 11 : 12))
        }
        .foregroundStyle(color)
        .padding(.horizontal, small ? 8 : 10)
        .padding(.vertical, small ? 2 : 3)
        .background(color.opacity(0.14), in: Capsule())
    }
    
    private var label: String {
        switch status {
        case .pending:     "Pending"
        case .approved:    "Approved"
        case .denied:      "Denied"
        case .clockedIn:   "Clocked in"
        case .clockedOut:  "Clocked out"
        case .onBreak:     "On break"
        }
    }
    
    private var color: Color {
        switch status {
        case .pending, .onBreak: theme.gold
        case .approved, .clockedIn: theme.green
        case .denied: theme.roseDeep
        case .clockedOut: theme.inkFaint
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack { StatusBadge(status: .pending); StatusBadge(status: .approved); StatusBadge(status: .denied) }
        HStack { StatusBadge(status: .clockedIn); StatusBadge(status: .onBreak); StatusBadge(status: .clockedOut) }
    }
    .padding(40)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
