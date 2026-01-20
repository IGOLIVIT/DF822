//
//  TutorialView.swift
//  DF822
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var demoY: CGFloat = 0
    @State private var isHoldingDemo = false
    
    // Timer references for cleanup
    @State private var physicsTimer: Timer?
    @State private var autoPlayTimer: Timer?
    
    private let tutorials: [(icon: String, title: String, description: String)] = [
        ("hand.tap.fill", "Control", "Hold anywhere on screen to rise. Release to descend. Master this rhythm to navigate."),
        ("bolt.trianglebadge.exclamationmark.fill", "Obstacles", "Avoid electrified barriers and rotating storm pillars. Contact ends your run instantly."),
        ("sparkle", "Collect Runes", "Runes of Light are essential. Collect enough to progress through each level."),
        ("diamond.fill", "Energy Crystals", "Rare crystals grant bonus progress. Their light guides your path."),
        ("bolt.fill", "Storm Fragments", "The rarest rewards. Fragments unlock enhanced visual abilities."),
        ("chart.line.uptrend.xyaxis", "Progression", "Complete levels to unlock harder challenges. Each mastered storm strengthens you.")
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color("PrimaryBackground"),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Title
                Text("How to Play")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("HighlightGlow"))
                    .padding(.top, 10)
                
                // Interactive demo
                interactiveDemo
                    .padding(.top, 20)
                
                // Tutorial pages
                TabView(selection: $currentPage) {
                    ForEach(0..<tutorials.count, id: \.self) { index in
                        tutorialCard(index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 280)
                
                Spacer()
                
                // Got it button
                Button(action: { dismiss() }) {
                    Text("Got It")
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
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startDemoAnimation()
        }
        .onDisappear {
            // Clean up timers
            physicsTimer?.invalidate()
            physicsTimer = nil
            autoPlayTimer?.invalidate()
            autoPlayTimer = nil
        }
    }
    
    // MARK: - Interactive Demo
    private var interactiveDemo: some View {
        ZStack {
            // Demo container
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("PrimaryBackground").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("HighlightGlow").opacity(0.2), lineWidth: 1)
                )
            
            // Obstacles
            HStack(spacing: 50) {
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.6), Color.orange.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 8, height: 50)
                        .offset(y: i % 2 == 0 ? -30 : 30)
                }
            }
            .offset(x: 30)
            
            // Energy sphere
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("HighlightGlow").opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white, Color("HighlightGlow")],
                            center: .center,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 20, height: 20)
                    .shadow(color: Color("HighlightGlow"), radius: 8)
            }
            .offset(x: -80, y: demoY)
            
            // Touch indicator
            VStack(spacing: 4) {
                Image(systemName: isHoldingDemo ? "hand.tap.fill" : "hand.point.up.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("PrimaryAccent"))
                
                Text(isHoldingDemo ? "Rising" : "Falling")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color("PrimaryAccent").opacity(0.8))
            }
            .offset(x: 90, y: 35)
        }
        .frame(height: 160)
        .padding(.horizontal, 30)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isHoldingDemo = true }
                .onEnded { _ in isHoldingDemo = false }
        )
    }
    
    private func startDemoAnimation() {
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if isHoldingDemo {
                demoY = max(-40, demoY - 2)
            } else {
                demoY = min(40, demoY + 1.5)
            }
        }
        
        // Auto demo when not touched
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            if !isHoldingDemo {
                isHoldingDemo = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isHoldingDemo = false
                }
            }
        }
    }
    
    // MARK: - Tutorial Card
    private func tutorialCard(index: Int) -> some View {
        let tutorial = tutorials[index]
        
        return VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color("PrimaryAccent").opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: tutorial.icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color("PrimaryAccent"))
            }
            
            VStack(spacing: 12) {
                Text(tutorial.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color("HighlightGlow"))
                
                Text(tutorial.description)
                    .font(.system(size: 15))
                    .foregroundColor(Color("HighlightGlow").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    TutorialView()
}
