import SwiftUI

/// The farm is the home screen for long-term progress and the bridge between
/// the active level, the shop, and Clara's journal.
struct SkyFarmDashboardView: View {
    @ObservedObject var progress: SkyFarmProgress
    let navigate: (SkyFarmTab) -> Void
    /// Kept optional so the existing dashboard can ship before the route map
    /// is wired, while the map feature can opt in without another redesign.
    let openMap: (() -> Void)?

    @State private var restorationFeedback: String?

    init(
        progress: SkyFarmProgress,
        navigate: @escaping (SkyFarmTab) -> Void,
        openMap: (() -> Void)? = nil
    ) {
        _progress = ObservedObject(wrappedValue: progress)
        self.navigate = navigate
        self.openMap = openMap
    }

    private var nextAchievement: SkyAchievement? {
        progress.achievements.first { !$0.isUnlocked }
    }

    private var equippedItem: SkyShopItem? {
        progress.shopItems.first { $0.id == progress.equippedItemID }
    }

    private var farmRecovery: Double {
        progress.farmRestorationProgress
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                scoreCard
                recoveryCard
                restorationWorkshop
                activitySection
                nextGoalCard
                shortcuts
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.98, blue: 0.96),
                    Color(red: 1, green: 0.97, blue: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Sky Farm")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let openMap {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: openMap) {
                        Label("Routes", systemImage: "map.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .accessibilityHint("Choose an island route")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Label("\(progress.skyPoints) Sky Points", systemImage: "sparkles")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(DashboardPalette.deepSky)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Sky Points: \(progress.skyPoints)")
            }
        }
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SKY POINTS")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.76))
                    Text("\(progress.skyPoints)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 74, height: 74)
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Text("Earn points for parts, rescued chicks, and completed islands.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            if let equippedItem {
                Label("Equipped: \(equippedItem.title)", systemImage: equippedItem.iconName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.14), in: Capsule())
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [DashboardPalette.deepSky, DashboardPalette.blueberry],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .shadow(color: DashboardPalette.deepSky.opacity(0.24), radius: 16, y: 8)
    }

    private var recoveryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(DashboardPalette.mint.opacity(0.22))
                    Image(systemName: "house.and.flag.fill")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(DashboardPalette.leaf)
                }
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Farm Restoration")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.ink)
                    Text(recoveryDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(DashboardPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ProgressView(value: farmRecovery)
                .tint(DashboardPalette.leaf)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            HStack {
                Text("\(progress.totalFarmUpgradeLevels) of \(progress.totalFarmUpgradeCapacity) upgrades complete")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(DashboardPalette.mutedInk)
                Spacer()
                Text("\(Int((farmRecovery * 100).rounded()))%")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(DashboardPalette.leaf)
            }

            HStack(spacing: 8) {
                FarmResourceChip(
                    icon: "gearshape.fill",
                    value: progress.totalPartsFound,
                    label: "parts",
                    tint: DashboardPalette.sunflower
                )
                FarmResourceChip(
                    icon: "leaf.fill",
                    value: progress.seedsPlanted,
                    label: "seeds",
                    tint: DashboardPalette.leaf
                )
                FarmResourceChip(
                    icon: "bird.fill",
                    value: progress.totalChicksRescued,
                    label: "helpers",
                    tint: DashboardPalette.coral
                )
            }
        }
        .padding(17)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(.white.opacity(0.94), lineWidth: 1)
        }
    }

    private var restorationWorkshop: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Restoration Workshop")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.ink)
                    Text("Spend Sky Points after finding the materials on your flights.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(DashboardPalette.mutedInk)
                }

                Spacer(minLength: 8)

                Label("\(progress.restoredFarmBuildingCount)/4", systemImage: "house.and.flag.fill")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(DashboardPalette.leaf)
            }

            ForEach(progress.farmBuildings) { building in
                FarmBuildingCard(building: building) {
                    restore(building)
                }
            }

            if let restorationFeedback {
                Label(restorationFeedback, systemImage: "sparkles")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(DashboardPalette.deepSky)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DashboardPalette.deepSky.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy(duration: 0.28), value: progress.totalFarmUpgradeLevels)
        .animation(.easeInOut(duration: 0.2), value: restorationFeedback)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flight Log")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardPalette.ink)

            HStack(spacing: 10) {
                DashboardStatCard(
                    icon: "gearshape.fill",
                    value: progress.totalPartsFound,
                    label: "parts",
                    tint: DashboardPalette.sunflower
                )
                DashboardStatCard(
                    icon: "bird.fill",
                    value: progress.totalChicksRescued,
                    label: "chicks",
                    tint: DashboardPalette.coral
                )
                DashboardStatCard(
                    icon: "flag.checkered",
                    value: progress.completedLevels,
                    label: "islands",
                    tint: DashboardPalette.deepSky
                )
            }
        }
    }

    @ViewBuilder
    private var nextGoalCard: some View {
        if let nextAchievement {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: nextAchievement.icon)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(DashboardPalette.coral)
                    .frame(width: 52, height: 52)
                    .background(DashboardPalette.coral.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("NEXT GOAL")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(DashboardPalette.coral)
                    Text(nextAchievement.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.ink)
                    Text(nextAchievement.detail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(DashboardPalette.mutedInk)
                        .lineLimit(2)
                    ProgressView(value: Double(nextAchievement.progress), total: Double(max(nextAchievement.target, 1)))
                        .tint(DashboardPalette.coral)
                    Text("\(nextAchievement.progress)/\(nextAchievement.target)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.coral)
                }
            }
            .padding(15)
            .background(DashboardPalette.coral.opacity(0.08), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        } else {
            Label("All current achievements are unlocked — Clara is proud of you!", systemImage: "rosette")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardPalette.leaf)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DashboardPalette.mint.opacity(0.18), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where next?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardPalette.ink)

            if let openMap {
                DashboardWideActionButton(
                    title: "Routes",
                    subtitle: "Choose the next island and see what each restoration unlocks.",
                    icon: "map.fill",
                    tint: DashboardPalette.leaf,
                    action: openMap
                )
            }

            HStack(spacing: 12) {
                DashboardActionButton(
                    title: "Shop",
                    subtitle: "New finds",
                    icon: "bag.fill",
                    tint: DashboardPalette.coral
                ) {
                    navigate(.shop)
                }

                DashboardActionButton(
                    title: "Journal",
                    subtitle: "Tips & goals",
                    icon: "book.closed.fill",
                    tint: DashboardPalette.deepSky
                ) {
                    navigate(.journal)
                }
            }
        }
    }

    private var recoveryDescription: String {
        switch farmRecovery {
        case 0..<0.25:
            "Start with the Sky Coop: every stage makes the home farm feel more alive."
        case 0.25..<0.65:
            "The orchard is growing. Keep collecting seeds and parts to wake the windmill."
        case 0.65..<1:
            "The farm is nearly ready — the balloon only needs its final repairs."
        default:
            "The farm flies again! New islands are waiting for Clara."
        }
    }

    private func restore(_ building: SkyFarmBuilding) {
        let result = progress.upgradeFarmBuilding(building.id)
        withAnimation(.snappy(duration: 0.28)) {
            restorationFeedback = "\(building.title): \(result.message)"
        }
    }
}

private struct DashboardStatCard: View {
    let icon: String
    let value: Int
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tint)
            Text("\(value)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(DashboardPalette.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(DashboardPalette.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(.white.opacity(0.94), lineWidth: 1)
        }
    }
}

private struct FarmResourceChip: View {
    let icon: String
    let value: Int
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
            Text("\(value) \(label)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardPalette.mutedInk)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(tint.opacity(0.1), in: Capsule())
    }
}

private struct FarmBuildingCard: View {
    let building: SkyFarmBuilding
    let restore: () -> Void

    private var nextUpgrade: SkyFarmBuildingUpgrade? {
        building.nextUpgrade
    }

    private var actionTitle: String {
        switch building.availability {
        case .ready:
            return building.level == 0 ? "Build \(nextUpgrade?.title ?? building.title)" : "Upgrade \(nextUpgrade?.title ?? building.title)"
        case .locked:
            return "Locked route"
        case .missingResources:
            return "Gather materials"
        case .insufficientPoints:
            return "Need Sky Points"
        case .restored:
            return "Restored"
        }
    }

    private var actionSymbol: String {
        switch building.availability {
        case .ready:
            return "hammer.fill"
        case .locked:
            return "lock.fill"
        case .missingResources:
            return "backpack.fill"
        case .insufficientPoints:
            return "sparkles"
        case .restored:
            return "checkmark.seal.fill"
        }
    }

    private var availabilityTint: Color {
        switch building.availability {
        case .ready:
            return building.tint
        case .restored:
            return DashboardPalette.leaf
        case .locked, .missingResources, .insufficientPoints:
            return DashboardPalette.mutedInk
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: building.iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(building.tint)
                    .frame(width: 50, height: 50)
                    .background(building.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(building.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.ink)
                    Text(building.detail)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(DashboardPalette.mutedInk)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("LVL \(building.level)/\(building.maximumLevel)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(building.tint)
                    Text(building.currentStageTitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.mutedInk)
                        .lineLimit(1)
                }
            }

            ProgressView(value: building.completionFraction)
                .tint(building.tint)
                .scaleEffect(x: 1, y: 1.25, anchor: .center)

            if let nextUpgrade {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT: \(nextUpgrade.title.uppercased())")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(building.tint)
                    Text(nextUpgrade.requirementSummary)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.mutedInk)
                }
            }

            Text(building.availability.message)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(availabilityTint)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: restore) {
                HStack(spacing: 7) {
                    Image(systemName: actionSymbol)
                        .font(.system(size: 12, weight: .bold))
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))

                    Spacer(minLength: 0)

                    if case .ready = building.availability, let nextUpgrade {
                        Label("\(nextUpgrade.skyPointCost)", systemImage: "sparkles")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                }
                .foregroundStyle(building.availability.isActionEnabled ? .white : availabilityTint)
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .background(
                    building.availability.isActionEnabled ? building.tint : availabilityTint.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(!building.availability.isActionEnabled)
            .accessibilityLabel("\(actionTitle) for \(building.title)")
            .accessibilityHint(building.availability.message)
        }
        .padding(15)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(building.tint.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct DashboardWideActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.ink)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(DashboardPalette.mutedInk)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
            }
            .padding(14)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.96), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Open routes")
    }
}

private struct DashboardActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 43, height: 43)
                    .background(tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(DashboardPalette.ink)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(DashboardPalette.mutedInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.96), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Open section")
    }
}

private enum DashboardPalette {
    static let deepSky = Color(red: 0.15, green: 0.46, blue: 0.62)
    static let blueberry = Color(red: 0.27, green: 0.32, blue: 0.67)
    static let leaf = Color(red: 0.2, green: 0.6, blue: 0.37)
    static let mint = Color(red: 0.51, green: 0.84, blue: 0.58)
    static let sunflower = Color(red: 0.95, green: 0.64, blue: 0.22)
    static let coral = Color(red: 0.91, green: 0.39, blue: 0.31)
    static let ink = Color(red: 0.12, green: 0.22, blue: 0.37)
    static let mutedInk = Color(red: 0.32, green: 0.45, blue: 0.57)
}
