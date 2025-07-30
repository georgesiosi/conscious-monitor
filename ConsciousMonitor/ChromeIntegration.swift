import Foundation
import AppKit

// MARK: - Chrome Integration Extension
extension ActivityMonitor {
    
    /// Handles Chrome-specific functionality when Chrome becomes active
    func handleChromeActivation(for eventId: UUID) {
        print("Chrome detected. Querying active tab...")
        
        // Run AppleScript in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = AppleScriptRunner.getChromeActiveTabInfo()
            
            // Switch back to main thread to update published property
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let tabInfo):
                    print("Chrome Tab Info: Title='\(tabInfo.title)', URL='\(tabInfo.url)'")
                    
                    if let index = self.activationEvents.firstIndex(where: { $0.id == eventId }) {
                        self.activationEvents[index].chromeTabTitle = tabInfo.title
                        self.activationEvents[index].chromeTabUrl = tabInfo.url
                        
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
                    print("DEBUG: Entered .failure case for Chrome tab info.")
                    print("DEBUG: eventId to find for UI update: \(eventId)")
                    print("Failed to get Chrome tab info: \(error.localizedDescription)")
                    
                    // Update the event with an error message
                    if let index = self.activationEvents.firstIndex(where: { $0.id == eventId }) {
                        self.activationEvents[index].chromeTabTitle = "Error: Unable to retrieve tab information"
                    } else {
                        print("DEBUG: CRITICAL - Could not find event with id \(eventId) to update its title.")
                    }
                }
            }
        }
    }
}
