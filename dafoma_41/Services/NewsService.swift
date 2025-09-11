//
//  NewsService.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import Combine
import CoreLocation

class NewsService: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let cache = NewsCache()
    
    // Упрощенная задержка
    private let mockAPIDelay: TimeInterval = 0.5
    
    init() {
        // Start with empty articles, load data later
        articles = []
    }
    
    // MARK: - Public Methods
    
    func fetchNews(for categories: Set<NewsCategory>, location: CLLocation? = nil, country: String = "us", language: String = "en") {
        isLoading = true
        errorMessage = nil
        
        // Простая загрузка данных
        DispatchQueue.main.asyncAfter(deadline: .now() + mockAPIDelay) { [weak self] in
            self?.articles = Array(NewsArticle.sampleArticles.prefix(10))
            self?.isLoading = false
        }
    }
    
    func refreshNews(for categories: Set<NewsCategory>, location: CLLocation? = nil, country: String = "us", language: String = "en") {
        fetchNews(for: categories, location: location, country: country, language: language)
    }
    
    func searchNews(query: String, categories: Set<NewsCategory> = Set(NewsCategory.allCases)) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + mockAPIDelay) { [weak self] in
            self?.simulateSearchResponse(query: query, categories: categories)
        }
    }
    
    func getTopHeadlines(country: String = "us", category: NewsCategory? = nil) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + mockAPIDelay) { [weak self] in
            self?.simulateTopHeadlinesResponse(country: country, category: category)
        }
    }
    
    // MARK: - Private Methods
    
    func loadCachedArticles() {
        // Простая загрузка только sample данных
        articles = Array(NewsArticle.sampleArticles.prefix(10))
    }
    
    private func simulateNewsAPIResponse(categories: Set<NewsCategory>, location: CLLocation?, country: String, language: String) {
        // Generate realistic mock articles based on categories and location
        var mockArticles: [NewsArticle] = []
        
        for category in categories {
            let categoryArticles = generateMockArticles(for: category, location: location, count: Int.random(in: 3...8))
            mockArticles.append(contentsOf: categoryArticles)
        }
        
        // Add some location-based articles if location is provided
        if let location = location {
            let localArticles = generateLocalNews(for: location, count: Int.random(in: 2...5))
            mockArticles.append(contentsOf: localArticles)
        }
        
        // Sort by publication date (newest first)
        mockArticles.sort { $0.publishedAt > $1.publishedAt }
        
        DispatchQueue.main.async { [weak self] in
            self?.articles = mockArticles
            self?.cache.cacheArticles(mockArticles)
            self?.isLoading = false
        }
    }
    
    private func simulateSearchResponse(query: String, categories: Set<NewsCategory>) {
        let searchResults = generateSearchResults(for: query, categories: categories)
        
        DispatchQueue.main.async { [weak self] in
            self?.articles = searchResults
            self?.isLoading = false
        }
    }
    
    private func simulateTopHeadlinesResponse(country: String, category: NewsCategory?) {
        let headlines = generateTopHeadlines(country: country, category: category)
        
        DispatchQueue.main.async { [weak self] in
            self?.articles = headlines
            self?.cache.cacheArticles(headlines)
            self?.isLoading = false
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockArticles(for category: NewsCategory, location: CLLocation?, count: Int) -> [NewsArticle] {
        let titles = getTitlesForCategory(category)
        let descriptions = getDescriptionsForCategory(category)
        let sources = getSourcesForCategory(category)
        
        return (0..<count).compactMap { index in
            guard index < titles.count else { return nil }
            
            let randomSource = sources.randomElement() ?? sources[0]
            let publishedAt = Date().addingTimeInterval(-TimeInterval.random(in: 0...86400 * 7)) // Last 7 days
            
            return NewsArticle(
                title: titles[index],
                description: descriptions[index % descriptions.count],
                content: generateMockContent(for: titles[index]),
                author: generateRandomAuthor(),
                source: randomSource,
                publishedAt: publishedAt,
                url: URL(string: "https://\(randomSource.id).com/article-\(UUID().uuidString.prefix(8))")!,
                imageURL: getRandomImageURL(for: category),
                category: category,
                location: location != nil ? generateNewsLocation(near: location!) : nil
            )
        }
    }
    
    private func generateLocalNews(for location: CLLocation, count: Int) -> [NewsArticle] {
        let localTitles = [
            "Local Business District Sees Major Revitalization Project",
            "City Council Approves New Public Transportation Initiative",
            "Community Festival Brings Together Local Artists and Vendors",
            "New Park Opens with State-of-the-Art Facilities",
            "Local University Announces Groundbreaking Research Program",
            "Downtown Area to Get New Bike Sharing Program",
            "Local Restaurant Chain Expands to Three New Locations",
            "City Implements New Recycling Program",
            "Local Sports Team Wins Regional Championship",
            "Community Garden Project Transforms Vacant Lot"
        ]
        
        let localDescriptions = [
            "Exciting developments in the local community bring new opportunities for residents and businesses.",
            "City officials announce plans that will significantly impact the daily lives of local residents.",
            "Community initiatives continue to strengthen local bonds and promote economic growth.",
            "New facilities and services enhance the quality of life for area residents.",
            "Local institutions contribute to the advancement of knowledge and community development."
        ]
        
        return (0..<count).compactMap { index in
            guard index < localTitles.count else { return nil }
            
            let localSource = NewsSource(
                id: "local-news-\(Int.random(in: 1000...9999))",
                name: "Local News Network",
                description: "Your trusted source for local news",
                url: URL(string: "https://localnews.com"),
                category: "general",
                language: "en",
                country: "us"
            )
            
            return NewsArticle(
                title: localTitles[index],
                description: localDescriptions[index % localDescriptions.count],
                content: generateMockContent(for: localTitles[index]),
                author: generateRandomAuthor(),
                source: localSource,
                publishedAt: Date().addingTimeInterval(-TimeInterval.random(in: 0...86400 * 3)), // Last 3 days
                url: URL(string: "https://localnews.com/article-\(UUID().uuidString.prefix(8))")!,
                imageURL: URL(string: "https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800"),
                category: .general,
                location: generateNewsLocation(near: location)
            )
        }
    }
    
    private func generateSearchResults(for query: String, categories: Set<NewsCategory>) -> [NewsArticle] {
        // Generate articles that would match the search query
        let searchTitles = [
            "\(query.capitalized) Industry Sees Unprecedented Growth",
            "Experts Discuss the Future of \(query.capitalized)",
            "Breaking: Major Developments in \(query.capitalized) Sector",
            "Analysis: How \(query.capitalized) is Changing the World",
            "New Study Reveals Impact of \(query.capitalized) on Society"
        ]
        
        return searchTitles.enumerated().map { index, title in
            let category = categories.randomElement() ?? .general
            let source = getSourcesForCategory(category).randomElement() ?? getSourcesForCategory(.general)[0]
            
            return NewsArticle(
                title: title,
                description: "Comprehensive coverage and analysis of \(query) developments and their impact on various industries.",
                content: generateMockContent(for: title),
                author: generateRandomAuthor(),
                source: source,
                publishedAt: Date().addingTimeInterval(-TimeInterval.random(in: 0...86400 * 2)),
                url: URL(string: "https://\(source.id).com/search-\(UUID().uuidString.prefix(8))")!,
                imageURL: getRandomImageURL(for: category),
                category: category
            )
        }
    }
    
    private func generateTopHeadlines(country: String, category: NewsCategory?) -> [NewsArticle] {
        let headlineTitles = [
            "Breaking: Major Political Development Shakes Capital",
            "Economic Markets React to Latest Policy Changes",
            "International Summit Addresses Global Challenges",
            "Technology Giants Announce Strategic Partnership",
            "Climate Action Plan Receives Widespread Support",
            "Healthcare Innovation Promises Better Patient Outcomes",
            "Education Reform Initiative Launches Nationwide",
            "Infrastructure Investment Program Gets Green Light"
        ]
        
        return headlineTitles.enumerated().map { index, title in
            let articleCategory = category ?? NewsCategory.allCases.randomElement() ?? .general
            let source = getSourcesForCategory(articleCategory).randomElement() ?? getSourcesForCategory(.general)[0]
            
            return NewsArticle(
                title: title,
                description: "Top headline story covering the most important developments of the day.",
                content: generateMockContent(for: title),
                author: generateRandomAuthor(),
                source: source,
                publishedAt: Date().addingTimeInterval(-TimeInterval.random(in: 0...3600 * 12)),
                url: URL(string: "https://\(source.id).com/headline-\(UUID().uuidString.prefix(8))")!,
                imageURL: getRandomImageURL(for: articleCategory),
                category: articleCategory
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTitlesForCategory(_ category: NewsCategory) -> [String] {
        switch category {
        case .technology:
            return [
                "AI Revolution Transforms Software Development",
                "Quantum Computing Breakthrough Achieved",
                "5G Networks Enable New IoT Applications",
                "Cybersecurity Threats Evolve with Technology",
                "Blockchain Technology Finds New Use Cases",
                "Virtual Reality Enters Mainstream Market",
                "Edge Computing Reduces Latency Issues",
                "Machine Learning Improves Medical Diagnosis"
            ]
        case .business:
            return [
                "Stock Market Reaches New All-Time High",
                "Startup Funding Hits Record Levels",
                "Major Merger Reshapes Industry Landscape",
                "Economic Indicators Show Strong Growth",
                "Supply Chain Challenges Create Opportunities",
                "Remote Work Transforms Corporate Culture",
                "Sustainable Business Practices Gain Momentum",
                "Digital Transformation Accelerates"
            ]
        case .health:
            return [
                "New Treatment Shows Promise for Rare Disease",
                "Mental Health Awareness Campaign Launches",
                "Breakthrough in Cancer Research Announced",
                "Fitness Technology Improves Health Outcomes",
                "Nutrition Study Reveals Surprising Results",
                "Telemedicine Usage Continues to Grow",
                "Vaccine Development Reaches New Milestone",
                "Public Health Initiative Targets Prevention"
            ]
        case .science:
            return [
                "Space Mission Discovers New Exoplanet",
                "Climate Research Reveals Unexpected Findings",
                "Archaeological Discovery Rewrites History",
                "Marine Biology Study Uncovers New Species",
                "Physics Experiment Confirms Theoretical Model",
                "Environmental Conservation Effort Shows Results",
                "Renewable Energy Efficiency Improves",
                "Genetic Research Opens New Possibilities"
            ]
        case .sports:
            return [
                "Championship Final Breaks Viewership Records",
                "Olympic Training Program Shows Innovation",
                "Sports Medicine Advances Athlete Recovery",
                "Youth Sports Participation Reaches New High",
                "Professional League Expands Internationally",
                "Stadium Technology Enhances Fan Experience",
                "Sports Analytics Revolutionizes Strategy",
                "Athletic Scholarship Program Launches"
            ]
        case .entertainment:
            return [
                "Film Festival Showcases Independent Cinema",
                "Streaming Platform Announces Original Series",
                "Music Industry Embraces Digital Innovation",
                "Gaming Technology Creates Immersive Experiences",
                "Theater Productions Return to Full Capacity",
                "Celebrity Charity Event Raises Millions",
                "Art Exhibition Features Contemporary Artists",
                "Entertainment Awards Honor Outstanding Work"
            ]
        case .general:
            return [
                "Community Initiative Brings Positive Change",
                "Local Government Announces Infrastructure Plan",
                "Education Program Receives National Recognition",
                "Environmental Project Restores Natural Habitat",
                "Cultural Festival Celebrates Diversity",
                "Transportation Improvements Benefit Commuters",
                "Housing Development Addresses Affordability",
                "Public Safety Measures Show Effectiveness"
            ]
        }
    }
    
    private func getDescriptionsForCategory(_ category: NewsCategory) -> [String] {
        switch category {
        case .technology:
            return [
                "Latest technological innovations continue to reshape industries and improve daily life.",
                "Cutting-edge research and development lead to breakthrough discoveries.",
                "Technology companies push the boundaries of what's possible.",
                "Digital transformation accelerates across all sectors of the economy."
            ]
        case .business:
            return [
                "Market analysis reveals trends that could impact investment strategies.",
                "Business leaders adapt to changing economic conditions and consumer demands.",
                "Corporate innovation drives growth and competitive advantage.",
                "Economic policies create new opportunities for businesses and investors."
            ]
        case .health:
            return [
                "Medical research continues to advance treatment options for patients.",
                "Healthcare professionals implement new approaches to patient care.",
                "Public health initiatives focus on prevention and wellness.",
                "Healthcare technology improves diagnosis and treatment outcomes."
            ]
        case .science:
            return [
                "Scientific discoveries expand our understanding of the natural world.",
                "Research findings have implications for future technological development.",
                "Environmental studies inform conservation and sustainability efforts.",
                "Scientific collaboration leads to breakthrough innovations."
            ]
        case .sports:
            return [
                "Athletic achievements inspire and entertain fans around the world.",
                "Sports organizations implement new programs and initiatives.",
                "Technology and analytics transform how sports are played and watched.",
                "Community sports programs promote health and social connection."
            ]
        case .entertainment:
            return [
                "Creative industries continue to evolve with new technologies and platforms.",
                "Artists and performers find innovative ways to connect with audiences.",
                "Entertainment content reflects and shapes cultural conversations.",
                "Industry developments impact how we consume and create media."
            ]
        case .general:
            return [
                "Community developments affect the daily lives of local residents.",
                "Public policies and initiatives address important social issues.",
                "Local organizations work to improve quality of life for all.",
                "Civic engagement and participation strengthen democratic institutions."
            ]
        }
    }
    
    private func getSourcesForCategory(_ category: NewsCategory) -> [NewsSource] {
        switch category {
        case .technology:
            return [
                NewsSource(id: "tech-insider", name: "Tech Insider", description: "Technology news and analysis", url: URL(string: "https://techinsider.com"), category: "technology", language: "en", country: "us"),
                NewsSource(id: "digital-trends", name: "Digital Trends", description: "Latest in digital technology", url: URL(string: "https://digitaltrends.com"), category: "technology", language: "en", country: "us")
            ]
        case .business:
            return [
                NewsSource(id: "business-weekly", name: "Business Weekly", description: "Business news and insights", url: URL(string: "https://businessweekly.com"), category: "business", language: "en", country: "us"),
                NewsSource(id: "market-watch", name: "Market Watch", description: "Financial market analysis", url: URL(string: "https://marketwatch.com"), category: "business", language: "en", country: "us")
            ]
        default:
            return [
                NewsSource(id: "news-central", name: "News Central", description: "Comprehensive news coverage", url: URL(string: "https://newscentral.com"), category: "general", language: "en", country: "us")
            ]
        }
    }
    
    private func generateMockContent(for title: String) -> String {
        let paragraphs = [
            "This developing story continues to unfold as experts analyze the implications and potential outcomes. Stakeholders from various sectors are closely monitoring the situation and preparing for potential impacts.",
            "Industry leaders have responded with cautious optimism, noting that while challenges remain, there are significant opportunities for growth and innovation. The long-term effects are expected to be substantial.",
            "Analysts suggest that this development could set a precedent for future initiatives and policies. The response from the public and private sectors will likely influence how similar situations are handled in the future.",
            "Further details are expected to emerge as investigations continue and more information becomes available. Experts recommend staying informed about developments as they occur."
        ]
        
        return paragraphs.joined(separator: "\n\n")
    }
    
    private func generateRandomAuthor() -> String {
        let firstNames = ["Sarah", "Michael", "Emma", "David", "Lisa", "James", "Maria", "Robert", "Jennifer", "William"]
        let lastNames = ["Johnson", "Smith", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"]
        
        let firstName = firstNames.randomElement() ?? "John"
        let lastName = lastNames.randomElement() ?? "Doe"
        
        return "\(firstName) \(lastName)"
    }
    
    private func getRandomImageURL(for category: NewsCategory) -> URL? {
        let imageUrls = [
            "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800",
            "https://images.unsplash.com/photo-1495020689067-958852a7765e?w=800",
            "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800",
            "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800",
            "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=800"
        ]
        
        return URL(string: imageUrls.randomElement() ?? imageUrls[0])
    }
    
    private func generateNewsLocation(near location: CLLocation) -> NewsLocation? {
        // Generate a location within ~50km of the provided location
        let latOffset = Double.random(in: -0.5...0.5)
        let lonOffset = Double.random(in: -0.5...0.5)
        
        return NewsLocation(
            city: "Local City",
            country: "United States",
            coordinate: NewsLocation.LocationCoordinate(
                latitude: location.coordinate.latitude + latOffset,
                longitude: location.coordinate.longitude + lonOffset
            )
        )
    }
}

// MARK: - News Cache

class NewsCache {
    private let cacheKey = "CachedNewsArticles"
    private let cacheExpirationKey = "CacheExpiration"
    private let cacheExpirationInterval: TimeInterval = 30 * 60 // 30 minutes
    
    func cacheArticles(_ articles: [NewsArticle]) {
        do {
            let data = try JSONEncoder().encode(articles)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheExpirationKey)
        } catch {
            print("Failed to cache articles: \(error)")
        }
    }
    
    func getCachedArticles() -> [NewsArticle] {
        guard let cacheDate = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date,
              Date().timeIntervalSince(cacheDate) < cacheExpirationInterval,
              let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([NewsArticle].self, from: data)
        } catch {
            print("Failed to decode cached articles: \(error)")
            return []
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpirationKey)
    }
}


