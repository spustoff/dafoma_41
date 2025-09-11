//
//  SimpleOnboardingView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct SimpleOnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentStep = 0
    @State private var selectedCategories: Set<String> = ["general", "technology", "business"]
    
    // Простой массив шагов без сложных вычислений
    private let steps = ["Welcome", "Categories", "Ready"]
    
    var body: some View {
        ZStack {
            // Простой черный фон без hex
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Простая иконка без анимаций
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                // Контент шага
                stepContent
                
                Spacer()
                
                // Простые кнопки
                navigationButtons
            }
            .padding(20)
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            VStack(spacing: 16) {
                Text("Welcome to NewsEaseAvi")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get news from around the world")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
        case 1:
            VStack(spacing: 20) {
                Text("Choose Categories")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Простая сетка без LazyVGrid
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        categoryButton("General", "globe")
                        categoryButton("Technology", "laptopcomputer")
                    }
                    HStack(spacing: 12) {
                        categoryButton("Business", "briefcase")
                        categoryButton("Sports", "sportscourt")
                    }
                }
            }
            
        default:
            VStack(spacing: 16) {
                Text("You're Ready!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your news feed is ready")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            Button {
                if currentStep < steps.count - 1 {
                    currentStep += 1
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentStep == steps.count - 1 ? "Get Started" : "Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.green)
                    .cornerRadius(8)
            }
            
            if currentStep > 0 && currentStep < steps.count - 1 {
                Button("Back") {
                    currentStep -= 1
                }
                .foregroundColor(.gray)
            }
        }
    }
    
    private func categoryButton(_ title: String, _ icon: String) -> some View {
        Button {
            if selectedCategories.contains(title.lowercased()) {
                selectedCategories.remove(title.lowercased())
            } else {
                selectedCategories.insert(title.lowercased())
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedCategories.contains(title.lowercased()) ? .black : .white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(selectedCategories.contains(title.lowercased()) ? .green : Color.gray.opacity(0.3))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func completeOnboarding() {
        // Простое сохранение без сложной логики
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        isOnboardingComplete = true
    }
}

#Preview {
    SimpleOnboardingView(isOnboardingComplete: .constant(false))
}
