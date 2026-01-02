import Foundation

/// Service for performing web searches using DuckDuckGo
class WebSearchService {
    
    /// Perform a web search and return formatted results
    /// - Parameter query: The search query
    /// - Returns: Formatted search results as a string, or nil if search fails
    func search(query: String) async -> String? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://lite.duckduckgo.com/lite/?q=\(encodedQuery)") else {
            print("Error: Invalid search query")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Error: Invalid response from DuckDuckGo")
                return nil
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                print("Error: Could not decode HTML")
                return nil
            }
            
            return parseSearchResults(html: html, query: query)
            
        } catch {
            print("Error performing web search: \(error)")
            return nil
        }
    }
    
    /// Parse HTML from DuckDuckGo Lite and extract search results
    private func parseSearchResults(html: String, query: String) -> String {
        var results: [String] = []
        results.append("Web search results for: \"\(query)\"\n")
        
        // DuckDuckGo Lite uses simple HTML structure
        // Extract results between <tr> tags that contain result links
        let lines = html.components(separatedBy: "\n")
        var currentResult = ""
        var resultCount = 0
        let maxResults = 5
        
        for line in lines {
            // Look for result links (class="result-link")
            if line.contains("class=\"result-link\"") {
                if !currentResult.isEmpty && resultCount < maxResults {
                    results.append("\n[\(resultCount + 1)] \(currentResult)")
                    resultCount += 1
                    currentResult = ""
                }
                
                // Extract the link text and URL
                if let titleMatch = extractBetween(line, start: "\">", end: "</a>") {
                    currentResult = cleanHTML(titleMatch)
                }
            }
            
            // Look for snippets (class="result-snippet")
            if line.contains("class=\"result-snippet\"") {
                if let snippetMatch = extractBetween(line, start: "\">", end: "</td>") {
                    let cleanSnippet = cleanHTML(snippetMatch)
                    if !cleanSnippet.isEmpty {
                        currentResult += "\n   " + cleanSnippet
                    }
                }
            }
            
            if resultCount >= maxResults {
                break
            }
        }
        
        // Add last result if exists
        if !currentResult.isEmpty && resultCount < maxResults {
            results.append("\n[\(resultCount + 1)] \(currentResult)")
        }
        
        if results.count <= 1 {
            return "No search results found for: \"\(query)\""
        }
        
        return results.joined(separator: "\n")
    }
    
    /// Extract text between two delimiters
    private func extractBetween(_ text: String, start: String, end: String) -> String? {
        guard let startRange = text.range(of: start) else { return nil }
        let afterStart = text[startRange.upperBound...]
        guard let endRange = afterStart.range(of: end) else { return nil }
        return String(afterStart[..<endRange.lowerBound])
    }
    
    /// Clean HTML entities and tags from text
    private func cleanHTML(_ text: String) -> String {
        var cleaned = text
        
        // Remove HTML tags
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode common HTML entities
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
        cleaned = cleaned.replacingOccurrences(of: "&#39;", with: "'")
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}
