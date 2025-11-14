import SwiftUI

struct WatchlistView: View {
    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var watchlistMovies: [WatchedMovie] = []
    @State private var isLoading = true
    
    var filteredMovies: [WatchedMovie] {
        watchlistMovies.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            if FirebaseService.shared.isAnonymousUser {
                // user is guest
                // prompt sign up
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("Sign Up to Save Movies")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create a free account to track your watched movies and build your watchlist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .navigationTitle("Watchlist") // or "Watchlist"
                .navigationBarTitleDisplayMode(.large)
            }
            
            // user has account
            else {
                VStack(spacing: 0) {
                    // selector for picking between movies and tv shows
                    // has liquid glass
                    Picker("Content Type", selection: $selectedSegment) {
                        Text("Movies").tag(0)
                        Text("TV Shows").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedSegment) { oldValue, newValue in
                        Task {
                            await loadWatchlist()
                        }
                    }
                    .padding()
                    
                    // search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search watchlist...", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // loading
                    if isLoading {
                        Spacer()
                        ProgressView("Loading your watchlist...")
                        Spacer()
                    }
                    
                    // no content watchlisted
                    else if filteredMovies.isEmpty && searchText.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "bookmark")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Your watchlist is empty")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("Add movies you want to watch later")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Spacer()
                        }
                    }
                    
                    // no search results
                    else if filteredMovies.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No results found")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    
                    // normal view
                    else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredMovies) { movie in
                                    WatchlistMovieCard(
                                        movie: movie,
                                        onDelete: {
                                            Task {
                                                // delete movie from watchlist
                                                await removeMovie(movie)
                                            }
                                        },
                                        onMoveToWatched: {
                                            Task {
                                                // move from watchlist to watched
                                                await moveToWatched(movie)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Watchlist")
                .navigationBarTitleDisplayMode(.large)
                .task {
                    await loadWatchlist()
                }
                .refreshable {
                    await loadWatchlist()
                }
                .onAppear {
                    Task {
                        await loadWatchlist()
                    }
                }
            }
        }
    }
    
    
    // get watchlist from database
    private func loadWatchlist() async {
        isLoading = true
        
        // fetch from firebase
        do {
            let contentType = selectedSegment == 0 ? "movie" : "tv"
            let movies = try await FirebaseService.shared.getWatchlist(contentType: contentType)
            
            await MainActor.run {
                watchlistMovies = movies
            }
        }
        catch {
            // handling error
            await MainActor.run {
                print("Error loading watchlist: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    
    // deleting from firebase
    private func removeMovie(_ movie: WatchedMovie) async {
        do {
            try await FirebaseService.shared.removeFromWatchlist(movieId: movie.id, contentType: movie.contentType)
            await loadWatchlist()
        }
        catch {
            print("Error removing movie: \(error)")
        }
    }

    
    
    // move to watched from watchlist
    private func moveToWatched(_ movie: WatchedMovie) async {
        do {
            // adding to watched and then removing from watchlist
            try await FirebaseService.shared.addToWatched(
                movieId: movie.id,
                title: movie.title,
                year: movie.year,
                posterPath: movie.posterPath,
                rating: movie.rating,
                contentType: movie.contentType
            )

            try await FirebaseService.shared.removeFromWatchlist(movieId: movie.id, contentType: movie.contentType)
            
            // refresh watchlist
            await loadWatchlist()
        }
        catch {
            print("Error moving to watched: \(error)")
        }
    }
}

// watchlist movie card
struct WatchlistMovieCard: View {
    let movie: WatchedMovie
    let onDelete: () -> Void
    let onMoveToWatched: () -> Void
    @State private var showingDeleteAlert = false
    @State private var showingMoveAlert = false
    
    var body: some View {
        HStack(spacing: 15) {
            // poster
            if let posterURL = movie.posterURL {
                // using cached image
                CachedAsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.6), .red.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 120)
                        
                        ProgressView()
                    }
                }
            }
            // no poster available on tmdb
            else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.6), .red.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 120)
                    
                    Image(systemName: "film.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            
            // content info
            VStack(alignment: .leading, spacing: 6) {
                // title
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // release year
                Text(movie.year)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(movie.ratingFormatted)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // subtext like: Watchlisted [...] or Watchlisted [...] ago
                Text("Added \(movie.addedAtFormatted)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // removing from watchlist
            VStack(spacing: 8) {
                // move to watched
                Button(action: {
                    showingMoveAlert = true
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                
                // deleted from watchlist
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert("Mark as Watched", isPresented: $showingMoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Mark as Watched") {
                onMoveToWatched()
            }
        } message: {
            Text("Move \(movie.title) to your watched list?")
        }
        .alert("Remove from Watchlist", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove \(movie.title) from your watchlist?")
        }
    }
}
