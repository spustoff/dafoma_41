//
//  SettingsView.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var preferencesManager: UserPreferencesManager
    @ObservedObject private var locationService: LocationService
    @State private var showingDeleteConfirmation = false
    @State private var showingStats = false
    
    init(preferencesManager: UserPreferencesManager, locationService: LocationService) {
        self.preferencesManager = preferencesManager
        self.locationService = locationService
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Заголовок
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding()
                
                // Расширенный список настроек
                List {
                    // Основные настройки
                    Section("Appearance") {
                        Toggle("Dark Mode", isOn: $preferencesManager.preferences.darkMode)
                        
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Picker("Font Size", selection: $preferencesManager.preferences.fontSize) {
                                ForEach(FontSize.allCases, id: \.self) { size in
                                    Text(size.displayName).tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    
                    // Новости
                    Section("News") {
                        Toggle("Location News", isOn: $preferencesManager.preferences.locationBasedNews)
                        Toggle("Push Notifications", isOn: $preferencesManager.preferences.pushNotifications)
                        
                        HStack {
                            Text("Refresh Interval")
                            Spacer()
                            Picker("Refresh", selection: $preferencesManager.preferences.refreshInterval) {
                                ForEach(RefreshInterval.allCases, id: \.self) { interval in
                                    Text(interval.displayName).tag(interval)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    
                    // Статистика
                    Section("Analytics") {
                        Button("View Reading Stats") {
                            showingStats = true
                        }
                        .foregroundColor(.green)
                        
                        Button("Clear Search History") {
                            // Очистить историю поиска
                        }
                        .foregroundColor(.orange)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    
                    // Аккаунт
                    Section("Account") {
                        Button("Reset Settings") {
                            preferencesManager.reset()
                        }
                        .foregroundColor(.red)
                        
                        Button("Delete Account") {
                            showingDeleteConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                }
                .listStyle(InsetGroupedListStyle())
                .background(Color.black)
            }
        }
        .sheet(isPresented: $showingStats) {
            ReadingStatsView()
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                preferencesManager.reset()
            }
        }
    }
}

#Preview {
    let preferencesManager = UserPreferencesManager()
    let locationService = LocationService()
    return SettingsView(preferencesManager: preferencesManager, locationService: locationService)
}