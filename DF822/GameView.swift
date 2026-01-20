//
//  GameView.swift
//  DF822
//

import SwiftUI

// MARK: - Game Objects
struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var isRotating: Bool
    var rotation: Double = 0
    var speed: CGFloat = 1.0
}

struct Collectible: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var type: CollectibleType
    var isCollected: Bool = false
    var pulsePhase: Double = 0
}

enum CollectibleType: CaseIterable {
    case rune
    case crystal
    case fragment
    
    var color: Color {
        switch self {
        case .rune: return Color("PrimaryAccent")
        case .crystal: return Color("HighlightGlow")
        case .fragment: return Color.purple
        }
    }
    
    var icon: String {
        switch self {
        case .rune: return "sparkle"
        case .crystal: return "diamond.fill"
        case .fragment: return "bolt.fill"
        }
    }
}

// MARK: - Game State
enum GameState {
    case ready
    case playing
    case paused
    case completed
    case failed
}

// MARK: - Game View
struct GameView: View {
    @ObservedObject var gameManager: GameManager
    let level: GameLevel
    @Environment(\.dismiss) private var dismiss
    
    @State private var gameState: GameState = .ready
    @State private var playerY: CGFloat = 0
    @State private var playerVelocity: CGFloat = 0
    @State private var isHolding = false
    @State private var obstacles: [Obstacle] = []
    @State private var collectibles: [Collectible] = []
    @State private var scrollOffset: CGFloat = 0
    @State private var runesCollected = 0
    @State private var crystalsCollected = 0
    @State private var fragmentsCollected = 0
    @State private var score = 0
    @State private var showReward = false
    @State private var animatePulse = false
    @State private var screenSize: CGSize = .zero
    @State private var levelProgress: CGFloat = 0
    @State private var gameTimer: Timer?
    @State private var collisionFlash = false
    
    private let playerSize: CGFloat = 30
    private let gravity: CGFloat = 0.4
    private let liftForce: CGFloat = -0.8
    private let maxVelocity: CGFloat = 8
    private let levelLength: CGFloat = 3000
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layers
                gameBackground
                
                // Game area
                gameArea(geometry: geometry)
                
                // UI Overlay
                gameUI
                
                // Ready overlay
                if gameState == .ready {
                    readyOverlay
                }
                
                // Paused overlay
                if gameState == .paused {
                    pausedOverlay
                }
                
                // Failed overlay
                if gameState == .failed {
                    failedOverlay
                }
                
                // Collision flash
                if collisionFlash {
                    Color.red.opacity(0.3)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                screenSize = geometry.size
                setupLevel()
            }
            .onDisappear {
                // CRITICAL: Clean up timer when view disappears
                gameTimer?.invalidate()
                gameTimer = nil
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showReward) {
            RewardView(
                gameManager: gameManager,
                level: level,
                runes: runesCollected,
                crystals: crystalsCollected,
                fragments: fragmentsCollected,
                score: score
            )
        }
        .onChange(of: showReward) { isShowing in
            // When RewardView is dismissed, also dismiss GameView
            if !isShowing && gameState == .completed {
                dismiss()
            }
        }
    }
    
    // MARK: - Background
    private var gameBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color("PrimaryBackground"),
                    Color("PrimaryBackground").opacity(0.9),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Storm clouds effect with consistent positions
            ForEach(0..<8, id: \.self) { i in
                Ellipse()
                    .fill(Color("HighlightGlow").opacity(0.03 + Double(gameManager.stats.currentBackgroundLevel) * 0.01))
                    .frame(width: 200, height: 100)
                    .offset(
                        x: CGFloat(i % 4) * 100 - 150 - scrollOffset * 0.1,
                        y: CGFloat(i / 4) * 200 - 200
                    )
                    .blur(radius: 40)
            }
            
            // Lightning flickers for harder levels
            if level.difficulty != .easy && animatePulse {
                Rectangle()
                    .fill(Color("HighlightGlow").opacity(0.05))
                    .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Game Area
    private func gameArea(geometry: GeometryProxy) -> some View {
        ZStack {
            // Obstacles - use position instead of offset for consistent coordinates
            ForEach(obstacles) { obstacle in
                obstacleView(obstacle)
                    .position(
                        x: obstacle.x - scrollOffset + 80, // Align with player's X reference
                        y: screenSize.height / 2 + obstacle.y
                    )
            }
            
            // Collectibles - use position instead of offset
            ForEach(collectibles) { collectible in
                if !collectible.isCollected {
                    collectibleView(collectible)
                        .position(
                            x: collectible.x - scrollOffset + 80, // Align with player's X reference
                            y: screenSize.height / 2 + collectible.y
                        )
                }
            }
            
            // Player
            playerView
                .position(x: 80, y: screenSize.height / 2 + playerY)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if gameState == .playing {
                        isHolding = true
                    }
                }
                .onEnded { _ in
                    isHolding = false
                }
        )
        .onTapGesture {
            if gameState == .ready {
                startGame()
            }
        }
    }
    
    // MARK: - Player View
    private var playerView: some View {
        ZStack {
            // Outer glow based on upgrades
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("HighlightGlow").opacity(0.3 + Double(gameManager.stats.currentGlowLevel) * 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: playerSize * 1.5
                    )
                )
                .frame(width: playerSize * 3, height: playerSize * 3)
                .scaleEffect(animatePulse ? 1.1 : 0.9)
            
            // Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color("HighlightGlow"),
                            Color("PrimaryAccent").opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: playerSize / 2
                    )
                )
                .frame(width: playerSize, height: playerSize)
                .shadow(color: Color("HighlightGlow"), radius: 10 + CGFloat(gameManager.stats.currentGlowLevel) * 2)
            
            // Trail effect when moving
            if gameState == .playing {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color("HighlightGlow").opacity(0.3 - Double(i) * 0.1))
                        .frame(width: playerSize * 0.6, height: playerSize * 0.6)
                        .offset(x: CGFloat(-10 - i * 8))
                }
            }
        }
    }
    
    // MARK: - Obstacle View
    private func obstacleView(_ obstacle: Obstacle) -> some View {
        ZStack {
            // Glow
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red.opacity(0.3))
                .frame(width: obstacle.width + 10, height: obstacle.height + 10)
                .blur(radius: 8)
            
            // Main barrier
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.7),
                            Color.orange.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: obstacle.width, height: obstacle.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.orange.opacity(0.8), lineWidth: 2)
                )
            
            // Electric effect
            if animatePulse {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: obstacle.width, height: obstacle.height)
            }
        }
        .rotationEffect(.degrees(obstacle.rotation))
    }
    
    // MARK: - Collectible View
    private func collectibleView(_ collectible: Collectible) -> some View {
        ZStack {
            // Glow
            Circle()
                .fill(collectible.type.color.opacity(0.3))
                .frame(width: 40, height: 40)
                .blur(radius: 10)
                .scaleEffect(animatePulse ? 1.2 : 0.8)
            
            // Icon
            Image(systemName: collectible.type.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(collectible.type.color)
                .scaleEffect(animatePulse ? 1.1 : 1.0)
        }
    }
    
    // MARK: - Game UI
    private var gameUI: some View {
        VStack {
            // Top bar
            HStack {
                // Pause button
                Button(action: {
                    if gameState == .playing {
                        pauseGame()
                    }
                }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("HighlightGlow"))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color("PrimaryBackground").opacity(0.8))
                        )
                }
                
                Spacer()
                
                // Collectibles count
                HStack(spacing: 16) {
                    collectibleCounter(icon: "sparkle", count: runesCollected, color: Color("PrimaryAccent"))
                    collectibleCounter(icon: "diamond.fill", count: crystalsCollected, color: Color("HighlightGlow"))
                    collectibleCounter(icon: "bolt.fill", count: fragmentsCollected, color: Color.purple)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color("PrimaryBackground").opacity(0.8))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
            
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("HighlightGlow").opacity(0.7))
                    Spacer()
                    Text("\(Int(levelProgress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color("PrimaryAccent"))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("HighlightGlow").opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color("PrimaryAccent"), Color("HighlightGlow")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * levelProgress)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    private func collectibleCounter(icon: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color("HighlightGlow"))
        }
    }
    
    // MARK: - Ready Overlay
    private var readyOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    startGame()
                }
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text(level.difficulty.rawValue.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(level.difficulty.color)
                    
                    Text("Level \(level.levelNumber)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color("HighlightGlow"))
                }
                
                VStack(spacing: 6) {
                    Text("Tap anywhere to begin")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("HighlightGlow").opacity(0.7))
                    
                    Text("Hold to rise, release to fall")
                        .font(.system(size: 14))
                        .foregroundColor(Color("HighlightGlow").opacity(0.5))
                }
                
                // Start button
                Button(action: {
                    startGame()
                }) {
                    Text("Start")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("PrimaryBackground"))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color("PrimaryAccent"))
                        )
                }
                .padding(.top, 10)
                
                Button(action: {
                    gameTimer?.invalidate()
                    gameTimer = nil
                    dismiss()
                }) {
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("HighlightGlow").opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(Color("HighlightGlow").opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .allowsHitTesting(true)
        }
    }
    
    // MARK: - Paused Overlay
    private var pausedOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Paused")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("HighlightGlow"))
                
                VStack(spacing: 12) {
                    Button(action: { resumeGame() }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("PrimaryBackground"))
                        .frame(width: 180)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("PrimaryAccent"))
                        )
                    }
                    
                    Button(action: { restartLevel() }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restart")
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color("HighlightGlow"))
                        .frame(width: 180)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("HighlightGlow").opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        gameTimer?.invalidate()
                        gameTimer = nil
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Exit")
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color("HighlightGlow").opacity(0.7))
                        .frame(width: 180)
                        .padding(.vertical, 14)
                    }
                }
            }
        }
    }
    
    // MARK: - Failed Overlay
    private var failedOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.red.opacity(0.8))
                    
                    Text("Storm Consumed")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color("HighlightGlow"))
                    
                    Text("The tempest was too strong")
                        .font(.system(size: 15))
                        .foregroundColor(Color("HighlightGlow").opacity(0.6))
                }
                
                // Collected items this attempt
                HStack(spacing: 20) {
                    failedStatItem(icon: "sparkle", count: runesCollected, color: Color("PrimaryAccent"))
                    failedStatItem(icon: "diamond.fill", count: crystalsCollected, color: Color("HighlightGlow"))
                    failedStatItem(icon: "bolt.fill", count: fragmentsCollected, color: Color.purple)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("PrimaryBackground").opacity(0.6))
                )
                
                VStack(spacing: 12) {
                    Button(action: { restartLevel() }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Try Again")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("PrimaryBackground"))
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("PrimaryAccent"))
                        )
                    }
                    
                    Button(action: {
                        gameTimer?.invalidate()
                        gameTimer = nil
                        dismiss()
                    }) {
                        Text("Exit")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color("HighlightGlow").opacity(0.7))
                            .padding(.vertical, 10)
                    }
                }
            }
        }
    }
    
    private func failedStatItem(icon: String, count: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color("HighlightGlow"))
        }
    }
    
    // MARK: - Game Logic
    private func setupLevel() {
        playerY = 0
        playerVelocity = 0
        scrollOffset = 0
        runesCollected = 0
        crystalsCollected = 0
        fragmentsCollected = 0
        score = 0
        levelProgress = 0
        obstacles = []
        collectibles = []
        
        generateObstacles()
        generateCollectibles()
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            animatePulse = true
        }
    }
    
    private func generateObstacles() {
        let count = level.obstacleCount
        let spacing = levelLength / CGFloat(count + 1)
        
        // Use safe bounds for Y positions
        let safeHeight = max(screenSize.height * 0.3, 100)
        
        for i in 0..<count {
            let x = 200 + spacing * CGFloat(i + 1)
            let isTop = i % 2 == 0 // Alternate instead of random for consistency
            let height = CGFloat(80 + (i * 17) % 120) // Deterministic height
            let y = isTop ? -safeHeight + height / 2 : safeHeight - height / 2
            
            let obstacle = Obstacle(
                x: x,
                y: y,
                width: CGFloat(15 + (i * 7) % 10),
                height: height,
                isRotating: level.difficulty == .hard && i % 3 == 0,
                speed: CGFloat(level.obstacleSpeed)
            )
            obstacles.append(obstacle)
        }
        
        // Add some rotating pillars for harder difficulties
        if level.difficulty != .easy {
            let pillarCount = level.difficulty == .hard ? 3 : 1
            for i in 0..<pillarCount {
                let x = 300 + CGFloat(i) * (levelLength / CGFloat(pillarCount + 1))
                let pillar = Obstacle(
                    x: x,
                    y: 0,
                    width: 80,
                    height: 12,
                    isRotating: true,
                    rotation: Double(i * 45)
                )
                obstacles.append(pillar)
            }
        }
    }
    
    private func generateCollectibles() {
        let runeCount = level.requiredRunes + 2
        let crystalCount = 2 + level.levelNumber
        let fragmentCount = level.difficulty == .easy ? 1 : (level.difficulty == .normal ? 2 : 3)
        
        let totalItems = runeCount + crystalCount + fragmentCount
        let spacing = levelLength / CGFloat(totalItems + 2)
        var currentX: CGFloat = 150
        
        // Safe Y range - keep within visible bounds
        let safeYRange = screenSize.height * 0.25
        
        // Runes
        for i in 0..<runeCount {
            currentX += spacing
            // Deterministic Y position based on index
            let yOffset = CGFloat((i * 37) % 100) / 100.0 * 2.0 - 1.0
            let y = yOffset * safeYRange
            collectibles.append(Collectible(x: currentX, y: y, type: .rune))
        }
        
        // Crystals
        for i in 0..<crystalCount {
            currentX += spacing * 0.8
            let yOffset = CGFloat((i * 53 + 17) % 100) / 100.0 * 2.0 - 1.0
            let y = yOffset * safeYRange
            collectibles.append(Collectible(x: currentX, y: y, type: .crystal))
        }
        
        // Fragments
        for i in 0..<fragmentCount {
            currentX += spacing * 0.6
            let yOffset = CGFloat((i * 71 + 31) % 100) / 100.0 * 2.0 - 1.0
            let y = yOffset * safeYRange * 0.8 // Fragments slightly more centered
            collectibles.append(Collectible(x: currentX, y: y, type: .fragment))
        }
    }
    
    private func startGame() {
        gameState = .playing
        gameManager.recordAttempt()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateGame()
        }
    }
    
    private func pauseGame() {
        gameState = .paused
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func resumeGame() {
        gameState = .playing
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateGame()
        }
    }
    
    private func restartLevel() {
        gameTimer?.invalidate()
        gameTimer = nil
        gameState = .ready
        setupLevel()
    }
    
    private func updateGame() {
        guard gameState == .playing else { return }
        
        // Physics
        if isHolding {
            playerVelocity += liftForce
        } else {
            playerVelocity += gravity
        }
        playerVelocity = max(-maxVelocity, min(maxVelocity, playerVelocity))
        playerY += playerVelocity
        
        // Boundaries
        let halfScreen = screenSize.height / 2 - 60
        if playerY < -halfScreen {
            playerY = -halfScreen
            playerVelocity = 0
        }
        if playerY > halfScreen {
            playerY = halfScreen
            playerVelocity = 0
        }
        
        // Scroll
        scrollOffset += CGFloat(level.obstacleSpeed) * 1.5
        levelProgress = min(1.0, scrollOffset / levelLength)
        
        // Update rotating obstacles
        for i in obstacles.indices {
            if obstacles[i].isRotating {
                obstacles[i].rotation += 2
            }
        }
        
        // Check collisions with obstacles
        // Player is at position x=80, y=screenSize.height/2 + playerY
        // Obstacles are at position x=obstacle.x - scrollOffset + 80, y=screenSize.height/2 + obstacle.y
        // So for collision: obstacleScreenX = obstacle.x - scrollOffset + 80
        
        let playerCenterX: CGFloat = 80
        let playerCenterY = screenSize.height / 2 + playerY
        let playerRadius = playerSize / 2 - 2 // Slightly smaller hitbox for fairness
        
        for obstacle in obstacles {
            // Calculate obstacle screen position (same formula as in view)
            let obstacleScreenX = obstacle.x - scrollOffset + 80
            let obstacleScreenY = screenSize.height / 2 + obstacle.y
            
            // For rotating obstacles, use circular collision
            if obstacle.isRotating {
                // Use the longer dimension as radius for rotating obstacles
                let obstacleRadius = max(obstacle.width, obstacle.height) / 2
                let distance = sqrt(pow(playerCenterX - obstacleScreenX, 2) + pow(playerCenterY - obstacleScreenY, 2))
                
                if distance < playerRadius + obstacleRadius {
                    failLevel()
                    return
                }
            } else {
                // Standard rectangle collision for non-rotating obstacles
                let obstacleFrame = CGRect(
                    x: obstacleScreenX - obstacle.width / 2,
                    y: obstacleScreenY - obstacle.height / 2,
                    width: obstacle.width,
                    height: obstacle.height
                )
                
                let playerFrame = CGRect(
                    x: playerCenterX - playerRadius,
                    y: playerCenterY - playerRadius,
                    width: playerRadius * 2,
                    height: playerRadius * 2
                )
                
                if playerFrame.intersects(obstacleFrame) {
                    failLevel()
                    return
                }
            }
        }
        
        // Check collectibles
        // Collectible visual: glow circle 40x40, icon 18pt
        // Use reasonable collection radius
        let collectRadius: CGFloat = 20
        
        for i in collectibles.indices {
            if collectibles[i].isCollected { continue }
            
            // Calculate collectible screen position (same formula as in view)
            let collectibleScreenX = collectibles[i].x - scrollOffset + 80
            let collectibleScreenY = screenSize.height / 2 + collectibles[i].y
            let distance = sqrt(pow(playerCenterX - collectibleScreenX, 2) + pow(playerCenterY - collectibleScreenY, 2))
            
            if distance < playerRadius + collectRadius {
                collectibles[i].isCollected = true
                score += 10
                
                switch collectibles[i].type {
                case .rune:
                    runesCollected += 1
                case .crystal:
                    crystalsCollected += 1
                case .fragment:
                    fragmentsCollected += 1
                }
            }
        }
        
        // Check level completion
        if levelProgress >= 1.0 {
            completeLevel()
        }
    }
    
    private func failLevel() {
        gameTimer?.invalidate()
        gameTimer = nil
        
        withAnimation(.easeInOut(duration: 0.1)) {
            collisionFlash = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            collisionFlash = false
            gameState = .failed
        }
    }
    
    private func completeLevel() {
        gameTimer?.invalidate()
        gameTimer = nil
        gameState = .completed
        
        // Calculate final score
        let totalCollected = runesCollected + crystalsCollected * 2 + fragmentsCollected * 3
        score += totalCollected * 10
        
        // Save progress
        gameManager.completeLevel(
            level,
            runes: runesCollected,
            crystals: crystalsCollected,
            fragments: fragmentsCollected,
            score: score
        )
        
        // Show reward screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showReward = true
        }
    }
}

#Preview {
    GameView(
        gameManager: GameManager.shared,
        level: GameLevel(
            id: 0,
            difficulty: .easy,
            levelNumber: 1,
            isUnlocked: true,
            isCompleted: false,
            bestScore: 0,
            runesCollected: 0,
            crystalsCollected: 0,
            stormFragmentsCollected: 0
        )
    )
}
