//
//  NewsArticle.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import CoreLocation

struct NewsArticle: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let content: String?
    let author: String?
    let source: NewsSource
    let publishedAt: Date
    let url: URL
    let imageURL: URL?
    let category: NewsCategory
    let location: NewsLocation?
    var isBookmarked: Bool
    var isRead: Bool
    
    // Новые свойства для trending
    var trendingScore: Double = 0.0
    var isHot: Bool = false
    var isTrending: Bool = false
    var isBreaking: Bool = false
    var isDownloaded: Bool = false
    var downloadedContent: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        content: String? = nil,
        author: String? = nil,
        source: NewsSource,
        publishedAt: Date,
        url: URL,
        imageURL: URL? = nil,
        category: NewsCategory,
        location: NewsLocation? = nil,
        isBookmarked: Bool = false,
        isRead: Bool = false,
        trendingScore: Double = 0.0,
        isHot: Bool = false,
        isTrending: Bool = false,
        isBreaking: Bool = false,
        isDownloaded: Bool = false,
        downloadedContent: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.author = author
        self.source = source
        self.publishedAt = publishedAt
        self.url = url
        self.imageURL = imageURL
        self.category = category
        self.location = location
        self.isBookmarked = isBookmarked
        self.isRead = isRead
        self.trendingScore = trendingScore
        self.isHot = isHot
        self.isTrending = isTrending
        self.isBreaking = isBreaking
        self.isDownloaded = isDownloaded
        self.downloadedContent = downloadedContent
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
    
    var isLocal: Bool {
        location != nil
    }
}

struct NewsSource: Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let url: URL?
    let category: String?
    let language: String
    let country: String
}

struct NewsLocation: Codable, Equatable {
    let city: String?
    let country: String
    let coordinate: LocationCoordinate?
    
    struct LocationCoordinate: Codable, Equatable {
        let latitude: Double
        let longitude: Double
        
        var clLocation: CLLocation {
            CLLocation(latitude: latitude, longitude: longitude)
        }
    }
}

enum NewsCategory: String, CaseIterable, Codable {
    case general = "general"
    case business = "business"
    case entertainment = "entertainment"
    case health = "health"
    case science = "science"
    case sports = "sports"
    case technology = "technology"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .business: return "Business"
        case .entertainment: return "Entertainment"
        case .health: return "Health"
        case .science: return "Science"
        case .sports: return "Sports"
        case .technology: return "Technology"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "globe"
        case .business: return "briefcase"
        case .entertainment: return "tv"
        case .health: return "heart"
        case .science: return "atom"
        case .sports: return "sportscourt"
        case .technology: return "laptopcomputer"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "#28a809"
        case .business: return "#d17305"
        case .entertainment: return "#e6053a"
        case .health: return "#28a809"
        case .science: return "#d17305"
        case .sports: return "#e6053a"
        case .technology: return "#28a809"
        }
    }
}

// Sample data for development and testing
extension NewsArticle {
    static let sampleArticles: [NewsArticle] = [
        NewsArticle(
            title: "Revolutionary AI Technology Transforms Healthcare Industry",
            description: "New artificial intelligence breakthrough promises to revolutionize patient care and medical diagnostics worldwide.",
            content: "Scientists at leading research institutions have developed groundbreaking AI technology that can diagnose diseases with unprecedented accuracy. This innovation represents a major leap forward in healthcare technology, potentially saving millions of lives through early detection and personalized treatment plans.",
            author: "Dr. Sarah Johnson",
            source: NewsSource(id: "tech-news", name: "Tech News Daily", description: "Leading technology news source", url: URL(string: "https://technews.com"), category: "technology", language: "en", country: "us"),
            publishedAt: Date().addingTimeInterval(-3600),
            url: URL(string: "https://technews.com/ai-healthcare")!,
            imageURL: URL(string: "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800"),
            category: .technology,
            location: NewsLocation(city: "San Francisco", country: "United States", coordinate: NewsLocation.LocationCoordinate(latitude: 37.7749, longitude: -122.4194)),
            trendingScore: 8.5,
            isHot: true,
            isTrending: true,
            isBreaking: false
        ),
        NewsArticle(
            title: "Global Climate Summit Reaches Historic Agreement",
            description: "World leaders unite on ambitious climate action plan to combat global warming and protect the environment.",
            content: "In an unprecedented show of global cooperation, representatives from 195 countries have reached a comprehensive agreement on climate action. The summit concluded with commitments to reduce carbon emissions by 50% within the next decade and invest $2 trillion in renewable energy infrastructure.",
            author: "Michael Chen",
            source: NewsSource(id: "global-news", name: "Global News Network", description: "International news coverage", url: URL(string: "https://globalnews.com"), category: "general", language: "en", country: "us"),
            publishedAt: Date().addingTimeInterval(-7200),
            url: URL(string: "https://globalnews.com/climate-summit")!,
            imageURL: URL(string: "https://images.unsplash.com/photo-1569163139394-de4e4f43e4e5?w=800"),
            category: .general,
            trendingScore: 9.2,
            isHot: true,
            isTrending: true,
            isBreaking: true
        ),
        NewsArticle(
            title: "Stock Market Hits Record High Amid Economic Recovery",
            description: "Major indices surge as investors show confidence in post-pandemic economic growth and corporate earnings.",
            content: "The stock market reached new all-time highs today as investors demonstrated renewed confidence in the economic recovery. Strong corporate earnings reports and positive economic indicators have fueled the rally, with the S&P 500 gaining 2.5% in today's trading session.",
            author: "Amanda Rodriguez",
            source: NewsSource(id: "finance-times", name: "Finance Times", description: "Financial news and analysis", url: URL(string: "https://financetimes.com"), category: "business", language: "en", country: "us"),
            publishedAt: Date().addingTimeInterval(-10800),
            url: URL(string: "https://financetimes.com/market-high")!,
            imageURL: URL(string: "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800"),
            category: .business,
            trendingScore: 6.8,
            isHot: false,
            isTrending: true,
            isBreaking: false
        ),
        NewsArticle(
            title: "New Study Reveals Benefits of Mediterranean Diet",
            description: "Research shows Mediterranean diet significantly reduces risk of heart disease and improves cognitive function.",
            content: "A comprehensive 10-year study involving 50,000 participants has conclusively demonstrated the health benefits of the Mediterranean diet. Participants following this eating pattern showed a 30% reduction in heart disease risk and improved cognitive performance compared to control groups.",
            author: "Dr. Elena Vasquez",
            source: NewsSource(id: "health-today", name: "Health Today", description: "Latest health and medical news", url: URL(string: "https://healthtoday.com"), category: "health", language: "en", country: "us"),
            publishedAt: Date().addingTimeInterval(-14400),
            url: URL(string: "https://healthtoday.com/mediterranean-diet")!,
            imageURL: URL(string: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800"),
            category: .health
        )
    ]
}


