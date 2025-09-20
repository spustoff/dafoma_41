//
//  ReadingModeView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct ReadingModeView: View {
    let article: NewsArticle
    @Environment(\.dismiss) private var dismiss
    @State private var readingProgress: Double = 0.0
    @State private var isNightMode = false
    @State private var fontSize: ReadingFontSize = .medium
    @State private var showingSafari = false
    @State private var isDownloaded = false
    @State private var downloadedContent = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Прогресс-бар чтения
                    ProgressView(value: readingProgress)
                        .tint(isNightMode ? .orange : .green)
                        .background(Color.gray.opacity(0.3))
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Заголовок статьи
                                Text(article.title)
                                    .font(.system(size: fontSize.titleSize, weight: .bold))
                                    .foregroundColor(textColor)
                                    .padding(.horizontal)
                                    .id("title")
                                
                                // Мета-информация
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            if article.isBreaking {
                                                Text("⚡ BREAKING")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.red)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red.opacity(0.2))
                                                    .cornerRadius(4)
                                            }
                                            
                                            if article.isHot {
                                                Text("🔥 HOT")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.orange)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.orange.opacity(0.2))
                                                    .cornerRadius(4)
                                            }
                                            
                                            if article.isTrending {
                                                Text("📈 TRENDING")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.2))
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        HStack {
                                            Text(article.source.name)
                                                .font(.caption)
                                                .foregroundColor(isNightMode ? .orange : .green)
                                            
                                            Text("•")
                                                .foregroundColor(.gray)
                                            
                                            Text(article.timeAgo)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            if let author = article.author {
                                                Text("•")
                                                    .foregroundColor(.gray)
                                                
                                                Text("By \(author)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                // Описание
                                Text(article.description)
                                    .font(.system(size: fontSize.bodySize))
                                    .foregroundColor(secondaryTextColor)
                                    .lineSpacing(4)
                                    .padding(.horizontal)
                                
                                // Контент статьи
                                if let content = article.downloadedContent ?? article.content {
                                    Text(content)
                                        .font(.system(size: fontSize.bodySize))
                                        .foregroundColor(textColor)
                                        .lineSpacing(6)
                                        .padding(.horizontal)
                                        .id("content")
                                } else if !isDownloaded {
                                    // Кнопка загрузки контента
                                    Button {
                                        downloadArticle()
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.down.circle")
                                            Text("Download for Offline Reading")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(isNightMode ? .orange : .green)
                                        .cornerRadius(8)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Кнопка открытия в Safari
                                Button {
                                    showingSafari = true
                                } label: {
                                    HStack {
                                        Image(systemName: "safari")
                                        Text("Read Full Article")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(isNightMode ? .orange : .green)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                                
                                Spacer(minLength: 100)
                            }
                            .onAppear {
                                startReadingProgress()
                            }
                        }
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        updateReadingProgress(geometry: geometry)
                                    }
                                    .onChange(of: geometry.frame(in: .global)) { _ in
                                        updateReadingProgress(geometry: geometry)
                                    }
                            }
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(isNightMode ? .orange : .green)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Night mode toggle
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isNightMode.toggle()
                            }
                        } label: {
                            Image(systemName: isNightMode ? "sun.max.fill" : "moon.fill")
                                .foregroundColor(isNightMode ? .orange : .blue)
                        }
                        
                        // Font size menu
                        Menu {
                            ForEach(ReadingFontSize.allCases, id: \.self) { size in
                                Button(size.displayName) {
                                    fontSize = size
                                }
                            }
                        } label: {
                            Image(systemName: "textformat.size")
                                .foregroundColor(isNightMode ? .orange : .green)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSafari) {
            SafariView(url: article.url)
        }
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        if isNightMode {
            return Color(red: 0.1, green: 0.05, blue: 0.0) // Теплый темный
        } else {
            return Color.black
        }
    }
    
    private var textColor: Color {
        if isNightMode {
            return Color(red: 1.0, green: 0.9, blue: 0.8) // Теплый белый
        } else {
            return Color.white
        }
    }
    
    private var secondaryTextColor: Color {
        if isNightMode {
            return Color(red: 0.8, green: 0.7, blue: 0.6) // Теплый серый
        } else {
            return Color.gray
        }
    }
    
    // MARK: - Helper Methods
    private func startReadingProgress() {
        withAnimation(.linear(duration: 2.0)) {
            readingProgress = 0.1
        }
    }
    
    private func updateReadingProgress(geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        let progress = max(0, min(1, -frame.minY / max(1, frame.height - UIScreen.main.bounds.height)))
        
        withAnimation(.easeOut(duration: 0.1)) {
            readingProgress = progress
        }
    }
    
    private func downloadArticle() {
        // Симулируем загрузку контента
        isDownloaded = true
        downloadedContent = """
        This is the full downloaded content of the article. In a real app, this would be fetched from the article's URL and cached locally for offline reading.
        
        The content would include the complete article text, formatted for optimal reading experience. Users could access this content even without an internet connection.
        
        Features of offline reading:
        • Full article content available offline
        • Preserved formatting and structure
        • Fast loading from local storage
        • Synchronized reading progress
        """
        
        // В реальном приложении здесь был бы API вызов
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Обновляем статью как загруженную
        }
    }
}

// MARK: - Reading Font Size
enum ReadingFontSize: CaseIterable {
    case small
    case medium
    case large
    case extraLarge
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var titleSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 24
        case .large: return 28
        case .extraLarge: return 32
        }
    }
    
    var bodySize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
}

#Preview {
    ReadingModeView(article: NewsArticle.sampleArticles[0])
}
