//
//  TrendingView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct TrendingView: View {
    @StateObject private var trendingService = TrendingService()
    @ObservedObject var newsFeedViewModel: NewsFeedViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок
                    HStack {
                        Text("Trending")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Button {
                            refreshTrending()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Breaking News
                    if !trendingService.breakingNews.isEmpty {
                        breakingNewsSection
                    }
                    
                    // Hot Articles
                    if !trendingService.hotArticles.isEmpty {
                        hotArticlesSection
                    }
                    
                    // Trending Topics
                    if !trendingService.trendingTopics.isEmpty {
                        trendingTopicsSection
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
        }
        .onAppear {
            refreshTrending()
        }
    }
    
    // MARK: - Breaking News Section
    private var breakingNewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚡ Breaking News")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trendingService.breakingNews, id: \.id) { article in
                        BreakingNewsCard(article: article) {
                            newsFeedViewModel.markAsRead(article)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Hot Articles Section
    private var hotArticlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔥 Hot Articles")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ForEach(Array(trendingService.hotArticles.prefix(5)), id: \.id) { article in
                HotArticleRow(article: article, viewModel: newsFeedViewModel)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Trending Topics Section
    private var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📈 Trending Topics")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Array(trendingService.trendingTopics.prefix(8)), id: \.id) { topic in
                    TrendingTopicCard(topic: topic) {
                        // Поиск по этой теме
                        searchForTopic(topic.keyword)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func refreshTrending() {
        trendingService.analyzeTrending(articles: newsFeedViewModel.articles)
    }
    
    private func searchForTopic(_ keyword: String) {
        // Переключаемся на главную вкладку и ищем по ключевому слову
        newsFeedViewModel.searchText = keyword
        newsFeedViewModel.addToSearchHistory(keyword)
    }
}

// MARK: - Breaking News Card
struct BreakingNewsCard: View {
    let article: NewsArticle
    let onTap: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            onTap()
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("⚡ BREAKING")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(article.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Text(article.source.name)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            .padding()
            .frame(width: 250)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            SimpleArticleDetailView(article: article)
        }
    }
}

// MARK: - Hot Article Row
struct HotArticleRow: View {
    let article: NewsArticle
    @ObservedObject var viewModel: NewsFeedViewModel
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            viewModel.markAsRead(article)
            showingDetail = true
        } label: {
            HStack(spacing: 12) {
                // Hot indicator
                VStack {
                    Text("🔥")
                        .font(.title2)
                    
                    Text(String(format: "%.1f", article.trendingScore))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(article.source.name)
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(article.timeAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ReadingModeView(article: article)
        }
    }
}

// MARK: - Trending Topic Card
struct TrendingTopicCard: View {
    let topic: TrendingTopic
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack {
                    Text(topic.popularityLevel.emoji)
                        .font(.title2)
                    
                    Spacer()
                    
                    Text("\(topic.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: topic.popularityLevel.color))
                        .cornerRadius(8)
                }
                
                Text(topic.displayText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(topic.category.displayName)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let viewModel = NewsFeedViewModel(
        newsService: NewsService(),
        locationService: LocationService(),
        preferencesManager: UserPreferencesManager()
    )
    return TrendingView(newsFeedViewModel: viewModel)
}
