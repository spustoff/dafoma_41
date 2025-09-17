//
//  NewsFeedView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct NewsFeedView: View {
    @StateObject private var viewModel: NewsFeedViewModel
    @State private var searchText = ""
    @State private var showingSearch = false
    @State private var selectedCategory: String? = nil
    @State private var lastRefreshTime = Date()
    
    init(viewModel: NewsFeedViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок с поиском
                headerView
                
                // Поисковая строка
                if showingSearch {
                    searchBarView
                }
                
                // Категории
                categoriesView
                
                // Статистика
                statsView
                
                // Список статей с pull-to-refresh
                articlesListView
            }
        }
        .refreshable {
            await refreshNews()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NewsEaseAvi")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Updated: \(lastRefreshTime.timeAgoDisplay)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Кнопка поиска
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSearch.toggle()
                        if !showingSearch {
                            searchText = ""
                        }
                    }
                } label: {
                    Image(systemName: showingSearch ? "xmark.circle.fill" : "magnifyingglass")
                        .foregroundColor(showingSearch ? .red : .gray)
                        .font(.title2)
                }
                
                // Кнопка обновления
                Button {
                    Task { await refreshNews() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search news...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .onChange(of: searchText) { _ in
                    filterArticles()
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    filterArticles()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Categories View
    private var categoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All categories
                CategoryChip(
                    title: "All",
                    icon: "globe",
                    isSelected: selectedCategory == nil,
                    count: viewModel.articles.count
                ) {
                    selectedCategory = nil
                    filterArticles()
                }
                
                // Individual categories
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category.rawValue,
                        count: viewModel.articles.filter { $0.category == category }.count
                    ) {
                        selectedCategory = selectedCategory == category.rawValue ? nil : category.rawValue
                        filterArticles()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        HStack {
            StatItem(title: "Total", value: "\(viewModel.articles.count)", icon: "newspaper")
            StatItem(title: "Read", value: "\(viewModel.getReadArticles().count)", icon: "eye.fill")
            StatItem(title: "Bookmarks", value: "\(viewModel.getBookmarkedArticles().count)", icon: "bookmark.fill")
            StatItem(title: "Today", value: "\(getTodayArticles().count)", icon: "calendar")
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Articles List
    private var articlesListView: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading news...")
                        .tint(.green)
                    Spacer()
                }
            } else if getFilteredArticles().isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: searchText.isEmpty ? "newspaper" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? "No articles available" : "No results found")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                List {
                    ForEach(getFilteredArticles(), id: \.id) { article in
                        EnhancedNewsRow(article: article, viewModel: viewModel)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.black)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func refreshNews() async {
        await MainActor.run {
            viewModel.refreshNews()
            lastRefreshTime = Date()
        }
    }
    
    private func filterArticles() {
        // Применяем фильтры в ViewModel
        viewModel.searchText = searchText
        viewModel.selectedCategory = selectedCategory.flatMap { NewsCategory(rawValue: $0) }
    }
    
    private func getFilteredArticles() -> [NewsArticle] {
        var filtered = viewModel.articles
        
        // Фильтр по поиску
        if !searchText.isEmpty {
            filtered = filtered.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Фильтр по категории
        if let categoryString = selectedCategory,
           let category = NewsCategory(rawValue: categoryString) {
            filtered = filtered.filter { $0.category == category }
        }
        
        return Array(filtered.prefix(20))
    }
    
    private func getTodayArticles() -> [NewsArticle] {
        let today = Calendar.current.startOfDay(for: Date())
        return viewModel.articles.filter { article in
            Calendar.current.startOfDay(for: article.publishedAt) == today
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.black : Color.green)
                        .foregroundColor(isSelected ? Color.green : Color.black)
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? .green : Color.gray.opacity(0.3))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.green)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Enhanced News Row
struct EnhancedNewsRow: View {
    let article: NewsArticle
    @ObservedObject var viewModel: NewsFeedViewModel
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            viewModel.markAsRead(article)
            showingDetail = true
        } label: {
            HStack(spacing: 12) {
                // Категория иконка
                Image(systemName: article.category.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: article.category.color))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Заголовок с индикатором прочитанности
                    HStack {
                        Text(article.title)
                            .font(.headline)
                            .foregroundColor(isArticleRead ? .gray : .white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if isArticleRead {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(article.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack {
                        Text(article.source.name)
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(article.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        // Кнопка закладки
                        Button {
                            viewModel.toggleBookmark(for: article)
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.caption)
                                .foregroundColor(isBookmarked ? .orange : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color.black)
        .sheet(isPresented: $showingDetail) {
            SimpleArticleDetailView(article: article)
        }
    }
    
    private var isBookmarked: Bool {
        viewModel.preferencesManager.preferences.bookmarkedArticles.contains(article.id)
    }
    
    private var isArticleRead: Bool {
        viewModel.preferencesManager.preferences.readArticles.contains(article.id)
    }
}

#Preview {
    let newsService = NewsService()
    let locationService = LocationService()
    let preferencesManager = UserPreferencesManager()
    let viewModel = NewsFeedViewModel(
        newsService: newsService,
        locationService: locationService,
        preferencesManager: preferencesManager
    )
    
    return NewsFeedView(viewModel: viewModel)
}