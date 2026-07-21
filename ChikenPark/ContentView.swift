import Foundation
import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var game = SkyFarmGame()
    @StateObject private var progress = SkyFarmProgress()
    @State private var selectedTab: SkyFarmTab = .play
    @State private var isPresentingFullScreenGame = false
    @State private var isFullScreenGameActive = false
    @State private var isPresentingWorldMap = false
    @AppStorage("hasCompletedSkyFarmOnboarding.v1") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                appShell
                    .transition(.opacity)
            } else {
                SkyFarmOnboardingView(onComplete: completeOnboarding)
                    .transition(.opacity)
            }
        }
        .tint(Color(red: 0.91, green: 0.39, blue: 0.31))
        .preferredColorScheme(.light)
    }

    private var appShell: some View {
        TabView(selection: $selectedTab) {
            Group {
                if isPresentingFullScreenGame {
                    Color.clear
                } else {
                    SkyFarmPlayView(
                        game: game,
                        progress: progress,
                        isSceneActive: selectedTab == .play && !isFullScreenGameActive,
                        openFullscreen: presentFullScreenGame,
                        openFarm: { selectedTab = .farm }
                    )
                }
            }
            .tag(SkyFarmTab.play)
            .tabItem {
                Label("Island", systemImage: "play.circle.fill")
            }

            NavigationStack {
                SkyFarmDashboardView(
                    progress: progress,
                    navigate: { selectedTab = $0 },
                    openMap: { isPresentingWorldMap = true }
                )
            }
            .tag(SkyFarmTab.farm)
            .tabItem {
                Label("Farm", systemImage: "house.and.flag.fill")
            }

            NavigationStack {
                SkyFarmShopView(progress: progress)
            }
                .tag(SkyFarmTab.shop)
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }

            NavigationStack {
                SkyFarmLibraryView(progress: progress)
            }
                .tag(SkyFarmTab.journal)
                .tabItem {
                    Label("Journal", systemImage: "book.closed.fill")
                }

            NavigationStack {
                SkyFarmSettingsView(progress: progress)
            }
            .tag(SkyFarmTab.settings)
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .fullScreenCover(isPresented: $isPresentingFullScreenGame, onDismiss: finishFullScreenGame) {
            SkyFarmFullScreenGameView(
                game: game,
                progress: progress,
                isSceneActive: isFullScreenGameActive,
                close: dismissFullScreenGame,
                openFarm: openFarmFromFullScreen
            )
            .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $isPresentingWorldMap) {
            NavigationStack {
                SkyFarmWorldMapView(
                    progress: progress,
                    startLevel: startGardenFlightFromMap,
                    openFarm: openFarmFromMap,
                    close: { isPresentingWorldMap = false }
                )
            }
            .tint(Color(red: 0.91, green: 0.39, blue: 0.31))
            .preferredColorScheme(.light)
        }
        .onChange(of: game.collectedPartsCount) { oldValue, newValue in
            guard newValue > oldValue else { return }
            for _ in oldValue..<newValue {
                progress.apply(.partCollected)
            }
        }
        .onChange(of: game.chickIsRescued) { oldValue, newValue in
            if !oldValue && newValue {
                progress.apply(.chickRescued)
            }
        }
        .onChange(of: game.checkpointIsActive) { oldValue, newValue in
            if !oldValue && newValue {
                progress.apply(.checkpointReached)
            }
        }
        .onChange(of: game.player.seeds) { oldValue, newValue in
            guard newValue < oldValue else { return }
            for _ in newValue..<oldValue {
                progress.apply(.seedPlanted)
            }
        }
        .onChange(of: game.secretEggIsFound) { oldValue, newValue in
            if !oldValue && newValue {
                progress.apply(.secretEggFound)
            }
        }
        .onChange(of: game.phase) { oldValue, newValue in
            if oldValue != .completed && newValue == .completed {
                progress.apply(.levelCompleted(elapsedTime: game.elapsedTime))
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.32)) {
            hasCompletedOnboarding = true
        }
    }

    private func presentFullScreenGame() {
        isFullScreenGameActive = true
        isPresentingFullScreenGame = true
    }

    private func dismissFullScreenGame() {
        game.releaseControls()
        isPresentingFullScreenGame = false
    }

    private func openFarmFromFullScreen() {
        selectedTab = .farm
        dismissFullScreenGame()
    }

    private func startGardenFlightFromMap() {
        selectedTab = .play
        isPresentingWorldMap = false

        switch game.phase {
        case .intro:
            game.start()
        case .completed:
            game.restart()
            game.start()
        case .running:
            break
        }
    }

    private func openFarmFromMap() {
        selectedTab = .farm
        isPresentingWorldMap = false
    }

    private func finishFullScreenGame() {
        game.releaseControls()
        game.resetClock()
        isFullScreenGameActive = false
    }
}

enum SkyFarmTab: Hashable {
    case play
    case farm
    case shop
    case journal
    case settings
}

private struct SkyFarmPlayView: View {
    @ObservedObject var game: SkyFarmGame
    @ObservedObject var progress: SkyFarmProgress
    let isSceneActive: Bool
    let openFullscreen: () -> Void
    let openFarm: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 620 || proxy.size.width < 520
            ZStack {
                SkyFarmBackdrop()

                VStack(spacing: compact ? 8 : 14) {
                    SkyFarmHeader(
                        compact: compact,
                        skyPoints: progress.skyPoints,
                        openFullscreen: openFullscreen,
                        restart: game.restart
                    )

                    SkyFarmHUD(game: game, compact: compact)

                    SkyFarmSceneView(game: game, isActive: isSceneActive)
                        .frame(height: stageHeight(for: proxy.size, compact: compact))
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 24 : 32, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: compact ? 24 : 32, style: .continuous)
                                .stroke(.white.opacity(0.88), lineWidth: 3)
                        }
                        .shadow(color: Color(red: 0.13, green: 0.38, blue: 0.48).opacity(0.2), radius: 20, y: 10)

                    SkyFarmControls(game: game, compact: compact)

                    if compact {
                        CompactMissionHint(text: game.currentHint)
                    } else {
                        SkyFarmMissionPanel(game: game)
                    }
                }
                .padding(.horizontal, compact ? 12 : 20)
                .padding(.vertical, compact ? 8 : 16)

                if let toast = game.toast, game.phase != .intro {
                    SkyFarmToast(toast: toast)
                        .padding(.top, compact ? 76 : 98)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                if game.phase == .intro {
                    SkyFarmStartCard {
                        game.start()
                    }
                    .padding(24)
                }

                if game.phase == .completed {
                    SkyFarmCompletionCard(
                        elapsedTime: game.elapsedTime,
                        restart: { game.restart() },
                        openFarm: openFarm
                    )
                    .padding(24)
                }
            }
        }
    }

    private func stageHeight(for size: CGSize, compact: Bool) -> CGFloat {
        if compact {
            return max(220, min(size.height * 0.54, 340))
        }
        return max(350, min(size.height * 0.60, 540))
    }
}

private struct SkyFarmFullScreenGameView: View {
    @ObservedObject var game: SkyFarmGame
    @ObservedObject var progress: SkyFarmProgress
    let isSceneActive: Bool
    let close: () -> Void
    let openFarm: () -> Void

    var body: some View {
        ZStack {
            SkyFarmBackdrop()

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Button(action: close) {
                        Label("Back", systemImage: "chevron.down")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(SkyFarmSecondaryButtonStyle())
                    .accessibilityLabel("Close full screen game")

                    Spacer(minLength: 0)

                    VStack(spacing: 1) {
                        Text("CLARA'S FLIGHT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(Color(red: 0.24, green: 0.43, blue: 0.58))
                        Text("Garden Island")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.11, green: 0.25, blue: 0.38))
                    }

                    Spacer(minLength: 0)

                    Label("\(progress.skyPoints)", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.2, green: 0.43, blue: 0.61))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.72), in: Capsule())
                        .accessibilityLabel("Sky Points: \(progress.skyPoints)")
                }

                SkyFarmHUD(game: game, compact: true)

                SkyFarmSceneView(game: game, isActive: isSceneActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(.white.opacity(0.88), lineWidth: 3)
                    }
                    .shadow(color: Color(red: 0.13, green: 0.38, blue: 0.48).opacity(0.24), radius: 22, y: 10)
                    .layoutPriority(1)

                SkyFarmControls(game: game, compact: false)
                CompactMissionHint(text: game.currentHint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)

            if let toast = game.toast, game.phase != .intro {
                SkyFarmToast(toast: toast)
                    .padding(.top, 78)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if game.phase == .intro {
                SkyFarmStartCard {
                    game.start()
                }
                .padding(24)
            }

            if game.phase == .completed {
                SkyFarmCompletionCard(
                    elapsedTime: game.elapsedTime,
                    restart: game.restart,
                    openFarm: openFarm
                )
                .padding(24)
            }
        }
        .statusBarHidden(true)
    }
}

private struct SkyFarmBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.62, green: 0.88, blue: 0.96),
                Color(red: 0.84, green: 0.95, blue: 0.97),
                Color(red: 0.98, green: 0.96, blue: 0.87)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct SkyFarmHeader: View {
    let compact: Bool
    let skyPoints: Int
    let openFullscreen: () -> Void
    let restart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 9) {
                Text("🐔")
                    .font(.system(size: compact ? 24 : 29))
                    .frame(width: compact ? 38 : 46, height: compact ? 38 : 46)
                    .background(Color(red: 1, green: 0.82, blue: 0.4), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.88), lineWidth: 2)
                    }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Chick")
                        .font(.system(size: compact ? 18 : 21, weight: .bold, design: .rounded))
                    Text("SKY FARM")
                        .font(.system(size: compact ? 8 : 9, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color(red: 0.33, green: 0.49, blue: 0.63))
                }
            }

            Spacer(minLength: 8)

            if !compact {
                Label("Vertical Slice · Garden Island", systemImage: "circle.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.25, green: 0.42, blue: 0.56))
                    .labelStyle(.titleAndIcon)
                    .symbolRenderingMode(.palette)
                    .symbolVariant(.fill)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.66), in: Capsule())
            }

            Label("\(skyPoints)", systemImage: "sparkles")
                .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.2, green: 0.43, blue: 0.61))
                .symbolRenderingMode(.hierarchical)
                .padding(.horizontal, compact ? 9 : 11)
                .padding(.vertical, compact ? 8 : 10)
                .background(.white.opacity(0.72), in: Capsule())
                .accessibilityLabel("Sky Points: \(skyPoints)")

            Button(action: openFullscreen) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: compact ? 14 : 16, weight: .bold))
                    .frame(width: compact ? 34 : 40, height: compact ? 34 : 40)
            }
            .buttonStyle(SkyFarmSecondaryButtonStyle())
            .accessibilityLabel("Open full screen game")

            Button(action: restart) {
                Text("Restart")
                    .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                    .padding(.horizontal, compact ? 11 : 14)
                    .padding(.vertical, compact ? 8 : 10)
            }
            .buttonStyle(SkyFarmSecondaryButtonStyle())
            .accessibilityLabel("Restart level")
        }
    }
}

private struct SkyFarmHUD: View {
    @ObservedObject var game: SkyFarmGame
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 6 : 9) {
            SkyFarmMetric(icon: "gearshape.fill", title: "\(game.collectedPartsCount)/3", tint: Color(red: 1, green: 0.78, blue: 0.34), compact: compact)
            SkyFarmMetric(icon: "sparkles", title: "\(game.player.seeds)", tint: Color(red: 0.77, green: 0.93, blue: 0.46), compact: compact)
            SkyFarmMetric(icon: game.chickIsRescued ? "heart.fill" : "circle.fill", title: game.chickIsRescued ? "Pip" : "Pip is waiting", tint: game.chickIsRescued ? Color(red: 1, green: 0.83, blue: 0.38) : Color(red: 0.72, green: 0.83, blue: 0.85), compact: compact)

            Spacer(minLength: 0)

            Text(String(repeating: "♥", count: game.player.hearts) + String(repeating: "♡", count: 3 - game.player.hearts))
                .font(.system(size: compact ? 16 : 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.25, green: 0.37, blue: 0.51))
                .accessibilityLabel("Health: \(game.player.hearts) of 3")
        }
    }
}

private struct SkyFarmMetric: View {
    let icon: String
    let title: String
    let tint: Color
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            Image(systemName: icon)
                .font(.system(size: compact ? 9 : 10, weight: .bold))
                .foregroundStyle(tint)
            Text(title)
        }
            .font(.system(size: compact ? 11 : 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .symbolRenderingMode(.hierarchical)
            .padding(.horizontal, compact ? 8 : 11)
            .padding(.vertical, compact ? 6 : 8)
            .background(Color(red: 0.14, green: 0.31, blue: 0.43).opacity(0.78), in: Capsule())
    }
}

private struct SkyFarmSceneView: View {
    @ObservedObject var game: SkyFarmGame
    let isActive: Bool
    @State private var scene = SkyFarmSpriteScene()

    var body: some View {
        SpriteView(scene: scene)
            .onAppear {
                updateSceneActivity()
            }
            .onChange(of: isActive) { _, _ in
                updateSceneActivity()
            }
            .onDisappear {
                scene.isPaused = true
                game.releaseControls()
                game.resetClock()
            }
            .background(Color(red: 0.49, green: 0.8, blue: 0.91))
        .accessibilityLabel("Sky Farm game scene")
    }

    private func updateSceneActivity() {
        guard isActive else {
            scene.isPaused = true
            game.releaseControls()
            game.resetClock()
            return
        }

        scene.bind(game: game)
        scene.isPaused = false
    }
}

private struct SkyFarmControls: View {
    @ObservedObject var game: SkyFarmGame
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 10 : 14) {
            HStack(spacing: compact ? 8 : 10) {
                SkyFarmHoldButton(symbol: "chevron.left", compact: compact) { isPressed in
                    game.setMove(direction: -1, isPressed: isPressed)
                }
                SkyFarmHoldButton(symbol: "chevron.right", compact: compact) { isPressed in
                    game.setMove(direction: 1, isPressed: isPressed)
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: compact ? 8 : 10) {
                Button(action: game.plantSeed) {
                    Image(systemName: "sparkles")
                        .font(.system(size: compact ? 19 : 21, weight: .bold))
                }
                .buttonStyle(SkyFarmActionButtonStyle(color: Color(red: 0.94, green: 0.42, blue: 0.34), compact: compact))
                .accessibilityLabel("Throw seed")

                Button(action: game.rescueChick) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: compact ? 18 : 20, weight: .bold))
                }
                .buttonStyle(SkyFarmActionButtonStyle(color: Color(red: 0.96, green: 0.73, blue: 0.3), compact: compact))
                .accessibilityLabel("Rescue chick")

                SkyFarmHoldButton(symbol: "arrow.up", compact: compact) { isPressed in
                    if isPressed {
                        game.pressJump()
                    } else {
                        game.setGlideHeld(false)
                    }
                }
            }
        }
    }
}

private struct SkyFarmHoldButton: View {
    let symbol: String
    let compact: Bool
    let pressing: (Bool) -> Void

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: compact ? 20 : 24, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: compact ? 48 : 58, height: compact ? 48 : 58)
            .background(Color(red: 0.12, green: 0.29, blue: 0.41).opacity(0.82), in: RoundedRectangle(cornerRadius: compact ? 15 : 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 15 : 18, style: .continuous)
                    .stroke(.white.opacity(0.65), lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: compact ? 15 : 18, style: .continuous))
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .greatestFiniteMagnitude,
                pressing: pressing,
                perform: {}
            )
            .accessibilityAddTraits(.isButton)
    }
}

private struct SkyFarmMissionPanel: View {
    @ObservedObject var game: SkyFarmGame

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("OBJECTIVE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color(red: 0.83, green: 0.41, blue: 0.29))
                Text("Collect farm parts")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(game.currentHint)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.33, green: 0.45, blue: 0.57))
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 5) {
                GuideLine(icon: "chevron.left.forwardslash.chevron.right", text: "Run")
                GuideLine(icon: "arrow.up", text: "Jump & glide")
                GuideLine(icon: "sparkles", text: "Seeds & garden beds")
            }
        }
        .padding(.horizontal, 8)
    }
}

private struct CompactMissionHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.24, green: 0.4, blue: 0.53))
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
}

private struct GuideLine: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.33, green: 0.45, blue: 0.57))
    }
}

private struct SkyFarmToast: View {
    let toast: SkyToast

    var color: Color {
        switch toast.tone {
        case .sunshine: Color(red: 1, green: 0.93, blue: 0.59)
        case .leaf: Color(red: 0.81, green: 0.95, blue: 0.68)
        case .coral: Color(red: 1, green: 0.81, blue: 0.73)
        case .cloud: Color(red: 0.84, green: 0.93, blue: 0.95)
        }
    }

    var body: some View {
        Text(toast.message)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.25, blue: 0.34).opacity(0.86), in: Capsule())
            .shadow(color: .black.opacity(0.13), radius: 8, y: 4)
    }
}

private struct SkyFarmStartCard: View {
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CLARA'S FIRST FLIGHT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.84, green: 0.42, blue: 0.29))
            Text("Return the\nSky Farm parts")
                .font(.system(size: 37, weight: .bold, design: .rounded))
                .tracking(-1)
                .foregroundStyle(Color(red: 0.12, green: 0.22, blue: 0.37))
            Text("Catch the wind with your wings, plant seeds in garden beds, and guide Clara to the lighthouse.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.32, green: 0.44, blue: 0.57))
                .fixedSize(horizontal: false, vertical: true)
            Button(action: start) {
                Label("Let's go", systemImage: "arrow.right")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
            }
            .buttonStyle(SkyFarmPrimaryButtonStyle())
            Text("Use the on-screen controls")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.44, green: 0.55, blue: 0.64))
        }
        .frame(maxWidth: 390, alignment: .leading)
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.82), lineWidth: 2)
        }
        .shadow(color: Color(red: 0.12, green: 0.3, blue: 0.4).opacity(0.23), radius: 24, y: 12)
    }
}

private struct SkyFarmCompletionCard: View {
    let elapsedTime: TimeInterval
    let restart: () -> Void
    let openFarm: () -> Void

    private var timeLabel: String {
        let seconds = max(1, Int(elapsedTime.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        VStack(spacing: 13) {
            Text("ISLAND SAVED")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.84, green: 0.42, blue: 0.29))
            Text("The first farm part\nis back home!")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.12, green: 0.22, blue: 0.37))
            Text("3 parts · Pip rescued · \(timeLabel)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.32, green: 0.44, blue: 0.57))
            HStack(spacing: 10) {
                Button(action: openFarm) {
                    Label("To Farm", systemImage: "house.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }
                .buttonStyle(SkyFarmSecondaryButtonStyle())

                Button(action: restart) {
                    Label("Play again", systemImage: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }
                .buttonStyle(SkyFarmPrimaryButtonStyle())
            }
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.82), lineWidth: 2)
        }
        .shadow(color: Color(red: 0.12, green: 0.3, blue: 0.4).opacity(0.23), radius: 24, y: 12)
    }
}

private struct SkyFarmPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.94, green: 0.41, blue: 0.34))
                    .shadow(
                        color: Color(red: 0.72, green: 0.27, blue: 0.23).opacity(0.5),
                        radius: 0,
                        y: configuration.isPressed ? 2 : 5
                    )
            }
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SkyFarmSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.25, green: 0.4, blue: 0.53))
            .background(.white.opacity(configuration.isPressed ? 0.92 : 0.68), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color(red: 0.2, green: 0.36, blue: 0.49).opacity(0.1), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct SkyFarmActionButtonStyle: ButtonStyle {
    let color: Color
    let compact: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(width: compact ? 48 : 58, height: compact ? 48 : 58)
            .background(color, in: RoundedRectangle(cornerRadius: compact ? 15 : 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 15 : 18, style: .continuous)
                    .stroke(.white.opacity(0.66), lineWidth: 2)
            }
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
