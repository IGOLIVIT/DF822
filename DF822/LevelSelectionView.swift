//
//  LevelSelectionView.swift
//  DF822
//

import SwiftUI

struct LevelSelectionView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var levelToPlay: GameLevel?
    @State private var showGame = false
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Background
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Difficulty tabs
                difficultyTabs
                
                // Levels grid
                ScrollView(showsIndicators: false) {
                    levelsGrid
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                }
            }
        }
        .fullScreenCover(isPresented: $showGame) {
            if let level = levelToPlay {
                GameView(gameManager: gameManager, level: level)
            }
        }
        .onAppear {
            // Ensure animation triggers
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateIn = true
                }
            }
        }
        .onChange(of: showGame) { isShowing in
            // Clear levelToPlay when game is dismissed
            if !isShowing {
                levelToPlay = nil
            }
        }
    }
    
    private func selectLevel(_ level: GameLevel) {
        levelToPlay = level
        // Small delay to ensure levelToPlay is set before presenting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            showGame = true
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
            
            Text("Select Level")
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
    
    // MARK: - Difficulty Tabs
    private var difficultyTabs: some View {
        HStack(spacing: 8) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                difficultyTab(difficulty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func difficultyTab(_ difficulty: Difficulty) -> some View {
        let isSelected = selectedDifficulty == difficulty
        let unlockedLevels = gameManager.levels(for: difficulty).filter { $0.isUnlocked }
        let isAvailable = !unlockedLevels.isEmpty
        
        return Button(action: {
            if isAvailable {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDifficulty = difficulty
                }
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 18))
                
                Text(difficulty.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? Color("PrimaryBackground") : (isAvailable ? difficulty.color : difficulty.color.opacity(0.4)))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? difficulty.color : Color("PrimaryBackground").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(difficulty.color.opacity(isAvailable ? 0.4 : 0.2), lineWidth: 1)
                    )
            )
        }
        .disabled(!isAvailable)
    }
    
    // MARK: - Levels Grid
    private var levelsGrid: some View {
        let levels = gameManager.levels(for: selectedDifficulty)
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                levelCard(level: level, index: index)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.1),
                        value: animateIn
                    )
            }
        }
    }
    
    private func levelCard(level: GameLevel, index: Int) -> some View {
        VStack(spacing: 12) {
            // Level icon/number
            ZStack {
                if level.isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    selectedDifficulty.color.opacity(0.3),
                                    selectedDifficulty.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    if level.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color("PrimaryAccent"))
                    } else {
                        Text("\(level.levelNumber)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color("HighlightGlow"))
                    }
                } else {
                    Circle()
                        .fill(Color("HighlightGlow").opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color("HighlightGlow").opacity(0.4))
                }
            }
            
            // Level name
            Text("Level \(level.levelNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(level.isUnlocked ? Color("HighlightGlow") : Color("HighlightGlow").opacity(0.4))
            
            // Stats or locked text
            if level.isUnlocked {
                if level.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("\(level.bestScore)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color("PrimaryAccent"))
                } else {
                    Text("Ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color("HighlightGlow").opacity(0.6))
                }
            } else {
                Text("Locked")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color("HighlightGlow").opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("PrimaryBackground").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            level.isUnlocked
                                ? selectedDifficulty.color.opacity(0.3)
                                : Color("HighlightGlow").opacity(0.1),
                            lineWidth: 1
                        )
                )
                .shadow(color: level.isUnlocked ? selectedDifficulty.color.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if level.isUnlocked {
                selectLevel(level)
            }
        }
    }
}

#Preview {
    LevelSelectionView(gameManager: GameManager.shared)
}
