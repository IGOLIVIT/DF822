//
//  OnboardingView.swift
//  DF822
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var showOnboarding: Bool
    @State private var currentStep = 0
    @State private var animateParticles = false
    @State private var animateGlow = false
    @State private var sphereY: CGFloat = 0
    @State private var sphereGoingUp = false
    
    // Store timer references for cleanup
    @State private var sphereTimer: Timer?
    @State private var directionTimer: Timer?
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color("PrimaryBackground"),
                    Color("PrimaryBackground").opacity(0.8),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating particles
            ForEach(0..<20, id: \.self) { index in
                ParticleView(
                    index: index,
                    animate: animateParticles
                )
            }
            
            VStack(spacing: 0) {
                // Step indicator
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color("PrimaryAccent") : Color("HighlightGlow").opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(index == currentStep ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Content
                TabView(selection: $currentStep) {
                    step1Content
                        .tag(0)
                    
                    step2Content
                        .tag(1)
                    
                    step3Content
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentStep)
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color("HighlightGlow"))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("HighlightGlow").opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    
                    Button(action: {
                        if currentStep < 2 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            gameManager.completeOnboarding()
                            withAnimation {
                                showOnboarding = false
                            }
                        }
                    }) {
                        Text(currentStep < 2 ? "Next" : "Begin")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color("PrimaryBackground"))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("PrimaryAccent"))
                                    .shadow(color: Color("PrimaryAccent").opacity(0.5), radius: 10, x: 0, y: 4)
                            )
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateParticles = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            startSphereAnimation()
        }
        .onDisappear {
            // Clean up timers
            sphereTimer?.invalidate()
            sphereTimer = nil
            directionTimer?.invalidate()
            directionTimer = nil
        }
    }
    
    private func startSphereAnimation() {
        sphereTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                sphereY = sphereGoingUp ? -30 : 30
            }
        }
        
        directionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            sphereGoingUp.toggle()
        }
    }
    
    // MARK: - Step 1: Atmospheric Introduction
    private var step1Content: some View {
        VStack(spacing: 30) {
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
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateGlow ? 1.2 : 1.0)
                
                // Core sphere
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
                            endRadius: 40
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color("HighlightGlow"), radius: 20)
                
                // Orbiting particles
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color("HighlightGlow").opacity(0.7))
                        .frame(width: 6, height: 6)
                        .offset(x: 50)
                        .rotationEffect(.degrees(Double(i) * 60 + (animateGlow ? 360 : 0)))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: animateGlow)
                }
            }
            .frame(height: 220)
            
            VStack(spacing: 16) {
                Text("Harness the Storm")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("HighlightGlow"))
                
                Text("Within chaos lies order. Focus your energy, find calm in the tempest, and ascend beyond the storm.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("HighlightGlow").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Step 2: Gameplay Preview
    private var step2Content: some View {
        VStack(spacing: 30) {
            ZStack {
                // Storm corridor preview
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("PrimaryBackground").opacity(0.8))
                    .frame(width: 280, height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("HighlightGlow").opacity(0.3), lineWidth: 1)
                    )
                
                // Animated obstacles
                HStack(spacing: 40) {
                    ForEach(0..<3, id: \.self) { i in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.6), Color.orange.opacity(0.4)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 8, height: 60)
                            .offset(y: animateGlow ? -20 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(Double(i) * 0.2).repeatForever(autoreverses: true), value: animateGlow)
                    }
                }
                
                // Energy sphere
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white, Color("HighlightGlow")],
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 24, height: 24)
                    .shadow(color: Color("HighlightGlow"), radius: 10)
                    .offset(x: -80, y: sphereY)
                
                // Touch indicator
                VStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("PrimaryAccent"))
                        .opacity(animateGlow ? 1 : 0.5)
                    
                    Text("Hold")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("PrimaryAccent"))
                }
                .offset(x: 100, y: 50)
            }
            .frame(height: 200)
            
            VStack(spacing: 16) {
                Text("Control Your Path")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("HighlightGlow"))
                
                Text("Hold to rise through the storm. Release to descend. Navigate through electrified barriers with precision timing.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("HighlightGlow").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Step 3: Rewards Preview
    private var step3Content: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                rewardItem(icon: "sparkle", name: "Runes", color: Color("PrimaryAccent"))
                rewardItem(icon: "diamond.fill", name: "Crystals", color: Color("HighlightGlow"))
                rewardItem(icon: "bolt.fill", name: "Fragments", color: Color.purple)
            }
            .padding(.horizontal, 20)
            
            // Progress bar preview
            VStack(spacing: 12) {
                HStack {
                    Text("Your Journey")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("HighlightGlow").opacity(0.7))
                    Spacer()
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("HighlightGlow").opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color("PrimaryAccent"), Color("HighlightGlow")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: animateGlow ? geometry.size.width * 0.6 : 0, height: 12)
                            .animation(.easeInOut(duration: 1.5), value: animateGlow)
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("PrimaryBackground").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("HighlightGlow").opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
            
            VStack(spacing: 16) {
                Text("Grow Stronger")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("HighlightGlow"))
                
                Text("Collect rewards to unlock visual enhancements. Each level mastered brings new challenges and deeper immersion.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("HighlightGlow").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private func rewardItem(icon: String, name: String, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .scaleEffect(animateGlow ? 1.1 : 1.0)
            }
            
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("HighlightGlow").opacity(0.8))
        }
    }
}

// MARK: - Particle View
struct ParticleView: View {
    let index: Int
    let animate: Bool
    
    private let randomX: CGFloat
    private let randomY: CGFloat
    private let randomSize: CGFloat
    private let randomDelay: Double
    
    init(index: Int, animate: Bool) {
        self.index = index
        self.animate = animate
        // Use index-based seeding for consistent positions
        self.randomX = CGFloat((index * 37 + 13) % 100) / 100.0
        self.randomY = CGFloat((index * 53 + 29) % 100) / 100.0
        self.randomSize = CGFloat(2 + (index % 5))
        self.randomDelay = Double(index % 20) / 10.0
    }
    
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(Color("HighlightGlow").opacity(0.3))
                .frame(width: randomSize, height: randomSize)
                .position(
                    x: randomX * geometry.size.width,
                    y: randomY * geometry.size.height + (animate ? -50 : 50)
                )
                .animation(
                    .easeInOut(duration: 3.0)
                    .delay(randomDelay)
                    .repeatForever(autoreverses: true),
                    value: animate
                )
        }
    }
}

#Preview {
    OnboardingView(gameManager: GameManager.shared, showOnboarding: .constant(true))
}
