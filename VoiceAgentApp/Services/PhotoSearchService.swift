import Foundation
import Photos
import Vision
import CoreML

class PhotoSearchService: ObservableObject {
    @Published var isAuthorized = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        isAuthorized = (status == .authorized || status == .limited)
    }
    
    func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                let granted = (status == .authorized || status == .limited)
                self?.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    func searchPhotos(query: String, completion: @escaping ([PHAsset]) -> Void) {
        guard isAuthorized else {
            completion([])
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let results = self.performSearch(query: query)
            completion(results)
        }
    }
    
    private func performSearch(query: String) -> [PHAsset] {
        let lowercasedQuery = query.lowercased()
        var allResults: [PHAsset] = []
        
        // Try different search strategies
        
        // 1. Date-based search
        if let dateResults = searchByDate(query: lowercasedQuery) {
            allResults.append(contentsOf: dateResults)
        }
        
        // 2. Media type search
        if let mediaResults = searchByMediaType(query: lowercasedQuery) {
            allResults.append(contentsOf: mediaResults)
        }
        
        // 3. Location-based search (if query contains location keywords)
        if let locationResults = searchByLocation(query: lowercasedQuery) {
            allResults.append(contentsOf: locationResults)
        }
        
        // 4. Album search
        if let albumResults = searchByAlbum(query: lowercasedQuery) {
            allResults.append(contentsOf: albumResults)
        }
        
        // 5. General photo search with smart filters
        if allResults.isEmpty {
            allResults = searchAllPhotos(query: lowercasedQuery)
        }
        
        // Remove duplicates and limit results
        let uniqueResults = Array(Set(allResults)).prefix(100)
        return Array(uniqueResults)
    }
    
    private func searchByDate(query: String) -> [PHAsset]? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Parse date-related queries
        if query.contains("today") {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", startOfDay as NSDate)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        } else if query.contains("yesterday") {
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
            let startOfYesterday = calendar.startOfDay(for: yesterday)
            let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startOfYesterday as NSDate, endOfYesterday as NSDate)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        } else if query.contains("last week") || query.contains("this week") {
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", weekAgo as NSDate)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        } else if query.contains("last month") || query.contains("this month") {
            let calendar = Calendar.current
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", monthAgo as NSDate)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        }
        
        return nil
    }
    
    private func searchByMediaType(query: String) -> [PHAsset]? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if query.contains("video") || query.contains("movie") {
            return Array(PHAsset.fetchAssets(with: .video, options: fetchOptions))
        } else if query.contains("selfie") || query.contains("front camera") {
            // Photos taken with front camera
            fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        } else if query.contains("screenshot") {
            fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        } else if query.contains("panorama") || query.contains("pano") {
            fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoPanorama.rawValue)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        } else if query.contains("portrait") {
            fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoDepthEffect.rawValue)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        } else if query.contains("live photo") {
            fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
            return Array(PHAsset.fetchAssets(with: .image, options: fetchOptions))
        }
        
        return nil
    }
    
    private func searchByLocation(query: String) -> [PHAsset]? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Only return photos with location data for location-based queries
        let locationKeywords = ["beach", "mountain", "city", "park", "home", "work", "restaurant", "airport", "hotel"]
        
        for keyword in locationKeywords {
            if query.contains(keyword) {
                // Get photos with location data
                fetchOptions.predicate = NSPredicate(format: "location != nil")
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                
                // In a real implementation, you'd filter by actual location
                // For now, return photos with any location data
                return Array(assets.objects(at: IndexSet(integersIn: 0..<min(50, assets.count))))
            }
        }
        
        return nil
    }
    
    private func searchByAlbum(query: String) -> [PHAsset]? {
        // Search in album names
        let albumOptions = PHFetchOptions()
        albumOptions.predicate = NSPredicate(format: "localizedTitle CONTAINS[cd] %@", query)
        
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: albumOptions)
        var results: [PHAsset] = []
        
        albums.enumerateObjects { collection, _, _ in
            let assetOptions = PHFetchOptions()
            assetOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: collection, options: assetOptions)
            results.append(contentsOf: Array(assets))
        }
        
        return results.isEmpty ? nil : results
    }
    
    private func searchAllPhotos(query: String) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100
        
        // For generic queries, return recent photos
        // In a real app with iOS 26, this would use natural language search
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        // Filter based on common keywords
        var results: [PHAsset] = []
        let keywords = ["sunset", "sunrise", "nature", "food", "people", "animal", "car", "building"]
        
        for keyword in keywords {
            if query.contains(keyword) {
                // Return a subset of photos (in real implementation, would use ML to identify content)
                results = Array(assets.objects(at: IndexSet(integersIn: 0..<min(30, assets.count))))
                break
            }
        }
        
        // If no keyword match, return recent photos
        if results.isEmpty {
            results = Array(assets.objects(at: IndexSet(integersIn: 0..<min(20, assets.count))))
        }
        
        return results
    }
}

// Helper extension to convert PHFetchResult to Array
extension PHFetchResult where ObjectType == PHAsset {
    func toArray() -> [PHAsset] {
        var results: [PHAsset] = []
        enumerateObjects { asset, _, _ in
            results.append(asset)
        }
        return results
    }
}

extension Array where Element == PHAsset {
    init(_ fetchResult: PHFetchResult<PHAsset>) {
        var results: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            results.append(asset)
        }
        self = results
    }
}