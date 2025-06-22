import SwiftUI

struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sessionManager: UserSessionManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 24) {
                        // Close Button
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 20)
                        
                        // App Icon with subtle shadow
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "person.crop.circle.badge.plus")
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
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Join us and start your journey")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 48)
                    
                    // Form Section
                    VStack(spacing: 20) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("Choose a username", text: $username)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .font(.system(size: 16))
                        }
                        
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
                            
                            SecureField("Create a password", text: $password)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .font(.system(size: 16))
                        }
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Text("Password should be at least 8 characters")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 4)
                        
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
                    
                    // Sign Up Button
                    Button(action: {
                        sessionManager.signup(email: email, password: password, username: username)
                    }) {
                        HStack(spacing: 12) {
                            if sessionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Group {
                                if email.isEmpty || password.isEmpty || username.isEmpty {
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
                    .disabled(email.isEmpty || password.isEmpty || username.isEmpty || sessionManager.isLoading)
                    .animation(.easeInOut(duration: 0.2), value: email.isEmpty || password.isEmpty || username.isEmpty)
                    
                    // Terms and Privacy
                    VStack(spacing: 12) {
                        Text("By creating an account, you agree to our")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") { }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.accentColor)
                            
                            Text("and")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Button("Privacy Policy") { }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.top, 24)
                    
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
                    
                    // Login Section
                    VStack(spacing: 16) {
                        Text("Already have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        Button(action: { dismiss() }) {
                            Text("Sign In Instead")
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
        }
    }
}
