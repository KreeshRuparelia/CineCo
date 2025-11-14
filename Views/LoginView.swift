import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignup = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.6), Color.black.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    // symbol and text
                    VStack(spacing: 10) {
                        Image(systemName: "film.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("CineCo")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Track your favorite movies & shows")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 40)
                    
                    // login text field
                    VStack(spacing: 20) {
                        // email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            TextField("", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }
                        
                        // password field (secure)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            // dots for password
                            SecureField("", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // login button
                    Button(action: {
                        Task {
                            await login()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                        }
                        else {
                            Text("Log In")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                    .disabled(isLoading)
                    
                    // guest button
                    Button(action: {
                        Task {
                            await signInAsGuest()
                        }
                    }) {
                        Text("Continue as Guest")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                    }
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                    .disabled(isLoading)
                    
                    Spacer()
                    
                    // sign up button
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.white)
                        Button("Sign Up") {
                            isShowingSignup = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    }
                    .font(.subheadline)
                    .padding(.bottom, 30)
                }
            }
            .navigationDestination(isPresented: $isShowingSignup) {
                // redirect to signup view
                SignupView()
            }
            .alert("Login Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // sign in handler
    private func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please enter both email and password"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // autheniticate sign in
        do {
            _ = try await FirebaseService.shared.signIn(email: email, password: password)
        }
        catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
        
        isLoading = false
    }
    
    // guest handler
    private func signInAsGuest() async {
        isLoading = true
        
        // guest sign in
        do {
            _ = try await FirebaseService.shared.signInAnonymously()

        }
        catch {
            alertMessage = "Failed to sign in as guest: \(error.localizedDescription)"
            showAlert = true
        }
        
        isLoading = false
    }
}

// custom text
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
            .foregroundColor(.black)
    }
}
