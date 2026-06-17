import SwiftUI

struct ShiftDetailView: View {
    @Environment(\.knotTheme) private var theme
    let shift: Shift
    var onSwap: () -> Void = {}
    var onGiveUp: () -> Void = {}
    var onTimeOff: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                infoTile(icon: .user, label: "Role", value: shift.role)
                infoTile(icon: .clock, label: "Duration", value: "6 hours")
                if let brk = shift.breakLabel {
                    infoTile(icon: .pause, label: "Break", value: brk, trailing: "~9:00 AM")
                }
                if let note = shift.note, !note.isEmpty { noteCard(note) }
                actions
            }
            .padding(20)
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Shift")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(dayFull).font(theme.mono(12)).foregroundStyle(theme.rose).textCase(.uppercase)
            Text(shift.date).font(theme.display(44)).foregroundStyle(theme.ink)
            Text(shift.timeRange).font(theme.body(17)).foregroundStyle(theme.inkSoft)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
    }

    private func infoTile(icon: KnotIcon, label: String, value: String, trailing: String? = nil) -> some View {
        HStack(spacing: 12) {
            IconView(icon: icon, size: 20, color: theme.inkSoft)
                .frame(width: 40, height: 40)
                .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(theme.body(12)).foregroundStyle(theme.inkMuted)
                Text(value).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
            }
            Spacer()
            if let trailing { Text(trailing).font(theme.body(12)).foregroundStyle(theme.inkMuted) }
        }
        .knotCard()
    }

    private func noteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                IconView(icon: .message, size: 16, color: theme.gold)
                Text("Manager note").font(theme.bodyMedium(13)).foregroundStyle(theme.inkSoft)
            }
            Text(note).font(theme.body(14)).foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .knotCard()
    }

    private var actions: some View {
        VStack(spacing: 10) {
            actionButton(icon: .swap, title: "Request a swap", action: onSwap)
            actionButton(icon: .handoff, title: "Give up shift", action: onGiveUp)
            actionButton(icon: .calendar, title: "Request time off", action: onTimeOff)
        }
        .padding(.top, 8)
    }

    private func actionButton(icon: KnotIcon, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                IconView(icon: icon, size: 18, color: theme.ink)
                Text(title).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(theme.card, in: Capsule())
            .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var dayFull: String {
        ["Mon":"Monday","Tue":"Tuesday","Wed":"Wednesday","Thu":"Thursday",
         "Fri":"Friday","Sat":"Saturday","Sun":"Sunday"][shift.day] ?? shift.day
    }
}

#Preview {
    NavigationStack {
        ShiftDetailView(shift: Shift(day: "Fri", date: "Jun 13", start: "6:00 AM", end: "12:00 PM",
            role: "Lead Baker", note: "Market day — double batch.", breakLabel: "30 min · unpaid"))
    }
    .environment(\.knotTheme, BakeryCoTheme())
}
