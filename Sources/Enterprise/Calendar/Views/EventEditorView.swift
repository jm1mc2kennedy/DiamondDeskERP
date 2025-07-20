import SwiftUI

public struct EventEditorView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State var event: CalendarEvent?
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var allDay = false
    @State private var location = ""

    public init(viewModel: CalendarViewModel, event: CalendarEvent? = nil) {
        self.viewModel = viewModel
        _event = State(initialValue: event)
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Info")) {
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    Toggle("All Day", isOn: $allDay)
                }
                .onChange(of: allDay) { newVal in
                    if newVal {
                        startDate = Calendar.current.startOfDay(for: startDate)
                        endDate = Calendar.current.startOfDay(for: endDate)
                    }
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes).frame(minHeight: 100)
                }
                Section(header: Text("Time")) {
                    DatePicker("Start", selection: $startDate, displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                    DatePicker("End", selection: $endDate, displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(event == nil ? "Create" : "Save") {
                        let evt = CalendarEvent(
                            id: event?.id ?? UUID(),
                            title: title,
                            notes: notes.isEmpty ? nil : notes,
                            startDate: startDate,
                            endDate: endDate,
                            allDay: allDay,
                            location: location.isEmpty ? nil : location,
                            createdBy: "current-user"
                        )
                        Task {
                            if event == nil {
                                await viewModel.createEvent(evt)
                            } else {
                                await viewModel.updateEvent(evt)
                            }
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || startDate >= endDate)
                }
            }
            .onAppear {
                if let e = event {
                    title = e.title
                    notes = e.notes ?? ""
                    startDate = e.startDate
                    endDate = e.endDate
                    allDay = e.allDay
                    location = e.location ?? ""
                }
            }
        }
    }
}
