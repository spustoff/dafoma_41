//
//  NewsFeedViewModel.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import Combine
import CoreLocation

// MARK: - Reading Stats
struct ReadingStats: Codable {
    var totalArticlesRead: Int = 0
    var timeSpentReading: TimeInterval = 0
    var favoriteCategories: [String: Int] = [:]
    var articlesReadToday: Int = 0
    var lastReadDate: Date = Date()
    var weeklyReadingGoal: Int = 50
    var currentStreak: Int = 0
    
    mutating func recordArticleRead(category: NewsCategory) {
        totalArticlesRead += 1
        favoriteCategories[category.rawValue, default: 0] += 1
        
        // Проверяем, читали ли сегодня
        if Calendar.current.isDateInToday(lastReadDate) {
            articlesReadToday += 1
        } else {
            articlesReadToday = 1
            updateStreak()
        }
        
        lastReadDate = Date()
    }
    
    mutating func updateStreak() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        if Calendar.current.isDate(lastReadDate, inSameDayAs: yesterday) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
    }
    
    var weeklyProgress: Double {
        return min(Double(articlesReadToday) / Double(weeklyReadingGoal), 1.0)
    }
    
    var topCategory: String {
        return favoriteCategories.max(by: { $0.value < $1.value })?.key ?? "general"
    }
}

class NewsFeedViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var filteredArticles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedCategory: NewsCategory? = nil
    @Published var showingBookmarksOnly: Bool = false
    @Published var refreshDate: Date = Date()
    
    // Новые свойства для фич
    @Published var searchHistory: [String] = []
    @Published var readingStats = ReadingStats()
    @Published var autoRefreshEnabled = true
    
    private let newsService: NewsService
    let locationService: LocationService
    let preferencesManager: UserPreferencesManager
    private var cancellables = Set<AnyCancellable>()
    private var autoRefreshTimer: Timer?
    
    init(newsService: NewsService, locationService: LocationService, preferencesManager: UserPreferencesManager) {
        self.newsService = newsService
        self.locationService = locationService
        self.preferencesManager = preferencesManager
        
        // Минимальная инициализация
        setupBindings()
        loadReadingStats()
        startAutoRefreshTimer()
        
        // Загружаем данные только при необходимости
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    func refreshNews() {
        let categories = preferencesManager.preferences.selectedCategories
        let location = preferencesManager.preferences.locationBasedNews ? locationService.currentLocation : nil
        
        newsService.fetchNews(
            for: categories,
            location: location,
            country: preferencesManager.preferences.preferredCountry,
            language: preferencesManager.preferences.preferredLanguage
        )
        
        refreshDate = Date()
    }
    
    func searchNews() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            applyFilters()
            return
        }
        
        let categories = selectedCategory != nil ? [selectedCategory!] : preferencesManager.preferences.selectedCategories
        newsService.searchNews(query: searchText, categories: Set(categories))
    }
    
    func toggleBookmark(for article: NewsArticle) {
        if preferencesManager.preferences.bookmarkedArticles.contains(article.id) {
            preferencesManager.unbookmarkArticle(article.id)
        } else {
            preferencesManager.bookmarkArticle(article.id)
        }
        
        updateArticleBookmarkStatus(article.id)
    }
    
    func markAsRead(_ article: NewsArticle) {
        preferencesManager.markArticleAsRead(article.id)
        updateArticleReadStatus(article.id)
        
        // Обновляем статистику
        readingStats.recordArticleRead(category: article.category)
        saveReadingStats()
    }
    
    func selectCategory(_ category: NewsCategory?) {
        selectedCategory = category
        applyFilters()
    }
    
    func toggleBookmarksFilter() {
        showingBookmarksOnly.toggle()
        applyFilters()
    }
    
    func blockSource(_ sourceId: String) {
        preferencesManager.blockSource(sourceId)
        applyFilters()
    }
    
    func getTopHeadlines() {
        newsService.getTopHeadlines(
            country: preferencesManager.preferences.preferredCountry,
            category: selectedCategory
        )
    }
    
    func shareArticle(_ article: NewsArticle) -> String {
        return "\(article.title)\n\n\(article.description)\n\nRead more: \(article.url.absoluteString)"
    }
    
    func addToSearchHistory(_ query: String) {
        guard !query.isEmpty else { return }
        
        // Убираем дубликаты и добавляем в начало
        searchHistory.removeAll { $0 == query }
        searchHistory.insert(query, at: 0)
        
        // Ограничиваем до 10 запросов
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }
        
        saveSearchHistory()
    }
    
    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }
    
    // MARK: - Auto Refresh
    func startAutoRefreshTimer() {
        guard autoRefreshEnabled else { return }
        
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            self?.refreshNews()
        }
    }
    
    func stopAutoRefreshTimer() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    // MARK: - Data Persistence
    private func loadReadingStats() {
        if let data = UserDefaults.standard.data(forKey: "ReadingStats"),
           let stats = try? JSONDecoder().decode(ReadingStats.self, from: data) {
            readingStats = stats
        }
    }
    
    private func saveReadingStats() {
        if let data = try? JSONEncoder().encode(readingStats) {
            UserDefaults.standard.set(data, forKey: "ReadingStats")
        }
    }
    
    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "SearchHistory")
    }
    
    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: "SearchHistory") ?? []
    }
    
    // MARK: - Helper Methods for Views
    func getReadArticles() -> [NewsArticle] {
        return articles.filter { preferencesManager.preferences.readArticles.contains($0.id) }
    }
    
    func getBookmarkedArticles() -> [NewsArticle] {
        return articles.filter { preferencesManager.preferences.bookmarkedArticles.contains($0.id) }
    }
    
    func getLocalArticles() -> [NewsArticle] {
        return articles.filter { $0.isLocal }
    }
    
    var bookmarkedArticlesCount: Int {
        return getBookmarkedArticles().count
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Только самые необходимые привязки
        newsService.$articles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] articles in
                self?.articles = articles
                self?.filteredArticles = articles
            }
            .store(in: &cancellables)
        
        newsService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load cached articles first
        newsService.loadCachedArticles()
        // Then refresh if needed
        if newsService.articles.isEmpty {
            refreshNews()
        }
    }
    
    private func handleSearchTextChange() {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            applyFilters()
        } else {
            searchNews()
        }
    }
    
    private func applyFilters() {
        // Упрощенная фильтрация без сложных вычислений
        if showingBookmarksOnly {
            filteredArticles = articles.filter { article in
                preferencesManager.preferences.bookmarkedArticles.contains(article.id)
            }
        } else {
            filteredArticles = Array(articles.prefix(20)) // Ограничиваем количество
        }
    }
    
    private func updateArticleBookmarkStatus(_ articleId: UUID) {
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isBookmarked = preferencesManager.preferences.bookmarkedArticles.contains(articleId)
        }
        applyFilters()
    }
    
    private func updateArticleReadStatus(_ articleId: UUID) {
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isRead = preferencesManager.preferences.readArticles.contains(articleId)
        }
        applyFilters()
    }
    
    // MARK: - Computed Properties
    
    var hasArticles: Bool {
        !filteredArticles.isEmpty
    }
    
    var totalArticlesCount: Int {
        articles.count
    }
    
    var filteredArticlesCount: Int {
        filteredArticles.count
    }
    
    var unreadArticlesCount: Int {
        articles.filter { !preferencesManager.preferences.readArticles.contains($0.id) }.count
    }
    
    var localArticlesCount: Int {
        articles.filter { $0.isLocal }.count
    }
    
    var categoriesWithArticles: [NewsCategory] {
        let categories = Set(articles.map { $0.category })
        return NewsCategory.allCases.filter { categories.contains($0) }
    }
    
    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canRefresh: Bool {
        !isLoading
    }
    
    var statusMessage: String {
        if isLoading {
            return "Loading news..."
        } else if !hasArticles {
            return "No articles available"
        } else {
            return "\(filteredArticlesCount) articles"
        }
    }
}
