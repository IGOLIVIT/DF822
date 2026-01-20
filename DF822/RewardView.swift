//
//  RewardView.swift
//  DF822
//

import SwiftUI

struct RewardView: View {
    @ObservedObject var gameManager: GameManager
    let level: GameLevel
    let runes: Int
    let crystals: Int
    let fragments: Int
    let score: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false
    @State private var animateRewards = false
    @State private var animateGlow = false
    @State private var showUpgrade = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    // Success icon
                    successIcon
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -30)
                    
                    // Level completed text
                    VStack(spacing: 8) {
                        Text(level.difficulty.rawValue.uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(level.difficulty.color)
                        
                        Text("Level \(level.levelNumber) Complete")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color("HighlightGlow"))
                    }
                    .padding(.top, 24)
                    .opacity(animateIn ? 1 : 0)
                    
                    // Score
                    scoreDisplay
                        .padding(.top, 20)
                        .opacity(animateRewards ? 1 : 0)
                        .offset(y: animateRewards ? 0 : 20)
                    
                    // Rewards collected
                    rewardsDisplay
                        .padding(.top, 30)
                        .opacity(animateRewards ? 1 : 0)
                    
                    // Upgrade notification
                    if showUpgrade {
                        upgradeNotification
                            .padding(.top, 24)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer().frame(height: 40)
                    
                    // Buttons
                    buttonsView
                        .opacity(animateIn ? 1 : 0)
                    
                    Spacer().frame(height: 50)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            // Radial glow
            RadialGradient(
                colors: [
                    Color("PrimaryAccent").opacity(0.2),
                    Color("PrimaryBackground"),
                    Color.black.opacity(0.5)
                ],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            // Floating particles with consistent positions
            ForEach(0..<15, id: \.self) { i in
                Circle()
                    .fill(Color("HighlightGlow").opacity(0.3))
                    .frame(width: CGFloat(3 + i % 6))
                    .offset(
                        x: CGFloat(-150 + (i * 23) % 300),
                        y: CGFloat(-300 + (i * 47) % 600) + (animateGlow ? -50 : 50)
                    )
                    .animation(
                        .easeInOut(duration: Double(2 + i % 3))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i % 10) / 10.0),
                        value: animateGlow
                    )
            }
        }
    }
    
    // MARK: - Success Icon
    private var successIcon: some View {
        ZStack {
            // Outer rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color("PrimaryAccent").opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                    .frame(width: 140 + CGFloat(i) * 30, height: 140 + CGFloat(i) * 30)
                    .scaleEffect(animateGlow ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .delay(Double(i) * 0.1)
                        .repeatForever(autoreverses: true),
                        value: animateGlow
                    )
            }
            
            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("PrimaryAccent").opacity(0.4),
                            Color("PrimaryAccent").opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(Color("PrimaryAccent"))
                .scaleEffect(animateIn ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: animateIn)
        }
    }
    
    // MARK: - Score Display
    private var scoreDisplay: some View {
        VStack(spacing: 6) {
            Text("Score")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("HighlightGlow").opacity(0.6))
            
            Text("\(score)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(Color("HighlightGlow"))
        }
    }
    
    // MARK: - Rewards Display
    private var rewardsDisplay: some View {
        HStack(spacing: 20) {
            rewardItem(
                icon: "sparkle",
                count: runes,
                label: "Runes",
                color: Color("PrimaryAccent"),
                delay: 0
            )
            
            rewardItem(
                icon: "diamond.fill",
                count: crystals,
                label: "Crystals",
                color: Color("HighlightGlow"),
                delay: 0.1
            )
            
            rewardItem(
                icon: "bolt.fill",
                count: fragments,
                label: "Fragments",
                color: Color.purple,
                delay: 0.2
            )
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("PrimaryBackground").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("HighlightGlow").opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func rewardItem(icon: String, count: Int, label: String, color: Color, delay: Double) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .scaleEffect(animateRewards ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.5 + delay), value: animateRewards)
            }
            
            Text("+\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("HighlightGlow"))
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color("HighlightGlow").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Upgrade Notification
    private var upgradeNotification: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color("PrimaryAccent"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Visual Upgrade!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("HighlightGlow"))
                
                Text("Your sphere glows brighter")
                    .font(.system(size: 12))
                    .foregroundColor(Color("HighlightGlow").opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("PrimaryAccent").opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("PrimaryAccent").opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Buttons
    private var buttonsView: some View {
        VStack(spacing: 12) {
            // Continue button - returns to level selection
            Button(action: { dismiss() }) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color("PrimaryBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("PrimaryAccent"))
                            .shadow(color: Color("PrimaryAccent").opacity(0.4), radius: 10, x: 0, y: 4)
                    )
            }
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6)) {
            animateIn = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                animateRewards = true
            }
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animateGlow = true
        }
        
        // Check for upgrades - show if crossed a 50-reward threshold
        let previousTotal = gameManager.stats.totalRunesCollected + gameManager.stats.totalCrystalsCollected + gameManager.stats.totalStormFragments - runes - crystals - fragments
        let currentTotal = previousTotal + runes + crystals + fragments
        
        if currentTotal >= 50 && (previousTotal / 50) < (currentTotal / 50) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showUpgrade = true
                }
            }
        }
    }
}

#Preview {
    RewardView(
        gameManager: GameManager.shared,
        level: GameLevel(
            id: 0,
            difficulty: .easy,
            levelNumber: 1,
            isUnlocked: true,
            isCompleted: true,
            bestScore: 150,
            runesCollected: 5,
            crystalsCollected: 2,
            stormFragmentsCollected: 1
        ),
        runes: 5,
        crystals: 2,
        fragments: 1,
        score: 150
    )
}
