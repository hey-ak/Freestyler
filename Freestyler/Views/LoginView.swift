import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @ObservedObject var sessionManager: UserSessionManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 24) {
                            Spacer(minLength: 60)
                            
                            // App Icon with subtle shadow
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "music.mic")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Sign in to continue your journey")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 48)
                        
                        // Form Section
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .font(.system(size: 16))
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                SecureField("Enter your password", text: $password)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .font(.system(size: 16))
                            }
                            
                            // Error Message
                            if let error = sessionManager.authError {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.bottom, 32)
                        
                        // Login Button
                        Button(action: {
                            sessionManager.login(email: email, password: password)
                        }) {
                            HStack(spacing: 12) {
                                if sessionManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                        .modifier(PulseEffect())
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Group {
                                    if email.isEmpty || password.isEmpty {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.3))
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple, .blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                }
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(email.isEmpty || password.isEmpty || sessionManager.isLoading)
                        .animation(.easeInOut(duration: 0.2), value: email.isEmpty || password.isEmpty)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 32)
                        
                        // Sign Up Section
                        VStack(spacing: 16) {
                            Text("Don't have an account?")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Button(action: { showSignup = true }) {
                                Text("Create Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.purple, .blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color.purple.opacity(0.02),
                            Color.blue.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .sheet(isPresented: $showSignup) {
                    SignupView(sessionManager: sessionManager)
                }
                
                // Full-screen loading overlay
                if sessionManager.isLoading {
                    ZStack {
                        // Remove VisualEffectBlur, keep only the gradient overlay
                        LinearGradient(
                            colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        .blendMode(.overlay)
                        // Animated spinner and message
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2.0)
                                .modifier(PulseEffect())
                            Text("Signing In...")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
        }
    }
}
