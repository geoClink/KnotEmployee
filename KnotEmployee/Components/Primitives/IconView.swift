import SwiftUI

// Maps named icons to SF Symbols — native, scalable, no asset files.
enum KnotIcon: String {
    case home, calendar, message, clock, swap, bell, dollar, user, users
    case chart, gear, chevronRight, chevronLeft, plus, check, xmark
    case search, download, send, lock, handoff, pause

    var systemName: String {
        switch self {
        case .home: "house"
        case .calendar: "calendar"
        case .message: "bubble.left"
        case .clock: "clock"
        case .swap: "arrow.left.arrow.right"
        case .bell: "bell"
        case .dollar: "dollarsign.circle"
        case .user: "person"
        case .users: "person.2"
        case .chart: "chart.bar"
        case .gear: "gearshape"
        case .chevronRight: "chevron.right"
        case .chevronLeft: "chevron.left"
        case .plus: "plus"
        case .check: "checkmark"
        case .xmark: "xmark"
        case .search: "magnifyingglass"
        case .download: "square.and.arrow.down"
        case .send: "paperplane.fill"
        case .lock: "lock"
        case .handoff: "arrow.up.forward.square"
        case .pause: "pause"
        }
    }
}

struct IconView: View {
    @Environment(\.knotTheme) private var theme
    let icon: KnotIcon
    var size: CGFloat = 22
    var color: Color? = nil

    var body: some View {
        Image(systemName: icon.systemName)
            .font(.system(size: size * 0.9))
            .foregroundStyle(color ?? theme.inkSoft)
            .frame(width: size, height: size)
    }
}

#Preview {
    let icons: [KnotIcon] = [.home, .calendar, .message, .clock, .swap, .bell, .handoff, .pause]
    return HStack(spacing: 16) {
        ForEach(icons, id: \.rawValue) { IconView(icon: $0, size: 26) }
    }
    .padding(40)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
