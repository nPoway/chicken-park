import Combine
import Foundation
import SwiftUI

/// Events the level uses to report noteworthy player actions.
///
/// The store is independent of a specific scene: the same event set can be
/// sent from both the SpriteKit level and a future world map.
enum SkyProgressEvent: Equatable {
    case partCollected
    case chickRescued
    case checkpointReached
    case seedPlanted
    case secretEggFound
    case levelCompleted(elapsedTime: TimeInterval)
}

/// An item from the Sky Farm shop.
///
/// effectDescription intentionally describes only the cosmetic effect: the
/// shop does not change balance or promise nonexistent gameplay benefits.
struct SkyShopItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let iconName: String
    let cost: Int
    let tint: Color
    let category: String
    let effectDescription: String
}

enum SkyPurchaseResult: Equatable {
    case success
    case alreadyOwned
    case insufficientPoints(required: Int)
}

/// Stable identifiers for the four structures Clara restores between flights.
///
/// Their raw values are stored in the progress snapshot, so the display names
/// and artwork can evolve without invalidating a player's farm.
enum SkyFarmBuildingID: String, CaseIterable, Codable, Hashable, Identifiable {
    case coop
    case orchard
    case mill
    case balloon

    var id: String { rawValue }
}

/// The next visual restoration stage of a farm building. Resource requirements
/// are lifetime milestones (parts found, seeds planted, chicks rescued, and
/// completed flights); Sky Points are the spendable construction currency.
struct SkyFarmBuildingUpgrade: Equatable {
    let title: String
    let skyPointCost: Int
    let partsRequired: Int
    let seedsRequired: Int
    let chicksRequired: Int
    let completedLevelsRequired: Int

    var requirementSummary: String {
        var requirements = ["\(skyPointCost) points"]

        if partsRequired > 0 {
            requirements.append("\(partsRequired) \(partsRequired == 1 ? "part" : "parts")")
        }
        if seedsRequired > 0 {
            requirements.append("\(seedsRequired) \(seedsRequired == 1 ? "seed" : "seeds")")
        }
        if chicksRequired > 0 {
            requirements.append("\(chicksRequired) \(chicksRequired == 1 ? "chick" : "chicks")")
        }
        if completedLevelsRequired > 0 {
            requirements.append("\(completedLevelsRequired) \(completedLevelsRequired == 1 ? "flight" : "flights")")
        }

        return requirements.joined(separator: " • ")
    }
}

/// Describes why a restoration action is, or is not, available right now.
enum SkyFarmBuildingAvailability: Equatable {
    case ready
    case locked(requirement: String)
    case missingResources(requirement: String)
    case insufficientPoints(required: Int)
    case restored

    var isActionEnabled: Bool {
        if case .ready = self {
            return true
        }
        return false
    }

    var message: String {
        switch self {
        case .ready:
            return "Ready to restore"
        case let .locked(requirement):
            return requirement
        case let .missingResources(requirement):
            return requirement
        case let .insufficientPoints(required):
            return "Need \(required) Sky Points"
        case .restored:
            return "Fully restored"
        }
    }
}

/// Result returned by a user-initiated restoration action. The dashboard can
/// show the reason without duplicating economy rules in SwiftUI.
enum SkyFarmBuildingUpgradeResult: Equatable {
    case success(newLevel: Int)
    case alreadyRestored
    case locked(requirement: String)
    case missingResources(requirement: String)
    case insufficientPoints(required: Int)

    var message: String {
        switch self {
        case let .success(newLevel):
            return "Restored to level \(newLevel)!"
        case .alreadyRestored:
            return "This building is already ready for flight."
        case let .locked(requirement), let .missingResources(requirement):
            return requirement
        case let .insufficientPoints(required):
            return "Need \(required) Sky Points"
        }
    }
}

/// View-ready building state. It intentionally contains no persistence logic;
/// `SkyFarmProgress` remains the single authoritative economy store.
struct SkyFarmBuilding: Identifiable {
    let id: SkyFarmBuildingID
    let title: String
    let detail: String
    let iconName: String
    let tint: Color
    let level: Int
    let maximumLevel: Int
    let currentStageTitle: String
    let nextUpgrade: SkyFarmBuildingUpgrade?
    let availability: SkyFarmBuildingAvailability

    var isRestored: Bool {
        level >= maximumLevel
    }

    var completionFraction: Double {
        guard maximumLevel > 0 else { return 1 }
        return min(1, Double(level) / Double(maximumLevel))
    }
}

/// Display state for an achievement. Progress is already capped at target, so
/// the screen can show progress/target without additional logic.
struct SkyAchievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let progress: Int
    let target: Int
    let reward: Int
    let tint: Color
    let isUnlocked: Bool

    var completionFraction: Double {
        guard target > 0 else { return 1 }
        return min(1, Double(progress) / Double(target))
    }
}

/// Persistent player profile: points, purchases, counters, and achievements.
///
/// The store persists only a small Codable snapshot in UserDefaults. The item
/// catalog and achievement text live in the app, so they can change safely
/// without migrating user data.
@MainActor
final class SkyFarmProgress: ObservableObject {
    @Published private(set) var skyPoints: Int

    @Published private(set) var totalPartsFound: Int
    @Published private(set) var totalChicksRescued: Int
    @Published private(set) var completedLevels: Int
    @Published private(set) var seedsPlanted: Int
    @Published private(set) var checkpointCount: Int
    @Published private(set) var totalSecretEggsFound: Int
    @Published private(set) var fastestLevelTime: TimeInterval?

    @Published private(set) var achievements: [SkyAchievement]
    @Published private(set) var purchasedItemIDs: Set<String>
    @Published private(set) var equippedItemID: String?
    @Published private(set) var farmBuildingLevels: [SkyFarmBuildingID: Int]

    let shopItems: [SkyShopItem]

    /// Number of already unlocked achievements for the profile card and navigation.
    var unlockedAchievementCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var equippedItem: SkyShopItem? {
        guard let equippedItemID else { return nil }
        return shopItems.first(where: { $0.id == equippedItemID })
    }

    /// All four restorations, with their live availability calculated from the
    /// same counters and points used by the rest of the app.
    var farmBuildings: [SkyFarmBuilding] {
        Self.farmBuildingDefinitions.map { definition in
            makeFarmBuilding(from: definition)
        }
    }

    /// Overall recovery is based on actual upgrade stages rather than a loose
    /// score formula, so the dashboard and future world map tell the same story.
    var farmRestorationProgress: Double {
        let totalCapacity = totalFarmUpgradeCapacity
        guard totalCapacity > 0 else { return 1 }
        return min(1, Double(totalFarmUpgradeLevels) / Double(totalCapacity))
    }

    var totalFarmUpgradeLevels: Int {
        farmBuildingLevels.values.reduce(0, +)
    }

    var totalFarmUpgradeCapacity: Int {
        Self.farmBuildingDefinitions.reduce(0) { $0 + $1.stages.count }
    }

    var restoredFarmBuildingCount: Int {
        farmBuildings.filter(\.isRestored).count
    }

    var isFarmFullyRestored: Bool {
        restoredFarmBuildingCount == Self.farmBuildingDefinitions.count
    }

    private let defaults: UserDefaults
    private let storageKey: String
    private var unlockedAchievementIDs: Set<String>

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "SkyFarmProgress.v1"
    ) {
        let catalog = Self.makeShopItems()
        let saved = Self.loadSnapshot(from: defaults, key: storageKey)
        let catalogIDs = Set(catalog.map(\.id))
        let purchasedIDs = Set(saved.purchasedItemIDs).intersection(catalogIDs)
        let equippedID = saved.equippedItemID.flatMap { purchasedIDs.contains($0) ? $0 : nil }

        self.defaults = defaults
        self.storageKey = storageKey
        self.shopItems = catalog
        self.skyPoints = max(0, saved.skyPoints)
        self.totalPartsFound = max(0, saved.totalPartsFound)
        self.totalChicksRescued = max(0, saved.totalChicksRescued)
        self.completedLevels = max(0, saved.completedLevels)
        self.seedsPlanted = max(0, saved.seedsPlanted)
        self.checkpointCount = max(0, saved.checkpointCount)
        self.totalSecretEggsFound = max(0, saved.totalSecretEggsFound)
        self.fastestLevelTime = Self.validTime(saved.fastestLevelTime)
        self.purchasedItemIDs = purchasedIDs
        self.equippedItemID = equippedID
        self.farmBuildingLevels = Self.normalizedFarmBuildingLevels(saved.farmBuildingLevels)
        self.unlockedAchievementIDs = Set(saved.unlockedAchievementIDs)
        self.achievements = []

        refreshAchievements(awardingNewRewards: false)
    }

    /// Applies one gameplay event and immediately saves the updated profile.
    func apply(_ event: SkyProgressEvent) {
        switch event {
        case .partCollected:
            totalPartsFound += 1
            skyPoints += 30

        case .chickRescued:
            totalChicksRescued += 1
            skyPoints += 55

        case .checkpointReached:
            checkpointCount += 1
            skyPoints += 15

        case .seedPlanted:
            seedsPlanted += 1
            skyPoints += 5

        case .secretEggFound:
            totalSecretEggsFound += 1
            skyPoints += 40

        case let .levelCompleted(elapsedTime):
            completedLevels += 1
            skyPoints += 120

            if let validTime = Self.validTime(elapsedTime) {
                if let fastestLevelTime {
                    self.fastestLevelTime = min(fastestLevelTime, validTime)
                } else {
                    self.fastestLevelTime = validTime
                }
            }
        }

        refreshAchievements(awardingNewRewards: true)
        persist()
    }

    /// Purchases an item when the player has enough Sky Points.
    @discardableResult
    func purchase(_ item: SkyShopItem) -> SkyPurchaseResult {
        guard shopItems.contains(where: { $0.id == item.id }) else {
            // The shop screen only passes catalog items. Do not expose an
            // internal error in the UI or allow a substituted item to be bought.
            return .alreadyOwned
        }

        guard !purchasedItemIDs.contains(item.id) else {
            return .alreadyOwned
        }

        guard skyPoints >= item.cost else {
            return .insufficientPoints(required: item.cost)
        }

        skyPoints -= item.cost
        purchasedItemIDs.insert(item.id)
        persist()
        return .success
    }

    /// Returns the live state for a single building. This is useful for a
    /// future world map without making it reimplement affordability checks.
    func farmBuilding(for id: SkyFarmBuildingID) -> SkyFarmBuilding? {
        guard let definition = Self.definition(for: id) else { return nil }
        return makeFarmBuilding(from: definition)
    }

    func farmBuildingLevel(for id: SkyFarmBuildingID) -> Int {
        farmBuildingLevels[id] ?? 0
    }

    func isFarmBuildingRestored(_ id: SkyFarmBuildingID) -> Bool {
        guard let definition = Self.definition(for: id) else { return false }
        return farmBuildingLevel(for: id) >= definition.stages.count
    }

    func upgradeAvailability(for id: SkyFarmBuildingID) -> SkyFarmBuildingAvailability {
        guard let definition = Self.definition(for: id) else {
            return .locked(requirement: "This restoration route is unavailable.")
        }
        return availability(for: definition, at: farmBuildingLevel(for: id))
    }

    /// Spends Sky Points and advances exactly one stage when both the route
    /// prerequisite and the earned-resource milestones are met.
    @discardableResult
    func upgradeFarmBuilding(_ id: SkyFarmBuildingID) -> SkyFarmBuildingUpgradeResult {
        guard let definition = Self.definition(for: id) else {
            return .locked(requirement: "This restoration route is unavailable.")
        }

        let currentLevel = farmBuildingLevel(for: id)
        let availability = availability(for: definition, at: currentLevel)

        switch availability {
        case .restored:
            return .alreadyRestored
        case let .locked(requirement):
            return .locked(requirement: requirement)
        case let .missingResources(requirement):
            return .missingResources(requirement: requirement)
        case let .insufficientPoints(required):
            return .insufficientPoints(required: required)
        case .ready:
            let nextUpgrade = definition.stages[currentLevel]
            skyPoints -= nextUpgrade.skyPointCost

            var nextLevels = farmBuildingLevels
            nextLevels[id] = currentLevel + 1
            farmBuildingLevels = nextLevels
            persist()
            return .success(newLevel: currentLevel + 1)
        }
    }

    /// Equips an owned cosmetic item. Unowned items are ignored so the state
    /// cannot be changed accidentally through the UI.
    func equip(_ item: SkyShopItem) {
        guard purchasedItemIDs.contains(item.id), shopItems.contains(where: { $0.id == item.id }) else {
            return
        }

        guard equippedItemID != item.id else { return }
        equippedItemID = item.id
        persist()
    }

    func isPurchased(_ item: SkyShopItem) -> Bool {
        purchasedItemIDs.contains(item.id)
    }

    func isEquipped(_ item: SkyShopItem) -> Bool {
        equippedItemID == item.id
    }

    private func makeFarmBuilding(from definition: SkyFarmBuildingDefinition) -> SkyFarmBuilding {
        let level = farmBuildingLevel(for: definition.id)
        let currentStageTitle: String

        if level == 0 {
            currentStageTitle = "Waiting for restoration"
        } else {
            currentStageTitle = definition.stages[level - 1].title
        }

        return SkyFarmBuilding(
            id: definition.id,
            title: definition.title,
            detail: definition.detail,
            iconName: definition.iconName,
            tint: definition.tint,
            level: level,
            maximumLevel: definition.stages.count,
            currentStageTitle: currentStageTitle,
            nextUpgrade: level < definition.stages.count ? definition.stages[level] : nil,
            availability: availability(for: definition, at: level)
        )
    }

    private func availability(
        for definition: SkyFarmBuildingDefinition,
        at currentLevel: Int
    ) -> SkyFarmBuildingAvailability {
        guard currentLevel < definition.stages.count else {
            return .restored
        }

        if let prerequisite = definition.prerequisite,
           farmBuildingLevel(for: prerequisite.building) < prerequisite.minimumLevel {
            let buildingName = Self.definition(for: prerequisite.building)?.title ?? "previous building"
            return .locked(
                requirement: "Restore \(buildingName) to level \(prerequisite.minimumLevel) first."
            )
        }

        let upgrade = definition.stages[currentLevel]
        if let missingRequirement = missingResourceRequirement(for: upgrade) {
            return .missingResources(requirement: missingRequirement)
        }

        guard skyPoints >= upgrade.skyPointCost else {
            return .insufficientPoints(required: upgrade.skyPointCost)
        }

        return .ready
    }

    private func missingResourceRequirement(for upgrade: SkyFarmBuildingUpgrade) -> String? {
        var missing = [String]()

        appendMissingRequirement(
            current: totalPartsFound,
            required: upgrade.partsRequired,
            singular: "part",
            plural: "parts",
            to: &missing
        )
        appendMissingRequirement(
            current: seedsPlanted,
            required: upgrade.seedsRequired,
            singular: "seed",
            plural: "seeds",
            to: &missing
        )
        appendMissingRequirement(
            current: totalChicksRescued,
            required: upgrade.chicksRequired,
            singular: "chick",
            plural: "chicks",
            to: &missing
        )
        appendMissingRequirement(
            current: completedLevels,
            required: upgrade.completedLevelsRequired,
            singular: "completed flight",
            plural: "completed flights",
            to: &missing
        )

        guard !missing.isEmpty else { return nil }
        return "Find \(missing.joined(separator: ", ")) more."
    }

    private func appendMissingRequirement(
        current: Int,
        required: Int,
        singular: String,
        plural: String,
        to missing: inout [String]
    ) {
        let remainder = max(0, required - current)
        guard remainder > 0 else { return }
        missing.append("\(remainder) \(remainder == 1 ? singular : plural)")
    }

    private func refreshAchievements(awardingNewRewards: Bool) {
        var earnedReward = 0
        var nextUnlockedIDs = unlockedAchievementIDs

        let nextAchievements = Self.achievementDefinitions.map { definition -> SkyAchievement in
            let rawProgress = progress(for: definition.source)
            let reachedTarget = rawProgress >= definition.target
            let wasUnlocked = nextUnlockedIDs.contains(definition.id)

            if reachedTarget, !wasUnlocked {
                nextUnlockedIDs.insert(definition.id)
                if awardingNewRewards {
                    earnedReward += definition.reward
                }
            }

            return SkyAchievement(
                id: definition.id,
                title: definition.title,
                detail: definition.detail,
                icon: definition.icon,
                progress: min(rawProgress, definition.target),
                target: definition.target,
                reward: definition.reward,
                tint: definition.tint,
                isUnlocked: nextUnlockedIDs.contains(definition.id)
            )
        }

        unlockedAchievementIDs = nextUnlockedIDs
        achievements = nextAchievements
        skyPoints += earnedReward
    }

    private func progress(for source: SkyAchievementSource) -> Int {
        switch source {
        case .parts:
            return totalPartsFound
        case .chicks:
            return totalChicksRescued
        case .checkpoints:
            return checkpointCount
        case .seeds:
            return seedsPlanted
        case .levels:
            return completedLevels
        case .secretEggs:
            return totalSecretEggsFound
        case .quickFlight:
            guard let fastestLevelTime else { return 0 }
            return fastestLevelTime <= 90 ? 1 : 0
        }
    }

    private func persist() {
        let snapshot = SkyFarmProgressSnapshot(
            schemaVersion: 3,
            skyPoints: skyPoints,
            totalPartsFound: totalPartsFound,
            totalChicksRescued: totalChicksRescued,
            completedLevels: completedLevels,
            seedsPlanted: seedsPlanted,
            checkpointCount: checkpointCount,
            totalSecretEggsFound: totalSecretEggsFound,
            fastestLevelTime: fastestLevelTime,
            purchasedItemIDs: Array(purchasedItemIDs).sorted(),
            equippedItemID: equippedItemID,
            unlockedAchievementIDs: Array(unlockedAchievementIDs).sorted(),
            farmBuildingLevels: Dictionary(
                uniqueKeysWithValues: farmBuildingLevels.map { ($0.key.rawValue, $0.value) }
            )
        )

        guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(encoded, forKey: storageKey)
    }

    private static func loadSnapshot(from defaults: UserDefaults, key: String) -> SkyFarmProgressSnapshot {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(SkyFarmProgressSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    private static func validTime(_ value: TimeInterval?) -> TimeInterval? {
        guard let value, value.isFinite, value > 0 else { return nil }
        return value
    }

    private static func makeShopItems() -> [SkyShopItem] {
        [
            SkyShopItem(
                id: "sunny_bandana",
                title: "Sunny Bandana",
                detail: "A warm accessory for Clara.",
                iconName: "sun.max.fill",
                cost: 80,
                tint: Color(red: 1, green: 0.66, blue: 0.23),
                category: "Styles",
                effectDescription: "Cosmetic item — does not affect stats."
            ),
            SkyShopItem(
                id: "cloud_parachute",
                title: "Cloud Parachute",
                detail: "A fluffy cover for her parachute wings.",
                iconName: "cloud.sun.fill",
                cost: 140,
                tint: Color(red: 0.42, green: 0.76, blue: 0.95),
                category: "Styles",
                effectDescription: "Cosmetic item — does not affect stats."
            ),
            SkyShopItem(
                id: "lavender_trail",
                title: "Lavender Trail",
                detail: "A gentle cloud behind fast wingbeats.",
                iconName: "sparkles",
                cost: 180,
                tint: Color(red: 0.68, green: 0.55, blue: 0.94),
                category: "Trails",
                effectDescription: "Cosmetic item — does not affect stats."
            ),
            SkyShopItem(
                id: "starlight_badge",
                title: "Firefly Badge",
                detail: "A small reward for a brave pilot.",
                iconName: "star.fill",
                cost: 240,
                tint: Color(red: 0.99, green: 0.79, blue: 0.27),
                category: "Badges",
                effectDescription: "Cosmetic item — does not affect stats."
            )
        ]
    }

    private static func definition(for id: SkyFarmBuildingID) -> SkyFarmBuildingDefinition? {
        farmBuildingDefinitions.first { $0.id == id }
    }

    private static func normalizedFarmBuildingLevels(_ savedLevels: [String: Int]) -> [SkyFarmBuildingID: Int] {
        Dictionary(
            uniqueKeysWithValues: SkyFarmBuildingID.allCases.map { id in
                let maximumLevel = definition(for: id)?.stages.count ?? 0
                let savedLevel = max(0, savedLevels[id.rawValue] ?? 0)
                return (id, min(savedLevel, maximumLevel))
            }
        )
    }

    private static let farmBuildingDefinitions: [SkyFarmBuildingDefinition] = [
        SkyFarmBuildingDefinition(
            id: .coop,
            title: "Sky Coop",
            detail: "A warm home where rescued chicks become farm helpers.",
            iconName: "house.and.flag.fill",
            tint: Color(red: 0.94, green: 0.5, blue: 0.3),
            prerequisite: nil,
            stages: [
                SkyFarmBuildingUpgrade(
                    title: "Foundation",
                    skyPointCost: 80,
                    partsRequired: 1,
                    seedsRequired: 0,
                    chicksRequired: 0,
                    completedLevelsRequired: 0
                ),
                SkyFarmBuildingUpgrade(
                    title: "Roost",
                    skyPointCost: 130,
                    partsRequired: 3,
                    seedsRequired: 0,
                    chicksRequired: 1,
                    completedLevelsRequired: 0
                ),
                SkyFarmBuildingUpgrade(
                    title: "Lantern Loft",
                    skyPointCost: 190,
                    partsRequired: 5,
                    seedsRequired: 2,
                    chicksRequired: 1,
                    completedLevelsRequired: 0
                )
            ]
        ),
        SkyFarmBuildingDefinition(
            id: .orchard,
            title: "Cloud Orchard",
            detail: "Grow a garden that sends useful seeds back to the routes.",
            iconName: "leaf.fill",
            tint: Color(red: 0.23, green: 0.65, blue: 0.38),
            prerequisite: SkyFarmBuildingPrerequisite(building: .coop, minimumLevel: 1),
            stages: [
                SkyFarmBuildingUpgrade(
                    title: "Starter Beds",
                    skyPointCost: 110,
                    partsRequired: 2,
                    seedsRequired: 1,
                    chicksRequired: 0,
                    completedLevelsRequired: 0
                ),
                SkyFarmBuildingUpgrade(
                    title: "Fruit Canopy",
                    skyPointCost: 160,
                    partsRequired: 4,
                    seedsRequired: 4,
                    chicksRequired: 0,
                    completedLevelsRequired: 0
                ),
                SkyFarmBuildingUpgrade(
                    title: "Blooming Garden",
                    skyPointCost: 220,
                    partsRequired: 6,
                    seedsRequired: 7,
                    chicksRequired: 0,
                    completedLevelsRequired: 0
                )
            ]
        ),
        SkyFarmBuildingDefinition(
            id: .mill,
            title: "Windmill",
            detail: "Restore the sails to power the farm's garden machinery.",
            iconName: "wind",
            tint: Color(red: 0.28, green: 0.59, blue: 0.85),
            prerequisite: SkyFarmBuildingPrerequisite(building: .orchard, minimumLevel: 1),
            stages: [
                SkyFarmBuildingUpgrade(
                    title: "Repair Frame",
                    skyPointCost: 140,
                    partsRequired: 3,
                    seedsRequired: 2,
                    chicksRequired: 0,
                    completedLevelsRequired: 0
                ),
                SkyFarmBuildingUpgrade(
                    title: "Turning Sails",
                    skyPointCost: 210,
                    partsRequired: 6,
                    seedsRequired: 5,
                    chicksRequired: 1,
                    completedLevelsRequired: 0
                ),
                SkyFarmBuildingUpgrade(
                    title: "Powering the Farm",
                    skyPointCost: 280,
                    partsRequired: 8,
                    seedsRequired: 8,
                    chicksRequired: 1,
                    completedLevelsRequired: 1
                )
            ]
        ),
        SkyFarmBuildingDefinition(
            id: .balloon,
            title: "Farm Balloon",
            detail: "The final lift that carries Clara's whole farm to new islands.",
            iconName: "airplane",
            tint: Color(red: 0.72, green: 0.47, blue: 0.87),
            prerequisite: SkyFarmBuildingPrerequisite(building: .mill, minimumLevel: 1),
            stages: [
                SkyFarmBuildingUpgrade(
                    title: "Envelope Patch",
                    skyPointCost: 180,
                    partsRequired: 4,
                    seedsRequired: 0,
                    chicksRequired: 1,
                    completedLevelsRequired: 0
                ),
                SkyFarmBuildingUpgrade(
                    title: "Lift Test",
                    skyPointCost: 260,
                    partsRequired: 7,
                    seedsRequired: 0,
                    chicksRequired: 2,
                    completedLevelsRequired: 1
                ),
                SkyFarmBuildingUpgrade(
                    title: "Ready for Flight",
                    skyPointCost: 340,
                    partsRequired: 10,
                    seedsRequired: 10,
                    chicksRequired: 2,
                    completedLevelsRequired: 2
                )
            ]
        )
    ]

    private static let achievementDefinitions: [SkyAchievementDefinition] = [
        SkyAchievementDefinition(
            id: "first_part",
            title: "First Feather",
            detail: "Collect your first Sky Farm part.",
            icon: "gearshape.fill",
            target: 1,
            reward: 20,
            tint: Color(red: 1, green: 0.72, blue: 0.22),
            source: .parts
        ),
        SkyAchievementDefinition(
            id: "chick_friend",
            title: "Pip's Friend",
            detail: "Rescue your first chick.",
            icon: "heart.fill",
            target: 1,
            reward: 30,
            tint: Color(red: 1, green: 0.48, blue: 0.43),
            source: .chicks
        ),
        SkyAchievementDefinition(
            id: "cloud_gardener",
            title: "Cloud Gardener",
            detail: "Grow 10 temporary plants from seeds.",
            icon: "leaf.fill",
            target: 10,
            reward: 45,
            tint: Color(red: 0.37, green: 0.72, blue: 0.34),
            source: .seeds
        ),
        SkyAchievementDefinition(
            id: "route_keeper",
            title: "Route Keeper",
            detail: "Activate 3 checkpoints.",
            icon: "flag.checkered",
            target: 3,
            reward: 40,
            tint: Color(red: 0.28, green: 0.64, blue: 0.91),
            source: .checkpoints
        ),
        SkyAchievementDefinition(
            id: "farm_mechanic",
            title: "Farm Mechanic",
            detail: "Find 9 farm parts.",
            icon: "wrench.and.screwdriver.fill",
            target: 9,
            reward: 80,
            tint: Color(red: 0.91, green: 0.54, blue: 0.22),
            source: .parts
        ),
        SkyAchievementDefinition(
            id: "island_pioneer",
            title: "Island Pioneer",
            detail: "Complete 3 flights.",
            icon: "map.fill",
            target: 3,
            reward: 90,
            tint: Color(red: 0.39, green: 0.49, blue: 0.91),
            source: .levels
        ),
        SkyAchievementDefinition(
            id: "golden_glint",
            title: "Golden Glint",
            detail: "Find a secret egg above the garden canopy.",
            icon: "seal.fill",
            target: 1,
            reward: 50,
            tint: Color(red: 0.94, green: 0.65, blue: 0.18),
            source: .secretEggs
        ),
        SkyAchievementDefinition(
            id: "swift_wings",
            title: "Swift Wings",
            detail: "Finish a level in under 90 seconds.",
            icon: "wind",
            target: 1,
            reward: 70,
            tint: Color(red: 0.48, green: 0.78, blue: 0.9),
            source: .quickFlight
        )
    ]
}

private struct SkyFarmBuildingDefinition {
    let id: SkyFarmBuildingID
    let title: String
    let detail: String
    let iconName: String
    let tint: Color
    let prerequisite: SkyFarmBuildingPrerequisite?
    let stages: [SkyFarmBuildingUpgrade]
}

private struct SkyFarmBuildingPrerequisite {
    let building: SkyFarmBuildingID
    let minimumLevel: Int
}

private enum SkyAchievementSource {
    case parts
    case chicks
    case checkpoints
    case seeds
    case levels
    case secretEggs
    case quickFlight
}

private struct SkyAchievementDefinition {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let target: Int
    let reward: Int
    let tint: Color
    let source: SkyAchievementSource
}

private struct SkyFarmProgressSnapshot: Codable {
    let schemaVersion: Int
    let skyPoints: Int
    let totalPartsFound: Int
    let totalChicksRescued: Int
    let completedLevels: Int
    let seedsPlanted: Int
    let checkpointCount: Int
    let totalSecretEggsFound: Int
    let fastestLevelTime: TimeInterval?
    let purchasedItemIDs: [String]
    let equippedItemID: String?
    let unlockedAchievementIDs: [String]
    let farmBuildingLevels: [String: Int]

    static let empty = SkyFarmProgressSnapshot(
        schemaVersion: 3,
        skyPoints: 0,
        totalPartsFound: 0,
        totalChicksRescued: 0,
        completedLevels: 0,
        seedsPlanted: 0,
        checkpointCount: 0,
        totalSecretEggsFound: 0,
        fastestLevelTime: nil,
        purchasedItemIDs: [],
        equippedItemID: nil,
        unlockedAchievementIDs: [],
        farmBuildingLevels: [:]
    )

    init(
        schemaVersion: Int,
        skyPoints: Int,
        totalPartsFound: Int,
        totalChicksRescued: Int,
        completedLevels: Int,
        seedsPlanted: Int,
        checkpointCount: Int,
        totalSecretEggsFound: Int,
        fastestLevelTime: TimeInterval?,
        purchasedItemIDs: [String],
        equippedItemID: String?,
        unlockedAchievementIDs: [String],
        farmBuildingLevels: [String: Int]
    ) {
        self.schemaVersion = schemaVersion
        self.skyPoints = skyPoints
        self.totalPartsFound = totalPartsFound
        self.totalChicksRescued = totalChicksRescued
        self.completedLevels = completedLevels
        self.seedsPlanted = seedsPlanted
        self.checkpointCount = checkpointCount
        self.totalSecretEggsFound = totalSecretEggsFound
        self.fastestLevelTime = fastestLevelTime
        self.purchasedItemIDs = purchasedItemIDs
        self.equippedItemID = equippedItemID
        self.unlockedAchievementIDs = unlockedAchievementIDs
        self.farmBuildingLevels = farmBuildingLevels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        skyPoints = try container.decodeIfPresent(Int.self, forKey: .skyPoints) ?? 0
        totalPartsFound = try container.decodeIfPresent(Int.self, forKey: .totalPartsFound) ?? 0
        totalChicksRescued = try container.decodeIfPresent(Int.self, forKey: .totalChicksRescued) ?? 0
        completedLevels = try container.decodeIfPresent(Int.self, forKey: .completedLevels) ?? 0
        seedsPlanted = try container.decodeIfPresent(Int.self, forKey: .seedsPlanted) ?? 0
        checkpointCount = try container.decodeIfPresent(Int.self, forKey: .checkpointCount) ?? 0
        totalSecretEggsFound = try container.decodeIfPresent(Int.self, forKey: .totalSecretEggsFound) ?? 0
        fastestLevelTime = try container.decodeIfPresent(TimeInterval.self, forKey: .fastestLevelTime)
        purchasedItemIDs = try container.decodeIfPresent([String].self, forKey: .purchasedItemIDs) ?? []
        equippedItemID = try container.decodeIfPresent(String.self, forKey: .equippedItemID)
        unlockedAchievementIDs = try container.decodeIfPresent([String].self, forKey: .unlockedAchievementIDs) ?? []
        farmBuildingLevels = try container.decodeIfPresent([String: Int].self, forKey: .farmBuildingLevels) ?? [:]
    }
}
