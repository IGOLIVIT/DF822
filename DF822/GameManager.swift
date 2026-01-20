//
//  GameManager.swift
//  DF822
//

import SwiftUI
import Combine

// MARK: - Level Model
struct GameLevel: Identifiable, Codable {
    let id: Int
    let difficulty: Difficulty
    let levelNumber: Int
    var isUnlocked: Bool
    var isCompleted: Bool
    var bestScore: Int
    var runesCollected: Int
    var crystalsCollected: Int
    var stormFragmentsCollected: Int
    
    var displayName: String {
        "\(difficulty.rawValue) \(levelNumber)"
    }
    
    var requiredRunes: Int {
        switch difficulty {
        case .easy: return 3 + levelNumber
        case .normal: return 5 + levelNumber
        case .hard: return 7 + levelNumber
        }
    }
    
    var obstacleSpeed: Double {
        switch difficulty {
        case .easy: return 2.0 + Double(levelNumber) * 0.3
        case .normal: return 3.0 + Double(levelNumber) * 0.4
        case .hard: return 4.0 + Double(levelNumber) * 0.5
        }
    }
    
    var obstacleCount: Int {
        switch difficulty {
        case .easy: return 4 + levelNumber
        case .normal: return 6 + levelNumber
        case .hard: return 8 + levelNumber
        }
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Calm"
    case normal = "Surge"
    case hard = "Tempest"
    
    var color: Color {
        switch self {
        case .easy: return Color("HighlightGlow")
        case .normal: return Color("PrimaryAccent")
        case .hard: return Color.red.opacity(0.8)
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "wind"
        case .normal: return "cloud.bolt"
        case .hard: return "hurricane"
        }
    }
}

// MARK: - Player Stats
struct PlayerStats: Codable {
    var totalLevelsCompleted: Int = 0
    var totalAttempts: Int = 0
    var totalRunesCollected: Int = 0
    var totalCrystalsCollected: Int = 0
    var totalStormFragments: Int = 0
    var hasCompletedOnboarding: Bool = false
    var currentGlowLevel: Int = 1
    var currentBackgroundLevel: Int = 1
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var levels: [GameLevel] = []
    @Published var stats: PlayerStats = PlayerStats()
    @Published var currentLevel: GameLevel?
    
    private let levelsKey = "gameLevels"
    private let statsKey = "playerStats"
    
    private let levelsPerDifficulty = 8
    
    init() {
        loadData()
        if levels.isEmpty {
            generateLevels()
        } else {
            // Check if we need to add more levels (when updating from older version)
            updateLevelsIfNeeded()
        }
    }
    
    private func updateLevelsIfNeeded() {
        let expectedLevelCount = Difficulty.allCases.count * levelsPerDifficulty
        if levels.count < expectedLevelCount {
            // Generate missing levels
            var maxId = levels.map { $0.id }.max() ?? -1
            
            for difficulty in Difficulty.allCases {
                let existingLevels = levels.filter { $0.difficulty == difficulty }
                let currentCount = existingLevels.count
                
                if currentCount < levelsPerDifficulty {
                    for levelNum in (currentCount + 1)...levelsPerDifficulty {
                        maxId += 1
                        // Check if previous level in this difficulty is completed to unlock
                        let previousCompleted = existingLevels.last?.isCompleted ?? false
                        let isUnlocked = previousCompleted
                        
                        levels.append(GameLevel(
                            id: maxId,
                            difficulty: difficulty,
                            levelNumber: levelNum,
                            isUnlocked: isUnlocked,
                            isCompleted: false,
                            bestScore: 0,
                            runesCollected: 0,
                            crystalsCollected: 0,
                            stormFragmentsCollected: 0
                        ))
                    }
                }
            }
            
            // Sort levels by difficulty and level number
            levels.sort { 
                if $0.difficulty == $1.difficulty {
                    return $0.levelNumber < $1.levelNumber
                }
                return Difficulty.allCases.firstIndex(of: $0.difficulty)! < Difficulty.allCases.firstIndex(of: $1.difficulty)!
            }
            
            saveData()
        }
    }
    
    private func generateLevels() {
        var allLevels: [GameLevel] = []
        var id = 0
        
        for difficulty in Difficulty.allCases {
            for levelNum in 1...levelsPerDifficulty {
                let isUnlocked = difficulty == .easy && levelNum == 1
                allLevels.append(GameLevel(
                    id: id,
                    difficulty: difficulty,
                    levelNumber: levelNum,
                    isUnlocked: isUnlocked,
                    isCompleted: false,
                    bestScore: 0,
                    runesCollected: 0,
                    crystalsCollected: 0,
                    stormFragmentsCollected: 0
                ))
                id += 1
            }
        }
        
        levels = allLevels
        saveData()
    }
    
    func levels(for difficulty: Difficulty) -> [GameLevel] {
        levels.filter { $0.difficulty == difficulty }
    }
    
    func unlockNextLevel(after level: GameLevel) {
        guard let index = levels.firstIndex(where: { $0.id == level.id }) else { return }
        
        if index + 1 < levels.count {
            levels[index + 1].isUnlocked = true
        }
        
        saveData()
    }
    
    func completeLevel(_ level: GameLevel, runes: Int, crystals: Int, fragments: Int, score: Int) {
        guard let index = levels.firstIndex(where: { $0.id == level.id }) else { return }
        
        let wasCompleted = levels[index].isCompleted
        let previousRunes = levels[index].runesCollected
        let previousCrystals = levels[index].crystalsCollected
        let previousFragments = levels[index].stormFragmentsCollected
        
        // Update level best scores (keep maximum)
        let newBestRunes = max(previousRunes, runes)
        let newBestCrystals = max(previousCrystals, crystals)
        let newBestFragments = max(previousFragments, fragments)
        
        levels[index].isCompleted = true
        levels[index].runesCollected = newBestRunes
        levels[index].crystalsCollected = newBestCrystals
        levels[index].stormFragmentsCollected = newBestFragments
        levels[index].bestScore = max(levels[index].bestScore, score)
        
        if !wasCompleted {
            stats.totalLevelsCompleted += 1
        }
        
        // Only add the DIFFERENCE (new rewards earned above previous best)
        let runesDiff = max(0, newBestRunes - previousRunes)
        let crystalsDiff = max(0, newBestCrystals - previousCrystals)
        let fragmentsDiff = max(0, newBestFragments - previousFragments)
        
        stats.totalRunesCollected += runesDiff
        stats.totalCrystalsCollected += crystalsDiff
        stats.totalStormFragments += fragmentsDiff
        
        updateVisualUpgrades()
        unlockNextLevel(after: level)
        saveData()
    }
    
    func recordAttempt() {
        stats.totalAttempts += 1
        saveData()
    }
    
    func completeOnboarding() {
        stats.hasCompletedOnboarding = true
        saveData()
    }
    
    private func updateVisualUpgrades() {
        let totalRewards = stats.totalRunesCollected + stats.totalCrystalsCollected + stats.totalStormFragments
        stats.currentGlowLevel = min(5, 1 + totalRewards / 50)
        stats.currentBackgroundLevel = min(3, 1 + totalRewards / 100)
    }
    
    func resetProgress() {
        stats = PlayerStats()
        generateLevels()
    }
    
    private func saveData() {
        if let encodedLevels = try? JSONEncoder().encode(levels) {
            UserDefaults.standard.set(encodedLevels, forKey: levelsKey)
        }
        if let encodedStats = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encodedStats, forKey: statsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: levelsKey),
           let decoded = try? JSONDecoder().decode([GameLevel].self, from: data) {
            levels = decoded
        }
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(PlayerStats.self, from: data) {
            stats = decoded
        }
    }
}

