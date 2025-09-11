//
//  UserPreferences.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import CoreLocation

struct UserPreferences: Codable {
    var selectedCategories: Set<NewsCategory>
    var preferredLanguage: String
    var preferredCountry: String
    var locationBasedNews: Bool
    var pushNotifications: Bool
    var darkMode: Bool
    var fontSize: FontSize
    var refreshInterval: RefreshInterval
    var bookmarkedArticles: Set<UUID>
    var readArticles: Set<UUID>
    var blockedSources: Set<String>
    var lastLocation: UserLocation?
    
    init() {
        self.selectedCategories = Set(NewsCategory.allCases)
        self.preferredLanguage = "en"
        self.preferredCountry = "us"
        self.locationBasedNews = true
        self.pushNotifications = true
        self.darkMode = false
        self.fontSize = .medium
        self.refreshInterval = .thirtyMinutes
        self.bookmarkedArticles = []
        self.readArticles = []
        self.blockedSources = []
        self.lastLocation = nil
    }
}

enum FontSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }
}

enum RefreshInterval: String, CaseIterable, Codable {
    case fifteenMinutes = "15min"
    case thirtyMinutes = "30min"
    case oneHour = "1hour"
    case twoHours = "2hours"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .fifteenMinutes: return "Every 15 minutes"
        case .thirtyMinutes: return "Every 30 minutes"
        case .oneHour: return "Every hour"
        case .twoHours: return "Every 2 hours"
        case .manual: return "Manual only"
        }
    }
    
    var timeInterval: TimeInterval? {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .manual: return nil
        }
    }
}

struct UserLocation: Codable {
    let latitude: Double
    let longitude: Double
    let city: String?
    let country: String?
    let timestamp: Date
    
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(from location: CLLocation, city: String? = nil, country: String? = nil) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.city = city
        self.country = country
        self.timestamp = Date()
    }
}

// UserPreferences manager for persistence
class UserPreferencesManager: ObservableObject {
    @Published var preferences: UserPreferences
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "UserPreferences"
    
    init() {
        if let data = userDefaults.data(forKey: preferencesKey),
           let decodedPreferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = decodedPreferences
        } else {
            self.preferences = UserPreferences()
            save()
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            userDefaults.set(encoded, forKey: preferencesKey)
        }
    }
    
    func reset() {
        preferences = UserPreferences()
        save()
    }
    
    // MARK: - Convenience methods
    
    func toggleCategory(_ category: NewsCategory) {
        if preferences.selectedCategories.contains(category) {
            preferences.selectedCategories.remove(category)
        } else {
            preferences.selectedCategories.insert(category)
        }
        save()
    }
    
    func bookmarkArticle(_ articleId: UUID) {
        preferences.bookmarkedArticles.insert(articleId)
        save()
    }
    
    func unbookmarkArticle(_ articleId: UUID) {
        preferences.bookmarkedArticles.remove(articleId)
        save()
    }
    
    func markArticleAsRead(_ articleId: UUID) {
        preferences.readArticles.insert(articleId)
        save()
    }
    
    func blockSource(_ sourceId: String) {
        preferences.blockedSources.insert(sourceId)
        save()
    }
    
    func unblockSource(_ sourceId: String) {
        preferences.blockedSources.remove(sourceId)
        save()
    }
    
    func updateLocation(_ location: UserLocation) {
        preferences.lastLocation = location
        save()
    }
}


