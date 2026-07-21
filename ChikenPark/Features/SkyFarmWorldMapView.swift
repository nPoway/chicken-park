import SwiftUI

/// A calm overview of Clara's routes. The current build ships one playable
/// island, while the route states make the next two destinations visible and
/// tied to progress the player can already earn in the garden level.
struct SkyFarmWorldMapView: View {
    @ObservedObject var progress: SkyFarmProgress
    let startLevel: () -> Void
    let openFarm: () -> Void
    let close: () -> Void

    private var stormUnlocked: Bool {
        progress.isFarmBuildingRestored(.mill)
    }

    private var nightUnlocked: Bool {
        progress.isFarmBuildingRestored(.balloon)
    }

    private var farmRecovery: Double {
        progress.farmRestorationProgress
    }

    private var nextRouteHint: String {
        if !stormUnlocked {
            return "Restore the Windmill to chart the Storm Route."
        }

        if !nightUnlocked {
            return "Repair the Farm Balloon to reveal Glowhouse Night."
        }

        return "All planned routes are charted. New islands will arrive in a future flight update."
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                routeHero
                routeMap
                nextRouteCard
                farmProgressCard
                actionRow
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(WorldMapPalette.canvas.ignoresSafeArea())
        .navigationTitle("Island Map")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: close) {
                    Label("Close", systemImage: "chevron.down")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .accessibilityLabel("Close island map")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Label("\(progress.skyPoints) Sky Points", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(WorldMapPalette.deepSky)
                    .accessibilityLabel("Sky Points: \(progress.skyPoints)")
            }
        }
    }

    private var routeHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 58, height: 58)
                    Image(systemName: "map.fill")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("CLARA'S SKY ROUTES")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("Choose the next island")
                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 0)
            }

            Text("Restore the farm one short flight at a time. Garden Island is ready for takeoff.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [WorldMapPalette.deepSky, WorldMapPalette.blueberry],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .shadow(color: WorldMapPalette.deepSky.opacity(0.22), radius: 18, y: 9)
    }

    private var routeMap: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Flight routes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(WorldMapPalette.ink)
                Spacer()
                Text("1–3 min each")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(WorldMapPalette.mutedInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(WorldMapPalette.cloud, in: Capsule())
            }

            VStack(spacing: 0) {
                WorldMapIslandCard(
                    number: 1,
                    title: "Garden Island",
                    subtitle: "Learn to glide, grow a bridge, and rescue Pip.",
                    icon: "leaf.fill",
                    accent: WorldMapPalette.leaf,
                    isUnlocked: true,
                    status: "READY TO FLY",
                    isPlayable: true,
                    action: startLevel
                )

                WorldMapRouteConnector(isUnlocked: stormUnlocked)

                WorldMapIslandCard(
                    number: 2,
                    title: "Storm Route",
                    subtitle: stormUnlocked ? "The restored windmill points toward a storm route still beyond the horizon." : "Restore the Windmill to clear the route through the clouds.",
                    icon: "cloud.bolt.fill",
                    accent: WorldMapPalette.storm,
                    isUnlocked: stormUnlocked,
                    status: stormUnlocked ? "COMING NEXT" : "LOCKED",
                    isPlayable: false,
                    action: nil
                )

                WorldMapRouteConnector(isUnlocked: nightUnlocked)

                WorldMapIslandCard(
                    number: 3,
                    title: "Glowhouse Night",
                    subtitle: nightUnlocked ? "The balloon has revealed a night route waiting for its first expedition." : "Repair the Farm Balloon to discover the glowing islands.",
                    icon: "moon.stars.fill",
                    accent: WorldMapPalette.night,
                    isUnlocked: nightUnlocked,
                    status: nightUnlocked ? "COMING NEXT" : "LOCKED",
                    isPlayable: false,
                    action: nil
                )
            }
        }
    }

    private var nextRouteCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: stormUnlocked ? "point.3.connected.trianglepath.dotted" : "lock.fill")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(stormUnlocked ? WorldMapPalette.deepSky : WorldMapPalette.coral)
                .frame(width: 44, height: 44)
                .background((stormUnlocked ? WorldMapPalette.deepSky : WorldMapPalette.coral).opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(stormUnlocked ? "ROUTE UPDATE" : "NEXT UNLOCK")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(stormUnlocked ? WorldMapPalette.deepSky : WorldMapPalette.coral)
                Text(nextRouteHint)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(WorldMapPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.96), lineWidth: 1)
        }
    }

    private var farmProgressCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("FARM RESTORATION")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.9)
                        .foregroundStyle(WorldMapPalette.leaf)
                    Text("\(Int((farmRecovery * 100).rounded()))% back in the sky")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(WorldMapPalette.ink)
                }

                Spacer()

                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(WorldMapPalette.leaf)
                    .frame(width: 48, height: 48)
                    .background(WorldMapPalette.leaf.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            }

            ProgressView(value: farmRecovery)
                .tint(WorldMapPalette.leaf)
                .scaleEffect(x: 1, y: 1.45, anchor: .center)

            Text("\(progress.totalFarmUpgradeLevels) of \(progress.totalFarmUpgradeCapacity) restoration stages complete")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(WorldMapPalette.mutedInk)

            HStack(spacing: 8) {
                WorldMapMiniStat(icon: "gearshape.fill", value: progress.totalPartsFound, label: "parts", tint: WorldMapPalette.sunflower)
                WorldMapMiniStat(icon: "bird.fill", value: progress.totalChicksRescued, label: "chicks", tint: WorldMapPalette.coral)
                WorldMapMiniStat(icon: "flag.checkered", value: progress.completedLevels, label: "flights", tint: WorldMapPalette.deepSky)
            }
        }
        .padding(17)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(.white.opacity(0.96), lineWidth: 1)
        }
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            Button(action: startLevel) {
                Label("Start Garden Flight", systemImage: "play.fill")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(WorldMapPrimaryButtonStyle())
            .accessibilityHint("Starts the Garden Island level")

            Button(action: openFarm) {
                Label("Visit the Farm", systemImage: "house.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(WorldMapPalette.deepSky)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(WorldMapPalette.deepSky.opacity(0.14), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens farm restoration progress")
        }
    }
}

private struct WorldMapIslandCard: View {
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let isUnlocked: Bool
    let status: String
    let isPlayable: Bool
    let action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
                .accessibilityHint("Starts \(title)")
            } else {
                cardContent
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(title). \(status). \(subtitle)")
            }
        }
    }

    private var cardContent: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? accent.opacity(0.17) : WorldMapPalette.cloud)
                    .frame(width: 58, height: 58)
                Image(systemName: isUnlocked ? icon : "lock.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isUnlocked ? accent : WorldMapPalette.mutedInk)
                Text("\(number)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(isUnlocked ? accent : WorldMapPalette.mutedInk, in: Circle())
                    .offset(x: 21, y: 21)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(isUnlocked ? WorldMapPalette.ink : WorldMapPalette.mutedInk)
                    if isPlayable {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(accent)
                    }
                }
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WorldMapPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Text(status)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(isUnlocked ? accent : WorldMapPalette.mutedInk)
                .multilineTextAlignment(.trailing)
                .frame(width: 68, alignment: .trailing)
        }
        .padding(15)
        .background(isUnlocked ? .white.opacity(0.90) : .white.opacity(0.64), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(isPlayable ? accent.opacity(0.45) : .white.opacity(0.88), lineWidth: isPlayable ? 2 : 1)
        }
        .shadow(color: isPlayable ? accent.opacity(0.12) : .clear, radius: 12, y: 5)
    }
}

private struct WorldMapRouteConnector: View {
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isUnlocked ? WorldMapPalette.deepSky : WorldMapPalette.cloud)
                .frame(width: 8, height: 8)
            WorldMapFlightPath()
                .stroke(
                    isUnlocked ? WorldMapPalette.deepSky.opacity(0.55) : WorldMapPalette.mutedInk.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
                )
                .frame(height: 26)
            Image(systemName: isUnlocked ? "wind" : "lock.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isUnlocked ? WorldMapPalette.deepSky : WorldMapPalette.mutedInk)
            WorldMapFlightPath()
                .stroke(
                    isUnlocked ? WorldMapPalette.deepSky.opacity(0.55) : WorldMapPalette.mutedInk.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
                )
                .frame(height: 26)
            Circle()
                .fill(isUnlocked ? WorldMapPalette.deepSky : WorldMapPalette.cloud)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 32)
    }
}

private struct WorldMapFlightPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.28, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.72, y: rect.maxY)
        )
        return path
    }
}

private struct WorldMapMiniStat: View {
    let icon: String
    let value: Int
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
            Text("\(value) \(label)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(WorldMapPalette.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(WorldMapPalette.canvas, in: Capsule())
    }
}

private struct WorldMapPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(WorldMapPalette.coral.opacity(configuration.isPressed ? 0.82 : 1))
                    .shadow(
                        color: WorldMapPalette.coral.opacity(configuration.isPressed ? 0.08 : 0.24),
                        radius: 10,
                        y: configuration.isPressed ? 3 : 7
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private enum WorldMapPalette {
    static let canvas = Color(red: 0.91, green: 0.97, blue: 0.96)
    static let cloud = Color(red: 0.83, green: 0.91, blue: 0.92)
    static let deepSky = Color(red: 0.13, green: 0.39, blue: 0.60)
    static let blueberry = Color(red: 0.24, green: 0.46, blue: 0.70)
    static let ink = Color(red: 0.10, green: 0.21, blue: 0.30)
    static let mutedInk = Color(red: 0.34, green: 0.45, blue: 0.53)
    static let leaf = Color(red: 0.25, green: 0.62, blue: 0.38)
    static let sunflower = Color(red: 0.95, green: 0.67, blue: 0.18)
    static let coral = Color(red: 0.92, green: 0.35, blue: 0.28)
    static let storm = Color(red: 0.42, green: 0.47, blue: 0.74)
    static let night = Color(red: 0.35, green: 0.27, blue: 0.63)
}
