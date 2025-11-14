import Foundation

struct Movie: Identifiable, Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String
    let voteAverage: Double
    let genreIds: [Int]
    let popularity: Double
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case genreIds = "genre_ids"
    }
    
    // poster
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    // release year
    var year: String {
        String(releaseDate.prefix(4))
    }
    
    // rating
    var ratingFormatted: String {
        String(format: "%.1f", voteAverage)
    }
}


struct TVShow: Identifiable, Codable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String
    let voteAverage: Double
    let genreIds: [Int]
    let popularity: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview, popularity
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case genreIds = "genre_ids"
    }
    
    // poster
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    // backdrop
    var backdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(backdropPath)")
    }
    
    // original air year
    var year: String {
        guard !firstAirDate.isEmpty else { return "N/A" }
        return String(firstAirDate.prefix(4))
    }
    
    // rating
    var ratingFormatted: String {
        String(format: "%.1f", voteAverage)
    }
    
    // update content item
    var asContentItem: ContentItem {
        ContentItem(
            id: id,
            title: name,
            overview: overview,
            posterPath: posterPath,
            year: year,
            rating: voteAverage,
            contentType: "tv",
            genreIds: genreIds
        )
    }
}


struct ContentItem {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let year: String
    let rating: Double
    let contentType: String // "movie" / "tv"
    let genreIds: [Int]
    
    // poster url
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    // rating
    var ratingFormatted: String {
        String(format: "%.1f", rating)
    }
}


struct MovieResponse: Codable {
    let results: [Movie]
    let page: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
    }
}


struct TVShowResponse: Codable {
    let results: [TVShow]
    let page: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
    }
}
