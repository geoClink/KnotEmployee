import SwiftUI

struct AddEditShiftView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let rowIndex: Int
    let dayIndex: Int
    let weekStart: Date

    @State private var selectedStaffName: String = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var role = ""
    @State private var note = ""

    private var dayLabel: String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return dayIndex < days.count ? days[dayIndex] : ""
    }

    private var existingCell: String? {
        guard rowIndex < store.weekGrid.count,
              dayIndex < store.weekGrid[rowIndex].cells.count else { return nil }
        return store.weekGrid[rowIndex].cells[dayIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    staffDisplay
                    timeFields
                    roleField
                    noteField
                    saveButton
                    if existingCell != nil {
                        removeButton
                    }
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle(existingCell != nil ? "Edit shift" : "Add shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(theme.body(15)).foregroundStyle(theme.inkSoft)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(dayLabel.uppercased()).font(theme.mono(12)).foregroundStyle(theme.rose)
            Text(store.weekGrid[rowIndex].name).font(theme.display(24)).foregroundStyle(theme.ink)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }

    private var staffDisplay: some View {
        HStack(spacing: 12) {
            Avatar(name: store.weekGrid[rowIndex].name, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.weekGrid[rowIndex].name)
                    .font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                if let cell = existingCell {
                    Text("Currently: \(cell)")
                        .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                } else {
                    Text("No shift assigned")
                        .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                }
            }
            Spacer()
        }
        .knotCard(padding: 13)
    }

    private var timeFields: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Start time").font(theme.body(15)).foregroundStyle(theme.ink)
                Spacer()
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden().tint(theme.rose)
            }
            .knotCard(padding: 13)
            HStack {
                Text("End time").font(theme.body(15)).foregroundStyle(theme.ink)
                Spacer()
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden().tint(theme.rose)
            }
            .knotCard(padding: 13)
        }
    }

    private var roleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ROLE").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField("e.g. Lead Baker", text: $role)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTE (OPTIONAL)").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField("Shift notes", text: $note, axis: .vertical)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .lineLimit(3...6)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 6) {
                IconView(icon: .check, size: 16, color: theme.paper)
                Text("Save shift").font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(theme.ink, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save shift")
    }

    private var removeButton: some View {
        Button(action: remove) {
            Text("Remove shift").font(theme.bodyMedium(15)).foregroundStyle(theme.roseDeep)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove shift")
    }

    private func save() {
        let fmt = DateFormatter(); fmt.dateFormat = "h"
        store.weekGrid[rowIndex].cells[dayIndex] = "\(fmt.string(from: startTime))–\(fmt.string(from: endTime))"
        if let empId = store.weekGrid[rowIndex].employeeId {
            Task { await store.upsertShift(employeeId: empId, dayIndex: dayIndex,
                                           weekStart: weekStart, start: startTime,
                                           end: endTime, role: role, note: note) }
        }
        dismiss()
    }

    private func remove() {
        store.weekGrid[rowIndex].cells[dayIndex] = nil
        if let empId = store.weekGrid[rowIndex].employeeId {
            let cal = Calendar.current
            let shiftDate = cal.date(byAdding: .day, value: dayIndex, to: weekStart)!
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            Task { await store.removeShift(employeeId: empId, shiftDate: df.string(from: shiftDate)) }
        }
        dismiss()
    }
}

#Preview {
    AddEditShiftView(rowIndex: 0, dayIndex: 0, weekStart: Date())
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
