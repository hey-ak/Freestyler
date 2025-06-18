import SwiftUI

struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sessionManager: UserSessionManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.accentColor)
                Text("Create Account")
                    .font(.largeTitle).bold()
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .padding()
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(12)
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
                    sessionManager.signup(email: email, password: password, username: username)
                }) {
                    if sessionManager.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign Up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || username.isEmpty)
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Log In") { dismiss() }
                        .font(.headline)
                }
                Spacer()
            }
            .padding()
        }
    }
} 