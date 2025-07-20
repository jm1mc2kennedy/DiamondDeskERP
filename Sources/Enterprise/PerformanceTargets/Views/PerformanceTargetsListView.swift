//
//  PerformanceTargetsListView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct PerformanceTargetsListView: View {
    @StateObject var viewModel: PerformanceTargetsViewModel

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Performance Targets...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else if viewModel.targets.isEmpty {
                    Text("No performance targets found.")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(viewModel.targets) { target in
                            NavigationLink(
                                destination: NavigationRouter.shared.selectedPerformanceTarget == target ? nil : nil
                            ) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(target.name)
                                            .font(.headline)
                                        Text(target.metricType.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(target.targetValue, specifier: "%.1f") \(target.unit)")
                                        .font(.subheadline)
                                }
                            }
                            .onTapGesture {
                                NavigationRouter.shared.selectedPerformanceTarget = target
                                NavigationRouter.shared.tasksPath.append(.performanceTargetDetail(target.id.uuidString))
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    let target = viewModel.targets[index]
                                    await viewModel.deleteTarget(target)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Performance Targets")
            .toolbar {
                Button(action: {
                    NavigationRouter.shared.tasksPath.append(.performanceTargetCreation)
                }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .task {
                await viewModel.loadTargets()
            }
        }
    }
}

#Preview {
    PerformanceTargetsListView(viewModel: PerformanceTargetsViewModel())
}
