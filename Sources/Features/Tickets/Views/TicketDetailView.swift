import SwiftUI

struct TicketDetailView: View {
    @StateObject private var viewModel = TicketViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let ticket: TicketModel
    
    @State private var showingEditView = false
    @State private var showingComments = false
    @State private var showingStatusHistory = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ticket.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(ticket.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 8) {
                                // Priority indicator
                                HStack {
                                    Circle()
                                        .fill(ticket.priority.color)
                                        .frame(width: 12, height: 12)
                                    Text(ticket.priority.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                // Status badge
                                Text(ticket.status.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(statusColor(for: ticket.status))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Description
                        Text(ticket.description)
                            .font(.body)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Assignment Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assignment")
                            .font(.headline)
                        
                        // Reporter
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reporter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(ticket.reporter.displayName)
                                        .fontWeight(.medium)
                                    Text(ticket.reporter.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Assignee
                        if let assignee = ticket.assignee {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assignee")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(assignee.displayName)
                                            .fontWeight(.medium)
                                        Text(assignee.email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Watchers
                        if !ticket.watchers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Watchers (\(ticket.watchers.count))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                                    ForEach(ticket.watchers, id: \.id) { user in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(user.displayName)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                Text(user.email)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // SLA & Timeline Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("SLA & Timeline")
                                .font(.headline)
                            Spacer()
                            Button("History") {
                                showingStatusHistory = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 8) {
                            SLARow(
                                title: "Estimated Resolution",
                                duration: ticket.estimatedResolutionTime,
                                isWarning: false
                            )
                            
                            TimelineRow(
                                title: "Created",
                                date: ticket.createdAt,
                                isOverdue: false
                            )
                            
                            TimelineRow(
                                title: "Last Updated",
                                date: ticket.updatedAt,
                                isOverdue: false
                            )
                            
                            if !ticket.responseDeltas.isEmpty {
                                HStack {
                                    Text("Avg Response Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatDuration(ticket.responseDeltas.reduce(0, +) / Double(ticket.responseDeltas.count)))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Attachments Section
                    if !ticket.attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attachments (\(ticket.attachments.count))")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 8) {
                                ForEach(ticket.attachments, id: \.self) { attachment in
                                    HStack {
                                        Image(systemName: "paperclip")
                                            .foregroundColor(.blue)
                                        Text("Attachment")
                                            .font(.caption)
                                        Spacer()
                                        Button("View") {
                                            // Handle attachment view
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    // Metadata Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Metadata")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Ticket ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(ticket.id)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            if !ticket.responseDeltas.isEmpty {
                                HStack {
                                    Text("Total Responses")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(ticket.responseDeltas.count)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingComments = true
                        }) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right")
                                Text("View Comments")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if ticket.status == .open || ticket.status == .inProgress {
                            Button(action: {
                                markAsResolved()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Mark as Resolved")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        if ticket.status == .resolved {
                            Button(action: {
                                closeTicket()
                            }) {
                                HStack {
                                    Image(systemName: "lock.circle")
                                    Text("Close Ticket")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Ticket Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditTicketView(ticket: ticket)
            }
            .sheet(isPresented: $showingComments) {
                TicketCommentsView(ticket: ticket)
            }
            .sheet(isPresented: $showingStatusHistory) {
                TicketStatusHistoryView(ticket: ticket)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func statusColor(for status: TicketStatus) -> Color {
        switch status {
        case .open: return .blue
        case .inProgress: return .orange
        case .resolved: return .green
        case .closed: return .gray
        case .pending: return .purple
        case .onHold: return .yellow
        }
    }
    
    private func markAsResolved() {
        isLoading = true
        
        Task {
            do {
                var updatedTicket = ticket
                updatedTicket.status = .resolved
                updatedTicket.updatedAt = Date()
                
                try await viewModel.updateTicket(updatedTicket)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Handle error
                }
            }
        }
    }
    
    private func closeTicket() {
        isLoading = true
        
        Task {
            do {
                var updatedTicket = ticket
                updatedTicket.status = .closed
                updatedTicket.updatedAt = Date()
                
                try await viewModel.updateTicket(updatedTicket)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Handle error
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "Unknown"
    }
}

struct SLARow: View {
    let title: String
    let duration: TimeInterval
    let isWarning: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatDuration(duration))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isWarning ? .red : .primary)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "Unknown"
    }
}

struct TicketCommentsView: View {
    let ticket: TicketModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Comments feature coming soon")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TicketDetailView(ticket: TicketModel.sampleTicket)
        .environment(\.currentUser, User.sampleUser)
}
