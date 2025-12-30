import Foundation
import UIKit

class HeroAlignmentSystem {
    
    // STEP 1: VISION EXTRACTION
    func getVisionSystemPrompt() -> String {
        return """
        You are a Character Profiler. 
        Analyze the uploaded image. Output ONLY a concise physical description string focusing on:
        Age, hair color/style, eye color, clothing, and distinctive features.
        """
    }
    
    // STEP 2: STORY GENERATION
    func getStoryGenerationPrompt(for hero: HeroProfile) -> String {
        return """
        Write a children's story about \(hero.name) in the \(hero.language) language.
        
        STRICT CHARACTER CONSISTENCY REQUIRED:
        Whenever you describe the hero's appearance, you MUST use these traits:
        "\(hero.visualTraits)"
        
        Story Theme: \(hero.storyTheme)
        Target Audience: Children aged 3-8
        """
    }
    
    // STEP 3: IMAGE GENERATION
    func getIllustrationPrompt(for hero: HeroProfile, specificAction: String) -> String {
        let artStyle = "3D Pixar-style animation render, vibrant colors, soft lighting, 4k resolution"
        
        return """
        A high-quality illustration of [ \(hero.visualTraits) ] named \(hero.name).
        The character is currently: \(specificAction).
        Style: \(artStyle).
        """
    }
}
