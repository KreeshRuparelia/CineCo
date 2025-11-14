import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    
    init() {
        // check if user is already signed in
        self.isAuthenticated = Auth.auth().currentUser != nil
         
        // listening for state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
            }
        }
    }
}
