import SwiftUI

struct TaskDetailView: View {
    @StateObject private var viewModel = TaskViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let task: TaskModel
    
    @State private var showingEditView = false
    @State private var showingComments = false
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(task.category)
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
                                        .fill(task.priority.color)
                                        .frame(width: 12, height: 12)
                                    Text(task.priority.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                // Status badge
                                Text(task.status.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(task.status.color)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Description
                        Text(task.description)
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
                        
                        if let assignee = task.assignee {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Assignee")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                        
                        if !task.collaborators.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Collaborators (\(task.collaborators.count))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                                    ForEach(task.collaborators, id: \.id) { user in
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
                    
                    // Timeline Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timeline")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            TimelineRow(
                                title: "Due Date",
                                date: task.dueDate,
                                isOverdue: task.dueDate < Date() && task.status != .completed
                            )
                            
                            TimelineRow(
                                title: "Created",
                                date: task.createdAt,
                                isOverdue: false
                            )
                            
                            TimelineRow(
                                title: "Last Updated",
                                date: task.updatedAt,
                                isOverdue: false
                            )
                        }
                        
                        HStack {
                            Text("Estimated Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDuration(task.estimatedDuration))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Completion Mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(task.completionMode.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Tags Section
                    if !task.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(task.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
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
                                Text("Created by")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(task.creator.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(task.creator.email)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text("Task ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(task.id)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
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
                        
                        if task.status != .completed {
                            Button(action: {
                                markAsCompleted()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Mark as Completed")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Task Details")
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
                EditTaskView(task: task)
            }
            .sheet(isPresented: $showingComments) {
                TaskCommentsView(task: task)
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
    
    private func markAsCompleted() {
        isLoading = true
        
        Task {
            do {
                var updatedTask = task
                updatedTask.status = .completed
                updatedTask.updatedAt = Date()
                
                try await viewModel.updateTask(updatedTask)
                
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

struct TimelineRow: View {
    let title: String
    let date: Date
    let isOverdue: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isOverdue ? .red : .primary)
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TaskCommentsView: View {
    let task: TaskModel
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
    TaskDetailView(task: TaskModel.sampleTask)
        .environment(\.currentUser, User.sampleUser)
}
