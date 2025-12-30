import Foundation
import UIKit

class StoryStorageManager {

    static let shared = StoryStorageManager()
    private let savedStoriesKey = "SavedStories"

    private init() {}

    // MARK: - Save Story
    func saveStory(title: String, heroImage: UIImage?, pages: [StoryPage], engine: StoryEngine, voice: String) async {
        
        var storedStories = loadStories()

        // 1. Save Hero Image
        var heroFilename = ""
        if let heroImage = heroImage, let data = heroImage.jpegData(compressionQuality: 0.8) {
            heroFilename = saveFileToDocuments(data: data, name: "hero_\(UUID().uuidString).jpg")
        }

        // 2. Process Pages
        var savedPages: [StoryPage] = []
        
        for var page in pages {
            // A. Download Image
            if let url = URL(string: page.imageURL), page.imageURL.hasPrefix("http") {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    let filename = "img_\(UUID().uuidString).jpg"
                    let savedName = saveFileToDocuments(data: data, name: filename)
                    page.imageURL = savedName
                }
            }
            
            // B. Generate & Save Audio
            if page.audioFilename == nil {
                do {
                    let audioData = try await engine.fetchAudio(text: page.text, voice: voice)
                    let audioFilename = "audio_\(UUID().uuidString).mp3"
                    let savedAudioName = saveFileToDocuments(data: audioData, name: audioFilename)
                    page.audioFilename = savedAudioName
                } catch {
                    print("Failed to save audio for page \(page.pageNumber): \(error)")
                }
            }
            
            savedPages.append(page)
        }

        // 3. Save Book
        let storybook = Storybook(
            id: UUID(),
            title: title,
            coverImage: heroFilename,
            pages: savedPages
        )

        storedStories.append(storybook)
        saveStoriesToDisk(stories: storedStories)
    }

    // MARK: - Load & Helper Methods (These were missing!)
    
    func loadStories() -> [Storybook] {
        guard let data = UserDefaults.standard.data(forKey: savedStoriesKey),
              let stories = try? JSONDecoder().decode([Storybook].self, from: data) else {
            return []
        }
        return stories
    }

    func loadHeroImage(for story: Storybook) -> UIImage? {
        return loadImage(named: story.coverImage)
    }
    
    // CRITICAL FIX: The missing function 'loadImage'
    func loadImage(named filename: String) -> UIImage? {
        guard !filename.isEmpty else { return nil }
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }
    
    // CRITICAL FIX: The missing function 'getAudioURL'
    func getAudioURL(named filename: String) -> URL? {
        guard !filename.isEmpty else { return nil }
        return getDocumentsDirectory().appendingPathComponent(filename)
    }

    func deleteStory(_ story: Storybook) {
        var storedStories = loadStories()
        storedStories.removeAll { $0.id == story.id }
        saveStoriesToDisk(stories: storedStories)
    }

    private func saveStoriesToDisk(stories: [Storybook]) {
        if let encoded = try? JSONEncoder().encode(stories) {
            UserDefaults.standard.set(encoded, forKey: savedStoriesKey)
        }
    }

    private func saveFileToDocuments(data: Data, name: String) -> String {
        let url = getDocumentsDirectory().appendingPathComponent(name)
        try? data.write(to: url)
        return name
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
