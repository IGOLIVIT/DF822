//
//  HomeView.swift
//  DF822
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var gameManager: GameManager
    @State private var animateGlow = false
    @State private var showLevelSelection = false
    @State private var showTutorial = false
    @State private var showSettings = false
    
    // Pre-computed background circle positions
    private let backgroundCircles: [(x: CGFloat, y: CGFloat, size: CGFloat)]
    
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        // Generate consistent positions based on index
        var circles: [(x: CGFloat, y: CGFloat, size: CGFloat)] = []
        for i in 0..<15 {
            let x = CGFloat((i * 67 + 23) % 100) / 100.0
            let y = CGFloat((i * 43 + 17) % 100) / 100.0
            let size = CGFloat(100 + (i * 31) % 200)
            circles.append((x: x, y: y, size: size))
        }
        self.backgroundCircles = circles
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Top spacer for visual balance
                        Spacer().frame(height: 20)
                        
                        // Central orb with progress
                        centralOrbView
                        
                        // Stats overview
                        statsOverview
                        
                        // Main navigation buttons
                        mainButtons
                        
                        // Secondary navigation
                        secondaryButtons
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showLevelSelection) {
            LevelSelectionView(gameManager: gameManager)
        }
        .sheet(isPresented: $showTutorial) {
            TutorialView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(gameManager: gameManager)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color("PrimaryBackground"),
                    Color.black.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle texture pattern with consistent positions
            GeometryReader { geometry in
                ForEach(0..<backgroundCircles.count, id: \.self) { i in
                    Circle()
                        .fill(Color("HighlightGlow").opacity(0.03))
                        .frame(width: backgroundCircles[i].size)
                        .position(
                            x: backgroundCircles[i].x * geometry.size.width,
                            y: backgroundCircles[i].y * geometry.size.height
                        )
                        .blur(radius: 30)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Central Orb
    private var centralOrbView: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        Color("HighlightGlow").opacity(0.1 - Double(i) * 0.03),
                        lineWidth: 2
                    )
                    .frame(width: 180 + CGFloat(i) * 40, height: 180 + CGFloat(i) * 40)
                    .scaleEffect(animateGlow ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .delay(Double(i) * 0.2)
                        .repeatForever(autoreverses: true),
                        value: animateGlow
                    )
            }
            
            // Main orb background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("HighlightGlow").opacity(0.3),
                            Color("PrimaryBackground").opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
            
            // Inner core
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
                        endRadius: 35
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(color: Color("HighlightGlow").opacity(0.8), radius: 20)
                .scaleEffect(animateGlow ? 1.1 : 1.0)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    LinearGradient(
                        colors: [Color("PrimaryAccent"), Color("HighlightGlow")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
        }
        .frame(height: 280)
    }
    
    private var progressValue: CGFloat {
        let totalLevels = gameManager.levels.count
        let completedLevels = gameManager.stats.totalLevelsCompleted
        return totalLevels > 0 ? CGFloat(completedLevels) / CGFloat(totalLevels) : 0
    }
    
    // MARK: - Stats Overview
    private var statsOverview: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "sparkle",
                value: "\(gameManager.stats.totalRunesCollected)",
                label: "Runes",
                color: Color("PrimaryAccent")
            )
            
            Divider()
                .frame(height: 40)
                .background(Color("HighlightGlow").opacity(0.3))
            
            statItem(
                icon: "diamond.fill",
                value: "\(gameManager.stats.totalCrystalsCollected)",
                label: "Crystals",
                color: Color("HighlightGlow")
            )
            
            Divider()
                .frame(height: 40)
                .background(Color("HighlightGlow").opacity(0.3))
            
            statItem(
                icon: "bolt.fill",
                value: "\(gameManager.stats.totalStormFragments)",
                label: "Fragments",
                color: Color.purple
            )
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("PrimaryBackground").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("HighlightGlow").opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("HighlightGlow"))
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color("HighlightGlow").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Main Buttons
    private var mainButtons: some View {
        VStack(spacing: 16) {
            // Play button
            Button(action: {
                showLevelSelection = true
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22))
                    
                    Text("Enter the Storm")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(Color("PrimaryBackground"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("PrimaryAccent"))
                        .shadow(color: Color("PrimaryAccent").opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            
            // Quick Play - continue from last unlocked level
            if let nextLevel = getNextLevel() {
                Button(action: {
                    gameManager.currentLevel = nextLevel
                    showLevelSelection = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                            Text(nextLevel.displayName)
                                .font(.system(size: 12, weight: .regular))
                                .opacity(0.7)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(Color("HighlightGlow"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("PrimaryBackground").opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("HighlightGlow").opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    private func getNextLevel() -> GameLevel? {
        // Find first incomplete unlocked level
        return gameManager.levels.first { $0.isUnlocked && !$0.isCompleted }
            ?? gameManager.levels.first { $0.isUnlocked }
    }
    
    // MARK: - Secondary Buttons
    private var secondaryButtons: some View {
        HStack(spacing: 16) {
            secondaryButton(
                icon: "book.fill",
                label: "Tutorial",
                action: { showTutorial = true }
            )
            
            secondaryButton(
                icon: "gearshape.fill",
                label: "Settings",
                action: { showSettings = true }
            )
        }
    }
    
    private func secondaryButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(Color("HighlightGlow"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("PrimaryBackground").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color("HighlightGlow").opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    HomeView(gameManager: GameManager.shared)
}
