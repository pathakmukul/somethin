import SwiftUI

struct LoginView: View {
    @State private var email = "iammap26@gmail.com"
    @State private var password = "••••••••"
    @State private var isLoggingIn = false
    @State private var navigateToOnboarding = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black base background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo/Title
                    VStack(spacing: 10) {
                        // Animated gradient circle logo
                        ZStack {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.6, blue: 1.0),
                                            Color(red: 0.4, green: 0.2, blue: 0.8),
                                            Color(red: 1.0, green: 0.3, blue: 0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(isLoggingIn ? 360 : 0))
                                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isLoggingIn)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.6, blue: 1.0),
                                            Color(red: 0.4, green: 0.2, blue: 0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        Text("Somethin'")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.2, blue: 0.8),
                                        Color(red: 0.2, green: 0.6, blue: 1.0),
                                        Color(red: 1.0, green: 0.3, blue: 0.5)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Your AI Voice Assistant")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 4)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.5),
                                                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.5)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    TextField("", text: $email)
                                        .foregroundColor(.white)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .disabled(true) // Since it's prepopulated
                                }
                                .padding(.horizontal, 16)
                            }
                            .frame(height: 50)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 4)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.5),
                                                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.5)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    SecureField("", text: $password)
                                        .foregroundColor(.white)
                                        .disabled(true) // Since it's prepopulated
                                }
                                .padding(.horizontal, 16)
                            }
                            .frame(height: 50)
                        }
                        
                        // Login Button
                        Button(action: {
                            withAnimation(.spring()) {
                                isLoggingIn = true
                                // Simulate login delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    navigateToOnboarding = true
                                }
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
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
                                    if isLoggingIn {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Text("Sign In")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(height: 50)
                        }
                        .disabled(isLoggingIn)
                        
                        // Or divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 10)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 5)
                        
                        // Social Login Buttons
                        HStack(spacing: 20) {
                            socialLoginButton(icon: "apple.logo", action: {})
                            socialLoginButton(icon: "g.circle.fill", action: {})
                            socialLoginButton(icon: "face.smiling", action: {})
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 5) {
                        Text("Don't have an account?")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Button(action: {}) {
                            Text("Sign Up")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.6, blue: 1.0),
                                            Color(red: 0.4, green: 0.2, blue: 0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding(.bottom, 30)
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.2),
                        Color.clear,
                        Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .navigationDestination(isPresented: $navigateToOnboarding) {
                OnboardingView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    private func socialLoginButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 50, height: 50)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}