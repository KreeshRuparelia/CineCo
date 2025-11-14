import SwiftUI

struct DiscoverContentDetailView: View {
    let content: ContentItem
    let onWatched: () -> Void
    let onWatchlist: () -> Void
    let onSkip: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // poster
                        if let posterURL = content.posterURL {
                            CachedAsyncImage(url: posterURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                                
                                Image(systemName: content.contentType == "movie" ? "film.fill" : "tv.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        // content info
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    // title
                                    Text(content.title)
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Spacer()
                                    
                                    // content type image
                                    Image(systemName: content.contentType == "movie" ? "film" : "tv")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                                
                                HStack(spacing: 15) {
                                    // release year
                                    Text(content.year)
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
                                        Text(content.ratingFormatted)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            Divider()
                                .padding(.vertical, 10)
                            
                            // synopsis of item
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Overview")
                                    .font(.headline)
                                Text(content.overview)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // action buttons
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // watchlist button
                        Button(action: {
                            Task {
                                // anon check
                                if !FirebaseService.shared.isAnonymousUser {
                                    try? await FirebaseService.shared.addToWatchlist(
                                        movieId: content.id,
                                        title: content.title,
                                        year: content.year,
                                        posterPath: content.posterPath,
                                        rating: content.rating,
                                        contentType: content.contentType
                                    )
                                }
                                onWatchlist()
                                dismiss()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "bookmark.fill")
                                    .font(.title3)
                                Text("Watchlist")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        // skip button
                        Button(action: {
                            onSkip()
                            dismiss()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                Text("Skip")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        
                        // watched button
                        Button(action: {
                            Task {
                                // anon check
                                if !FirebaseService.shared.isAnonymousUser {
                                    try? await FirebaseService.shared.addToWatched(
                                        movieId: content.id,
                                        title: content.title,
                                        year: content.year,
                                        posterPath: content.posterPath,
                                        rating: content.rating,
                                        contentType: content.contentType
                                    )
                                }
                                onWatched()
                                dismiss()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.title3)
                                Text("Watched")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
