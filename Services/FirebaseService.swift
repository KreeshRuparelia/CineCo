import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isUserLoggedIn: Bool {
        Auth.auth().currentUser != nil
    }
    
    var isAnonymousUser: Bool {
        Auth.auth().currentUser?.isAnonymous ?? false
    }
    
    
    // sign up on firebase
    func signUp(email: String, password: String, fullName: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = result.user.uid
        
        // creating user
        try await db.collection("users").document(userId).setData([
            "fullName": fullName,
            "email": email,
            "createdAt": Timestamp()
        ])
        
        return userId
    }
    
    
    // sign in a user
    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }
    
    
    // guest account sign in
    func signInAnonymously() async throws -> String {
        let result = try await Auth.auth().signInAnonymously()
        return result.user.uid
    }
    
    
    // log out
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    
    // password change handler
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        guard let email = user.email else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No email associated with account"])
        }
        
        // reauthenticate new password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        do {
            try await user.reauthenticate(with: credential)
            
            // update password
            try await user.updatePassword(to: newPassword)
        }
        catch {
            print("Password change error: \(error)")
            throw error
        }
    }
    
    
    // check authentication status
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            print("Is Anonymous: \(user.isAnonymous)")
        }
        else {
            print("No user is logged in")
        }
    }
    
    
    // add content to watched collection
    func addToWatched(movieId: Int, title: String, year: String, posterPath: String?, rating: Double, contentType: String = "movie", genreIds: [Int] = []) async throws {
        guard let userId = currentUserId else {
            print("Error: No user logged in")
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let watchedData: [String: Any] = [
            "movieId": movieId,
            "title": title,
            "year": year,
            "posterPath": posterPath ?? "",
            "rating": rating,
            "contentType": contentType,
            "genreIds": genreIds,
            "addedAt": Timestamp(),
            "userId": userId
        ]
        
        let docId = "\(userId)_\(contentType)_\(movieId)"
        
        // writing to database
        do {
            try await db.collection("watched").document(docId).setData(watchedData)
        }
        catch {
            print("Firestore error: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    // delete from watched collection
    func removeFromWatched(movieId: Int, contentType: String = "movie") async throws {
        guard let userId = currentUserId else { return }
        let docId = "\(userId)_\(contentType)_\(movieId)"
        // deleting
        try await db.collection("watched").document(docId).delete()
    }
    
    
    // get all ids of the user's watched content
    func getWatchedIds(contentType: String) async throws -> [Int] {
        guard let userId = currentUserId else { return [] }
        
        let snapshot = try await db.collection("watched")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .getDocuments()
        
        return snapshot.documents.compactMap { $0.data()["movieId"] as? Int }
    }

    
    // get watched movies list
    func getWatchedMovies(contentType: String = "movie") async throws -> [WatchedMovie] {
        guard let userId = currentUserId else {
            return []
        }
                
        let snapshot = try await db.collection("watched")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .order(by: "addedAt", descending: true)
            .getDocuments()
        
        
        let movies = snapshot.documents.compactMap { doc -> WatchedMovie? in
            let data = doc.data()
            
            guard let movieId = data["movieId"] as? Int,
                  let title = data["title"] as? String else {
                        print("Error: Unable to parse document: \(doc.documentID)")
                        return nil
            }
            
            // returning watched movies to movies
            return WatchedMovie(
                id: movieId,
                title: title,
                year: data["year"] as? String ?? "",
                posterPath: data["posterPath"] as? String,
                rating: data["rating"] as? Double ?? 0.0,
                addedAt: (data["addedAt"] as? Timestamp)?.dateValue() ?? Date(),
                contentType: data["contentType"] as? String ?? "movie"  // ADD THIS LINE
            )
        }
        
        // returning
        return movies
    }

    
    // add to watchlist
    func addToWatchlist(movieId: Int, title: String, year: String, posterPath: String?, rating: Double, contentType: String = "movie", genreIds: [Int] = []) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }

        // watchlist data
        let watchlistData: [String: Any] = [
            "movieId": movieId,
            "title": title,
            "year": year,
            "posterPath": posterPath ?? "",
            "rating": rating,
            "contentType": contentType,
            "genreIds": genreIds,
            "addedAt": Timestamp(),
            "userId": userId
        ]
        
        let docId = "\(userId)_\(contentType)_\(movieId)"
        
        do {
            try await db.collection("watchlist").document(docId).setData(watchlistData)
        }
        catch {
            print("Firestore error: \(error.localizedDescription)")
            throw error
        }
    }

    
    // delete from watchlist
    func removeFromWatchlist(movieId: Int, contentType: String = "movie") async throws {
        guard let userId = currentUserId else { return }
        let docId = "\(userId)_\(contentType)_\(movieId)"
        try await db.collection("watchlist").document(docId).delete()
    }
    
    
    // getter for watchlist collection
    func getWatchlist(contentType: String = "movie") async throws -> [WatchedMovie] {
        guard let userId = currentUserId else {
            return []
        }
        
        // get watchlist collection from firebase
        let snapshot = try await db.collection("watchlist")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .order(by: "addedAt", descending: true)
            .getDocuments()
        
        
        let movies = snapshot.documents.compactMap { doc -> WatchedMovie? in
            let data = doc.data()
            
            guard let movieId = data["movieId"] as? Int,
                  let title = data["title"] as? String else {
                print("Error: Failed to parse document: \(doc.documentID)")
                return nil
            }
            
            // returning watchlist to movies
            return WatchedMovie(
                id: movieId,
                title: title,
                year: data["year"] as? String ?? "",
                posterPath: data["posterPath"] as? String,
                rating: data["rating"] as? Double ?? 0.0,
                addedAt: (data["addedAt"] as? Timestamp)?.dateValue() ?? Date(),
                contentType: data["contentType"] as? String ?? "movie"  // ADD THIS LINE
            )
        }
        
        // returning
        return movies
    }
    
    
    // get all content type ids for the user's watchlist content
    func getWatchlistIds(contentType: String) async throws -> [Int] {
        guard let userId = currentUserId else { return [] }
        
        let snapshot = try await db.collection("watchlist")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .getDocuments()
        
        return snapshot.documents.compactMap { $0.data()["movieId"] as? Int }
    }
    
    
    // add to skipped in firebase
    func addToSkipped(movieId: Int, contentType: String, title: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let docId = "\(userId)_\(contentType)_\(movieId)"
        
        let skippedData: [String: Any] = [
            "movieId": movieId,
            "contentType": contentType,
            "skippedAt": Timestamp(),
            "userId": userId,
            "title": title
        ]
        
        // write to firebase
        try await db.collection("skipped").document(docId).setData(skippedData)
    }

    
    // get all skipped ids for user
    func getSkippedIds(contentType: String) async throws -> [Int] {
        guard let userId = currentUserId else { return [] }
        
        let snapshot = try await db.collection("skipped")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .getDocuments()
        
        return snapshot.documents.compactMap { $0.data()["movieId"] as? Int }
    }
    

    // get the user's profile
    func getUserProfile() async throws -> UserProfile? {
        guard let userId = currentUserId else { return nil }
        
        let doc = try await db.collection("users").document(userId).getDocument()
        
        guard let data = doc.data() else { return nil }
        
        // return user profile
        return UserProfile(
            id: userId,
            fullName: data["fullName"] as? String ?? "",
            email: data["email"] as? String ?? ""
        )
    }
    
    // get the count for watched items of content type
    func getWatchedCount(contentType: String) async throws -> Int {
        guard let userId = currentUserId else { return 0 }
        
        let snapshot = try await db.collection("watched")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .getDocuments()
        
        return snapshot.documents.count
    }

    
    // get the user's name
    func getUserDisplayName() async throws -> String {
        guard let userId = currentUserId else { return "" }
        
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data() else { return "" }
        
        return data["fullName"] as? String ?? ""
    }

    
    // get user email
    func getUserEmail() -> String {
        return Auth.auth().currentUser?.email ?? ""
    }
    
    
    // update user's name on firebase
    func updateUserDisplayName(_ newName: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // write to database with new name
        try await db.collection("users").document(userId).updateData([
            "fullName": newName
        ])
    }
}


// watched/watchlist movie format
struct WatchedMovie: Identifiable {
    let id: Int
    let title: String
    let year: String
    let posterPath: String?
    let rating: Double
    let addedAt: Date
    let contentType: String
    
    // poster
    var posterURL: URL? {
        guard let posterPath = posterPath, !posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    // rating
    var ratingFormatted: String {
        String(format: "%.1f", rating)
    }
    
    // logged time formatter
    var addedAtFormatted: String {
        let calendar = Calendar.current
        let now = Date()
        
        // today
        if calendar.isDateInToday(addedAt) {
            return "Today"
        }
        // yesterday
        else if calendar.isDateInYesterday(addedAt) {
            return "Yesterday"
        }
        // number formatter
        else if let daysAgo = calendar.dateComponents([.day], from: addedAt, to: now).day {
            // day sorter
            if daysAgo < 7 {
                return "\(daysAgo) days ago"
            }
            // week sorter
            else if daysAgo < 30 {
                let weeks = daysAgo / 7
                return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
            }
            // month sorter
            else if daysAgo < 365 {
                let months = daysAgo / 30
                return "\(months) month\(months == 1 ? "" : "s") ago"
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: addedAt)
    }
}


// user profile info
struct UserProfile {
    let id: String
    let fullName: String
    let email: String
}
