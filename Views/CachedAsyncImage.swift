import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            }
            else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    
    // image loader
    private func loadImage() async {
        guard let url = url else { return }
        
        // load image from cache if possibke
        if let cached = ImageCache.shared.get(forKey: url.absoluteString) {
            self.image = cached
            return
        }
        
        // load image from api
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                // caching image
                ImageCache.shared.set(uiImage, forKey: url.absoluteString)
                await MainActor.run {
                    self.image = uiImage
                }
            }
        }
        catch {
            print("Failed to load image: \(error)")
        }
    }
}


// image caching class
class ImageCache {
    static let shared = ImageCache()
    private var cache: [String: UIImage] = [:]
    private let queue = DispatchQueue(label: "ImageCache")
    
    private init() {}
    
    // getter
    func get(forKey key: String) -> UIImage? {
        queue.sync {
            cache[key]
        }
    }
    
    // setter
    func set(_ image: UIImage, forKey key: String) {
        queue.async {
            self.cache[key] = image
        }
    }
}
