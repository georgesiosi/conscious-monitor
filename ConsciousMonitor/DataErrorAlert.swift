import SwiftUI

struct DataErrorAlert: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @State private var showAlert = false
    
    var body: some View {
        EmptyView()
            .onChange(of: activityMonitor.lastDataError) { _, error in
                if error != nil {
                    showAlert = true
                }
            }
            .alert("Data Storage Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    activityMonitor.lastDataError = nil
                }
                Button("Retry") {
                    retryDataOperation()
                }
            } message: {
                Text(activityMonitor.lastDataError ?? "An unknown error occurred while saving your data.")
            }
    }
    
    private func retryDataOperation() {
        // Force a save to retry the operation
        activityMonitor.forceSaveAllData()
        activityMonitor.lastDataError = nil
    }
}

#Preview {
    DataErrorAlert(activityMonitor: ActivityMonitor())
}