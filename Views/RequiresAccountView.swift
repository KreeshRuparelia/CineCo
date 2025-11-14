import SwiftUI

struct RequiresAccountView: View {
    @Environment(\.dismiss) var dismiss
    @State private var navigateToSignup = false
    
    // default view in watched and watchlist for users in guest mode
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("Account Required")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Create a free account to save movies to your watchlist and track what you've watched")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 15) {
                    Button(action: {
                        navigateToSignup = true
                    }) {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationDestination(isPresented: $navigateToSignup) {
                SignupView()
            }
        }
    }
}
