import SwiftUI

struct KeyboardHintView: View {
    let hints: [(key: String, action: String)]
    let showHints: Bool
    
    var body: some View {
        if showHints && !hints.isEmpty {
            HStack(spacing: 20) {
                ForEach(hints, id: \.key) { hint in
                    HStack(spacing: 4) {
                        Text(hint.key)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                        Text(":")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(hint.action)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color(red: 0.08, green: 0.09, blue: 0.11)
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1),
                        alignment: .bottom
                    )
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)),
                removal: .opacity
            ))
        }
    }
}

// Usage tracker for progressive disclosure
class KeyboardHintUsageTracker: ObservableObject {
    private let usageKey = "com.grab.macos.NPBUsageCount"
    private let hintsEnabledKey = "com.grab.macos.ShowKeyboardHints"
    
    @Published var shouldShowHints: Bool = true
    @Published var hintDuration: Double = 3.0
    
    var usageCount: Int {
        get { UserDefaults.standard.integer(forKey: usageKey) }
        set { 
            UserDefaults.standard.set(newValue, forKey: usageKey)
            updateHintBehavior()
        }
    }
    
    var hintsEnabled: Bool {
        get { 
            // Default to true for new users
            if UserDefaults.standard.object(forKey: hintsEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: hintsEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hintsEnabledKey) }
    }
    
    init() {
        updateHintBehavior()
    }
    
    func incrementUsage() {
        usageCount += 1
    }
    
    private func updateHintBehavior() {
        // Progressive disclosure based on usage
        switch usageCount {
        case 0..<5:
            hintDuration = 3.0
        case 5..<20:
            hintDuration = 1.5
        case 20..<50:
            hintDuration = 0.5
        default:
            hintDuration = 0.0 // Don't auto-show, only on ?
        }
        
        shouldShowHints = hintsEnabled && (usageCount < 50)
    }
}