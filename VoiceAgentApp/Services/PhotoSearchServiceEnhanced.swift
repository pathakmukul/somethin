import Foundation
import Photos
import Vision
import CoreLocation
import NaturalLanguage

class PhotoSearchServiceEnhanced: ObservableObject {
    @Published var isAuthorized = false
    private let geocoder = CLGeocoder()
    
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
    
    // MARK: - Enhanced Search
    
    func searchPhotos(query: String, completion: @escaping ([PHAsset]) -> Void) {
        guard isAuthorized else {
            completion([])
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Parse the query to extract components
            let components = self.parseSearchQuery(query)
            
            // Perform multi-strategy search
            var allResults: [PHAsset] = []
            
            // 1. Date-based search
            if let dateResults = self.searchByParsedDates(components: components) {
                allResults.append(contentsOf: dateResults)
            }
            
            // 2. Location-based search (enhanced)
            if let locationResults = self.searchByParsedLocation(components: components) {
                allResults.append(contentsOf: locationResults)
            }
            
            // 3. Media type search
            if let mediaResults = self.searchByParsedMediaType(components: components) {
                allResults.append(contentsOf: mediaResults)
            }
            
            // 4. Album/Collection search
            if let albumResults = self.searchByParsedAlbum(components: components) {
                allResults.append(contentsOf: albumResults)
            }
            
            // 5. Smart collections (Favorites, Recently Added, etc.)
            if let smartResults = self.searchSmartAlbums(components: components) {
                allResults.append(contentsOf: smartResults)
            }
            
            // 6. If no specific results, try general search with all photos
            if allResults.isEmpty {
                allResults = self.performGeneralSearch(components: components)
            }
            
            // Remove duplicates and sort by relevance
            let uniqueResults = self.rankAndDeduplicate(results: allResults, query: query)
            
            DispatchQueue.main.async {
                completion(Array(uniqueResults.prefix(100)))
            }
        }
    }
    
    // MARK: - Query Parsing
    
    private func parseSearchQuery(_ query: String) -> SearchComponents {
        var components = SearchComponents()
        let lowercased = query.lowercased()
        
        // Use NaturalLanguage framework to tokenize
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = lowercased
        
        var tokens: [String] = []
        tagger.enumerateTags(in: lowercased.startIndex..<lowercased.endIndex, 
                            unit: .word, 
                            scheme: .lexicalClass) { tag, range in
            let token = String(lowercased[range])
            tokens.append(token)
            
            // Check for names (though iOS doesn't expose face names via API)
            if tag == .noun || tag == .personalName {
                components.possibleNames.append(token)
            }
            
            return true
        }
        
        // Parse dates
        components.dateKeywords = extractDateKeywords(from: lowercased)
        
        // Parse locations
        components.locationKeywords = extractLocationKeywords(from: lowercased)
        
        // Parse media types
        components.mediaTypeKeywords = extractMediaTypeKeywords(from: lowercased)
        
        // Parse events/occasions
        components.eventKeywords = extractEventKeywords(from: lowercased)
        
        // Parse album names
        components.albumKeywords = tokens.filter { $0.count > 2 }
        
        return components
    }
    
    private func extractDateKeywords(from query: String) -> [String] {
        let datePatterns = [
            "today", "yesterday", "tomorrow",
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
            "january", "february", "march", "april", "may", "june",
            "july", "august", "september", "october", "november", "december",
            "last week", "this week", "next week",
            "last month", "this month", "next month",
            "last year", "this year",
            "morning", "afternoon", "evening", "night",
            "weekend", "weekday"
        ]
        
        return datePatterns.filter { query.contains($0) }
    }
    
    private func extractLocationKeywords(from query: String) -> [String] {
        let locationPatterns = [
            "beach", "mountain", "city", "park", "home", "work",
            "restaurant", "airport", "hotel", "museum", "zoo",
            "school", "office", "gym", "mall", "store",
            "lake", "river", "ocean", "forest", "desert",
            "downtown", "uptown", "suburb"
        ]
        
        var found = locationPatterns.filter { query.contains($0) }
        
        // Also check for capitalized words that might be place names
        let words = query.split(separator: " ").map(String.init)
        for word in words {
            if word.first?.isUppercase == true && word.count > 2 {
                found.append(word.lowercased())
            }
        }
        
        return found
    }
    
    private func extractMediaTypeKeywords(from query: String) -> [String] {
        let mediaPatterns = [
            "video", "movie", "selfie", "screenshot", "panorama",
            "portrait", "live photo", "burst", "slow motion",
            "time lapse", "hdr", "raw"
        ]
        
        return mediaPatterns.filter { query.contains($0) }
    }
    
    private func extractEventKeywords(from query: String) -> [String] {
        let eventPatterns = [
            "wedding", "birthday", "party", "graduation", "vacation",
            "holiday", "christmas", "thanksgiving", "easter", "halloween",
            "anniversary", "concert", "festival", "ceremony", "celebration",
            "trip", "tour", "meeting", "conference"
        ]
        
        return eventPatterns.filter { query.contains($0) }
    }
    
    // MARK: - Enhanced Search Methods
    
    private func searchByParsedDates(components: SearchComponents) -> [PHAsset]? {
        guard !components.dateKeywords.isEmpty else { return nil }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        for keyword in components.dateKeywords {
            if let predicate = createDatePredicate(for: keyword) {
                fetchOptions.predicate = predicate
                let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                if results.count > 0 {
                    var assets: [PHAsset] = []
                    results.enumerateObjects { asset, _, _ in
                        assets.append(asset)
                    }
                    return assets
                }
            }
        }
        
        return nil
    }
    
    private func createDatePredicate(for keyword: String) -> NSPredicate? {
        let calendar = Calendar.current
        let now = Date()
        
        switch keyword {
        case "today":
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
            
        case "yesterday":
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let start = calendar.startOfDay(for: yesterday)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
            
        case "this week", "last week":
            let weeksAgo = keyword.contains("last") ? -1 : 0
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
               let targetWeek = calendar.date(byAdding: .weekOfYear, value: weeksAgo, to: weekStart) {
                let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: targetWeek)!
                return NSPredicate(format: "creationDate >= %@ AND creationDate < %@", targetWeek as NSDate, endOfWeek as NSDate)
            }
            
        case "this month", "last month":
            let monthsAgo = keyword.contains("last") ? -1 : 0
            if let monthStart = calendar.dateInterval(of: .month, for: now)?.start,
               let targetMonth = calendar.date(byAdding: .month, value: monthsAgo, to: monthStart) {
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: targetMonth)!
                return NSPredicate(format: "creationDate >= %@ AND creationDate < %@", targetMonth as NSDate, endOfMonth as NSDate)
            }
            
        case "weekend":
            // Get last weekend
            var lastWeekend = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            lastWeekend.weekday = 7 // Saturday
            if let saturday = calendar.date(from: lastWeekend),
               let monday = calendar.date(byAdding: .day, value: 2, to: saturday) {
                return NSPredicate(format: "creationDate >= %@ AND creationDate < %@", saturday as NSDate, monday as NSDate)
            }
            
        default:
            return nil
        }
        
        return nil
    }
    
    private func searchByParsedLocation(components: SearchComponents) -> [PHAsset]? {
        guard !components.locationKeywords.isEmpty else { return nil }
        
        // Fetch all photos with location data
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "location != nil")
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assetsWithLocation = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        // For now, return a subset since we can't actually filter by location name
        // In a real implementation, you'd need to reverse geocode each location
        // and match against the keywords
        
        if assetsWithLocation.count > 0 {
            // Return a reasonable subset
            let maxResults = min(50, assetsWithLocation.count)
            var locationAssets: [PHAsset] = []
            assetsWithLocation.enumerateObjects(at: IndexSet(integersIn: 0..<maxResults), options: []) { asset, _, _ in
                locationAssets.append(asset)
            }
            return locationAssets
        }
        
        return nil
    }
    
    private func searchByParsedMediaType(components: SearchComponents) -> [PHAsset]? {
        guard !components.mediaTypeKeywords.isEmpty else { return nil }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        var allResults: [PHAsset] = []
        
        for keyword in components.mediaTypeKeywords {
            var predicate: NSPredicate?
            var mediaType: PHAssetMediaType = .image
            
            switch keyword {
            case "video", "movie":
                mediaType = .video
                
            case "selfie":
                // Selfies typically have specific camera metadata
                // This is an approximation
                predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoDepthEffect.rawValue)
                
            case "screenshot":
                predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
                
            case "panorama":
                predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoPanorama.rawValue)
                
            case "portrait":
                predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoDepthEffect.rawValue)
                
            case "live photo":
                predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
                
            case "burst":
                // Check for burst photos
                fetchOptions.includeAllBurstAssets = true
                
            case "hdr":
                predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoHDR.rawValue)
                
            default:
                continue
            }
            
            if let pred = predicate {
                fetchOptions.predicate = pred
            }
            
            let results = PHAsset.fetchAssets(with: mediaType, options: fetchOptions)
            results.enumerateObjects { asset, _, _ in
                allResults.append(asset)
            }
        }
        
        return allResults.isEmpty ? nil : allResults
    }
    
    private func searchByParsedAlbum(components: SearchComponents) -> [PHAsset]? {
        guard !components.albumKeywords.isEmpty else { return nil }
        
        var allResults: [PHAsset] = []
        
        // Search user albums
        let albumOptions = PHFetchOptions()
        
        for keyword in components.albumKeywords {
            albumOptions.predicate = NSPredicate(format: "localizedTitle CONTAINS[cd] %@", keyword)
            
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: albumOptions)
            
            userAlbums.enumerateObjects { collection, _, _ in
                let assetOptions = PHFetchOptions()
                assetOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let assets = PHAsset.fetchAssets(in: collection, options: assetOptions)
                assets.enumerateObjects { asset, _, _ in
                    allResults.append(asset)
                }
            }
        }
        
        return allResults.isEmpty ? nil : allResults
    }
    
    private func searchSmartAlbums(components: SearchComponents) -> [PHAsset]? {
        var results: [PHAsset] = []
        
        // Check for smart album keywords
        if components.eventKeywords.contains("favorite") || 
           components.albumKeywords.contains("favorites") {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "isFavorite == YES")
            let favorites = PHAsset.fetchAssets(with: options)
            favorites.enumerateObjects { asset, _, _ in
                results.append(asset)
            }
        }
        
        // Check for recently added
        if components.dateKeywords.contains("recent") || 
           components.albumKeywords.contains("recent") {
            let smartAlbums = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: .smartAlbumRecentlyAdded,
                options: nil
            )
            
            if let recentAlbum = smartAlbums.firstObject {
                let assets = PHAsset.fetchAssets(in: recentAlbum, options: nil)
                let maxCount = min(30, assets.count)
                assets.enumerateObjects(at: IndexSet(integersIn: 0..<maxCount), options: []) { asset, _, _ in
                    results.append(asset)
                }
            }
        }
        
        return results.isEmpty ? nil : results
    }
    
    private func performGeneralSearch(components: SearchComponents) -> [PHAsset] {
        // Fallback to recent photos if no specific search criteria
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 50
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var generalResults: [PHAsset] = []
        allPhotos.enumerateObjects { asset, _, _ in
            generalResults.append(asset)
        }
        return generalResults
    }
    
    private func rankAndDeduplicate(results: [PHAsset], query: String) -> [PHAsset] {
        // Remove duplicates
        let uniqueResults = Array(Set(results))
        
        // Sort by creation date (newest first) as a basic ranking
        return uniqueResults.sorted { asset1, asset2 in
            guard let date1 = asset1.creationDate,
                  let date2 = asset2.creationDate else {
                return false
            }
            return date1 > date2
        }
    }
}

// MARK: - Supporting Types

struct SearchComponents {
    var possibleNames: [String] = []
    var dateKeywords: [String] = []
    var locationKeywords: [String] = []
    var mediaTypeKeywords: [String] = []
    var eventKeywords: [String] = []
    var albumKeywords: [String] = []
}