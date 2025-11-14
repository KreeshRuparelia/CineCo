import Foundation

class TMDBService {
    static let shared = TMDBService()
    
    private let baseURL = "https://api.themoviedb.org/3"
    // must use config to not share api key
    private let accessToken = Config.tmdbAccessToken
    
    private init() {}
    
    // get currently popular movies from tmdb
    func getPopularMovies(page: Int = 1) async throws -> [Movie] {
        // sort for english, and content with considerable review count
        let urlString = "\(baseURL)/discover/movie?language=en-US&page=\(page)&with_original_language=en&vote_count.gte=200"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // REST API request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // error check
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // interpret json
        let decoder = JSONDecoder()
        let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                
        // return popular movies
        return movieResponse.results
    }
    
    
    // make request
    private func request(urlString: String) async throws -> [Movie] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        // make the call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // error check
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // interpret json
        let decoder = JSONDecoder()
        let movieResponse = try decoder.decode(MovieResponse.self, from: data)
        
        // return
        return movieResponse.results
    }
    
    
    // search for movies
    func searchMovies(query: String) async throws -> [Movie] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/movie?query=\(encodedQuery)&include_adult=false&language=en-US&page=1"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // format and make request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // error check
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // interpret json
        let decoder = JSONDecoder()
        let movieResponse = try decoder.decode(MovieResponse.self, from: data)
        
        // return
        return movieResponse.results
    }
    
    
    // search for shows
    func searchTVShows(query: String) async throws -> [TVShow] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/tv?query=\(encodedQuery)&include_adult=false&language=en-US&page=1"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // format and make request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // error check
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // interpret json
        let decoder = JSONDecoder()
        let tvResponse = try decoder.decode(TVShowResponse.self, from: data)
        
        // return
        return tvResponse.results
    }

    
    // get popular tv shows on TMDB
    func getPopularTVShows(page: Int = 1) async throws -> [TVShow] {
        let urlString = "\(baseURL)/tv/popular?language=en-US&page=\(page)&with_original_language=en&vote_count.gte=200"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // format and make request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // error check
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // interpret json
        let decoder = JSONDecoder()
        let tvResponse = try decoder.decode(TVShowResponse.self, from: data)
                
        // return
        return tvResponse.results
    }
}
