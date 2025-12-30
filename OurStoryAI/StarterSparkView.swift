import SwiftUI

struct StarterSparkView: View {

    var body: some View {
        ZStack {
            FancyBackground()

            VStack(spacing: 30) {

                Text("✨ Starter Spark")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Kickstart your magical story journey")
                    .foregroundColor(.white.opacity(0.7))

                GlassCard {
                    VStack(spacing: 20) {
                        FancyButton(
                            title: "Create a Story",
                            systemImage: "sparkles"
                        ) {
                            print("Create Story")
                        }

                        FancyButton(
                            title: "Storyteller Mode",
                            systemImage: "book.fill"
                        ) {
                            print("Storyteller Mode")
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

