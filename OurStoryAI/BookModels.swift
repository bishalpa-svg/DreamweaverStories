import Foundation

// --- SHARED DATA MODELS ---
// Keep these ONLY here. Delete them from all other files to stop "Redeclaration" errors.

struct StoryPage: Identifiable, Codable {
    var id = UUID()
    let pageNumber: Int
    let text: String
    var imageURL: String
    var audioFilename: String? // <--- ADDED THIS to fix the build error
}

struct HeroProfile: Codable {
    let name: String
    let visualTraits: String
    let storyTheme: String
    let language: String
}

struct Storybook: Identifiable, Codable {
    var id = UUID()
    let title: String
    let coverImage: String
    let pages: [StoryPage]
}
