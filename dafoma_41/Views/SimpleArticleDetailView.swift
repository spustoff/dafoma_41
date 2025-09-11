//
//  SimpleArticleDetailView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI
import SafariServices

struct SimpleArticleDetailView: View {
    let article: NewsArticle
    @Environment(\.dismiss) private var dismiss
    @State private var showingSafari = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Заголовок статьи
                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // Информация о статье
                        HStack {
                            Text(article.source.name)
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Text(article.timeAgo)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        // Описание
                        Text(article.description)
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        // Контент (если есть)
                        if let content = article.content {
                            Text(content)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                        
                        // Кнопка открытия в Safari
                        Button {
                            showingSafari = true
                        } label: {
                            Text("Read Full Article")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(.green)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showingSafari) {
            SafariView(url: article.url)
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredBarTintColor = UIColor.black
        safariVC.preferredControlTintColor = UIColor.green
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    SimpleArticleDetailView(article: NewsArticle.sampleArticles[0])
}
