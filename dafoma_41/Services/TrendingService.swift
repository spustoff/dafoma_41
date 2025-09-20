//
//  TrendingService.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import Combine

class TrendingService: ObservableObject {
    @Published var trendingTopics: [TrendingTopic] = []
    @Published var hotArticles: [NewsArticle] = []
    @Published var breakingNews: [NewsArticle] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Trending Algorithm
    func analyzeTrending(articles: [NewsArticle]) {
        // Анализируем ключевые слова и темы
        let keywordFrequency = extractKeywords(from: articles)
        let topics = generateTrendingTopics(from: keywordFrequency)
        
        // Обновляем trending статьи
        let updatedArticles = assignTrendingScores(articles: articles, keywords: keywordFrequency)
        
        DispatchQueue.main.async { [weak self] in
            self?.trendingTopics = topics
            self?.hotArticles = self?.getHotArticles(from: updatedArticles) ?? []
            self?.breakingNews = self?.getBreakingNews(from: updatedArticles) ?? []
        }
    }
    
    private func extractKeywords(from articles: [NewsArticle]) -> [String: Int] {
        var keywords: [String: Int] = [:]
        
        for article in articles {
            let text = "\(article.title) \(article.description)".lowercased()
            let words = text.components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count > 3 } // Только слова длиннее 3 символов
                .filter { !commonWords.contains($0) } // Исключаем частые слова
            
            for word in words {
                keywords[word, default: 0] += 1
            }
        }
        
        return keywords
    }
    
    private func generateTrendingTopics(from keywords: [String: Int]) -> [TrendingTopic] {
        return keywords
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { keyword, count in
                TrendingTopic(
                    keyword: keyword.capitalized,
                    count: count,
                    trendingScore: calculateTrendingScore(count: count, totalArticles: 100),
                    category: determineCategoryForKeyword(keyword)
                )
            }
    }
    
    private func assignTrendingScores(articles: [NewsArticle], keywords: [String: Int]) -> [NewsArticle] {
        return articles.map { article in
            var updatedArticle = article
            let score = calculateArticleTrendingScore(article: article, keywords: keywords)
            
            updatedArticle.trendingScore = score
            updatedArticle.isHot = score > 7.0
            updatedArticle.isTrending = score > 5.0
            updatedArticle.isBreaking = isRecentAndPopular(article: article, score: score)
            
            return updatedArticle
        }
    }
    
    private func calculateTrendingScore(count: Int, totalArticles: Int) -> Double {
        let frequency = Double(count) / Double(totalArticles)
        return min(frequency * 100, 10.0) // Максимум 10 баллов
    }
    
    private func calculateArticleTrendingScore(article: NewsArticle, keywords: [String: Int]) -> Double {
        let text = "\(article.title) \(article.description)".lowercased()
        var score = 0.0
        
        // Очки за ключевые слова
        for (keyword, frequency) in keywords {
            if text.contains(keyword) {
                score += Double(frequency) * 0.1
            }
        }
        
        // Бонус за свежесть
        let hoursOld = Date().timeIntervalSince(article.publishedAt) / 3600
        if hoursOld < 1 {
            score += 3.0 // Очень свежие новости
        } else if hoursOld < 6 {
            score += 2.0 // Свежие новости
        } else if hoursOld < 24 {
            score += 1.0 // Новости дня
        }
        
        return score
    }
    
    private func isRecentAndPopular(article: NewsArticle, score: Double) -> Bool {
        let hoursOld = Date().timeIntervalSince(article.publishedAt) / 3600
        return hoursOld < 2 && score > 6.0 // Менее 2 часов и высокий рейтинг
    }
    
    private func getHotArticles(from articles: [NewsArticle]) -> [NewsArticle] {
        return articles
            .filter { $0.isHot }
            .sorted { $0.trendingScore > $1.trendingScore }
            .prefix(10)
            .map { $0 }
    }
    
    private func getBreakingNews(from articles: [NewsArticle]) -> [NewsArticle] {
        return articles
            .filter { $0.isBreaking }
            .sorted { $0.publishedAt > $1.publishedAt }
            .prefix(5)
            .map { $0 }
    }
    
    private func determineCategoryForKeyword(_ keyword: String) -> NewsCategory {
        let techWords = ["technology", "ai", "tech", "digital", "computer", "software"]
        let businessWords = ["business", "economy", "market", "finance", "stock"]
        let sportsWords = ["sports", "football", "basketball", "game", "team"]
        
        if techWords.contains(keyword.lowercased()) {
            return .technology
        } else if businessWords.contains(keyword.lowercased()) {
            return .business
        } else if sportsWords.contains(keyword.lowercased()) {
            return .sports
        }
        
        return .general
    }
    
    // Частые слова для исключения
    private let commonWords = Set([
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use"
    ])
}

// MARK: - Trending Topic Model
struct TrendingTopic: Identifiable, Codable {
    let id = UUID()
    let keyword: String
    let count: Int
    let trendingScore: Double
    let category: NewsCategory
    
    var displayText: String {
        return "#\(keyword)"
    }
    
    var popularityLevel: TrendingLevel {
        if trendingScore > 8.0 {
            return .hot
        } else if trendingScore > 5.0 {
            return .trending
        } else {
            return .normal
        }
    }
}

enum TrendingLevel {
    case hot
    case trending
    case normal
    
    var emoji: String {
        switch self {
        case .hot: return "🔥"
        case .trending: return "📈"
        case .normal: return ""
        }
    }
    
    var color: String {
        switch self {
        case .hot: return "#e6053a"
        case .trending: return "#d17305"
        case .normal: return "#888888"
        }
    }
}
