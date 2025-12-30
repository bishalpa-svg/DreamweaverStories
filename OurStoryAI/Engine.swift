import Foundation
import SwiftUI
import Combine

class StoryEngine: ObservableObject {
    
    // 🔒 USE THE SECURE KEY
    private let apiKey = Secrets.openAIKey

    // MARK: - 1. Generate Text (Refined)
    func generateStoryStructure(heroName: String, theme: String, insights: String, pageCount: Int, language: String) async throws -> [StoryPage] {
        // We ask for JSON specifically to prevent "Chatty" responses
        let systemPrompt = """
        You are a backend JSON generator.
        Write a \(pageCount)-page children's story about \(heroName) in \(language).
        Theme: \(theme). Moral: \(insights).
        
        Strictly return Valid JSON only. Format:
        {"pages": [{"page": 1, "text": "..."}]}
        """
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [["role": "system", "content": systemPrompt]],
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let res = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let content = res.choices.first?.message.content ?? ""
        
        // 🛡️ Safety: Clean up potential Markdown wrappers
        let cleanContent = content.replacingOccurrences(of: "```json", with: "")
                                  .replacingOccurrences(of: "```", with: "")
                                  .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanContent.data(using: .utf8) else { throw NSError(domain: "ParseError", code: 0) }
        
        struct Wrapper: Decodable { let pages: [TempPage] }
        struct TempPage: Decodable { let page: Int; let text: String }
        
        let decoded = try JSONDecoder().decode(Wrapper.self, from: jsonData)
        
        return decoded.pages.map { StoryPage(pageNumber: $0.page, text: $0.text, imageURL: "") }
    }

    // MARK: - 2. Generate Image
    func updatePageImage(heroName: String, context: String, focus: String) async throws -> String {
        let prompt = "Children's book illustration. 3D Pixar style. Character: \(heroName). Scene: \(context). Atmosphere: \(focus). High resolution, cute, vibrant."
        
        let url = URL(string: "https://api.openai.com/v1/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["model": "dall-e-3", "prompt": prompt, "n": 1, "size": "1024x1024"]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct DalleRes: Decodable { struct Data: Decodable { let url: String }; let data: [Data] }
        let decoded = try JSONDecoder().decode(DalleRes.self, from: data)
        return decoded.data.first?.url ?? ""
    }

    // MARK: - 3. Generate Audio
    func fetchAudio(text: String, voice: String) async throws -> Data {
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["model": "tts-1", "input": text, "voice": voice]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}

// Helper Structures
struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}
