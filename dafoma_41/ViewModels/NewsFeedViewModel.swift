//
//  NewsFeedViewModel.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import Combine
import CoreLocation

class NewsFeedViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var filteredArticles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedCategory: NewsCategory? = nil
    @Published var showingBookmarksOnly: Bool = false
    @Published var refreshDate: Date = Date()
    
    private let newsService: NewsService
    let locationService: LocationService
    private let preferencesManager: UserPreferencesManager
    private var cancellables = Set<AnyCancellable>()
    
    init(newsService: NewsService, locationService: LocationService, preferencesManager: UserPreferencesManager) {
        self.newsService = newsService
        self.locationService = locationService
        self.preferencesManager = preferencesManager
        
        // Минимальная инициализация
        setupBindings()
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
    
    var bookmarkedArticlesCount: Int {
        articles.filter { preferencesManager.preferences.bookmarkedArticles.contains($0.id) }.count
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
        } else if !hasArticles && isSearchActive {
            return "No articles found for '\(searchText)'"
        } else if !hasArticles && showingBookmarksOnly {
            return "No bookmarked articles"
        } else if !hasArticles {
            return "No articles available"
        } else if selectedCategory != nil {
            return "\(filteredArticlesCount) \(selectedCategory!.displayName.lowercased()) articles"
        } else if showingBookmarksOnly {
            return "\(filteredArticlesCount) bookmarked articles"
        } else {
            return "\(filteredArticlesCount) articles"
        }
    }
}

// MARK: - Extensions

extension NewsFeedViewModel {
    func getArticlesForCategory(_ category: NewsCategory) -> [NewsArticle] {
        return articles.filter { $0.category == category }
    }
    
    func getRecentArticles(limit: Int = 10) -> [NewsArticle] {
        return Array(articles.prefix(limit))
    }
    
    func getLocalArticles() -> [NewsArticle] {
        return articles.filter { $0.isLocal }
    }
    
    func getBookmarkedArticles() -> [NewsArticle] {
        return articles.filter { preferencesManager.preferences.bookmarkedArticles.contains($0.id) }
    }
    
    func getUnreadArticles() -> [NewsArticle] {
        return articles.filter { !preferencesManager.preferences.readArticles.contains($0.id) }
    }
}
