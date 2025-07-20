import SwiftUI
import Charts

// MARK: - Report Viewer View

public struct ReportViewerView: View {
    @ObservedObject var viewModel: ReportingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVisualization = 0
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let report = viewModel.selectedReport {
                        // Report Header
                        reportHeader(report)
                        
                        // Report Summary Stats
                        if let data = viewModel.reportData {
                            summaryStatsSection(data)
                        }
                        
                        // Main Visualization
                        if let visualization = report.visualizations.first,
                           let data = viewModel.reportData {
                            mainVisualizationSection(visualization, data: data)
                        }
                        
                        // Additional Visualizations
                        if report.visualizations.count > 1,
                           let data = viewModel.reportData {
                            additionalVisualizationsSection(report.visualizations.dropFirst(), data: data)
                        }
                        
                        // Raw Data Table
                        if viewModel.showRawData,
                           let data = viewModel.reportData {
                            rawDataSection(data)
                        }
                    } else {
                        loadingView
                    }
                }
                .padding()
            }
            .navigationTitle("Report Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showRawData.toggle()
                    } label: {
                        Image(systemName: "tablecells")
                    }
                    
                    Button {
                        showingExportOptions = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .confirmationDialog("Export Options", isPresented: $showingExportOptions) {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Button(format.displayName) {
                    Task {
                        await viewModel.exportReport(format: format)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingShareSheet) {
            if let report = viewModel.selectedReport {
                ShareSheet(items: [generateShareContent(report)])
            }
        }
        .task {
            await viewModel.loadReportData()
        }
    }
    
    private func reportHeader(_ report: Report) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ReportTypeIcon(type: report.reportType, category: report.category)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.reportName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let description = report.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ReportCategoryBadge(category: report.category)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDateTime(report.metadata.lastGenerated ?? Date()))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Date Range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(formatDate(report.dateRange.start)) - \(formatDate(report.dateRange.end))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func summaryStatsSection(_ data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(data.summaryStats.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    SummaryStatCard(title: key, value: value)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func mainVisualizationSection(_ visualization: ReportVisualization, data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(visualization.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VisualizationTypeBadge(type: visualization.type)
            }
            
            // Chart based on visualization type
            switch visualization.type {
            case .bar:
                BarChartView(data: data, visualization: visualization)
            case .line:
                LineChartView(data: data, visualization: visualization)
            case .pie:
                PieChartView(data: data, visualization: visualization)
            case .donut:
                DonutChartView(data: data, visualization: visualization)
            case .area:
                AreaChartView(data: data, visualization: visualization)
            case .scatter:
                ScatterChartView(data: data, visualization: visualization)
            case .stackedBar:
                StackedBarChartView(data: data, visualization: visualization)
            case .table:
                TableView(data: data, visualization: visualization)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func additionalVisualizationsSection<S: Sequence>(_ visualizations: S, data: ReportData) -> some View where S.Element == ReportVisualization {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Charts")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(visualizations), id: \.id) { visualization in
                additionalVisualizationCard(visualization, data: data)
            }
        }
    }
    
    private func additionalVisualizationCard(_ visualization: ReportVisualization, data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(visualization.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VisualizationTypeBadge(type: visualization.type)
                    .scaleEffect(0.8)
            }
            
            // Smaller chart
            Group {
                switch visualization.type {
                case .bar:
                    BarChartView(data: data, visualization: visualization)
                case .line:
                    LineChartView(data: data, visualization: visualization)
                case .pie:
                    PieChartView(data: data, visualization: visualization)
                case .donut:
                    DonutChartView(data: data, visualization: visualization)
                case .area:
                    AreaChartView(data: data, visualization: visualization)
                case .scatter:
                    ScatterChartView(data: data, visualization: visualization)
                case .stackedBar:
                    StackedBarChartView(data: data, visualization: visualization)
                case .table:
                    TableView(data: data, visualization: visualization)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func rawDataSection(_ data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Raw Data")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(data.dataPoints.count) rows")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            RawDataTableView(data: data)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading report data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func generateShareContent(_ report: Report) -> String {
        return "Check out this report: \(report.reportName)\n\nGenerated on \(formatDateTime(Date()))"
    }
}

// MARK: - Chart Views

public struct BarChartView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(Color.accentColor)
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }
    
    private var chartData: [ChartDataItem] {
        data.dataPoints.compactMap { point in
            guard let category = point[visualization.config.xField] as? String,
                  let value = point[visualization.config.yField] as? Double else {
                return nil
            }
            return ChartDataItem(category: category, value: value)
        }
    }
}

public struct LineChartView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                LineMark(
                    x: .value("Category", item.category),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(Color.accentColor)
                .symbol(Circle())
            }
        }
        .frame(height: 250)
    }
    
    private var chartData: [ChartDataItem] {
        data.dataPoints.compactMap { point in
            guard let category = point[visualization.config.xField] as? String,
                  let value = point[visualization.config.yField] as? Double else {
                return nil
            }
            return ChartDataItem(category: category, value: value)
        }
    }
}

public struct PieChartView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                SectorMark(
                    angle: .value("Value", item.value),
                    innerRadius: .ratio(0.0),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", item.category))
            }
        }
        .frame(height: 250)
    }
    
    private var chartData: [ChartDataItem] {
        data.dataPoints.compactMap { point in
            guard let category = point[visualization.config.xField] as? String,
                  let value = point[visualization.config.yField] as? Double else {
                return nil
            }
            return ChartDataItem(category: category, value: value)
        }
    }
}

public struct DonutChartView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                SectorMark(
                    angle: .value("Value", item.value),
                    innerRadius: .ratio(0.4),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", item.category))
            }
        }
        .frame(height: 250)
    }
    
    private var chartData: [ChartDataItem] {
        data.dataPoints.compactMap { point in
            guard let category = point[visualization.config.xField] as? String,
                  let value = point[visualization.config.yField] as? Double else {
                return nil
            }
            return ChartDataItem(category: category, value: value)
        }
    }
}

public struct AreaChartView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                AreaMark(
                    x: .value("Category", item.category),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(Color.accentColor.opacity(0.3))
                
                LineMark(
                    x: .value("Category", item.category),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(Color.accentColor)
            }
        }
        .frame(height: 250)
    }
    
    private var chartData: [ChartDataItem] {
        data.dataPoints.compactMap { point in
            guard let category = point[visualization.config.xField] as? String,
                  let value = point[visualization.config.yField] as? Double else {
                return nil
            }
            return ChartDataItem(category: category, value: value)
        }
    }
}

public struct ScatterChartView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                PointMark(
                    x: .value("X", item.xValue),
                    y: .value("Y", item.value)
                )
                .foregroundStyle(Color.accentColor)
            }
        }
        .frame(height: 250)
    }
    
    private var chartData: [ChartDataItem] {
        data.dataPoints.compactMap { point in
            guard let xValue = point[visualization.config.xField] as? Double,
                  let yValue = point[visualization.config.yField] as? Double else {
                return nil
            }
            return ChartDataItem(category: "", value: yValue, xValue: xValue)
        }
    }
}

public struct StackedBarChartView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        Chart {
            ForEach(stackedData, id: \.id) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Value", item.value),
                    stacking: .standard
                )
                .foregroundStyle(by: .value("Series", item.series))
            }
        }
        .frame(height: 250)
    }
    
    private var stackedData: [StackedChartDataItem] {
        // Simplified stacked data generation
        data.dataPoints.enumerated().compactMap { index, point in
            guard let category = point[visualization.config.xField] as? String,
                  let value = point[visualization.config.yField] as? Double else {
                return nil
            }
            return StackedChartDataItem(
                id: UUID(),
                category: category,
                value: value,
                series: "Series \(index % 3 + 1)"
            )
        }
    }
}

public struct TableView: View {
    let data: ReportData
    let visualization: ReportVisualization
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                ForEach(tableColumns, id: \.self) { column in
                    Text(column)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            
            // Rows
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(data.dataPoints.indices, id: \.self) { index in
                        let point = data.dataPoints[index]
                        HStack {
                            ForEach(tableColumns, id: \.self) { column in
                                Text("\(point[column] ?? "")")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(index % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var tableColumns: [String] {
        visualization.config.tableFields ?? Array(data.dataPoints.first?.keys ?? [])
    }
}

// MARK: - Supporting Views

public struct SummaryStatCard: View {
    let title: String
    let value: Any
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(formattedValue)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var formattedValue: String {
        if let doubleValue = value as? Double {
            return String(format: "%.2f", doubleValue)
        } else if let intValue = value as? Int {
            return "\(intValue)"
        } else {
            return "\(value)"
        }
    }
}

public struct VisualizationTypeBadge: View {
    let type: VisualizationType
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.systemImage)
                .font(.caption)
            
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .foregroundColor(.accentColor)
        .clipShape(Capsule())
    }
}

public struct RawDataTableView: View {
    let data: ReportData
    
    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    ForEach(columns, id: \.self) { column in
                        Text(column)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(8)
                            .frame(minWidth: 100, alignment: .leading)
                            .background(Color.secondary.opacity(0.2))
                    }
                }
                
                // Rows
                ForEach(data.dataPoints.indices, id: \.self) { index in
                    let point = data.dataPoints[index]
                    HStack(spacing: 0) {
                        ForEach(columns, id: \.self) { column in
                            Text("\(point[column] ?? "")")
                                .font(.caption)
                                .padding(8)
                                .frame(minWidth: 100, alignment: .leading)
                                .background(index % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 300)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var columns: [String] {
        Array(data.dataPoints.first?.keys ?? [])
    }
}

// MARK: - Share Sheet

public struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Chart Data Models

public struct ChartDataItem {
    let category: String
    let value: Double
    let xValue: Double?
    
    init(category: String, value: Double, xValue: Double? = nil) {
        self.category = category
        self.value = value
        self.xValue = xValue
    }
}

public struct StackedChartDataItem {
    let id: UUID
    let category: String
    let value: Double
    let series: String
}
