import Foundation
import AppKit

// MARK: - Chrome Integration Extension
extension ActivityMonitor {
    
    /// Handles Chrome-specific functionality when Chrome becomes active
    func handleChromeActivation(for eventId: UUID) {
        print("🌐 Chrome detected. Querying active tab for event: \(eventId)")
        
        // Run AppleScript in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = AppleScriptRunner.getChromeActiveTabInfo()
            
            // Switch back to main thread to update published property
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let tabInfo):
                    print("✅ Chrome Tab Info Retrieved: Title='\(tabInfo.title)', URL='\(tabInfo.url)'")
                    
                    print("🔍 Looking for event \(eventId) in \(self.activationEvents.count) events")
                    if let index = self.activationEvents.firstIndex(where: { $0.id == eventId }) {
                        print("📝 Found event at index \(index), updating with Chrome tab data")
                        self.activationEvents[index].chromeTabTitle = tabInfo.title
                        self.activationEvents[index].chromeTabUrl = tabInfo.url
                        
                        // Confirm the update was successful
                        print("✅ Chrome tab data saved: '\(self.activationEvents[index].chromeTabTitle ?? "nil")'")
                        print("✅ Chrome URL saved: '\(self.activationEvents[index].chromeTabUrl ?? "nil")'")
                        
                        // Trigger UI update by notifying observers
                        self.objectWillChange.send()
                        
                        // Extract domain and fetch favicon
                        if let domain = FaviconFetcher.shared.extractDomain(fromUrlString: tabInfo.url) {
                            self.activationEvents[index].siteDomain = domain
                            
                            // Fetch favicon asynchronously
                            FaviconFetcher.shared.fetchFavicon(forDomain: domain) { favicon in
                                DispatchQueue.main.async {
                                    if let favicon = favicon,
                                       let idx = self.activationEvents.firstIndex(where: { $0.id == eventId }) {
                                        self.activationEvents[idx].siteFavicon = favicon
                                    }
                                }
                            }
                        } else {
                            print("Could not extract domain from URL: \(tabInfo.url)")
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Chrome tab info retrieval failed for event \(eventId)")
                    print("❌ Error details: \(error.localizedDescription)")
                    
                    // Update the event with an error message
                    if let index = self.activationEvents.firstIndex(where: { $0.id == eventId }) {
                        print("📝 Setting error message for Chrome event at index \(index)")
                        self.activationEvents[index].chromeTabTitle = "Error: Unable to retrieve tab information"
                    } else {
                        print("🚨 Event \(eventId) NOT FOUND in activationEvents array!")
                        print("🔍 Current events count: \(self.activationEvents.count)")
                        print("🔍 Recent event IDs: \(self.activationEvents.prefix(3).map { $0.id })")
                        
                        // Try to update via EventStorageService directly
                        print("🔄 Attempting to update via EventStorageService...")
                        self.eventStorageService.updateEventChromeData(
                            eventId: eventId,
                            tabTitle: "Error: Unable to retrieve tab information",
                            tabUrl: "",
                            siteDomain: nil
                        )
                        print("📝 Updated event via EventStorageService")
                    }
                }
            }
        }
    }
}
