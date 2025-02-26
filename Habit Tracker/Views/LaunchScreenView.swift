import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    @State private var size = 0.7
    @State private var opacity = 0.3
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            VStack {
                VStack(spacing: 20) {
                    // App Logo
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "hourglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(Color.teal)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.teal)
                            .offset(x: 30, y: 30)
                    }
                    
                    Text("GainTime")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.teal)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
} 