import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var signupSuccess = false
    
    var body: some View {
        // overlay
        ZStack {
            // background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.6), Color.black.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // symbol and text
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Join CineCo today")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                    
                    // signup form
                    VStack(spacing: 16) {
                        // name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full Name")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            TextField("John Doe", text: $fullName)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textInputAutocapitalization(.words)
                                .textContentType(.name)
                        }
                        
                        // email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            TextField("email@example.com", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                        }
                        
                        // password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            SecureField("Min 6 characters", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                        
                        // confirm password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // sign up field
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        Task {
                            await signup()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                        } else {
                            Text("Sign Up")
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
                    .padding(.top, 10)
                    
                    // Back to Login
                    Button("Already have an account? Log In") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(.bottom, 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert(signupSuccess ? "Success" : "Error", isPresented: $showAlert) {
            // success
            Button("OK", role: .cancel) {
                if signupSuccess {
                    dismiss()
                }
            }
        } message: {
            // fail
            Text(alertMessage)
        }
    }
    
    // signup handler
    private func signup() async {
        // no name
        guard !fullName.isEmpty else {
            alertMessage = "Please enter your full name"
            showAlert = true
            return
        }
        
        // no email
        guard !email.isEmpty else {
            alertMessage = "Please enter your email"
            showAlert = true
            return
        }
        
        // password length wrong
        guard password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        
        // confirm password does not match
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // create account
            _ = try await FirebaseService.shared.signUp(email: email, password: password, fullName: fullName)
            alertMessage = "Account created successfully! Please log in."
            signupSuccess = true
            showAlert = true
        }
        catch {
            alertMessage = error.localizedDescription
            signupSuccess = false
            showAlert = true
        }
        
        isLoading = false
    }
}
