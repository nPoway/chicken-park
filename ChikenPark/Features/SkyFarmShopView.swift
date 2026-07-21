import SwiftUI

/// Screen for spending Sky Points. It does not create its own progress state:
/// all purchases and the selected item are stored in SkyFarmProgress.
struct SkyFarmShopView: View {
    @ObservedObject var progress: SkyFarmProgress

    @State private var selectedCategory: String?
    @State private var feedback: ShopFeedback?

    private var categories: [String] {
        Array(Set(progress.shopItems.map(\.category))).sorted()
    }

    private var visibleItems: [SkyShopItem] {
        guard let selectedCategory else { return progress.shopItems }
        return progress.shopItems.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                balanceCard

                VStack(alignment: .leading, spacing: 5) {
                    Text("Farm Shop")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.primary)

                    Text("Spend Sky Points on useful finds for your next flights.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !categories.isEmpty {
                    categoryPicker
                }

                if visibleItems.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(visibleItems, id: \.id) { item in
                            SkyFarmShopItemCard(
                                item: item,
                                isPurchased: progress.purchasedItemIDs.contains(item.id),
                                isEquipped: progress.equippedItemID == item.id,
                                canAfford: progress.skyPoints >= item.cost
                            ) {
                                handleAction(for: item)
                            }
                        }
                    }
                }

                howItWorksCard
                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                balanceBadge
            }
        }
        .alert(item: $feedback) { feedback in
            Alert(
                title: Text(feedback.title),
                message: Text(feedback.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .accessibilityIdentifier("sky-farm-shop")
    }

    private var balanceCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.24))
                    .frame(width: 54, height: 54)

                Image(systemName: "sparkles")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("SKY POINTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.white.opacity(0.78))
                Text("\(progress.skyPoints)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "basket.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Text("for upgrades")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(18)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.17, green: 0.55, blue: 0.66),
                    Color(red: 0.25, green: 0.36, blue: 0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sky Points: \(progress.skyPoints)")
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SkyFarmShopCategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories, id: \.self) { category in
                    SkyFarmShopCategoryChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 1)
        }
        .accessibilityLabel("Shop filter")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing here yet", systemImage: "basket")
        } description: {
            Text("There are no upgrades in this category yet. Select “All” to view the full catalog.")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var howItWorksCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.orange)
                .frame(width: 30, height: 30)
                .background(Color.orange.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("How it works")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Text("Earn points for parts, rescued chicks, and clean runs. Once purchased, a find stays with Clara forever.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var balanceBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
            Text("\(progress.skyPoints)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
        }
        .foregroundStyle(Color(red: 0.18, green: 0.43, blue: 0.63))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(red: 0.85, green: 0.95, blue: 0.98), in: Capsule())
        .accessibilityLabel("Sky Points: \(progress.skyPoints)")
    }

    private func handleAction(for item: SkyShopItem) {
        if progress.purchasedItemIDs.contains(item.id) {
            guard progress.equippedItemID != item.id else {
                feedback = .alreadyEquipped(item.title)
                return
            }

            progress.equip(item)
            feedback = .equipped(item.title)
            return
        }

        switch progress.purchase(item) {
        case .success:
            progress.equip(item)
            feedback = .purchased(item.title)

        case .alreadyOwned:
            progress.equip(item)
            feedback = .equipped(item.title)

        case .insufficientPoints:
            feedback = .notEnough(item.title, missing: max(1, item.cost - progress.skyPoints))
        }
    }
}

private struct SkyFarmShopItemCard: View {
    let item: SkyShopItem
    let isPurchased: Bool
    let isEquipped: Bool
    let canAfford: Bool
    let action: () -> Void

    private var buttonTitle: String {
        if isEquipped { return "Selected" }
        if isPurchased { return "Use" }
        return "Buy · \(item.cost)"
    }

    private var buttonIcon: String {
        if isEquipped { return "checkmark.circle.fill" }
        if isPurchased { return "wand.and.stars" }
        return "sparkles"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(item.tint.opacity(0.18))
                    .frame(width: 64, height: 64)

                Image(systemName: item.iconName)
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(item.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if isEquipped {
                        Text("SELECTED")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.12), in: Capsule())
                    }
                }

                Text(item.detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(item.effectDescription, systemImage: "plus.circle.fill")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(item.tint)
                    .lineLimit(2)
                    .padding(.top, 1)

                HStack(spacing: 10) {
                    if !isPurchased {
                        Label("\(item.cost) pts", systemImage: "sparkles")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(canAfford ? Color(red: 0.2, green: 0.48, blue: 0.62) : .secondary)
                    }

                    Spacer(minLength: 4)

                    Button(action: action) {
                        Label(buttonTitle, systemImage: buttonIcon)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .buttonStyle(SkyFarmShopActionStyle(
                        tint: item.tint,
                        isEmphasized: !isPurchased && canAfford,
                        isSelected: isEquipped
                    ))
                    .disabled(isEquipped)
                    .accessibilityLabel(accessibilityActionTitle)
                }
                .padding(.top, 3)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isEquipped ? item.tint.opacity(0.48) : Color.primary.opacity(0.06), lineWidth: isEquipped ? 1.5 : 1)
        }
        .opacity(!isPurchased && !canAfford ? 0.78 : 1)
        .accessibilityElement(children: .contain)
    }

    private var accessibilityActionTitle: String {
        if isEquipped { return "\(item.title), already selected" }
        if isPurchased { return "Use: \(item.title)" }
        if canAfford { return "Buy \(item.title) for \(item.cost) points" }
        return "Not enough points for \(item.title)"
    }
}

private struct SkyFarmShopCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? Color(red: 0.2, green: 0.52, blue: 0.64) : Color.primary.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SkyFarmShopActionStyle: ButtonStyle {
    let tint: Color
    let isEmphasized: Bool
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(background, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }

    private var foreground: Color {
        if isSelected { return .secondary }
        return isEmphasized ? .white : tint
    }

    private var background: Color {
        if isSelected { return Color.primary.opacity(0.07) }
        return isEmphasized ? tint : tint.opacity(0.13)
    }
}

private struct ShopFeedback: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    static func purchased(_ title: String) -> ShopFeedback {
        ShopFeedback(
            title: "Find ready",
            message: "“\(title)” was added to your inventory and selected for your next flight."
        )
    }

    static func equipped(_ title: String) -> ShopFeedback {
        ShopFeedback(
            title: "Clara is ready",
            message: "“\(title)” is selected. Its effect will be active in your next adventure."
        )
    }

    static func alreadyEquipped(_ title: String) -> ShopFeedback {
        ShopFeedback(
            title: "Already selected",
            message: "“\(title)” is already equipped on Clara."
        )
    }

    static func notEnough(_ title: String, missing: Int) -> ShopFeedback {
        let pointWord = missing == 1 ? "point" : "points"
        return ShopFeedback(
            title: "A few more points needed",
            message: "You need \(missing) \(pointWord) for “\(title)”. Replay an island, find parts, or rescue a chick."
        )
    }

    static func couldNotPurchase(_ title: String) -> ShopFeedback {
        ShopFeedback(
            title: "Purchase not completed",
            message: "We couldn't add “\(title)”. Try opening the shop again."
        )
    }
}
