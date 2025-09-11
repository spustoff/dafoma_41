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
    
    init(preferencesManager: UserPreferencesManager, locationService: LocationService) {
        self.preferencesManager = preferencesManager
        self.locationService = locationService
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Простой заголовок
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding()
                
                // Простой список настроек
                List {
                    Section {
                        Toggle("Dark Mode", isOn: $preferencesManager.preferences.darkMode)
                        Toggle("Location News", isOn: $preferencesManager.preferences.locationBasedNews)
                        Toggle("Notifications", isOn: $preferencesManager.preferences.pushNotifications)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    
                    Section {
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