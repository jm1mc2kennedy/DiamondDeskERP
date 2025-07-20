import SwiftUI

public struct CalendarListView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingEditor = false
    @State private var editingEvent: CalendarEvent? = nil

    public init() {}
    public var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if viewModel.events.isEmpty {
                    Text("No events scheduled")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(viewModel.events) { event in
                        Button(action: {
                            viewModel.selectedEvent = event
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                        .font(.headline)
                                    Text("\(formatDate(event.startDate)) - \(formatDate(event.endDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            let ev = viewModel.events[idx]
                            Task { await viewModel.deleteEvent(ev.id) }
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingEvent = nil
                        showingEditor = true
                    }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .onAppear {
                Task { await viewModel.loadEvents() }
            }
            .sheet(item: $viewModel.selectedEvent) { event in
                EventDetailView(viewModel: viewModel, event: event)
            }
            .sheet(isPresented: $showingEditor) {
                EventEditorView(viewModel: viewModel, event: editingEvent)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
