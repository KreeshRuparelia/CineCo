import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedContentType = 0
    @State private var movieResults: [Movie] = []
    @State private var tvResults: [TVShow] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // search bar
                HStack {
                    // symbol
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    // text
                    TextField("Search movies & TV shows...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { oldValue, newValue in
                            Task {
                                await performSearch()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            movieResults = []
                            tvResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // search text (allow for picking contentType)
                if !searchText.isEmpty {
                    Picker("Type", selection: $selectedContentType) {
                        Text("Movies").tag(0)
                        Text("TV Shows").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedContentType) { oldValue, newValue in }
                }
                
                // search text or no state
                if searchText.isEmpty {
                    // no state
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                        
                        Text("Search for Movies & Shows")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Find content to add to your watched list or watchlist")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                }
                
                // searching
                else if isSearching {
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                }
                
                // no results available
                else if (selectedContentType == 0 && movieResults.isEmpty) || (selectedContentType == 1 && tvResults.isEmpty) {
                    VStack(spacing: 15) {
                        Spacer()
                        Image(systemName: "film.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Try searching for something else")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // search results
                else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            // movies
                            if selectedContentType == 0 {
                                ForEach(movieResults) { movie in
                                    NavigationLink(destination: SearchDetailMovieView(movie: movie)) {
                                        TMDBSearchResultCard(
                                            title: movie.title,
                                            year: movie.year,
                                            rating: movie.ratingFormatted,
                                            posterURL: movie.posterURL,
                                            contentType: "movie"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // tv shows
                            else {
                                ForEach(tvResults) { show in
                                    NavigationLink(destination: SearchDetailTVShowView(show: show)) {
                                        TMDBSearchResultCard(
                                            title: show.name,
                                            year: show.year,
                                            rating: show.ratingFormatted,
                                            posterURL: show.posterURL,
                                            contentType: "tv"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // search using api
    private func performSearch() async {
        guard !searchText.isEmpty else {
            movieResults = []
            tvResults = []
            return
        }
        
        isSearching = true
        
        do {
            // search for both movies and tv shows for easy switching
            async let movies = TMDBService.shared.searchMovies(query: searchText)
            async let shows = TMDBService.shared.searchTVShows(query: searchText)
            
            // assign search results
            let (movieList, showList) = try await (movies, shows)
            
            movieResults = movieList
            tvResults = showList
        }
        catch {
            print("Search error: \(error)")
            movieResults = []
            tvResults = []
        }
        
        isSearching = false
    }
}

// search result card
struct TMDBSearchResultCard: View {
    let title: String
    let year: String
    let rating: String
    let posterURL: URL?
    let contentType: String
    
    var body: some View {
        HStack(spacing: 15) {
            // poster handling
            if let posterURL = posterURL {
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
            
            else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.red.opacity(0.6), .black.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 120)
                    
                    Image(systemName: contentType == "movie" ? "film.fill" : "tv.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            
            // content info
            VStack(alignment: .leading, spacing: 6) {
                // content title
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    // content release date
                    Text(year)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // seperator
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    // content type
                    Text(contentType == "movie" ? "Movie" : "TV Show")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(rating)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
