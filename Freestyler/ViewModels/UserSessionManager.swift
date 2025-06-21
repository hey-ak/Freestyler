import Foundation
import Security

class UserSessionManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authError: String?
    @Published var isLoading: Bool = false
    @Published var username: String?
    @Published var email: String?
    @Published var profileImage: String?
    
    private let keychainService = "com.freestyler.auth"
    private let tokenKey = "jwtToken"
    let apiBaseURL = Constants.apiBaseUrl
    
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
        let url = URL(string: "\(apiBaseURL)/api/auth/login")!
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
        let url = URL(string: "\(apiBaseURL)/api/auth/signup")!
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
        profileImage = nil
    }
    
    func fetchProfile() {
        guard let token = jwtToken else { return }
        let url = URL(string: "\(apiBaseURL)/api/auth/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Fetch profile error: \(error)")
                DispatchQueue.main.async { self.authError = error.localizedDescription }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.authError = "No data received from server." }
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    self.username = json["username"] as? String
                    self.email = json["email"] as? String
                    self.profileImage = json["profileImage"] as? String
                }
            } else {
                DispatchQueue.main.async { self.authError = "Failed to decode profile from server." }
            }
        }.resume()
    }
    
    func uploadProfileImage(imageData: Data, completion: @escaping (Bool) -> Void) {
        guard let token = jwtToken else { completion(false); return }
        let url = URL(string: "\(apiBaseURL)/api/auth/profile/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"profileImage\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload profile image error: \(error)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let profileImage = json["profileImage"] as? String {
                DispatchQueue.main.async {
                    self.profileImage = profileImage
                    completion(true)
                }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    func autoLogin() {
        if let token = loadTokenFromKeychain(), !token.isEmpty {
            isAuthenticated = true
            fetchProfile()
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
 
