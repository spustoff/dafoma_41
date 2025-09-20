//
//  ReadingStatsView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct ReadingStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stats = ReadingStats()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Заголовок
                        HStack {
                            Text("Reading Statistics")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding()
                        
                        // Основная статистика
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatsCard(
                                title: "Articles Read",
                                value: "\(stats.totalArticlesRead)",
                                icon: "book.fill",
                                color: .green
                            )
                            
                            StatsCard(
                                title: "Reading Streak",
                                value: "\(stats.currentStreak) days",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatsCard(
                                title: "Today's Goal",
                                value: "\(stats.articlesReadToday)/\(stats.weeklyReadingGoal)",
                                icon: "target",
                                color: .blue
                            )
                            
                            StatsCard(
                                title: "Favorite Topic",
                                value: stats.topCategory.capitalized,
                                icon: "heart.fill",
                                color: .red
                            )
                        }
                        .padding(.horizontal)
                        
                        // Прогресс бар
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekly Progress")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ProgressView(value: stats.weeklyProgress)
                                .tint(.green)
                                .background(Color.gray.opacity(0.3))
                            
                            Text("\(Int(stats.weeklyProgress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Категории
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reading by Category")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(stats.favoriteCategories.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                                HStack {
                                    Image(systemName: getCategoryIcon(category))
                                        .foregroundColor(.green)
                                        .frame(width: 20)
                                    
                                    Text(category.capitalized)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "ReadingStats"),
           let loadedStats = try? JSONDecoder().decode(ReadingStats.self, from: data) {
            stats = loadedStats
        }
    }
    
    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "technology": return "laptopcomputer"
        case "business": return "briefcase"
        case "sports": return "sportscourt"
        case "health": return "heart"
        case "science": return "atom"
        case "entertainment": return "tv"
        default: return "globe"
        }
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ReadingStatsView()
}

