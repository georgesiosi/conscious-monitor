import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: AppCategory
    let appToCategorize: AppSwitchChartData // appName, bundleId, and initial category come from here
    let chromeDomain: String? // For Chrome tabs, the domain to categorize
    let onSave: (AppCategory, String?) -> Void // Category, BundleID or Domain
    let onSaveDomain: ((AppCategory, String) -> Void)? // For Chrome domain categorization

    @ObservedObject private var categoryManager = CategoryManager.shared

    init(initialCategory: AppCategory, appToCategorize: AppSwitchChartData, chromeDomain: String? = nil, onSave: @escaping (AppCategory, String?) -> Void, onSaveDomain: ((AppCategory, String) -> Void)? = nil) {
        _selectedCategory = State(initialValue: initialCategory)
        self.appToCategorize = appToCategorize
        self.chromeDomain = chromeDomain
        self.onSave = onSave
        self.onSaveDomain = onSaveDomain
    }
    
    /// Display name - shows domain for Chrome tabs, app name for regular apps
    private var displayName: String {
        if let domain = chromeDomain {
            return domain
        }
        return appToCategorize.appName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            Text("Select Category")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            // App/Domain info
            Text("Categorize '\(displayName)'")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Divider()
            
            // Category picker
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Category")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categoryManager.allAvailableCategories) { category in
                        Text(category.name).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Category") {
                    if let domain = chromeDomain, let onSaveDomain = onSaveDomain {
                        // Save domain-specific category
                        onSaveDomain(selectedCategory, domain)
                    } else {
                        // Save app-specific category
                        onSave(selectedCategory, appToCategorize.bundleIdentifier)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(width: 400)
        .background(DesignSystem.Colors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
    }
}

struct CategoryPickerView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample AppSwitchChartData for preview
        let sampleChartData = AppSwitchChartData(
            appName: "Sample App",
            bundleIdentifier: "com.sample.app",
            activationCount: 1,
            category: .other // Initial category
        )
        
        CategoryPickerView(
            initialCategory: .other, // Initial category for the picker
            appToCategorize: sampleChartData,
            onSave: { category, bundleId in
                print("Preview: Saved category '\(category.name)' for bundle ID '\(bundleId ?? "N/A")'")
            }
        )
    }
}
