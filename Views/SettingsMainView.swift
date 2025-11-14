import SwiftUI

struct SettingsMainView: View {
    @State private var showingLogoutAlert = false
    @State private var showingEditProfile = false
    @State private var showingChangePassword = false
    @State private var isLoading = true
    
    // user data
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var moviesWatched = 0
    @State private var showsWatched = 0
    
    var body: some View {
        NavigationStack {
            // loading
            if isLoading {
                ProgressView("Loading profile...")
            }
            else {
                ScrollView {
                    VStack(spacing: 25) {
                        // profile
                        VStack(spacing: 15) {
                            ZStack {
                                // initials profile pic
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.red.opacity(0.6), .black.opacity(0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 100)
                                
                                Text(userName.isEmpty ? "?" : userName.prefix(2).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // name
                            Text(userName.isEmpty ? "User" : userName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // email
                            Text(userEmail.isEmpty ? "No email" : userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // movie and tv shows watched counter
                        HStack(spacing: 0) {
                            StatBox(title: "Movies", value: "\(moviesWatched)")
                            
                            Divider()
                                .frame(height: 50)
                            
                            StatBox(title: "TV Shows", value: "\(showsWatched)")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // update display name
                        VStack(spacing: 15) {
                            ProfileMenuItem(
                                icon: "person.text.rectangle",
                                title: "Edit Display Name",
                                action: {
                                    showingEditProfile = true
                                }
                            )
                            
                            ProfileMenuItem(
                                icon: "lock.rotation",
                                title: "Change Password",
                                action: {
                                    showingChangePassword = true
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                        // log out
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Log Out")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Version Info
                        Text("CineCo v1.2.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 20)
                    }
                }
                .refreshable {
                    await loadUserData()
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await loadUserData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                // log user out
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showingEditProfile) {
            EditDisplayNameView(currentName: userName, onSave: {
                Task {
                    // fetch data
                    await loadUserData()
                }
            })
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
        }
        .task {
            await loadUserData()
        }
    }
    
    
    // get user data
    private func loadUserData() async {
        isLoading = true
        
        do {
            // fetch user data from firebase
            userName = try await FirebaseService.shared.getUserDisplayName()
            userEmail = FirebaseService.shared.getUserEmail()
            
            // get count from firebase
            moviesWatched = try await FirebaseService.shared.getWatchedCount(contentType: "movie")
            showsWatched = try await FirebaseService.shared.getWatchedCount(contentType: "tv")
        }
        catch {
            print("Error loading user data: \(error)")
        }
        
        isLoading = false
    }
    
    
    // log out user on database
    private func handleLogout() {
        do {
            try FirebaseService.shared.signOut()
        }
        catch {
            print("Error logging out: \(error)")
        }
    }
}

// display name changer view
struct EditDisplayNameView: View {
    @Environment(\.dismiss) var dismiss
    let currentName: String
    let onSave: () -> Void
    
    // new data
    @State private var newName = ""
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Change your display name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 30)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    TextField(currentName, text: $newName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        // save new name
                        await saveDisplayName()
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    else {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .disabled(newName.isEmpty || isSaving)
                .opacity(newName.isEmpty ? 0.6 : 1.0)
                
                Spacer()
            }
            .navigationTitle("Edit Display Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // cancel button in case user changes there mind
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                newName = currentName
            }
            .alert("Update Name", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("success") {
                        onSave()
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    
    // update display name on firebase
    private func saveDisplayName() async {
        guard !newName.isEmpty else { return }
        
        isSaving = true
        
        // write to firebase about name change
        do {
            try await FirebaseService.shared.updateUserDisplayName(newName)
            alertMessage = "Display name updated successfully!"
            showAlert = true
        }
        catch {
            alertMessage = "Failed to update: \(error.localizedDescription)"
            showAlert = true
        }
        
        isSaving = false
    }
}


// view for changing passwords
struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChanging = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var passwordChangeSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Update your account password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 30)
                
                VStack(alignment: .leading, spacing: 20) {
                    // current password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        SecureField("Enter current password", text: $currentPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.password)
                    }
                    
                    // new password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        SecureField("At least 6 characters", text: $newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.newPassword)
                    }
                    
                    // confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        SecureField("Re-enter new password", text: $confirmPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.newPassword)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        // handler for password change
                        await handlePasswordChange()
                    }
                }) {
                    if isChanging {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    else {
                        Text("Update Password")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isChanging)
                .opacity((currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1.0)
                
                Spacer()
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // button in case user changes there mind
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                // button to confirm password change
                Button("OK", role: .cancel) {
                    if passwordChangeSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    
    // update password on firebase
    private func handlePasswordChange() async {
        // validate new password
        guard newPassword.count >= 6 else {
            alertTitle = "Invalid Password"
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        
        // validate matching passwords
        guard newPassword == confirmPassword else {
            alertTitle = "Password Mismatch"
            alertMessage = "New passwords do not match"
            showAlert = true
            return
        }
        
        // new password must be different
        guard newPassword != currentPassword else {
            alertTitle = "Same Password"
            alertMessage = "New password must be different from current password"
            showAlert = true
            return
        }
        
        isChanging = true
        
        // update password on firebase
        do {
            try await FirebaseService.shared.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            alertTitle = "Success"
            alertMessage = "Your password has been changed successfully!"
            passwordChangeSuccess = true
            showAlert = true
        }
        catch let error as NSError {
            alertTitle = "Error"
            
            // firebase error handling
            switch error.code {
            case 17026: // weak password
                alertMessage = "Password is too weak. Please use a stronger password."
            case 17009: // wrong current password
                alertMessage = "Current password is incorrect. Please try again."
            case 17011: // authentication error
                alertMessage = "Authentication error. Please log out and try again."
            case 17020: // needs re signing in
                alertMessage = "For security, please log out and log back in before changing your password."
            default:
                alertMessage = error.localizedDescription
            }
            
            passwordChangeSuccess = false
            showAlert = true
        }
        
        isChanging = false
    }
}


// stats for movie and tv show count
struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


// profile item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.red)
                    .frame(width: 30)
                
                // title
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
