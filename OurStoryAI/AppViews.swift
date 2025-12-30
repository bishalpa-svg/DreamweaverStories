import SwiftUI
import PhotosUI

struct AppViews: View {

    @StateObject private var engine = StoryEngine()

    // ✅ CORRECT for singleton
    @ObservedObject var creditManager = CreditManager.shared

    // MARK: - User Inputs
    @State private var heroName = ""
    @State private var storyTheme = ""
    @State private var storyInsights = ""
    @State private var selectedPageCount = 10
    @State private var selectedLanguage = "English"
    @State private var selectedVoice = "shimmer"


    // MARK: - Media
    @State private var heroImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false

    // MARK: - State
    @State private var generatedBook: [StoryPage] = []
    @State private var showStoryBook = false
    @State private var isGenerating = false
    @State private var isSaving = false
    @State private var currentIllustrationPage = 0
    @State private var showSavedStories = false
    @State private var saveSuccessMessage = false
    
    // MARK: - Store & Errors
    @State private var showStore = false
    @State private var showNoCreditsAlert = false
    @State private var errorMessage = ""
    @State private var showError = false

    let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese"]
    
    // MARK: - PRICING LOGIC (UPDATED)
    // Now purely linear: 1 Credit per 10 Pages.
    var currentStoryCost: Int {
        return max(1, selectedPageCount / 10)
    }

    func targetImageCount(for pages: Int) -> Int {
        switch pages {
        case 10: return 3
        case 20: return 6
        case 30: return 9
        case 40: return 12
        case 50: return 15
        case 100: return 25 // 25 Images for a massive story
        default: return max(1, pages / 4)
        }
    }

    // MARK: - MAIN BODY
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isIPad = geo.size.width > 600
                
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: isIPad ? 30 : 20) {
                            headerSection(isIPad: isIPad)
                            avatarSection(isIPad: isIPad)
                            formSection(isIPad: isIPad)
                            actionButtons(isIPad: isIPad)
                        }
                        .padding()
                        .frame(width: isIPad ? geo.size.width * 0.85 : nil)
                        .frame(maxWidth: isIPad ? 1000 : .infinity)
                        .frame(maxWidth: .infinity)
                    }
                }
                // MARK: - ALERTS & SHEETS
                .alert("Story Saved!", isPresented: $saveSuccessMessage) {
                    Button("OK", role: .cancel) { }
                }
                .alert("Generation Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                .alert("Not Enough Credits", isPresented: $showNoCreditsAlert) {
                    Button("Go to Store") { showStore = true }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This story costs \(currentStoryCost) Credits, but you only have \(creditManager.currentCredits).")
                }
                .fullScreenCover(isPresented: $showStoryBook) {
                    StoryReaderView(
                        pages: generatedBook,
                        heroImage: heroImage,
                        closeAction: { showStoryBook = false },
                        onSave: { saveCurrentStory() },
                        selectedVoiceName: $selectedVoice
                    )
                }
                .sheet(isPresented: $showCamera) { CameraPicker(image: $heroImage) }
                .sheet(isPresented: $showStore) { StoreView() }
                .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
                .onChange(of: selectedPhotoItem) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            heroImage = uiImage
                        }
                    }
                }
                .sheet(isPresented: $showSavedStories) {
                    SavedStoriesView { story in
                        heroImage = StoryStorageManager.shared.loadHeroImage(for: story)
                        generatedBook = story.pages
                        showStoryBook = true
                    }
                }
            }
        }
    }

    // MARK: - SUBVIEWS
    
    func headerSection(isIPad: Bool) -> some View {
        HStack {
            Text("Dreamweaver Stories")
                .font(.custom("Georgia-Italic", size: isIPad ? 40 : 24))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showStore = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(creditManager.currentCredits)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, isIPad ? 15 : 10)
                .padding(.vertical, isIPad ? 10 : 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            .scaleEffect(isIPad ? 1.2 : 1.0)
        }
    }

    func avatarSection(isIPad: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(colors: [.yellow, .white, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
                    .frame(width: isIPad ? 220 : 140, height: isIPad ? 220 : 140)

                if let image = heroImage {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: isIPad ? 210 : 130, height: isIPad ? 210 : 130)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: isIPad ? 60 : 32))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            HStack(spacing: 12) {
                BoutiqueButton(title: "Camera", icon: "camera", fullWidth: true) { showCamera = true }
                BoutiqueButton(title: "Upload", icon: "photo", fullWidth: true) { showPhotoLibrary = true }
            }
            .frame(maxWidth: isIPad ? 500 : nil)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    func formSection(isIPad: Bool) -> some View {
        let adaptiveColumns = [GridItem(.adaptive(minimum: isIPad ? 160 : 100), spacing: 8)]

        return VStack(spacing: 12) {
            BoutiqueTextField(placeholder: "Hero Name (e.g Nava)", text: $heroName, isIPad: isIPad)
            BoutiqueTextField(placeholder: "Theme (e.g Magical Castle)", text: $storyTheme, isIPad: isIPad)
            BoutiqueTextField(placeholder: "Moral / Insight (e.g Be kind)", text: $storyInsights, isIPad: isIPad)

            // Page Count Grid (UPDATED: 10, 20, 30, 40, 50, 100)
            VStack(alignment: .leading, spacing: 6) {
                Text("Pages (Cost varies)").font(isIPad ? .body : .caption).foregroundColor(.white.opacity(0.7))
                LazyVGrid(columns: adaptiveColumns, spacing: 8) {
                    ForEach([10, 20, 30, 40, 50, 100], id: \.self) { count in
                        Button { selectedPageCount = count } label: {
                            VStack(spacing: 2) {
                                Text("\(count) Pgs")
                                    .font(.system(size: isIPad ? 16 : 13, weight: .bold))
                                // Show badge for cost
                                Text(costFor(count))
                                    .font(.system(size: isIPad ? 10 : 8))
                                    .foregroundColor(.yellow)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isIPad ? 14 : 8)
                            .background(selectedPageCount == count ? Color.blue : Color.white.opacity(0.1))
                            .cornerRadius(8).foregroundColor(.white)
                        }
                    }
                }
            }

            // Language Grid
            VStack(alignment: .leading, spacing: 6) {
                Text("Language").font(isIPad ? .body : .caption).foregroundColor(.white.opacity(0.7))
                LazyVGrid(columns: adaptiveColumns, spacing: 8) {
                    ForEach(languages, id: \.self) { lang in
                        Button { selectedLanguage = lang } label: {
                            Text(lang)
                                .font(.system(size: isIPad ? 16 : 13, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, isIPad ? 14 : 8)
                                .background(selectedLanguage == lang ? Color.purple : Color.white.opacity(0.1))
                                .cornerRadius(8).foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // Helper for grid display
    func costFor(_ pages: Int) -> String {
        let cost = max(1, pages / 10)
        return "\(cost) Credit\(cost > 1 ? "s" : "")"
    }

    func actionButtons(isIPad: Bool) -> some View {
        VStack(spacing: 12) {
            BoutiqueButton(title: isGenerating ? "Illustrating..." : "Craft Your Tale (\(currentStoryCost) Credits)", icon: "sparkles", fullWidth: true, isIPad: isIPad) {
                generateBackgroundStory()
            }
            .disabled(heroName.isEmpty || heroImage == nil || isGenerating)
            
            BoutiqueButton(title: "Play Saved Stories", icon: "book", fullWidth: true, isIPad: isIPad) {
                showSavedStories = true
            }
        }
        .frame(maxWidth: isIPad ? 600 : nil)
    }

    // MARK: - LOGIC: SAVE STORY
    func saveCurrentStory() {
        isSaving = true
        Task {
            await StoryStorageManager.shared.saveStory(
                title: "\(heroName)'s Tale",
                heroImage: heroImage,
                pages: generatedBook,
                engine: engine,
                voice: selectedVoice
            )
            await MainActor.run {
                isSaving = false
                saveSuccessMessage = true
            }
        }
    }

    // MARK: - LOGIC: GENERATE STORY
    func generateBackgroundStory() {
        // 1. CHECK IF USER CAN AFFORD THIS SPECIFIC TIER
        let cost = currentStoryCost
        
        guard creditManager.canAfford(cost: cost) else {
            showNoCreditsAlert = true
            return
        }
        
        isGenerating = true
        currentIllustrationPage = 0
        
        // 2. DEDUCT THE COST
        creditManager.spendCredits(amount: cost)
        
        Task {
            do {
                let pages = try await engine.generateStoryStructure(
                    heroName: heroName,
                    theme: storyTheme,
                    insights: storyInsights,
                    pageCount: selectedPageCount,
                    language: selectedLanguage
                )
                
                var updatedPages = pages
                let maxImages = targetImageCount(for: selectedPageCount)
                let interval = max(1, selectedPageCount / maxImages)
                var imagesGenerated = 0
                var lastImageURL = ""

                for i in 0..<updatedPages.count {
                    await MainActor.run { currentIllustrationPage = i + 1 }
                    if imagesGenerated < maxImages && (i == 0 || i % interval == 0) {
                        let url = try await engine.updatePageImage(heroName: heroName, context: updatedPages[i].text, focus: storyTheme)
                        lastImageURL = url
                        updatedPages[i].imageURL = url
                        imagesGenerated += 1
                    } else {
                        updatedPages[i].imageURL = lastImageURL
                    }
                    await MainActor.run {
                        if generatedBook.indices.contains(i) { generatedBook[i].imageURL = lastImageURL }
                    }
                }
                
                await MainActor.run {
                    generatedBook = updatedPages
                    showStoryBook = true
                    isGenerating = false
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "Failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Components (UPDATED FOR IPAD)

struct BoutiqueButton: View {
    let title: String
    let icon: String
    var fullWidth: Bool = false
    var isIPad: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if title == "Illustrating..." || title == "Saving..." {
                    ProgressView().tint(.white).padding(.trailing, 5)
                }
                Image(systemName: icon)
                    .font(isIPad ? .title3 : .body)
                Text(title)
                    .font(isIPad ? .headline : .caption2)
                    .bold()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, isIPad ? 20 : 12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
            .foregroundColor(.white)
        }
    }
}

struct BoutiqueTextField: View {
    let placeholder: String
    @Binding var text: String
    var isIPad: Bool = false

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)).font(isIPad ? .body : .callout))
            .font(isIPad ? .body : .callout)
            .padding(isIPad ? 18 : 12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            picker.dismiss(animated: true)
        }
    }
}
