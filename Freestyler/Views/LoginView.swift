import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @ObservedObject var sessionManager: UserSessionManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "music.mic")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.accentColor)
                Text("Welcome Back!")
                    .font(.largeTitle).bold()
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(12)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(12)
                }
                if let error = sessionManager.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                Button(action: {
                    sessionManager.login(email: email, password: password)
                }) {
                    if sessionManager.isLoading {
                        ProgressView()
                    } else {
                        Text("Log In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty)
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") { showSignup = true }
                        .font(.headline)
                }
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showSignup) {
                SignupView(sessionManager: sessionManager)
            }
        }
    }
} 