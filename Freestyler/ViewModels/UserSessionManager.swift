import Foundation
import Security

class UserSessionManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authError: String?
    @Published var isLoading: Bool = false
    @Published var username: String?
    @Published var email: String?
    
    private let keychainService = "com.freestyler.auth"
    private let tokenKey = "jwtToken"
    private let apiBaseURL = "http://localhost:5001/api/auth" // Use your backend URL or local IP for device
    
    var jwtToken: String? {
        get { loadTokenFromKeychain() }
        set {
            if let token = newValue {
                saveTokenToKeychain(token)
            } else {
                deleteTokenFromKeychain()
            }
        }
    }
    
    init() {
        autoLogin()
    }
    
    func login(email: String, password: String) {
        authError = nil
        isLoading = true
        let url = URL(string: "\(apiBaseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                print("Login error: \(error)")
                DispatchQueue.main.async { self.authError = error.localizedDescription }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Login HTTP status: \(httpResponse.statusCode)")
            }
            if let data = data {
                print("Login raw response: ", String(data: data, encoding: .utf8) ?? "<nil>")
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                DispatchQueue.main.async { self.authError = "Invalid response from server." }
                return
            }
            self.jwtToken = token
            self.username = json["username"] as? String
            self.email = json["email"] as? String
            DispatchQueue.main.async { self.isAuthenticated = true }
        }.resume()
    }
    
    func signup(email: String, password: String, username: String) {
        authError = nil
        isLoading = true
        let url = URL(string: "\(apiBaseURL)/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password, "username": username]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                print("Signup error: \(error)")
                DispatchQueue.main.async { self.authError = error.localizedDescription }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Signup HTTP status: \(httpResponse.statusCode)")
            }
            if let data = data {
                print("Signup raw response: ", String(data: data, encoding: .utf8) ?? "<nil>")
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                DispatchQueue.main.async { self.authError = "Invalid response from server." }
                return
            }
            self.jwtToken = token
            self.username = json["username"] as? String
            self.email = json["email"] as? String
            DispatchQueue.main.async { self.isAuthenticated = true }
        }.resume()
    }
    
    func logout() {
        jwtToken = nil
        isAuthenticated = false
        username = nil
        email = nil
    }
    
    func autoLogin() {
        if let token = loadTokenFromKeychain(), !token.isEmpty {
            // Optionally, validate token with backend here
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    
    // MARK: - Keychain Helpers
    private func saveTokenToKeychain(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }
} 