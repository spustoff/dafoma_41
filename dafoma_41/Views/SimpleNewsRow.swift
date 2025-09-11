//
//  SimpleNewsRow.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct SimpleNewsRow: View {
    let article: NewsArticle
    let onTap: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            onTap()
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
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
}

#Preview {
    List {
        SimpleNewsRow(article: NewsArticle.sampleArticles[0]) {
            print("Tapped")
        }
    }
    .listStyle(PlainListStyle())
    .background(Color.black)
}
