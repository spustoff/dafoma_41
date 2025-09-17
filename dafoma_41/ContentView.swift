//
//  ContentView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    @State private var isAppReady = false
    
    var body: some View {
        Group {
            if !isAppReady {
                // Simple loading screen
                VStack(spacing: 16) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(Color(hex: "#28a809"))
                    
                    Text("NewsEaseAvi")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    ProgressView()
                        .tint(Color(hex: "#28a809"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#0e0e0e").ignoresSafeArea())
                .onAppear {
                    // Simulate app initialization
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isAppReady = true
                    }
                }
            } else if isOnboardingComplete {
                MainAppView()
            } else {
                SimpleOnboardingView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @StateObject private var preferencesManager = UserPreferencesManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var newsService = NewsService()
    @StateObject private var newsFeedViewModel: NewsFeedViewModel
    
    init() {
        let prefsManager = UserPreferencesManager()
        let locService = LocationService()
        let newsServ = NewsService()
        
        self._preferencesManager = StateObject(wrappedValue: prefsManager)
        self._locationService = StateObject(wrappedValue: locService)
        self._newsService = StateObject(wrappedValue: newsServ)
        self._newsFeedViewModel = StateObject(wrappedValue: NewsFeedViewModel(
            newsService: newsServ,
            locationService: locService,
            preferencesManager: prefsManager
        ))
    }
    
    var body: some View {
        TabView {
            // News Feed Tab
            NewsFeedView(viewModel: newsFeedViewModel)
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("News")
                }
            
            // Bookmarks Tab
            BookmarksView(viewModel: newsFeedViewModel)
                .tabItem {
                    Image(systemName: "bookmark")
                    Text("Bookmarks")
                }
            
            // Local News Tab
            LocalNewsView(viewModel: newsFeedViewModel)
                .tabItem {
                    Image(systemName: "location")
                    Text("Local")
                }
            
            // Settings Tab
            SettingsView(
                preferencesManager: preferencesManager,
                locationService: locationService
            )
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
        .accentColor(Color(hex: "#28a809"))
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0e0e0e"))
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "#888888"))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#888888"))
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#28a809"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#28a809"))
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Bookmarks View

struct BookmarksView: View {
    @ObservedObject private var viewModel: NewsFeedViewModel
    
    init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Заголовок с статистикой
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bookmarks")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("\(viewModel.getBookmarkedArticles().count) saved articles")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Кнопка очистки закладок
                    if viewModel.getBookmarkedArticles().count > 0 {
                        Button("Clear All") {
                            clearAllBookmarks()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .padding()
                
                // Список закладок
                if viewModel.getBookmarkedArticles().isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bookmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No bookmarks yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Tap the bookmark icon on articles to save them here")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.getBookmarkedArticles(), id: \.id) { article in
                            EnhancedNewsRow(article: article, viewModel: viewModel)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.black)
                }
            }
        }
    }
    
    private func clearAllBookmarks() {
        for article in viewModel.getBookmarkedArticles() {
            viewModel.preferencesManager.unbookmarkArticle(article.id)
        }
    }
}

// MARK: - Local News View

struct LocalNewsView: View {
    @ObservedObject private var viewModel: NewsFeedViewModel
    
    init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Заголовок с локацией
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local News")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            
                            Text(viewModel.locationService.currentAddress ?? "Location not available")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Кнопка запроса локации
                    Button {
                        viewModel.locationService.requestLocationPermission()
                    } label: {
                        Image(systemName: "location.circle")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                
                // Список локальных новостей
                if viewModel.getLocalArticles().isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "location.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No local news available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Enable location services to get news from your area")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.getLocalArticles(), id: \.id) { article in
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                
                                EnhancedNewsRow(article: article, viewModel: viewModel)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.black)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

