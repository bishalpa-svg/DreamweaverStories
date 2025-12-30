import SwiftUI
import AVFoundation

struct StoryReaderView: View {
    let pages: [StoryPage]
    let heroImage: UIImage?
    var closeAction: () -> Void
    var onSave: () -> Void // <--- NEW: Action to save from inside the reader
    
    @Binding var selectedVoiceName: String
    
    @State private var currentPageIndex = 0
    @State private var isNarratorOn = false
    @State private var isAutoTurnOn = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isDownloadingAudio = false
    @State private var currentAudioTask: Task<Void, Never>? = nil
    @State private var activeAudioDelegate: AudioDelegate?
    @State private var hasSaved = false // To disable button after saving
    
    let engine = StoryEngine()

    enum CloudVoice: String, CaseIterable {
        case onyx = "Gentleman", shimmer = "Lady", alloy = "Boy", nova = "Girl"
        var internalName: String {
            switch self {
            case .onyx: return "onyx"
            case .shimmer: return "shimmer"
            case .alloy: return "alloy"
            case .nova: return "nova"
            }
        }
    }

    var currentVoiceEnum: CloudVoice {
        CloudVoice.allCases.first(where: { $0.internalName == selectedVoiceName }) ?? .shimmer
    }

    var body: some View {
        ZStack {
            Color(hex: "1a1a2e").ignoresSafeArea()
            
            if !pages.isEmpty && currentPageIndex < pages.count {
                VStack(spacing: 15) {
                    
                    // HEADER
                    HStack {
                        // Close Button
                        Button(action: { stopEverything(); closeAction() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // NEW: SAVE BUTTON (Top Right)
                        if pages[currentPageIndex].audioFilename == nil && !hasSaved {
                            Button(action: {
                                onSave()
                                hasSaved = true
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Save")
                                }
                                .font(.caption.bold())
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.green)
                                .cornerRadius(20)
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // VOICE MENU (Moved below header to save space)
                    if pages[currentPageIndex].audioFilename == nil {
                        HStack {
                            Spacer()
                            Menu {
                                ForEach(CloudVoice.allCases, id: \.self) { v in
                                    Button(v.rawValue) {
                                        selectedVoiceName = v.internalName
                                        if isNarratorOn { playCloudVoice() }
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "waveform")
                                    Text(currentVoiceEnum.rawValue)
                                }
                                .font(.caption2)
                                .padding(6)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal)
                    }

                    // IMAGE DISPLAY
                    Group {
                        if let uiImage = StoryStorageManager.shared.loadImage(named: pages[currentPageIndex].imageURL) {
                            Image(uiImage: uiImage).resizable().scaledToFit().cornerRadius(20).padding(.horizontal)
                        } else {
                            AsyncImage(url: URL(string: pages[currentPageIndex].imageURL)) { phase in
                                if let img = phase.image { img.resizable().scaledToFit().cornerRadius(20).padding(.horizontal) }
                                else { ProgressView().tint(.white) }
                            }
                        }
                    }
                    .frame(maxHeight: 350)
                    .id(pages[currentPageIndex].imageURL)

                    // TEXT SCROLL
                    ScrollView {
                        if isDownloadingAudio { ProgressView("Loading Voice...").tint(.white).padding() }
                        Text(pages[currentPageIndex].text)
                            .font(.system(size: 22, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }.frame(maxHeight: 180)

                    // CONTROLS
                    HStack(spacing: 30) {
                        Button(action: {
                            isNarratorOn.toggle()
                            if isNarratorOn { playCloudVoice() } else { audioPlayer?.stop() }
                        }) {
                            VStack {
                                Image(systemName: isNarratorOn ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                Text("Voice").font(.caption2)
                            }
                        }.foregroundColor(isNarratorOn ? .yellow : .white)

                        Button(action: { if currentPageIndex > 0 { currentPageIndex -= 1 } }) {
                            Image(systemName: "chevron.left.circle.fill").font(.system(size: 50))
                        }.disabled(currentPageIndex == 0).foregroundColor(.white)

                        Button(action: {
                            isAutoTurnOn.toggle()
                            if isAutoTurnOn { isNarratorOn = true; playCloudVoice() }
                        }) {
                            VStack {
                                Image(systemName: isAutoTurnOn ? "pause.circle.fill" : "play.circle.fill")
                                Text("Auto").font(.caption2)
                            }
                        }.foregroundColor(isAutoTurnOn ? .green : .white)

                        Button(action: { if currentPageIndex < pages.count - 1 { currentPageIndex += 1 } }) {
                            Image(systemName: "chevron.right.circle.fill").font(.system(size: 50))
                        }.disabled(currentPageIndex == pages.count - 1).foregroundColor(.white)
                    }.padding(.bottom, 20)
                }
            } else {
                ProgressView().tint(.white)
            }
        }
        .onAppear { configureAudioSession() }
        .onChange(of: currentPageIndex) { _, _ in if isNarratorOn { playCloudVoice() } }
    }

    func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playCloudVoice() {
        audioPlayer?.stop(); audioPlayer = nil
        currentAudioTask?.cancel()
        isDownloadingAudio = true
        
        let page = pages[currentPageIndex]
        
        currentAudioTask = Task {
            do {
                var audioData: Data?
                
                if let filename = page.audioFilename,
                   let localURL = StoryStorageManager.shared.getAudioURL(named: filename),
                   let localData = try? Data(contentsOf: localURL) {
                    print("Playing from Memory (FREE)")
                    audioData = localData
                } else {
                    print("Fetching from Cloud (PAID)")
                    audioData = try await engine.fetchAudio(text: page.text, voice: selectedVoiceName)
                }

                if Task.isCancelled { return }
                
                if let data = audioData {
                    await MainActor.run {
                        let delegate = AudioDelegate(onFinish: {
                            if isAutoTurnOn && currentPageIndex < pages.count - 1 {
                                withAnimation { currentPageIndex += 1 }
                            } else if isAutoTurnOn { stopEverything() }
                        })
                        self.activeAudioDelegate = delegate
                        audioPlayer = try? AVAudioPlayer(data: data)
                        audioPlayer?.delegate = delegate
                        audioPlayer?.play()
                        isDownloadingAudio = false
                    }
                }
            } catch { await MainActor.run { isDownloadingAudio = false } }
        }
    }

    func stopEverything() {
        currentAudioTask?.cancel()
        audioPlayer?.stop()
        audioPlayer = nil
        activeAudioDelegate = nil
        isAutoTurnOn = false
        isNarratorOn = false
    }
}

class AudioDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
}

