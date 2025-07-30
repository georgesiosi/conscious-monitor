import SwiftUI

struct CategoryManagementView: View {
    @ObservedObject var categoryManager = CategoryManager.shared
    @State private var newCategoryName = ""
    @State private var showingAddCategory = false
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: AppCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Add button
            HStack {
                Text("App Categories")
                    .font(.headline)
                Spacer()
                Button("Add Category") {
                    showingAddCategory = true
                }
                .buttonStyle(.borderedProminent)
                .font(.footnote)
            }
            
            // Category list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(categoryManager.allAvailableCategories) { category in
                        CategoryRowView(
                            category: category,
                            isDefault: AppCategory.defaultCases.contains(where: { $0.name == category.name }),
                            onDelete: { categoryToDelete = category; showingDeleteAlert = true }
                        )
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("Default categories cannot be deleted. Custom categories can be created and assigned to apps.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet(
                newCategoryName: $newCategoryName,
                onSave: {
                    if let _ = categoryManager.addCustomCategory(name: newCategoryName) {
                        newCategoryName = ""
                        showingAddCategory = false
                    }
                },
                onCancel: {
                    newCategoryName = ""
                    showingAddCategory = false
                }
            )
        }
        .alert("Delete Category", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    categoryManager.removeCustomCategory(category)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove '\(categoryToDelete?.name ?? "")' and reset any apps assigned to it back to their default categories.")
        }
    }
}

struct CategoryRowView: View {
    let category: AppCategory
    let isDefault: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Color indicator
            Circle()
                .fill(category.color)
                .frame(width: 16, height: 16)
            
            // Category name
            Text(category.name)
                .font(.body)
            
            // Default indicator
            if isDefault {
                Text("Default")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Delete button (only for custom categories)
            if !isDefault {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Delete custom category")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct AddCategorySheet: View {
    @Binding var newCategoryName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Name")
                        .font(.headline)
                    
                    TextField("Enter category name", text: $newCategoryName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSave()
                            }
                        }
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Add Category") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Add Category")
        }
        .frame(width: 300, height: 200)
    }
}

#Preview {
    CategoryManagementView()
        .frame(width: 500, height: 400)
        .padding()
}