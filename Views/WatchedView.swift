import SwiftUI

struct WatchedView: View {
    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var watchedMovies: [WatchedMovie] = []
    @State private var isLoading = true
    
    var filteredMovies: [WatchedMovie] {
        watchedMovies.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            // user is guest
            // prompt sign up
            if FirebaseService.shared.isAnonymousUser {
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
                .navigationTitle("Watched")
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
                            await loadWatchedMovies()
                        }
                    }
                    .padding()
                    
                    // search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search watched...", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // loading
                    if isLoading {
                        Spacer()
                        ProgressView("Loading your watched movies...")
                        Spacer()
                    }
                    
                    // no content watched
                    else if filteredMovies.isEmpty && searchText.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "film")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No movies watched yet")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("Search for movies and mark them as watched")
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
                                    WatchedMovieCard(movie: movie, onDelete: {
                                        Task {
                                            // delete movie from watched list
                                            await removeMovie(movie)
                                        }
                                    })
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Watched")
                .navigationBarTitleDisplayMode(.large)
                .task {
                    await loadWatchedMovies()
                }
                .refreshable {
                    await loadWatchedMovies()
                }
                .onAppear {
                    Task {
                        await loadWatchedMovies()
                    }
                }
            }
        }
    }
    
    
    // get watched movies from database
    private func loadWatchedMovies() async {
        isLoading = true
        
        // fetch from firebase
        do {
            let contentType = selectedSegment == 0 ? "movie" : "tv"
            let movies = try await FirebaseService.shared.getWatchedMovies(contentType: contentType)
            
            await MainActor.run {
                watchedMovies = movies
            }
        }
        catch {
            // error
            await MainActor.run {
                print("Error loading watched: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    
    private func removeMovie(_ movie: WatchedMovie) async {
        // remove movie from watched
        do {
            try await FirebaseService.shared.removeFromWatched(movieId: movie.id, contentType: movie.contentType)
            // load watched movies again
            await loadWatchedMovies()
        }
        // error
        catch {
            print("Error removing movie: \(error)")
        }
    }
}


// watched movie card
struct WatchedMovieCard: View {
    let movie: WatchedMovie
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 15) {
            // poster
            if let posterURL = movie.posterURL {
                // use cached image
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
                                gradient: Gradient(colors: [.red.opacity(0.6), .black.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 120)
                        
                        ProgressView()
                    }
                }
            }
            // no poster on tmdb
            else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.red.opacity(0.6), .black.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 120)
                    
                    Image(systemName: "film.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            
            // information about content
            VStack(alignment: .leading, spacing: 6) {
                // title for movie in watched
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // release year for movie in watched
                Text(movie.year)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // rating for movie in watched
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(movie.ratingFormatted)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                // subtext like: Watched [...] or Watched [...] ago
                Text("Watched \(movie.addedAtFormatted)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // remove from watched
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .alert("Remove from Watched", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to remove \(movie.title) from your watched list?")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
