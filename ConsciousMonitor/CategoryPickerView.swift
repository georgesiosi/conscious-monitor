import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: AppCategory
    let appToCategorize: AppSwitchChartData // appName, bundleId, and initial category come from here
    let onSave: (AppCategory, String?) -> Void // Category, BundleID

    @ObservedObject private var categoryManager = CategoryManager.shared

    init(initialCategory: AppCategory, appToCategorize: AppSwitchChartData, onSave: @escaping (AppCategory, String?) -> Void) {
        _selectedCategory = State(initialValue: initialCategory)
        self.appToCategorize = appToCategorize
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            Text("Select Category")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            // App info
            Text("Categorize '\(appToCategorize.appName)'")
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
                    onSave(selectedCategory, appToCategorize.bundleIdentifier)
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
