import Foundation

struct AppleScriptRunner {

    enum ScriptError: Error, CustomStringConvertible {
        case scriptCompilationFailed(String?)
        case scriptExecutionFailed(String?)
        case scriptResultNotString
        case chromeSpecificError(String)

        var description: String {
            switch self {
            case .scriptCompilationFailed(let dict): return "AppleScript compilation failed: \(dict ?? "Unknown error")"
            case .scriptExecutionFailed(let dict): return "AppleScript execution failed: \(dict ?? "Unknown error")"
            case .scriptResultNotString: return "AppleScript result was not a string."
            case .chromeSpecificError(let msg): return "Chrome Script Error: \(msg)"
            }
        }
    }

    // Executes an AppleScript string and returns the result as a String
    // Throws ScriptError on failure
    static func runScript(script: String) -> Result<String, ScriptError> {
        var errorDict: NSDictionary? = nil
        
        // Compile the script
        guard let appleScript = NSAppleScript(source: script) else {
            return .failure(.scriptCompilationFailed(nil)) // Should ideally not happen with valid source
        }
        
        // Execute the script
        let resultDescriptor = appleScript.executeAndReturnError(&errorDict)
        
        // Check for execution errors
        if let errorInfo = errorDict {
            return .failure(.scriptExecutionFailed(errorInfo.description))
        }
        
        // Check if the result is a string
        guard let stringResult = resultDescriptor.stringValue else {
            return .failure(.scriptResultNotString)
        }

        // Check for specific errors returned by the script itself
        if stringResult.hasPrefix("Error: ") {
             return .failure(.chromeSpecificError(String(stringResult.dropFirst("Error: ".count))))
        }
        
        return .success(stringResult)
    }
    
    // Specific function to get Chrome tab info
    static func getChromeActiveTabInfo() -> Result<(title: String, url: String), ScriptError> {
        let script = """
        tell application "Google Chrome"
            if not (it is running) then
                return "Error: Chrome not running"
            end if

            if (count of windows) is 0 then
                return "Error: Chrome has no windows open"
            end if

            try
                set front_window to front window
                if not (exists active tab of front_window) then
                    return "Error: Front window has no active tab"
                end if
                set active_tab to active tab of front_window
                
                set tab_title to title of active_tab
                set tab_url to URL of active_tab
                
                -- Handle cases where title or URL might be missing value
                if tab_title is missing value then set tab_title to ""
                if tab_url is missing value then set tab_url to ""
                
                return tab_title & "\n" & tab_url
            on error errMsg number errorNumber
                return "Error: " & errMsg & " (" & (errorNumber as string) & ")"
            end try
        end tell
        """
        
        let result = runScript(script: script)
        
        switch result {
        case .success(let combinedString):
            let components = combinedString.split(separator: "\n", maxSplits: 1).map(String.init)
            if components.count == 2 {
                return .success((title: components[0], url: components[1]))
            } else {
                // Handle unexpected format if needed, treat as error for now
                return .failure(.chromeSpecificError("Unexpected script result format: \(combinedString)"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
