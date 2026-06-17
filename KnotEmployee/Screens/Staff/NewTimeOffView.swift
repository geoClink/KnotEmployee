import SwiftUI

struct NewTimeOffView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedKind: TimeOff.Kind = .pto
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var note = ""

    private var totalDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    kindPicker
                    dateFields
                    noteField
                    summaryCard
                    submitButton
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("New request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(theme.body(15)).foregroundStyle(theme.inkSoft)
                }
            }
        }
    }

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TYPE").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            HStack(spacing: 0) {
                ForEach([TimeOff.Kind.pto, .sick, .personal], id: \.rawValue) { kind in
                    Button { selectedKind = kind } label: {
                        Text(kind.rawValue)
                            .font(theme.bodyMedium(14))
                            .foregroundStyle(selectedKind == kind ? theme.paper : theme.ink)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(selectedKind == kind ? theme.ink : theme.card,
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedKind == kind ? .isSelected : [])
                }
            }
            .padding(3)
            .background(theme.card, in: Capsule())
            .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var dateFields: some View {
        VStack(spacing: 10) {
            dateRow("Start date", $startDate)
            dateRow("End date", $endDate)
        }
    }

    private func dateRow(_ label: String, _ date: Binding<Date>) -> some View {
        HStack {
            Text(label).font(theme.body(15)).foregroundStyle(theme.ink)
            Spacer()
            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .tint(theme.rose)
        }
        .knotCard(padding: 13)
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTE (OPTIONAL)").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField("Reason for time off", text: $note, axis: .vertical)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .lineLimit(3...6)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var summaryCard: some View {
        HStack {
            Text("Total days").font(theme.body(14)).foregroundStyle(theme.inkSoft)
            Spacer()
            Text("\(totalDays)").font(theme.display(28)).foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
        .accessibilityElement(children: .combine)
    }

    private var submitButton: some View {
        Button(action: submit) {
            HStack(spacing: 6) {
                IconView(icon: .check, size: 16, color: theme.paper)
                Text("Submit request").font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(theme.ink, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Submit time off request")
    }

    private func submit() {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let rangeStr = totalDays == 1
            ? fmt.string(from: startDate)
            : "\(fmt.string(from: startDate)) – \(fmt.string(from: endDate))"

        store.timeOff.append(
            TimeOff(kind: selectedKind, status: .pending,
                    range: rangeStr, days: totalDays,
                    note: note.isEmpty ? nil : note)
        )
        dismiss()
    }
}

#Preview {
    NewTimeOffView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
