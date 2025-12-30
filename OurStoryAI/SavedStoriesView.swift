import SwiftUI

struct SavedStoriesView: View {
    
    @State private var savedStories: [Storybook] = []
    var playStory: (Storybook) -> Void // Closure to play the story

    var body: some View {
        NavigationStack {
            List {
                ForEach(savedStories) { story in
                    HStack {
                        // Thumbnail for Hero Image
                        if let image = StoryStorageManager.shared.loadHeroImage(for: story) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "book")
                                .font(.largeTitle)
                                .frame(width: 60, height: 60)
                        }
                        
                        // Story title
                        Text(story.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        // Optional Trash Button
                        Button(action: {
                            deleteStory(story)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .contentShape(Rectangle()) // Make whole row tappable
                    .onTapGesture {
                        playStory(story)
                    }
                }
                .onDelete(perform: deleteStoriesSwipe) // Swipe-to-delete
            }
            .navigationTitle("Saved Stories")
            .onAppear {
                loadSavedStories()
            }
        }
    }
    
    // MARK: - Load Stories
    private func loadSavedStories() {
        savedStories = StoryStorageManager.shared.loadStories()
    }
    
    // MARK: - Delete Story (Button)
    private func deleteStory(_ story: Storybook) {
        StoryStorageManager.shared.deleteStory(story)
        loadSavedStories()
    }
    
    // MARK: - Delete Story (Swipe)
    private func deleteStoriesSwipe(at offsets: IndexSet) {
        offsets.forEach { index in
            let story = savedStories[index]
            deleteStory(story)
        }
    }
}

