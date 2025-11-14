import SwiftUI

struct DiscoverView: View {
    @State private var selectedSegment = 0
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var showingExpandedView = false
    @State private var contentItems: [ContentItem] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var excludeIds: Set<Int> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // control content type for discover
                Picker("Content Type", selection: $selectedSegment) {
                    Text("Movies").tag(0)
                    Text("TV Shows").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 15)
                .onChange(of: selectedSegment) { oldValue, newValue in
                    resetAndLoad()
                }
                
                // loading
                if isLoading {
                    Spacer()
                    ProgressView("Loading recommendations...")
                    Spacer()
                }
                
                // no recommendations loading
                else if contentItems.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "film.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No recommendations available")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Button("Reload") {
                            Task {
                                resetAndLoad()
                            }
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        Spacer()
                    }
                }
                
                // normal
                else {
                    Spacer()
                    
                    // card stack
                    ZStack {
                        // current
                        if currentIndex < contentItems.count {
                            // current card
                            DiscoverContentCard(content: contentItems[currentIndex])
                                .offset(offset)
                                .rotationEffect(.degrees(Double(offset.width / 20)))
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            offset = gesture.translation
                                        }
                                        .onEnded { gesture in
                                            withAnimation(.spring()) {
                                                handleSwipe(gesture.translation)
                                            }
                                        }
                                )
                                .onTapGesture {
                                    showingExpandedView = true
                                }
                                .id("card-\(currentIndex)-\(contentItems[currentIndex].id)")
                            
                            // swipe handler
                            if abs(offset.width) > 20 || abs(offset.height) > 20 {
                                SwipeIndicator(offset: offset)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // action buttons
                    HStack(spacing: 20) {
                        // watchlist button
                        Button(action: {
                            Task { await handleWatchlist() }
                        }) {
                            Image(systemName: "bookmark.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
                        // watched button
                        Button(action: {
                            Task { await handleWatched() }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
                        // skip button
                        Button(action: { handleSkip() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // loading
                    if isLoadingMore {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 10)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingExpandedView) {
                if currentIndex < contentItems.count {
                    DiscoverContentDetailView(
                        content: contentItems[currentIndex],
                        onWatched: { Task { await handleWatched() } },
                        onWatchlist: { Task { await handleWatchlist() } },
                        onSkip: { handleSkip() }
                    )
                }
            }
            .task {
                await loadInitial()
            }
        }
    }
    
    
    // resetter for discover
    private func resetAndLoad() {
        currentIndex = 0
        offset = .zero
        currentPage = 1
        contentItems = []
        excludeIds = []
        Task {
            await loadInitial()
        }
    }
    
    // loader for discover
    private func loadInitial() async {
        isLoading = true
        // default page
        currentPage = 1
        
        let contentType = selectedSegment == 0 ? "movie" : "tv"
        
        // ids to exclude
        do {
            let watched = try await FirebaseService.shared.getWatchedIds(contentType: contentType)
            let watchlist = try await FirebaseService.shared.getWatchlistIds(contentType: contentType)
            let skipped = try await FirebaseService.shared.getSkippedIds(contentType: contentType)
            
            excludeIds = Set(watched + watchlist + skipped)
        }
        catch {
            print("Error getting excluded IDs: \(error)")
            excludeIds = []
        }
        
        // load multiple pages
        for page in 1...3 {
            await loadPage(page: page)
            if contentItems.count > 0 {
                currentPage = page
            }
        }
        
        isLoading = false
        
        // no content error
        if contentItems.isEmpty {
            print("No content found")
        }
    }

    // page loader
    private func loadPage(page: Int) async {
        do {
            if selectedSegment == 0 {
                // get movies using tmdb api
                let movies = try await TMDBService.shared.getPopularMovies(page: page)
                
                // filter out movies watched, skipped, or in watchlist
                let filtered = movies.filter { !excludeIds.contains($0.id) }
                
                // list of suggestions
                let newItems = filtered.map { movie in
                    ContentItem(
                        id: movie.id,
                        title: movie.title,
                        overview: movie.overview,
                        posterPath: movie.posterPath,
                        year: movie.year,
                        rating: movie.voteAverage,
                        contentType: "movie",
                        genreIds: movie.genreIds
                    )
                }
                
                contentItems.append(contentsOf: newItems)
            }
            
            else {
                // get tv shows using tmdb api
                let shows = try await TMDBService.shared.getPopularTVShows(page: page)
                
                // filter out shows watched, skipped, or in watchlist
                let filtered = shows.filter { !excludeIds.contains($0.id) }
                
                // list of suggestions
                let newItems = filtered.map { $0.asContentItem }
                
                contentItems.append(contentsOf: newItems)
            }
            
        } catch {
            print("Error loading page \(page): \(error)")
        }
    }

    
    // excess case loader
    private func loadMoreIfNeeded() {
        guard !isLoadingMore else { return }
        guard currentIndex >= contentItems.count - 5 else { return }
                
        Task {
            isLoadingMore = true
            currentPage += 1
            await loadPage(page: currentPage)
            isLoadingMore = false
        }
    }
    
    
    // swipe handler
    private func handleSwipe(_ translation: CGSize) {
        let threshold: CGFloat = 100
        
        if translation.width < -threshold {
            Task { await handleWatchlist() }
        }
        else if translation.width > threshold {
            handleSkip()
        }
        else if translation.height < -threshold {
            Task { await handleWatched() }
        }
        else {
            offset = .zero
        }
    }
    
    
    // added current item to watchlist
    private func handleWatchlist() async {
        guard currentIndex < contentItems.count else { return }
        
        let content = contentItems[currentIndex]
        
        if !FirebaseService.shared.isAnonymousUser {
            do {
                try await FirebaseService.shared.addToWatchlist(
                    movieId: content.id,
                    title: content.title,
                    year: content.year,
                    posterPath: content.posterPath,
                    rating: content.rating,
                    contentType: content.contentType,
                    genreIds: content.genreIds
                )
                excludeIds.insert(content.id)
            }
            catch {
                print("Error adding to watchlist: \(error)")
            }
        }
        
        nextCard()
    }
    
    
    // added current item to watched
    private func handleWatched() async {
        guard currentIndex < contentItems.count else { return }
        
        let content = contentItems[currentIndex]
        
        if !FirebaseService.shared.isAnonymousUser {
            do {
                try await FirebaseService.shared.addToWatched(
                    movieId: content.id,
                    title: content.title,
                    year: content.year,
                    posterPath: content.posterPath,
                    rating: content.rating,
                    contentType: content.contentType,
                    genreIds: content.genreIds
                )
                excludeIds.insert(content.id)
            }
            catch {
                print("Error adding to watched: \(error)")
            }
        }
        
        nextCard()
    }
    
    
    // skipped current item
    private func handleSkip() {
        guard currentIndex < contentItems.count else { return }
        
        let content = contentItems[currentIndex]
        
        Task {
            if !FirebaseService.shared.isAnonymousUser {
                do {
                    try await FirebaseService.shared.addToSkipped(
                        movieId: content.id,
                        contentType: content.contentType,
                        title: content.title
                    )
                    excludeIds.insert(content.id)
                }
                catch {
                    print("Error saving skip: \(error)")
                }
            }
            
            await MainActor.run {
                nextCard()
            }
        }
    }
    
    
    // switching to next card
    private func nextCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = .zero
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.currentIndex < self.contentItems.count - 1 {
                self.currentIndex += 1
                self.loadMoreIfNeeded()
            }
        }
    }
}


// display card
struct DiscoverContentCard: View {
    let content: ContentItem
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // poster
                if let posterURL = content.posterURL {
                    CachedAsyncImage(url: posterURL) { image in
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } placeholder: {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.red.opacity(0.7), .black.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .aspectRatio(2/3, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                }
                
                else {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.red.opacity(0.7), .black.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(2/3, contentMode: .fit)
                        .overlay(
                            Image(systemName: content.contentType == "movie" ? "film.fill" : "tv.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                
                // rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text(content.ratingFormatted)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                .padding()
            }
            
            // content info
            VStack(alignment: .leading, spacing: 8) {
                // title
                Text(content.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // release year
                    Text(content.year)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    // seperator
                    Text("•")
                        .foregroundColor(.secondary)
                    // content type
                    Text(content.contentType == "movie" ? "Movie" : "TV Show")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
        }
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}


// swipe overlay indicator
struct SwipeIndicator: View {
    let offset: CGSize
    
    var body: some View {
        Group {
            // offset left: watchlist
            if offset.width < -50 {
                VStack {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 50))
                    Text("WATCHLIST")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(20)
            }
            // offset right: skip
            else if offset.width > 50 {
                VStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 50))
                    Text("SKIP")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.red.opacity(0.3))
                .cornerRadius(20)
            }
            // offset up: watched
            else if offset.height < -50 {
                VStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 50))
                    Text("WATCHED")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green.opacity(0.3))
                .cornerRadius(20)
            }
        }
    }
}
