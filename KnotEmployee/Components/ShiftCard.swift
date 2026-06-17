import SwiftUI

struct ShiftCard: View {
    @Environment(\.knotTheme) private var theme
    let shift: Shift

    private var isOffered: Bool { shift.status == .offered }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.s2) {
            HStack(spacing: Layout.s3) {
                dateBlock
                VStack(alignment: .leading, spacing: 2) {
                    Text(shift.timeRange).font(theme.bodyMedium(15))
                        .foregroundStyle(isOffered ? theme.inkMuted : theme.ink)
                    Text(shift.role).font(theme.body(13)).foregroundStyle(theme.inkMuted)
                }
                Spacer()
                if isOffered {
                    StatusBadge(status: .pending, small: true)
                }
            }
            if let note = shift.note {
                Text(note).font(theme.body(12)).foregroundStyle(theme.inkSoft)
                    .padding(Layout.s2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.cream, in: .rect(cornerRadius: 8))
            }
        }
        .padding(Layout.s3)
        .background(theme.card, in: .rect(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        .opacity(isOffered ? 0.6 : 1)
        .accessibilityElement(children: .combine)
    }

    private var dateBlock: some View {
        VStack(spacing: 1) {
            Text(shift.day.uppercased()).font(theme.bodyMedium(11))
            Text(shift.date.filter(\.isNumber)).font(theme.display(22))
        }
        .frame(minHeight: 54).frame(width: 50)
        .foregroundStyle(theme.inkSoft)
        .background(theme.creamDeep, in: .rect(cornerRadius: theme.rCard))
    }
}
