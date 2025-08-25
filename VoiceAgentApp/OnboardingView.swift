import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var navigateToMain = false
    @Environment(\.dismiss) var dismiss
    
    let features = [
        OnboardingFeature(
            icon: "sparkles",
            iconColors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.4, green: 0.2, blue: 0.8)],
            title: "Your Personal Everything Assistant",
            description: "Just speak naturally. \"Hey, remind me about tomorrow's meeting\" or \"What's the weather like?\" - Somethin' understands you.",
            animation: "pulse"
        ),
        OnboardingFeature(
            icon: "note.text",
            iconColors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 1.0, green: 0.3, blue: 0.5)],
            title: "Smart Notes & Memory",
            description: "\"Save this as a note\" or \"What did I write about the project?\" Chat naturally and Somethin' remembers everything for you.",
            animation: "rotate"
        ),
        OnboardingFeature(
            icon: "envelope.fill",
            iconColors: [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 0.2, green: 0.6, blue: 1.0)],
            title: "Email at Your Command",
            description: "\"Send John an email about lunch\" or \"Check my latest emails\" - manage your inbox without typing a single word.",
            animation: "bounce"
        ),
        OnboardingFeature(
            icon: "globe",
            iconColors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.2, green: 0.6, blue: 1.0)],
            title: "The Internet, Instantly",
            description: "Search any topic, get weather updates, check the news - the entire web at your voice command.",
            animation: "scale"
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black base background
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    // Skip button at top right
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateToMain = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    .white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                )
                        }
                        .padding()
                    }
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(0..<features.count, id: \.self) { index in
                            FeaturePageView(feature: features[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Custom page indicator and continue button
                    VStack(spacing: 30) {
                        // Page dots
                        HStack(spacing: 10) {
                            ForEach(0..<features.count, id: \.self) { index in
                                Circle()
                                    .fill(
                                        index == currentPage ?
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.2, green: 0.6, blue: 1.0),
                                                Color(red: 0.4, green: 0.2, blue: 0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                                    .animation(.spring(), value: currentPage)
                            }
                        }
                        
                        // Continue/Get Started button
                        Button(action: {
                            if currentPage < features.count - 1 {
                                withAnimation(.spring()) {
                                    currentPage += 1
                                }
                            } else {
                                navigateToMain = true
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.2, green: 0.6, blue: 1.0),
                                                Color(red: 0.4, green: 0.2, blue: 0.8),
                                                Color(red: 1.0, green: 0.3, blue: 0.5)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                HStack {
                                    Text(currentPage < features.count - 1 ? "Continue" : "Get Started")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 200, height: 50)
                        }
                    }
                    .padding(.bottom, 50)
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.2),
                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.15),
                        Color.clear,
                        Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .navigationDestination(isPresented: $navigateToMain) {
                VoiceAgentView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeaturePageView: View {
    let feature: OnboardingFeature
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon
            ZStack {
                // Animated circles behind icon
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: feature.iconColors + [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                    .opacity(isAnimating ? 0.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: feature.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(feature.animation == "rotate" && isAnimating ? 360 : 0))
                    .scaleEffect(feature.animation == "scale" && isAnimating ? 1.1 : 1.0)
                    .animation(
                        feature.animation == "rotate" ?
                        .linear(duration: 20).repeatForever(autoreverses: false) :
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Main icon
                Image(systemName: feature.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: feature.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(feature.animation == "pulse" && isAnimating ? 1.1 : 1.0)
                    .offset(y: feature.animation == "bounce" && isAnimating ? -10 : 0)
                    .animation(
                        feature.animation == "bounce" ?
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 20) {
                // Title
                Text(feature.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: feature.iconColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                // Description
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(5)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct OnboardingFeature {
    let icon: String
    let iconColors: [Color]
    let title: String
    let description: String
    let animation: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .preferredColorScheme(.dark)
    }
}