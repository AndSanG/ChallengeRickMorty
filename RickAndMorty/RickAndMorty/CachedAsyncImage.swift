import SwiftUI

enum CachedImagePhase {
    case empty
    case success(Image)
    case failure(Error)
}

struct CachedAsyncImage<Content: View>: View {
    let url: URL
    @ViewBuilder let content: (CachedImagePhase) -> Content
    
    @State private var phase: CachedImagePhase = .empty
    
    var body: some View {
        content(phase)
            .task(id: url) {
                await load()
            }
    }
    
    @MainActor
    private func load() async {
        if let cached = ImageCache.shared.get(url: url) {
            phase = .success(Image(uiImage: cached))
            return
        }
        
        phase = .empty
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                ImageCache.shared.set(uiImage, for: url)
                phase = .success(Image(uiImage: uiImage))
            } else {
                phase = .failure(URLError(.cannotDecodeRawData))
            }
        } catch {
            phase = .failure(error)
        }
    }
}

private final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
    }
    
    func get(url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func set(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
