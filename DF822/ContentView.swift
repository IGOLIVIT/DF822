//
//  ContentView.swift
//  DF822
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var gameManager = GameManager.shared
    @State private var showOnboarding: Bool = false
    @State private var isInitialized = false
    
    var body: some View {
        ZStack {
            if isInitialized {
                if showOnboarding {
                    OnboardingView(gameManager: gameManager, showOnboarding: $showOnboarding)
                        .transition(.opacity)
                } else {
                    HomeView(gameManager: gameManager)
                        .transition(.opacity)
                }
            } else {
                // Launch screen
                launchScreen
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: isInitialized)
        .onAppear {
            // Short delay for launch screen effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showOnboarding = !gameManager.stats.hasCompletedOnboarding
                withAnimation {
                    isInitialized = true
                }
            }
        }
    }
    
    private var launchScreen: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            // Central orb animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("HighlightGlow").opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                // Core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color("HighlightGlow"),
                                Color("PrimaryAccent").opacity(0.5)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: Color("HighlightGlow"), radius: 20)
            }
        }
    }
}

#Preview {
    ContentView()
}
