import SwiftUI

struct ScheduleBuilderView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @State private var published = false
    @State private var editRow: Int?
    @State private var editDay: Int?
    @State private var weekOffset = 0
    @State private var showSaveTemplate = false
    @State private var showLoadTemplate = false
    @State private var templateName = ""

    private var baseMonday: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return cal.date(from: comps) ?? Date()
    }

    private var weekStart: Date {
        Calendar.current.date(byAdding: .day, value: weekOffset * 7, to: baseMonday)!
    }

    private var weekLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        return "\(fmt.string(from: weekStart)) – \(fmt.string(from: end))"
    }

    private var days: [(String, String)] {
        let cal = Calendar.current
        let dayNames = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i, to: weekStart)!
            let num = cal.component(.day, from: date)
            return (dayNames[i], String(num))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                weekStepper.padding(20)
                ScrollView {
                    grid.padding(.horizontal, 20)
                    legend.padding(.horizontal, 20)
                }
                bottomBar
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Schedule")
            .task(id: weekOffset) { await store.fetchWeekGrid(weekStart: weekStart) }
            .onChange(of: weekOffset) { published = false }
            .sheet(isPresented: Binding(
                get: { editRow != nil && editDay != nil },
                set: { if !$0 { editRow = nil; editDay = nil } }
            )) {
                if let r = editRow, let d = editDay {
                    AddEditShiftView(rowIndex: r, dayIndex: d, weekStart: weekStart)
                }
            }
        }
    }

    private var weekStepper: some View {
        HStack {
            Button { weekOffset -= 1 } label: {
                IconView(icon: .chevronLeft, size: 18, color: theme.inkMuted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous week")
            Spacer()
            VStack(spacing: 1) {
                Text(weekLabel).font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
                Text("\(store.weekGrid.count) staff · 2 gaps").font(theme.body(11)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            Button { weekOffset += 1 } label: {
                IconView(icon: .chevronRight, size: 18, color: theme.inkMuted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next week")
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
    }

    private var grid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Color.clear.frame(width: 40)
                ForEach(days, id: \.0) { d in
                    VStack(spacing: 0) {
                        Text(d.0.uppercased()).font(theme.body(8)).foregroundStyle(theme.inkMuted)
                        Text(d.1).font(theme.bodyMedium(12)).foregroundStyle(theme.ink)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 6)

            ForEach(Array(store.weekGrid.enumerated()), id: \.element.id) { rowIdx, row in
                HStack(spacing: 4) {
                    Avatar(name: row.name, size: 28).frame(width: 40)
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { dayIdx, cell in
                        Button { editRow = rowIdx; editDay = dayIdx } label: {
                            cellView(cell, available: availableForDay(row.employeeId, dayIndex: dayIdx))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(row.name), \(days[dayIdx].0), \(cell ?? "off")")
                    }
                }
                .padding(.vertical, 5)
                .overlay(alignment: .bottom) { Rectangle().fill(theme.lineSoft).frame(height: 1) }
            }
        }
        .padding(8)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
    }

    private func availableForDay(_ employeeId: UUID?, dayIndex: Int) -> Bool {
        guard let eid = employeeId else { return true }
        return store.allStaffAvailability[eid]?[dayIndex] ?? true
    }

    private func cellView(_ cell: String?, available: Bool = true) -> some View {
        Group {
            if let cell {
                Text(cell).font(theme.mono(8.5)).foregroundStyle(theme.roseDeep)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(theme.roseSoft, in: RoundedRectangle(cornerRadius: 5))
            } else {
                Text("·").font(theme.body(11))
                    .foregroundStyle(available ? theme.inkFaint : theme.gold)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(available ? .clear : theme.gold.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 1)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 3).fill(theme.roseSoft).frame(width: 12, height: 10)
                Text("Shift").font(theme.body(11)).foregroundStyle(theme.inkMuted)
            }
            HStack(spacing: 5) {
                Text("·").foregroundStyle(theme.inkFaint)
                Text("Off").font(theme.body(11)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            Text("Tap a cell to edit").font(theme.body(11)).foregroundStyle(theme.inkMuted)
        }
        .padding(.vertical, 12)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Menu {
                Button {
                    Task { await store.fetchTemplates() }
                    showLoadTemplate = true
                } label: { Label("Load template", systemImage: "arrow.down.doc") }
                Button {
                    templateName = ""
                    showSaveTemplate = true
                } label: { Label("Save as template", systemImage: "arrow.up.doc") }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text").font(.system(size: 15))
                    Text("Templates").font(theme.bodyMedium(15))
                }
                .foregroundStyle(theme.ink)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Button {
                Task {
                    await store.publishSchedule(weekStart: weekStart)
                    published = true
                }
            } label: {
                HStack(spacing: 6) {
                    IconView(icon: .check, size: 16, color: theme.paper)
                    Text(published ? "Published" : "Publish").font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
                }
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(published ? theme.green : theme.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(published)
        }
        .padding(16)
        .background(theme.cream)
        .overlay(alignment: .top) { Rectangle().fill(theme.line).frame(height: 1) }
        .alert("Save as template", isPresented: $showSaveTemplate) {
            TextField("Template name (e.g. Summer Week)", text: $templateName)
            Button("Save") {
                let name = templateName.isEmpty ? "Week of \(weekLabel)" : templateName
                Task { await store.saveAsTemplate(name: name, weekStart: weekStart) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This saves every shift on the current schedule so you can reuse it in future weeks.")
        }
        .sheet(isPresented: $showLoadTemplate) {
            TemplatePickerSheet(weekLabel: weekLabel, weekStart: weekStart,
                                published: $published)
        }
    }
}

#Preview {
    ScheduleBuilderView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}

struct TemplatePickerSheet: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let weekLabel: String
    let weekStart: Date
    @Binding var published: Bool

    var body: some View {
        NavigationStack {
            Group {
                if store.templates.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 36)).foregroundStyle(theme.inkFaint)
                        Text("No saved templates")
                            .font(theme.body(15)).foregroundStyle(theme.inkMuted)
                        Text("Build a week and use Templates → Save as template.")
                            .font(theme.body(13)).foregroundStyle(theme.inkFaint)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    List {
                        Section(footer: Text("Shifts will be applied to \(weekLabel). Existing shifts for that week are kept unless they overlap.").font(theme.body(12)).foregroundStyle(theme.inkMuted)) {
                            ForEach(store.templates) { t in
                                Button {
                                    Task {
                                        await store.applyTemplate(id: t.id, weekStart: weekStart)
                                        published = false
                                        dismiss()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text").foregroundStyle(theme.inkSoft)
                                        Text(t.name).font(theme.body(15)).foregroundStyle(theme.ink)
                                        Spacer()
                                        Image(systemName: "arrow.down.doc").font(.system(size: 13))
                                            .foregroundStyle(theme.inkFaint)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                for idx in offsets {
                                    let id = store.templates[idx].id
                                    Task { await store.deleteTemplate(id: id) }
                                }
                            }
                        }
                    }
                }
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Load template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .task { await store.fetchTemplates() }
        }
    }
}
