//
//  SettingsView.swift
//  DF822
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var animateStats = false
    
    var body: some View {
        ZStack {
            // Background
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Statistics section
                        statisticsSection
                        
                        // Rewards collected
                        rewardsSection
                        
                        // Level progress
                        levelProgressSection
                        
                        // Reset button
                        resetSection
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .alert("Reset Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                gameManager.resetProgress()
            }
        } message: {
            Text("This will erase all your progress, collected rewards, and statistics. This action cannot be undone.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateStats = true
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("HighlightGlow"))
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color("HighlightGlow").opacity(0.1))
                    )
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("HighlightGlow"))
            
            Spacer()
            
            // Placeholder for balance
            Circle()
                .fill(Color.clear)
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Statistics", icon: "chart.bar.fill")
            
            VStack(spacing: 12) {
                statisticRow(
                    icon: "checkmark.circle.fill",
                    label: "Levels Completed",
                    value: "\(gameManager.stats.totalLevelsCompleted)",
                    total: "/\(gameManager.levels.count)",
                    color: Color("PrimaryAccent")
                )
                
                Divider()
                    .background(Color("HighlightGlow").opacity(0.1))
                
                statisticRow(
                    icon: "flame.fill",
                    label: "Total Attempts",
                    value: "\(gameManager.stats.totalAttempts)",
                    total: nil,
                    color: Color.orange
                )
                
                Divider()
                    .background(Color("HighlightGlow").opacity(0.1))
                
                statisticRow(
                    icon: "percent",
                    label: "Success Rate",
                    value: successRate,
                    total: nil,
                    color: Color("HighlightGlow")
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("PrimaryBackground").opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("HighlightGlow").opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
    
    private var successRate: String {
        let attempts = gameManager.stats.totalAttempts
        let completed = gameManager.stats.totalLevelsCompleted
        if attempts == 0 { return "0%" }
        let rate = Double(completed) / Double(attempts) * 100
        return String(format: "%.1f%%", rate)
    }
    
    private func statisticRow(icon: String, label: String, value: String, total: String?, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("HighlightGlow").opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 2) {
                Text(animateStats ? value : "0")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color("HighlightGlow"))
                
                if let total = total {
                    Text(total)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("HighlightGlow").opacity(0.5))
                }
            }
        }
    }
    
    // MARK: - Rewards Section
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Rewards Collected", icon: "gift.fill")
            
            HStack(spacing: 12) {
                rewardCard(
                    icon: "sparkle",
                    label: "Runes",
                    value: gameManager.stats.totalRunesCollected,
                    color: Color("PrimaryAccent")
                )
                
                rewardCard(
                    icon: "diamond.fill",
                    label: "Crystals",
                    value: gameManager.stats.totalCrystalsCollected,
                    color: Color("HighlightGlow")
                )
                
                rewardCard(
                    icon: "bolt.fill",
                    label: "Fragments",
                    value: gameManager.stats.totalStormFragments,
                    color: Color.purple
                )
            }
        }
    }
    
    private func rewardCard(icon: String, label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            Text(animateStats ? "\(value)" : "0")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color("HighlightGlow"))
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("HighlightGlow").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("PrimaryBackground").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Level Progress Section
    private var levelProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Journey Progress", icon: "map.fill")
            
            VStack(spacing: 16) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    difficultyProgressRow(difficulty)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("PrimaryBackground").opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("HighlightGlow").opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
    
    private func difficultyProgressRow(_ difficulty: Difficulty) -> some View {
        let levels = gameManager.levels(for: difficulty)
        let completed = levels.filter { $0.isCompleted }.count
        let total = levels.count
        let progress = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 14))
                    .foregroundColor(difficulty.color)
                
                Text(difficulty.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("HighlightGlow"))
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("HighlightGlow").opacity(0.7))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("HighlightGlow").opacity(0.15))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(difficulty.color)
                        .frame(width: animateStats ? geo.size.width * progress : 0)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Data", icon: "arrow.counterclockwise")
            
            Button(action: {
                showResetConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                    
                    Text("Reset All Progress")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .opacity(0.5)
                }
                .foregroundColor(Color.red)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("PrimaryAccent"))
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("HighlightGlow"))
        }
    }
}

#Preview {
    SettingsView(gameManager: GameManager.shared)
}



