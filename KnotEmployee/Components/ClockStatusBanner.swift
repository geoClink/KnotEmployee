import SwiftUI

struct ClockStatusBanner: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                IconView(icon: .clock, size: 24, color: dotColor)
                    .frame(width: 44, height: 44)
                    .background(theme.paper.opacity(0.08), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Circle().fill(dotColor).frame(width: 7, height: 7)
                            .accessibilityHidden(true)
                        Text(title).font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
                    }
                    TimelineView(.periodic(from: .now, by: 60)) { ctx in
                        Text(subtitle(now: ctx.date)).font(theme.body(13)).foregroundStyle(theme.inkFaint)
                    }
                }
                Spacer()
                Button(action: primaryAction) {
                    Text(buttonLabel).font(theme.bodyMedium(14)).foregroundStyle(buttonTextColor)
                        .padding(.horizontal, 18).frame(height: 44)
                        .background(buttonColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if store.clockState == .clockedIn {
                Button { store.startBreak() } label: {
                    Text("Take a break").font(theme.bodyMedium(13)).foregroundStyle(theme.paper)
                        .frame(maxWidth: .infinity).frame(height: 38)
                        .background(theme.paper.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(theme.ink, in: RoundedRectangle(cornerRadius: theme.rCardLarge))
    }

    private var title: String {
        switch store.clockState {
        case .out: "Not clocked in"
        case .clockedIn: "Clocked in"
        case .onBreak: "On break"
        }
    }
    private func formatTime(_ hhmm: String) -> String {
        let inf = DateFormatter(); inf.dateFormat = "HH:mm"
        let outf = DateFormatter(); outf.dateFormat = "h:mm a"
        return inf.date(from: hhmm).map { outf.string(from: $0) } ?? hhmm
    }

    private func subtitle(now: Date) -> String {
        switch store.clockState {
        case .out:
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let today = df.string(from: now)
            if let todayShift = store.shift.first(where: { $0.shiftDate == today }) {
                return "Your shift starts at \(formatTime(todayShift.start))"
            }
            return "No shift scheduled today"
        case .clockedIn:
            if let start = store.clockInAt {
                let mins = max(0, Int(now.timeIntervalSince(start) / 60))
                return "Since \(start.formatted(date: .omitted, time: .shortened)) · \(mins / 60)h \(mins % 60)m"
            }
            return "Clocked in"
        case .onBreak: 
            return "On break — back soon"
        }
    }
    private var buttonLabel: String {
        switch store.clockState {
        case .out: "Clock in"
        case .clockedIn: "Clock out"
        case .onBreak: "End break"
        }
    }
    private var dotColor: Color {
        switch store.clockState {
        case .out: theme.inkFaint
        case .clockedIn: theme.green
        case .onBreak: theme.gold
        }
    }
    private var buttonColor: Color { store.clockState == .out ? theme.rose : theme.paper }
    private var buttonTextColor: Color { store.clockState == .out ? theme.paper : theme.ink }

    private func primaryAction() {
        switch store.clockState {
        case .out:      store.clockIn()
        case .clockedIn: store.clockOut()
        case .onBreak:  store.endBreak()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ClockStatusBanner()
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
    .environment(AppStore.sample)
}
