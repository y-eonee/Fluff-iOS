import Foundation

nonisolated struct YouTubePlaylistPage: Decodable {
    struct Item: Decodable {
        struct Snippet: Decodable {
            struct Thumbnail: Decodable { let url: URL }
            let title: String
            let thumbnails: [String: Thumbnail]?
        }
        struct Details: Decodable { let itemCount: Int }
        let id: String
        let snippet: Snippet
        let contentDetails: Details
    }
    let items: [Item]
    let nextPageToken: String?
    var videos: [CouchVideo] {
        items.compactMap { item in
            guard YouTubeSource.validID(item.id, lengths: 10...128) else { return nil }
            return CouchVideo(source: YouTubeSource(videoID: nil, playlistID: item.id), title: item.snippet.title,
                              thumbnailURL: (item.snippet.thumbnails?["medium"] ?? item.snippet.thumbnails?["default"])?.url,
                              videoCount: item.contentDetails.itemCount)
        }
    }
}
