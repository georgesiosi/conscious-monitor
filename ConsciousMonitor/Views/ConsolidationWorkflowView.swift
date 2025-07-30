import SwiftUI

// MARK: - Guided Consolidation Workflow

struct ConsolidationWorkflowView: View {
    let category: AppCategory
    let tools: [AppUsageStat]
    @ObservedObject var activityMonitor: ActivityMonitor
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var selectedToolsToKeep: Set<String> = []
    @State private var selectedPrimaryTool: String? = nil
    @State private var consolidationPlan: ConsolidationPlan? = nil
    
    private let maxActiveTools = 3
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 3.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(y: 2)
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        ToolSelectionStep(
                            category: category,
                            tools: tools,
                            selectedTools: $selectedToolsToKeep,
                            maxTools: maxActiveTools
                        )
                    case 1:
                        PrimaryToolSelectionStep(
                            selectedTools: selectedToolsToKeep,
                            tools: tools,
                            selectedPrimaryTool: $selectedPrimaryTool
                        )
                    case 2:
                        ConsolidationPlanStep(
                            category: category,
                            selectedTools: selectedToolsToKeep,
                            primaryTool: selectedPrimaryTool,
                            tools: tools,
                            consolidationPlan: $consolidationPlan
                        )
                    default:
                        Text("Complete!")
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 2 ? "Complete" : "Next") {
                        if currentStep == 2 {
                            completeConsolidation()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("Consolidate \(category.name) Tools")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return selectedToolsToKeep.count <= maxActiveTools && !selectedToolsToKeep.isEmpty
        case 1:
            return selectedPrimaryTool != nil
        case 2:
            return consolidationPlan != nil
        default:
            return false
        }
    }
    
    private func completeConsolidation() {
        // In a real implementation, this would apply the consolidation plan
        dismiss()
    }
}

// MARK: - Tool Selection Step

struct ToolSelectionStep: View {
    let category: AppCategory
    let tools: [AppUsageStat]
    @Binding var selectedTools: Set<String>
    let maxTools: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Step 1: Choose Your Essential Tools")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.semibold)
            
            Text("Select up to \(maxTools) tools you want to keep active for \(category.name.lowercased()). These should be your most essential and frequently used tools.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text("\(selectedTools.count)/\(maxTools) tools selected")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(selectedTools.count <= maxTools ? DesignSystem.Colors.accent : .red)
            
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(tools.sorted { $0.activationCount > $1.activationCount }, id: \.bundleIdentifier) { tool in
                    let bundleId = tool.bundleIdentifier ?? "unknown.bundle.id"
                    ToolSelectionRow(
                        tool: tool,
                        isSelected: selectedTools.contains(bundleId),
                        canSelect: selectedTools.count < maxTools || selectedTools.contains(bundleId)
                    ) { isSelected in
                        if isSelected {
                            selectedTools.insert(bundleId)
                        } else {
                            selectedTools.remove(bundleId)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Primary Tool Selection Step

struct PrimaryToolSelectionStep: View {
    let selectedTools: Set<String>
    let tools: [AppUsageStat]
    @Binding var selectedPrimaryTool: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Step 2: Choose Your Primary Tool")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.semibold)
            
            Text("Select one tool as your primary focus. This should get 60%+ of your usage in this category.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            let filteredTools = tools.filter { selectedTools.contains($0.bundleIdentifier ?? "unknown.bundle.id") }
                .sorted { $0.activationCount > $1.activationCount }
            
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(filteredTools, id: \.bundleIdentifier) { tool in
                    let bundleId = tool.bundleIdentifier ?? "unknown.bundle.id"
                    PrimaryToolSelectionRow(
                        tool: tool,
                        isSelected: selectedPrimaryTool == bundleId
                    ) {
                        selectedPrimaryTool = bundleId
                    }
                }
            }
        }
    }
}

// MARK: - Consolidation Plan Step

struct ConsolidationPlanStep: View {
    let category: AppCategory
    let selectedTools: Set<String>
    let primaryTool: String?
    let tools: [AppUsageStat]
    @Binding var consolidationPlan: ConsolidationPlan?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Step 3: Review Your Plan")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.semibold)
            
            Text("Here's your consolidation plan for \(category.name.lowercased()) tools:")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            if let plan = generateConsolidationPlan() {
                ConsolidationPlanView(plan: plan)
                    .onAppear {
                        consolidationPlan = plan
                    }
            }
        }
    }
    
    private func generateConsolidationPlan() -> ConsolidationPlan? {
        guard let primaryToolId = primaryTool,
              let primaryToolStat = tools.first(where: { ($0.bundleIdentifier ?? "unknown.bundle.id") == primaryToolId }) else {
            return nil
        }
        
        let keepTools = tools.filter { selectedTools.contains($0.bundleIdentifier ?? "unknown.bundle.id") }
        let removeTools = tools.filter { !selectedTools.contains($0.bundleIdentifier ?? "unknown.bundle.id") }
        
        return ConsolidationPlan(
            category: category,
            primaryTool: primaryToolStat,
            toolsToKeep: keepTools,
            toolsToRemove: removeTools,
            expectedCognitiveLoadReduction: calculateCognitiveLoadReduction(),
            actions: generatePlanActions()
        )
    }
    
    private func calculateCognitiveLoadReduction() -> Double {
        let currentLoad = CategoryUsageMetrics.calculateCognitiveLoad(
            activeTools: tools,
            totalActivations: tools.reduce(0) { $0 + $1.activationCount }
        )
        
        let keepTools = tools.filter { selectedTools.contains($0.bundleIdentifier ?? "unknown.bundle.id") }
        let newLoad = CategoryUsageMetrics.calculateCognitiveLoad(
            activeTools: keepTools,
            totalActivations: keepTools.reduce(0) { $0 + $1.activationCount }
        )
        
        return max(0, currentLoad - newLoad)
    }
    
    private func generatePlanActions() -> [String] {
        var actions: [String] = []
        let removeTools = tools.filter { !selectedTools.contains($0.bundleIdentifier ?? "unknown.bundle.id") }
        
        if !removeTools.isEmpty {
            actions.append("Hide \(removeTools.count) unused tools from dock")
        }
        
        if let primaryToolId = primaryTool,
           let primaryTool = tools.first(where: { ($0.bundleIdentifier ?? "unknown.bundle.id") == primaryToolId }) {
            actions.append("Set \(primaryTool.appName) as primary tool")
        }
        
        actions.append("Set usage limits for secondary tools")
        actions.append("Schedule weekly review reminder")
        
        return actions
    }
}

// MARK: - Supporting Views

struct ToolSelectionRow: View {
    let tool: AppUsageStat
    let isSelected: Bool
    let canSelect: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                if canSelect || isSelected {
                    onToggle(!isSelected)
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiaryText)
                        .font(.system(size: 16))
                    
                    if let appIcon = tool.appIcon {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tool.appName)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("\(tool.activationCount) activations")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .disabled(!canSelect && !isSelected)
            .opacity((canSelect || isSelected) ? 1.0 : 0.5)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
    }
}

struct PrimaryToolSelectionRow: View {
    let tool: AppUsageStat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: isSelected ? "star.fill" : "star")
                    .foregroundColor(isSelected ? .orange : DesignSystem.Colors.tertiaryText)
                    .font(.system(size: 16))
                
                if let appIcon = tool.appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.appName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Most used tool - good choice for primary")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(DesignSystem.Spacing.md)
        .background(isSelected ? DesignSystem.Colors.accent.opacity(0.1) : DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .stroke(isSelected ? DesignSystem.Colors.accent : Color.clear, lineWidth: 1)
        )
    }
}

struct ConsolidationPlanView: View {
    let plan: ConsolidationPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Summary
            HStack {
                VStack(alignment: .leading) {
                    Text("Tools to Keep")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("\(plan.toolsToKeep.count)")
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Cognitive Load Reduction")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(String(format: "-%.1f", plan.expectedCognitiveLoadReduction))
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Tools to Remove")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("\(plan.toolsToRemove.count)")
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
            
            // Actions
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Actions")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                ForEach(plan.actions, id: \.self) { action in
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text(action)
                            .font(DesignSystem.Typography.body)
                    }
                }
            }
        }
    }
}

// MARK: - Data Models

struct ConsolidationPlan {
    let category: AppCategory
    let primaryTool: AppUsageStat
    let toolsToKeep: [AppUsageStat]
    let toolsToRemove: [AppUsageStat]
    let expectedCognitiveLoadReduction: Double
    let actions: [String]
}

#Preview {
    ConsolidationWorkflowView(
        category: .productivity,
        tools: [
            AppUsageStat(appName: "Notion", bundleIdentifier: "notion.id", activationCount: 25, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
            AppUsageStat(appName: "Obsidian", bundleIdentifier: "md.obsidian", activationCount: 15, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
            AppUsageStat(appName: "Bear", bundleIdentifier: "net.shinyfrog.bear", activationCount: 8, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
            AppUsageStat(appName: "Roam", bundleIdentifier: "com.roamresearch", activationCount: 5, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
            AppUsageStat(appName: "Logseq", bundleIdentifier: "com.logseq", activationCount: 3, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity)
        ],
        activityMonitor: ActivityMonitor()
    )
}