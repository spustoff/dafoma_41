//
//  NewsFeedView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct NewsFeedView: View {
    @StateObject private var viewModel: NewsFeedViewModel
    
    init(viewModel: NewsFeedViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Простой заголовок
                HStack {
                    Text("NewsEaseAvi")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button {
                        viewModel.refreshNews()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Простой список статей
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.green)
                    Spacer()
                } else if viewModel.filteredArticles.isEmpty {
                    Spacer()
                    Text("No articles available")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(Array(viewModel.filteredArticles.prefix(10)), id: \.id) { article in
                            SimpleNewsRow(article: article) {
                                viewModel.markAsRead(article)
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