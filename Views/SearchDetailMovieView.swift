import SwiftUI

struct SearchDetailMovieView: View {
    let movie: Movie
    @Environment(\.dismiss) var dismiss
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingRequiresAccount = false
    @State private var isInWatched = false
    @State private var isInWatchlist = false
    @State private var isCheckingStatus = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // poster
                if let backdropURL = movie.posterURL {
                    CachedAsyncImage(url: backdropURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 400)
                            .clipped()
                    } placeholder: {
                        ZStack {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.red.opacity(0.7), .black.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 400)
                            
                            ProgressView()
                        }
                    }
                }
                else {
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.red.opacity(0.7), .black.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 400)
                        
                        Image(systemName: "film.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // content info for movie
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // title
                            Text(movie.title)
                                .font(.system(size: 32, weight: .bold))
                            
                            Spacer()
                            
                            // content type image
                            Image(systemName: "film")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        
                        HStack(spacing: 15) {
                            // release year
                            Text(movie.year)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // seperator
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            // rating
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(movie.ratingFormatted)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // check if show is already watched/in watchlist
                    if isCheckingStatus {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    }
                    else {
                        VStack(spacing: 12) {
                            // add to watched button
                            Button(action: {
                                // check if adding to watched is allowed
                                if !isInWatched {
                                    // anon check
                                    if FirebaseService.shared.isAnonymousUser {
                                        showingRequiresAccount = true
                                    }
                                    else {
                                        Task {
                                            await addToWatched()
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: isInWatched ? "checkmark.circle.fill" : "checkmark.circle")
                                    Text(isInWatched ? "Added to Watched" : "Add to Watched")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isInWatched ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isInWatched)
                            
                            // add to watchlist button
                            Button(action: {
                                // check if adding to watchlist is allowed
                                if !isInWatchlist {
                                    // anon check
                                    if FirebaseService.shared.isAnonymousUser {
                                        showingRequiresAccount = true
                                    }
                                    else {
                                        Task {
                                            await addToWatchlist()
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                                    Text(isInWatchlist ? "Added to Watchlist" : "Add to Watchlist")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isInWatchlist ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isInWatchlist)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    // synopsis of movie
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                        Text(movie.overview)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingRequiresAccount) {
            RequiresAccountView()
        }
        .task {
            await checkStatus()
        }
    }
    
    
    // helper to check if movie is in watched or watchlist
    private func checkStatus() async {
        isCheckingStatus = true
        
        // anon check
        if FirebaseService.shared.isAnonymousUser {
            isInWatched = false
            isInWatchlist = false
            isCheckingStatus = false
            return
        }
        
        do {
            let watchedIds = try await FirebaseService.shared.getWatchedIds(contentType: "movie")
            let watchlistIds = try await FirebaseService.shared.getWatchlistIds(contentType: "movie")
            
            isInWatched = watchedIds.contains(movie.id)
            isInWatchlist = watchlistIds.contains(movie.id)
        }
        catch {
            print("Error checking status: \(error)")
        }
        
        isCheckingStatus = false
    }
    
    
    // add movie to watched
    private func addToWatched() async {
        // update on firebase
        do {
            try await FirebaseService.shared.addToWatched(
                movieId: movie.id,
                title: movie.title,
                year: movie.year,
                posterPath: movie.posterPath,
                rating: movie.voteAverage,
                contentType: "movie",
                genreIds: movie.genreIds
            )
            isInWatched = true
            alertTitle = "Success"
            alertMessage = "\(movie.title) has been added to your watched list!"
            showingAlert = true
        }
        catch {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    
    // add movie to watchlist
    private func addToWatchlist() async {
        // update on firebase
        do {
            try await FirebaseService.shared.addToWatchlist(
                movieId: movie.id,
                title: movie.title,
                year: movie.year,
                posterPath: movie.posterPath,
                rating: movie.voteAverage,
                contentType: "movie",
                genreIds: movie.genreIds
            )
            isInWatchlist = true
            alertTitle = "Success"
            alertMessage = "\(movie.title) has been added to your watchlist!"
            showingAlert = true
        }
        catch {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
