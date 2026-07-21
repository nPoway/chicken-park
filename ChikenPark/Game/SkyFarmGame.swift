import Combine
import Foundation
import SwiftUI

enum SkyFarmPhase: Equatable {
    case intro
    case running
    case completed
}

enum SkyPlatformStyle {
    case island
    case branch
}

enum SkyPlantKind {
    case bridge
    case mushroom
    case vine
}

enum SkySurfaceKind {
    case platform
    case mushroom
    case vineLeaf
}

enum SkyToastTone {
    case sunshine
    case leaf
    case coral
    case cloud
}

struct SkyRect {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var maxX: CGFloat { x + width }
    var maxY: CGFloat { y + height }

    func intersects(_ other: SkyRect) -> Bool {
        x < other.maxX && maxX > other.x && y < other.maxY && maxY > other.y
    }

    func contains(x pointX: CGFloat, y pointY: CGFloat) -> Bool {
        pointX >= x && pointX <= maxX && pointY >= y && pointY <= maxY
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct SkyPlatform: Identifiable {
    let id: String
    let rect: SkyRect
    let style: SkyPlatformStyle
    let flowers: Int
}

struct SkySurface: Identifiable {
    let id: String
    let rect: SkyRect
    let kind: SkySurfaceKind
}

struct SkyPlayer {
    var x: CGFloat = 142
    var y: CGFloat = 490
    var width: CGFloat = 46
    var height: CGFloat = 58
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0
    var facing: CGFloat = 1
    var isGrounded = false
    var isGliding = false
    var coyoteTime: TimeInterval = 0
    var jumpBuffer: TimeInterval = 0
    var seeds = 5
    var hearts = 3
    var invulnerability: TimeInterval = 0
    var trailClock: TimeInterval = 0

    var rect: SkyRect {
        SkyRect(x: x, y: y, width: width, height: height)
    }

    var center: CGPoint {
        CGPoint(x: x + width / 2, y: y + height / 2)
    }
}

struct SkyPart: Identifiable {
    let id: String
    let x: CGFloat
    let y: CGFloat
    let label: String
    var isCollected = false
}

struct SkySeedBed: Identifiable {
    let id: String
    let rect: SkyRect
    let kind: SkyPlantKind
    let title: String
    let tint: Color
    var isGrown = false
    var isPending = false
}

struct SkySeedFlight {
    let source: CGPoint
    let target: CGPoint
    let bedID: String
    let duration: TimeInterval
    var elapsed: TimeInterval = 0

    var progress: CGFloat {
        guard duration > 0 else { return 1 }
        return min(1, CGFloat(elapsed / duration))
    }

    var position: CGPoint {
        let eased = 1 - pow(1 - progress, 3)
        let x = source.x + (target.x - source.x) * eased
        let y = source.y + (target.y - source.y) * eased - CGFloat(sin(Double(progress * .pi))) * 108
        return CGPoint(x: x, y: y)
    }
}

struct SkyGrownPlant: Identifiable {
    let id = UUID()
    let kind: SkyPlantKind
    let bedID: String
    let rect: SkyRect
    let leaves: [SkyRect]
    let maximumLifetime: TimeInterval
    var remainingLifetime: TimeInterval

    var opacity: CGFloat {
        guard remainingLifetime < 4 else { return 1 }
        return max(0, CGFloat(remainingLifetime / 4))
    }
}

struct SkyRaven: Identifiable {
    let id = UUID()
    let anchorX: CGFloat
    let anchorY: CGFloat
    let range: CGFloat
    let amplitude: CGFloat
    let speed: CGFloat
    let offset: CGFloat
    var x: CGFloat
    var y: CGFloat
}

struct SkyWind {
    let rect: SkyRect
    let forceX: CGFloat
    let forceY: CGFloat
    let label: String
}

struct SkyToast {
    let message: String
    let tone: SkyToastTone
    let maximumLifetime: TimeInterval
    var remainingLifetime: TimeInterval
}

@MainActor
final class SkyFarmGame: ObservableObject {
    static let worldWidth: CGFloat = 4_650
    static let worldHeight: CGFloat = 720
    /// A slightly tighter framing keeps Clara and interactive props readable on a phone.
    static let cameraZoom: CGFloat = 0.86
    static let maximumSeeds = 5

    private let gravity: CGFloat = 1_850
    private let glideGravity: CGFloat = 460
    private let coyoteDuration: TimeInterval = 0.12
    private let jumpBufferDuration: TimeInterval = 0.13

    let platforms: [SkyPlatform] = [
        SkyPlatform(id: "home", rect: SkyRect(x: -120, y: 590, width: 830, height: 220), style: .island, flowers: 5),
        SkyPlatform(id: "orchard", rect: SkyRect(x: 1_120, y: 560, width: 850, height: 230), style: .island, flowers: 7),
        SkyPlatform(id: "loft", rect: SkyRect(x: 1_970, y: 385, width: 425, height: 165), style: .branch, flowers: 2),
        SkyPlatform(id: "westGarden", rect: SkyRect(x: 2_800, y: 525, width: 430, height: 190), style: .island, flowers: 4),
        SkyPlatform(id: "canopy", rect: SkyRect(x: 3_410, y: 300, width: 400, height: 180), style: .branch, flowers: 3),
        SkyPlatform(id: "lighthouse", rect: SkyRect(x: 3_750, y: 560, width: 900, height: 220), style: .island, flowers: 7)
    ]

    let winds: [SkyWind] = [
        SkyWind(
            rect: SkyRect(x: 2_225, y: 145, width: 820, height: 455),
            forceX: 600,
            forceY: -210,
            label: "Warm Updraft"
        )
    ]

    let goalRect = SkyRect(x: 4_410, y: 445, width: 98, height: 120)
    /// An optional reward tucked above the canopy. It is deliberately a fixed
    /// world coordinate so a restart always presents the same discovery route.
    let secretEggPosition = CGPoint(x: 3_735, y: 224)

    @Published private(set) var phase: SkyFarmPhase = .intro
    @Published private(set) var player = SkyPlayer()
    @Published private(set) var cameraX: CGFloat = 0
    @Published private(set) var parts: [SkyPart] = []
    @Published private(set) var beds: [SkySeedBed] = []
    @Published private(set) var grownPlants: [SkyGrownPlant] = []
    @Published private(set) var seedFlight: SkySeedFlight?
    @Published private(set) var ravens: [SkyRaven] = []
    @Published private(set) var chickIsRescued = false
    @Published private(set) var checkpointIsActive = false
    @Published private(set) var secretEggIsFound = false
    @Published private(set) var secretEggCount = 0
    @Published private(set) var toast: SkyToast?
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var animationTime: TimeInterval = 0

    private var lastTick: Date?
    private var leftPressed = false
    private var rightPressed = false
    private var glideHeld = false
    private var checkpoint = CGPoint(x: 142, y: 490)
    private var goalAnnounced = false

    init() {
        reset(phase: .intro)
    }

    var collectedPartsCount: Int {
        parts.filter(\.isCollected).count
    }

    var isGoalReady: Bool {
        parts.allSatisfy(\.isCollected) && chickIsRescued
    }

    var isChickNearby: Bool {
        distance(from: player.center, to: CGPoint(x: 3_910, y: 499)) < 82
    }

    var activeBed: SkySeedBed? {
        nearestReadyBed()
    }

    var currentHint: String {
        guard phase == .running else {
            return "Clara is ready for her first flight"
        }
        if let bridge = beds.first(where: { $0.id == "bridge" }), !bridge.isGrown, player.x < 700 {
            return "Walk up to a garden bed and throw a seed"
        }
        if player.x > 1_500, player.x < 1_960,
           let mushroom = beds.first(where: { $0.id == "mushroom" }), !mushroom.isGrown {
            return "The mushroom trampoline will launch Clara higher"
        }
        if player.x > 2_900, player.x < 3_410,
           let vine = beds.first(where: { $0.id == "vine" }), !vine.isGrown {
            return "The vine will help you reach the last part"
        }
        if !secretEggIsFound, player.x > 3_360, player.x < 3_880 {
            return "A golden glint is hiding above the canopy"
        }
        if collectedPartsCount < parts.count {
            return "Find the farm parts: \(parts.count - collectedPartsCount) left"
        }
        if !chickIsRescued {
            return "Pip is waiting on the final island"
        }
        return "The lighthouse is lit — fly to the finish"
    }

    func start() {
        reset(phase: .running)
    }

    func restart() {
        reset(phase: .running)
    }

    func setMove(direction: Int, isPressed: Bool) {
        guard phase == .running else { return }
        if direction < 0 {
            leftPressed = isPressed
        } else {
            rightPressed = isPressed
        }
    }

    func pressJump() {
        guard phase == .running else { return }
        player.jumpBuffer = jumpBufferDuration
        glideHeld = true
    }

    func setGlideHeld(_ isHeld: Bool) {
        guard phase == .running else { return }
        glideHeld = isHeld
    }

    func plantSeed() {
        guard phase == .running else { return }
        guard seedFlight == nil else { return }
        guard player.seeds > 0 else {
            showToast("Out of seeds", tone: .coral)
            return
        }
        guard let target = nearestReadyBed() else {
            showToast("No empty garden bed nearby", tone: .sunshine)
            return
        }

        player.seeds -= 1
        guard let index = beds.firstIndex(where: { $0.id == target.id }) else { return }
        beds[index].isPending = true
        let source = CGPoint(x: player.center.x + player.facing * 17, y: player.y + 22)
        let destination = CGPoint(x: target.rect.x + target.rect.width / 2, y: target.rect.y + 7)
        let flightDistance = distance(from: source, to: destination)
        seedFlight = SkySeedFlight(
            source: source,
            target: destination,
            bedID: target.id,
            duration: min(max(flightDistance / 660, 0.32), 0.75)
        )
    }

    func rescueChick() {
        guard phase == .running, !chickIsRescued else { return }
        guard isChickNearby else {
            showToast("Walk up to Pip's cage", tone: .cloud)
            return
        }
        chickIsRescued = true
        showToast("Pip is rescued! He's flying to the farm", tone: .sunshine, duration: 2.8)
        announceGoalIfNeeded()
    }

    func tick(at date: Date, viewport: CGSize) {
        guard viewport.width > 0, viewport.height > 0 else { return }
        let delta: TimeInterval
        if let lastTick {
            delta = min(max(date.timeIntervalSince(lastTick), 0), 1.0 / 30.0)
        } else {
            self.lastTick = date
            updateCamera(for: viewport, delta: 0)
            return
        }
        lastTick = date
        animationTime += delta
        updateToast(delta: delta)
        updateRavens()

        guard phase == .running else {
            updateCamera(for: viewport, delta: delta)
            return
        }

        elapsedTime += delta
        updateSeedFlight(delta: delta)
        updateGrownPlants(delta: delta)
        updatePlayer(delta: delta)
        updateCheckpoint()
        updateCollectibles()
        updateSecretEgg()
        updateRavensCollision()
        updateGoal()
        updateCamera(for: viewport, delta: delta)
    }

    func resetClock() {
        lastTick = nil
    }

    func releaseControls() {
        leftPressed = false
        rightPressed = false
        glideHeld = false
    }

    private func reset(phase newPhase: SkyFarmPhase) {
        phase = newPhase
        player = SkyPlayer()
        cameraX = 0
        parts = [
            SkyPart(id: "propeller", x: 470, y: 510, label: "windmill blade"),
            SkyPart(id: "gear", x: 2_190, y: 305, label: "garden mechanism"),
            SkyPart(id: "lantern", x: 3_600, y: 225, label: "greenhouse lantern")
        ]
        beds = [
            SkySeedBed(
                id: "bridge",
                rect: SkyRect(x: 638, y: 570, width: 65, height: 18),
                kind: .bridge,
                title: "bridge",
                tint: Color(red: 0.96, green: 0.66, blue: 0.34)
            ),
            SkySeedBed(
                id: "mushroom",
                rect: SkyRect(x: 1_640, y: 540, width: 68, height: 18),
                kind: .mushroom,
                title: "mushroom trampoline",
                tint: Color(red: 0.94, green: 0.49, blue: 0.41)
            ),
            SkySeedBed(
                id: "vine",
                rect: SkyRect(x: 2_990, y: 505, width: 70, height: 18),
                kind: .vine,
                title: "vine",
                tint: Color(red: 0.48, green: 0.75, blue: 0.40)
            )
        ]
        grownPlants = []
        seedFlight = nil
        ravens = [
            SkyRaven(anchorX: 2_540, anchorY: 305, range: 165, amplitude: 48, speed: 1.45, offset: 0.3, x: 2_540, y: 305),
            SkyRaven(anchorX: 2_920, anchorY: 250, range: 125, amplitude: 38, speed: 1.8, offset: 2.1, x: 2_920, y: 250)
        ]
        chickIsRescued = false
        checkpointIsActive = false
        secretEggIsFound = false
        secretEggCount = 0
        checkpoint = CGPoint(x: 142, y: 490)
        toast = nil
        elapsedTime = 0
        leftPressed = false
        rightPressed = false
        glideHeld = false
        goalAnnounced = false
        lastTick = nil
    }

    private func updateSeedFlight(delta: TimeInterval) {
        guard var flight = seedFlight else { return }
        flight.elapsed += delta
        seedFlight = flight
        if flight.progress >= 1 {
            seedFlight = nil
            growBed(id: flight.bedID)
        }
    }

    private func growBed(id: String) {
        guard let bedIndex = beds.firstIndex(where: { $0.id == id }) else { return }
        beds[bedIndex].isPending = false
        beds[bedIndex].isGrown = true
        let bed = beds[bedIndex]

        switch bed.kind {
        case .bridge:
            grownPlants.append(
                SkyGrownPlant(
                    kind: .bridge,
                    bedID: id,
                    rect: SkyRect(x: 690, y: 531, width: 405, height: 30),
                    leaves: [],
                    maximumLifetime: 36,
                    remainingLifetime: 36
                )
            )
            showToast("A temporary bridge has grown", tone: .leaf)
        case .mushroom:
            grownPlants.append(
                SkyGrownPlant(
                    kind: .mushroom,
                    bedID: id,
                    rect: SkyRect(x: 1_766, y: 510, width: 130, height: 50),
                    leaves: [],
                    maximumLifetime: 32,
                    remainingLifetime: 32
                )
            )
            showToast("Mushroom trampoline is ready!", tone: .coral)
        case .vine:
            grownPlants.append(
                SkyGrownPlant(
                    kind: .vine,
                    bedID: id,
                    rect: SkyRect(x: 3_170, y: 305, width: 250, height: 225),
                    leaves: [
                        SkyRect(x: 3_170, y: 463, width: 128, height: 21),
                        SkyRect(x: 3_260, y: 385, width: 128, height: 21),
                        SkyRect(x: 3_342, y: 307, width: 128, height: 21)
                    ],
                    maximumLifetime: 34,
                    remainingLifetime: 34
                )
            )
            showToast("The vine has woven a ladder", tone: .leaf)
        }
    }

    private func updateGrownPlants(delta: TimeInterval) {
        var expiredBedIDs: [String] = []
        for index in grownPlants.indices {
            grownPlants[index].remainingLifetime -= delta
            if grownPlants[index].remainingLifetime <= 0 {
                expiredBedIDs.append(grownPlants[index].bedID)
            }
        }
        guard !expiredBedIDs.isEmpty else { return }
        grownPlants.removeAll { $0.remainingLifetime <= 0 }
        for bedID in expiredBedIDs {
            if let bedIndex = beds.firstIndex(where: { $0.id == bedID }) {
                beds[bedIndex].isGrown = false
                beds[bedIndex].isPending = false
            }
        }
        showToast("The plant turned back into a seed", tone: .sunshine, duration: 1.8)
    }

    private func updatePlayer(delta: TimeInterval) {
        let wasGrounded = player.isGrounded
        if wasGrounded {
            player.coyoteTime = coyoteDuration
        } else {
            player.coyoteTime = max(0, player.coyoteTime - delta)
        }
        player.jumpBuffer = max(0, player.jumpBuffer - delta)
        player.invulnerability = max(0, player.invulnerability - delta)
        player.trailClock = max(0, player.trailClock - delta)

        let direction = (rightPressed ? 1 : 0) - (leftPressed ? 1 : 0)
        if direction != 0 {
            player.facing = CGFloat(direction)
        }
        let targetSpeed = CGFloat(direction) * (wasGrounded ? 300 : 270)
        let acceleration: CGFloat = wasGrounded ? 2_100 : 1_260
        player.velocityX = approach(player.velocityX, target: targetSpeed, delta: acceleration * CGFloat(delta))
        if direction == 0 {
            player.velocityX = approach(
                player.velocityX,
                target: 0,
                delta: (wasGrounded ? 2_550 : 410) * CGFloat(delta)
            )
        }

        if player.jumpBuffer > 0, player.coyoteTime > 0 {
            player.velocityY = -665
            player.isGrounded = false
            player.coyoteTime = 0
            player.jumpBuffer = 0
        }

        player.isGliding = !player.isGrounded && glideHeld && player.velocityY > -120
        var currentGravity = player.isGliding ? glideGravity : gravity
        for wind in winds where wind.rect.contains(x: player.center.x, y: player.center.y) {
            player.velocityX = approach(player.velocityX, target: wind.forceX * 0.72, delta: 860 * CGFloat(delta))
            player.velocityY += wind.forceY * CGFloat(delta)
            currentGravity *= 0.68
        }
        player.velocityY += currentGravity * CGFloat(delta)
        player.velocityY = min(player.velocityY, player.isGliding ? 165 : 940)

        let surfaces = allSurfaces
        let oldX = player.x
        player.x += player.velocityX * CGFloat(delta)
        for surface in surfaces where player.rect.intersects(surface.rect) {
            if player.velocityX > 0, oldX + player.width <= surface.rect.x + 18 {
                player.x = surface.rect.x - player.width
                player.velocityX = 0
            } else if player.velocityX < 0, oldX >= surface.rect.maxX - 18 {
                player.x = surface.rect.maxX
                player.velocityX = 0
            }
        }

        let oldY = player.y
        player.y += player.velocityY * CGFloat(delta)
        player.isGrounded = false
        for surface in surfaces where player.rect.intersects(surface.rect) {
            if player.velocityY >= 0, oldY + player.height <= surface.rect.y + 22 {
                player.y = surface.rect.y - player.height
                player.isGrounded = true
                player.isGliding = false
                player.coyoteTime = coyoteDuration
                if surface.kind == .mushroom {
                    player.velocityY = -955
                    player.isGrounded = false
                    showToast("Bouncy jump!", tone: .coral, duration: 1.25)
                } else {
                    player.velocityY = 0
                }
            } else if player.velocityY < 0, oldY >= surface.rect.maxY - 18 {
                player.y = surface.rect.maxY
                player.velocityY = 0
            }
        }

        player.x = min(max(player.x, -100), Self.worldWidth - player.width + 45)
        if player.y > Self.worldHeight + 220 {
            showToast("Clouds are soft, but stay on course", tone: .coral)
            respawnPlayer()
        }
    }

    private var allSurfaces: [SkySurface] {
        var surfaces = platforms.map {
            SkySurface(id: $0.id, rect: $0.rect, kind: .platform)
        }
        for plant in grownPlants {
            switch plant.kind {
            case .bridge:
                surfaces.append(SkySurface(id: plant.id.uuidString, rect: plant.rect, kind: .platform))
            case .mushroom:
                surfaces.append(SkySurface(id: plant.id.uuidString, rect: plant.rect, kind: .mushroom))
            case .vine:
                for (index, leaf) in plant.leaves.enumerated() {
                    surfaces.append(SkySurface(id: "\(plant.id.uuidString)-\(index)", rect: leaf, kind: .vineLeaf))
                }
            }
        }
        return surfaces
    }

    private func updateCheckpoint() {
        guard !checkpointIsActive else { return }
        if player.x > 1_390, player.x < 1_490, player.y + player.height > 490 {
            checkpoint = CGPoint(x: 1_400, y: 465)
            checkpointIsActive = true
            player.hearts = 3
            showToast("Checkpoint: garden windmill", tone: .leaf)
        }
    }

    private func updateCollectibles() {
        for index in parts.indices where !parts[index].isCollected {
            let partPoint = CGPoint(x: parts[index].x, y: parts[index].y)
            if distance(from: player.center, to: partPoint) < 38 {
                parts[index].isCollected = true
                showToast("Found: \(parts[index].label)", tone: .sunshine)
                announceGoalIfNeeded()
            }
        }
    }

    private func updateSecretEgg() {
        guard !secretEggIsFound else { return }
        guard distance(from: player.center, to: secretEggPosition) < 44 else { return }

        secretEggIsFound = true
        secretEggCount = 1
        showToast("Secret egg found! A hidden keepsake is safe.", tone: .sunshine, duration: 3.2)
    }

    private func updateRavens() {
        for index in ravens.indices {
            let raven = ravens[index]
            let wave = CGFloat(animationTime) * raven.speed + raven.offset
            ravens[index].x = raven.anchorX + CGFloat(sin(Double(wave))) * raven.range
            ravens[index].y = raven.anchorY + CGFloat(cos(Double(wave * 1.7))) * raven.amplitude
        }
    }

    private func updateRavensCollision() {
        guard player.invulnerability <= 0 else { return }
        for raven in ravens {
            if distance(from: player.center, to: CGPoint(x: raven.x, y: raven.y)) < 34 {
                player.hearts -= 1
                if player.hearts <= 0 {
                    player.hearts = 3
                    showToast("Clara caught her breath at the checkpoint", tone: .coral)
                } else {
                    showToast("A thieving crow knocked Clara off course", tone: .coral)
                }
                respawnPlayer()
                return
            }
        }
    }

    private func updateGoal() {
        guard isGoalReady, player.rect.intersects(goalRect) else { return }
        phase = .completed
        showToast("Island saved!", tone: .sunshine, duration: 3)
    }

    private func announceGoalIfNeeded() {
        guard isGoalReady, !goalAnnounced else { return }
        goalAnnounced = true
        showToast("The lighthouse is lit — Clara, fly to the finish!", tone: .sunshine, duration: 3)
    }

    private func respawnPlayer() {
        player.x = checkpoint.x
        player.y = checkpoint.y
        player.velocityX = 0
        player.velocityY = 0
        player.isGrounded = false
        player.isGliding = false
        player.invulnerability = 1.7
        player.seeds = Self.maximumSeeds
        seedFlight = nil
        grownPlants = []
        for index in beds.indices {
            beds[index].isGrown = false
            beds[index].isPending = false
        }
    }

    private func updateGoalNotification() {
        if isGoalReady { announceGoalIfNeeded() }
    }

    private func updateCamera(for viewport: CGSize, delta: TimeInterval) {
        let visibleWorldHeight = Self.worldHeight * Self.cameraZoom
        let scale = max(viewport.height / visibleWorldHeight, 0.01)
        let visibleWorldWidth = viewport.width / scale
        let target = min(max(player.x - visibleWorldWidth * 0.36, 0), Self.worldWidth - visibleWorldWidth)
        let amount = delta == 0 ? 1 : 1 - exp(-5.5 * delta)
        cameraX += (target - cameraX) * CGFloat(amount)
    }

    private func nearestReadyBed() -> SkySeedBed? {
        beds
            .filter { !$0.isGrown && !$0.isPending && abs(player.x - $0.rect.x) < 720 }
            .min { left, right in
                let leftDistance = abs(player.center.x - (left.rect.x + left.rect.width / 2)) + max(0, left.rect.x - player.x) * 0.25
                let rightDistance = abs(player.center.x - (right.rect.x + right.rect.width / 2)) + max(0, right.rect.x - player.x) * 0.25
                return leftDistance < rightDistance
            }
    }

    private func updateToast(delta: TimeInterval) {
        guard var toast else { return }
        toast.remainingLifetime -= delta
        self.toast = toast.remainingLifetime > 0 ? toast : nil
    }

    private func showToast(_ message: String, tone: SkyToastTone, duration: TimeInterval = 2.4) {
        toast = SkyToast(message: message, tone: tone, maximumLifetime: duration, remainingLifetime: duration)
    }

    private func approach(_ value: CGFloat, target: CGFloat, delta: CGFloat) -> CGFloat {
        if value < target {
            return min(value + delta, target)
        }
        return max(value - delta, target)
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }
}
