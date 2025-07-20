import SwiftUI
import Accessibility

@MainActor
class AccessibilityService: ObservableObject {
    @Published var isVoiceOverRunning = false
    @Published var isReduceMotionEnabled = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    @Published var isHighContrastEnabled = false
    @Published var isDarkModeEnabled = false
    
    private var accessibilityNotifications: Set<AnyCancellable> = []
    
    init() {
        setupAccessibilityObservers()
        updateAccessibilitySettings()
    }
    
    private func setupAccessibilityObservers() {
        // VoiceOver status
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateVoiceOverStatus()
            }
            .store(in: &accessibilityNotifications)
        
        // Reduce Motion
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateReduceMotionStatus()
            }
            .store(in: &accessibilityNotifications)
        
        // Content Size Category
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateContentSizeCategory()
            }
            .store(in: &accessibilityNotifications)
        
        // High Contrast
        NotificationCenter.default.publisher(for: UIAccessibility.differentiateWithoutColorDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateHighContrastStatus()
            }
            .store(in: &accessibilityNotifications)
    }
    
    private func updateAccessibilitySettings() {
        updateVoiceOverStatus()
        updateReduceMotionStatus()
        updateContentSizeCategory()
        updateHighContrastStatus()
        updateDarkModeStatus()
    }
    
    private func updateVoiceOverStatus() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    }
    
    private func updateReduceMotionStatus() {
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    }
    
    private func updateContentSizeCategory() {
        preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
    }
    
    private func updateHighContrastStatus() {
        isHighContrastEnabled = UIAccessibility.isDifferentiateWithoutColorEnabled
    }
    
    private func updateDarkModeStatus() {
        isDarkModeEnabled = UITraitCollection.current.userInterfaceStyle == .dark
    }
}

// MARK: - Accessible View Modifiers

struct AccessibleCard: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    
    init(label: String, hint: String? = nil, traits: AccessibilityTraits = []) {
        self.label = label
        self.hint = hint
        self.traits = traits
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityElement(children: .combine)
    }
}

struct AccessibleButton: ViewModifier {
    let label: String
    let hint: String?
    let action: () -> Void
    
    func body(content: Content) -> some View {
        Button(action: action) {
            content
        }
        .accessibilityLabel(label)
        .accessibilityHint(hint ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

struct DynamicTypeSupport: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: dynamicFontSize))
            .lineLimit(sizeCategory.isAccessibilityCategory ? nil : 1)
    }
    
    private var dynamicFontSize: CGFloat {
        switch sizeCategory {
        case .extraSmall: return 12
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        case .extraExtraLarge: return 22
        case .extraExtraExtraLarge: return 24
        case .accessibilityMedium: return 28
        case .accessibilityLarge: return 32
        case .accessibilityExtraLarge: return 36
        case .accessibilityExtraExtraLarge: return 40
        case .accessibilityExtraExtraExtraLarge: return 44
        @unknown default: return 16
        }
    }
}

struct HighContrastSupport: ViewModifier {
    @EnvironmentObject var accessibilityService: AccessibilityService
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(accessibilityService.isHighContrastEnabled ? .primary : .primary)
            .background(accessibilityService.isHighContrastEnabled ? Color.clear : Color.clear)
    }
}

struct ReducedMotionSupport: ViewModifier {
    @EnvironmentObject var accessibilityService: AccessibilityService
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(accessibilityService.isReduceMotionEnabled ? .none : animation, value: UUID())
    }
}

// MARK: - Accessible Components

struct AccessibleKPICard: View {
    let title: String
    let value: String
    let change: Double
    let color: Color
    let icon: String
    
    @EnvironmentObject var accessibilityService: AccessibilityService
    
    private var changeDescription: String {
        let direction = change >= 0 ? "increased" : "decreased"
        return "\(direction) by \(abs(change), specifier: "%.1f") percent"
    }
    
    private var accessibilityLabel: String {
        "\(title): \(value), \(changeDescription)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text("\(abs(change), specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(change >= 0 ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .modifier(DynamicTypeSupport())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .modifier(DynamicTypeSupport())
            }
        }
        .padding()
        .frame(width: 160, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        .modifier(AccessibleCard(
            label: accessibilityLabel,
            hint: "Key performance indicator",
            traits: [.updatesFrequently]
        ))
    }
}

struct AccessibleFollowUpCard: View {
    let followUp: ClientFollowUp
    let onTap: () -> Void
    
    @EnvironmentObject var accessibilityService: AccessibilityService
    
    private var accessibilityLabel: String {
        var label = "Follow-up for \(followUp.client.fullName)"
        label += ", scheduled for \(followUp.followUpDate.formatted(.dateTime.weekday().month().day()))"
        
        if followUp.isOverdue {
            label += ", overdue by \(followUp.daysSinceDate) days"
        }
        
        if !followUp.notes.isEmpty {
            label += ", notes: \(followUp.notes)"
        }
        
        return label
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(followUp.client.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .modifier(DynamicTypeSupport())
                
                Text(followUp.followUpDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .modifier(DynamicTypeSupport())
                
                if !followUp.notes.isEmpty {
                    Text(followUp.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(accessibilityService.preferredContentSizeCategory.isAccessibilityCategory ? nil : 2)
                        .modifier(DynamicTypeSupport())
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Circle()
                    .fill(followUp.priority.color)
                    .frame(width: 8, height: 8)
                    .accessibilityLabel("\(followUp.priority) priority")
                
                if followUp.isOverdue {
                    Text("\(followUp.daysSinceDate)d")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .accessibilityLabel("\(followUp.daysSinceDate) days overdue")
                }
            }
        }
        .padding(.vertical, 8)
        .modifier(AccessibleButton(
            label: accessibilityLabel,
            hint: "Double tap to complete follow-up",
            action: onTap
        ))
    }
}

struct AccessibleSearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    @EnvironmentObject var accessibilityService: AccessibilityService
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel("Search field")
                .accessibilityHint("Enter text to search")
                .accessibilityValue(text.isEmpty ? "Empty" : text)
                .modifier(DynamicTypeSupport())
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isSearchField)
    }
}

struct AccessibleMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    private var accessibilityLabel: String {
        "\(title): \(value), \(subtitle)"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .accessibilityHidden(true)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .modifier(DynamicTypeSupport())
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .modifier(DynamicTypeSupport())
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .modifier(DynamicTypeSupport())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        .modifier(AccessibleCard(
            label: accessibilityLabel,
            hint: "Performance metric",
            traits: [.updatesFrequently]
        ))
    }
}

struct AccessibleActivityRow: View {
    let activity: ActivityItem
    
    private var accessibilityLabel: String {
        var label = "\(activity.type.displayName): \(activity.title)"
        label += ", \(activity.description)"
        label += ", \(activity.timestamp.formatted(.relative(presentation: .numeric)))"
        return label
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .modifier(DynamicTypeSupport())
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .modifier(DynamicTypeSupport())
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
                .modifier(DynamicTypeSupport())
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .modifier(AccessibleCard(
            label: accessibilityLabel,
            hint: "Recent activity item"
        ))
    }
}

// MARK: - View Extensions

extension View {
    func accessibleCard(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        modifier(AccessibleCard(label: label, hint: hint, traits: traits))
    }
    
    func accessibleButton(label: String, hint: String? = nil, action: @escaping () -> Void) -> some View {
        modifier(AccessibleButton(label: label, hint: hint, action: action))
    }
    
    func dynamicTypeSupport() -> some View {
        modifier(DynamicTypeSupport())
    }
    
    func highContrastSupport() -> some View {
        modifier(HighContrastSupport())
    }
    
    func reducedMotionSupport(animation: Animation = .default) -> some View {
        modifier(ReducedMotionSupport(animation: animation))
    }
}

// MARK: - Accessibility Extensions

extension ContentSizeCategory {
    var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}

extension FollowUpPriority {
    var accessibilityDescription: String {
        switch self {
        case .low: return "Low priority"
        case .medium: return "Medium priority"
        case .high: return "High priority"
        }
    }
}
