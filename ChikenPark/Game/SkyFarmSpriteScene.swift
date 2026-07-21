import SpriteKit
import UIKit

/// SpriteKit owns the frame loop and scene graph. `SkyFarmGame` remains the
/// authoritative gameplay model until physics is migrated as a single step.
@MainActor
final class SkyFarmSpriteScene: SKScene {
    private let worldNode = SKNode()
    private let backgroundNode = SKNode()
    private let terrainNode = SKNode()
    private let decorationNode = SKNode()
    private let interactionNode = SKNode()
    private let characterNode = SKNode()
    private let cameraNode = SKCameraNode()

    private weak var game: SkyFarmGame?
    private var hasBuiltWorld = false
    private var platformNodes: [String: SKNode] = [:]
    private var bedNodes: [String: SKNode] = [:]
    private var plantNodes: [UUID: SKNode] = [:]
    private var partNodes: [String: SKNode] = [:]
    private var ravenNodes: [UUID: SKNode] = [:]

    private let playerNode = SKNode()
    private let seedNode = SKNode()
    private let secretEggNode = SKNode()
    private let chickNode = SKNode()
    private let lighthouseNode = SKNode()
    private let lighthouseBeam = SKShapeNode()
    private let millBlades = SKNode()

    override init(size: CGSize = CGSize(width: 1_280, height: 720)) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = Self.skyBlue

        worldNode.zPosition = 1
        addChild(worldNode)
        worldNode.addChild(backgroundNode)
        worldNode.addChild(terrainNode)
        worldNode.addChild(decorationNode)
        worldNode.addChild(interactionNode)
        worldNode.addChild(characterNode)

        camera = cameraNode
        addChild(cameraNode)

        backgroundNode.zPosition = -30
        terrainNode.zPosition = 0
        decorationNode.zPosition = 10
        interactionNode.zPosition = 30
        characterNode.zPosition = 60

        seedNode.zPosition = 85
        playerNode.zPosition = 100
        chickNode.zPosition = 70
        lighthouseNode.zPosition = 12
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func bind(game: SkyFarmGame) {
        self.game = game
        if !hasBuiltWorld {
            buildWorld(using: game)
        }
        game.resetClock()
        synchronize(with: game)
    }

    override func didMove(to view: SKView) {
        game?.resetClock()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        game?.resetClock()
        guard let game else { return }
        updateCamera(using: game)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let game else { return }
        game.tick(
            at: Date(timeIntervalSinceReferenceDate: currentTime),
            viewport: size
        )
        synchronize(with: game)
    }

    private func buildWorld(using game: SkyFarmGame) {
        hasBuiltWorld = true
        buildSky()
        buildWindZones(game.winds)

        for platform in game.platforms {
            let node = makeIsland(for: platform)
            platformNodes[platform.id] = node
            terrainNode.addChild(node)
        }

        buildCoop()
        buildMill()
        buildGardenMachine()
        buildLighthouse()
        buildSigns()
        buildChick()
        buildPlayer()
        buildSeed()
        buildSecretEgg(at: game.secretEggPosition)

        characterNode.addChild(playerNode)
        characterNode.addChild(seedNode)
        characterNode.addChild(chickNode)
        decorationNode.addChild(lighthouseNode)
        interactionNode.addChild(secretEggNode)

        for bed in game.beds {
            let node = makeSeedBed(for: bed)
            bedNodes[bed.id] = node
            interactionNode.addChild(node)
        }

        for part in game.parts {
            let node = makePart(for: part)
            partNodes[part.id] = node
            interactionNode.addChild(node)
        }
    }

    private func synchronize(with game: SkyFarmGame) {
        for bed in game.beds {
            updateSeedBed(bed, isActive: game.activeBed?.id == bed.id && game.phase == .running)
        }

        synchronizePlants(game.grownPlants)
        synchronizeParts(game.parts, time: game.animationTime)
        synchronizeRavens(game.ravens, time: game.animationTime)
        updateSecretEgg(
            isFound: game.secretEggIsFound,
            position: game.secretEggPosition,
            time: game.animationTime
        )
        updateMill(isActive: game.checkpointIsActive, time: game.animationTime)
        updateLighthouse(isLit: game.isGoalReady, time: game.animationTime)
        updateChick(isRescued: game.chickIsRescued, time: game.animationTime)
        updateSeed(game.seedFlight, time: game.animationTime)
        updatePlayer(game.player, time: game.animationTime)
        updateCamera(using: game)
    }

    private func buildSky() {
        // One continuous painted sky keeps the route calm while the camera moves.
        // The former repeated bitmap introduced visible vertical seams between tiles.
        let sky = SKSpriteNode(
            texture: makeSkyGradientTexture(),
            color: .white,
            size: CGSize(
                width: SkyFarmGame.worldWidth + 700,
                height: SkyFarmGame.worldHeight + 220
            )
        )
        sky.position = CGPoint(x: SkyFarmGame.worldWidth / 2, y: SkyFarmGame.worldHeight / 2)
        sky.zPosition = -30
        backgroundNode.addChild(sky)

        let sunGlow = makeCircle(radius: 118, fill: SKColor(red: 1, green: 0.94, blue: 0.57, alpha: 0.16))
        sunGlow.position = CGPoint(x: 4_140, y: 610)
        sunGlow.zPosition = -1
        backgroundNode.addChild(sunGlow)

        let sun = makeCircle(radius: 47, fill: SKColor(red: 1, green: 0.93, blue: 0.56, alpha: 0.94))
        sun.position = sunGlow.position
        sun.zPosition = 0
        backgroundNode.addChild(sun)

        let clouds: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (230, 590, 1.1, 0.42), (960, 625, 0.78, 0.34),
            (1_610, 505, 0.6, 0.24), (2_310, 640, 1.0, 0.32),
            (3_120, 570, 0.72, 0.28), (3_850, 645, 0.9, 0.34),
            (4_470, 500, 0.58, 0.22)
        ]
        for cloud in clouds {
            let node = makeCloud(scale: cloud.2, alpha: cloud.3)
            node.position = CGPoint(x: cloud.0, y: cloud.1)
            node.zPosition = -5
            backgroundNode.addChild(node)
        }

        let distantIslands: [(CGFloat, CGFloat, CGFloat)] = [
            (840, 140, 0.48), (2_530, 125, 0.4), (3_920, 150, 0.45)
        ]
        for island in distantIslands {
            let node = makeDistantIsland(scale: island.2)
            node.position = CGPoint(x: island.0, y: island.1)
            node.zPosition = -12
            backgroundNode.addChild(node)
        }
    }

    private func buildWindZones(_ winds: [SkyWind]) {
        for wind in winds {
            let group = SKNode()
            group.position = spriteCenter(for: wind.rect)
            group.zPosition = 4

            let field = makeRoundedRect(
                size: CGSize(width: wind.rect.width, height: wind.rect.height),
                radius: 42,
                fill: SKColor.white.withAlphaComponent(0.09),
                stroke: SKColor.white.withAlphaComponent(0.35),
                lineWidth: 2
            )
            group.addChild(field)

            for index in 0..<5 {
                let wave = SKShapeNode()
                let path = CGMutablePath()
                let x = -wind.rect.width / 2 + 90 + CGFloat(index) * 140
                let y = wind.rect.height / 2 - 100 - CGFloat(index.isMultiple(of: 2) ? 70 : 130)
                path.move(to: CGPoint(x: x - 45, y: y))
                path.addCurve(
                    to: CGPoint(x: x + 48, y: y),
                    control1: CGPoint(x: x - 10, y: y + 30),
                    control2: CGPoint(x: x + 18, y: y - 30)
                )
                wave.path = path
                wave.strokeColor = SKColor.white.withAlphaComponent(0.72)
                wave.lineWidth = 4
                wave.lineCap = .round
                wave.name = "wind-wave"
                group.addChild(wave)

                let arrow = makeTriangle(
                    points: [
                        CGPoint(x: x + 57, y: y),
                        CGPoint(x: x + 42, y: y + 10),
                        CGPoint(x: x + 42, y: y - 10)
                    ],
                    fill: SKColor.white.withAlphaComponent(0.72)
                )
                group.addChild(arrow)
            }
            interactionNode.addChild(group)
        }
    }

    private func makeIsland(for platform: SkyPlatform) -> SKNode {
        let rect = platform.rect
        let node = SKNode()
        node.position = spriteCenter(for: rect)
        node.zPosition = 1

        let dirt = platform.style == .branch
            ? SKColor(red: 0.71, green: 0.45, blue: 0.3, alpha: 1)
            : SKColor(red: 0.78, green: 0.5, blue: 0.34, alpha: 1)
        let shadow = platform.style == .branch
            ? SKColor(red: 0.48, green: 0.26, blue: 0.22, alpha: 1)
            : SKColor(red: 0.61, green: 0.31, blue: 0.25, alpha: 1)

        let underside = makeIslandUnderside(size: CGSize(width: rect.width, height: rect.height), fill: shadow)
        underside.position = CGPoint(x: 7, y: -9)
        node.addChild(underside)

        let body = makeIslandUnderside(size: CGSize(width: rect.width, height: rect.height), fill: dirt)
        node.addChild(body)

        let grass = makeRoundedRect(
            size: CGSize(width: rect.width, height: 28),
            radius: 14,
            fill: SKColor(red: 0.37, green: 0.71, blue: 0.42, alpha: 1)
        )
        grass.position.y = rect.height / 2 - 8
        node.addChild(grass)

        let grassLight = makeRoundedRect(
            size: CGSize(width: max(20, rect.width - 16), height: 11),
            radius: 6,
            fill: SKColor(red: 0.66, green: 0.84, blue: 0.42, alpha: 1)
        )
        grassLight.position.y = rect.height / 2 - 4
        node.addChild(grassLight)

        let marksCount = max(2, Int(rect.width / 125))
        for index in 0..<marksCount {
            let mark = makeEllipse(
                size: CGSize(width: 25, height: 9),
                fill: SKColor(red: 0.42, green: 0.22, blue: 0.17, alpha: 0.26)
            )
            let horizontal = -rect.width / 2 + 38 + CGFloat((index * 83 + platform.id.count * 17) % max(1, Int(rect.width - 72)))
            mark.position = CGPoint(x: horizontal, y: rect.height / 2 - 58 - CGFloat(index % 3) * 30)
            node.addChild(mark)
        }

        for index in 0..<platform.flowers {
            let flower = makeFlower(index: index)
            let horizontal = -rect.width / 2 + 34 + CGFloat((index * 73 + platform.id.count * 19) % max(1, Int(rect.width - 70)))
            flower.position = CGPoint(x: horizontal, y: rect.height / 2 + 1 + CGFloat(index % 2) * 3)
            flower.zPosition = 3
            node.addChild(flower)
        }
        return node
    }

    private func buildCoop() {
        let coop = SKNode()
        coop.position = spritePoint(x: 163, y: 530)
        coop.zPosition = 6

        let house = makeRoundedRect(
            size: CGSize(width: 122, height: 85),
            radius: 12,
            fill: SKColor(red: 0.94, green: 0.55, blue: 0.39, alpha: 1)
        )
        house.position.y = -2
        coop.addChild(house)

        let roof = makeTriangle(
            points: [CGPoint(x: -73, y: 35), CGPoint(x: 0, y: 85), CGPoint(x: 73, y: 35)],
            fill: SKColor(red: 0.44, green: 0.24, blue: 0.3, alpha: 1)
        )
        coop.addChild(roof)

        let door = makeRoundedRect(
            size: CGSize(width: 30, height: 43),
            radius: 12,
            fill: SKColor(red: 1, green: 0.95, blue: 0.79, alpha: 1)
        )
        door.position = CGPoint(x: 0, y: -23)
        coop.addChild(door)

        let window = makeCircle(radius: 9, fill: SKColor(red: 1, green: 0.82, blue: 0.39, alpha: 1))
        window.position = CGPoint(x: 0, y: 16)
        coop.addChild(window)
        decorationNode.addChild(coop)
    }

    private func buildMill() {
        let mill = SKNode()
        mill.position = spritePoint(x: 1_500, y: 500)
        mill.zPosition = 8

        let tower = makeTrapezoid(
            topWidth: 36,
            bottomWidth: 62,
            height: 90,
            fill: SKColor(red: 0.96, green: 0.83, blue: 0.54, alpha: 1)
        )
        tower.position.y = -4
        mill.addChild(tower)

        let roof = makeTriangle(
            points: [CGPoint(x: -31, y: 39), CGPoint(x: 0, y: 70), CGPoint(x: 31, y: 39)],
            fill: SKColor(red: 0.88, green: 0.49, blue: 0.38, alpha: 1)
        )
        mill.addChild(roof)

        for index in 0..<4 {
            let blade = makeTriangle(
                points: [CGPoint(x: 4, y: -4), CGPoint(x: 34, y: -19), CGPoint(x: 31, y: 2)],
                fill: SKColor(red: 1, green: 0.97, blue: 0.84, alpha: 1)
            )
            blade.zRotation = CGFloat(index) * .pi / 2
            millBlades.addChild(blade)
        }
        let hub = makeCircle(radius: 8, fill: SKColor(red: 0.93, green: 0.6, blue: 0.4, alpha: 1))
        millBlades.addChild(hub)
        millBlades.position = CGPoint(x: 0, y: 17)
        mill.addChild(millBlades)
        decorationNode.addChild(mill)
    }

    private func buildGardenMachine() {
        let machine = SKNode()
        machine.position = spritePoint(x: 2_123, y: 358)
        machine.zPosition = 7

        let base = makeRoundedRect(
            size: CGSize(width: 76, height: 44),
            radius: 10,
            fill: SKColor(red: 0.47, green: 0.72, blue: 0.63, alpha: 1)
        )
        base.position.y = -8
        machine.addChild(base)

        let frame = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -21, y: 14))
        path.addLine(to: CGPoint(x: -26, y: 36))
        path.addLine(to: CGPoint(x: 12, y: 36))
        path.addLine(to: CGPoint(x: 19, y: 14))
        frame.path = path
        frame.strokeColor = SKColor(red: 0.88, green: 0.97, blue: 0.85, alpha: 1)
        frame.lineWidth = 4
        frame.lineJoin = .round
        machine.addChild(frame)

        let gear = makeCircle(radius: 13, fill: SKColor(red: 1, green: 0.84, blue: 0.42, alpha: 1))
        gear.position = CGPoint(x: 0, y: -5)
        machine.addChild(gear)
        decorationNode.addChild(machine)
    }

    private func buildLighthouse() {
        lighthouseNode.position = spritePoint(x: 4_420, y: 500)
        lighthouseNode.zPosition = 9

        lighthouseBeam.path = beamPath()
        lighthouseBeam.fillColor = SKColor(red: 1, green: 0.96, blue: 0.67, alpha: 0.04)
        lighthouseBeam.strokeColor = .clear
        lighthouseBeam.position = CGPoint(x: 48, y: 38)
        lighthouseBeam.zPosition = -1
        lighthouseNode.addChild(lighthouseBeam)

        let tower = makeTrapezoid(
            topWidth: 47,
            bottomWidth: 74,
            height: 112,
            fill: SKColor(red: 0.97, green: 0.91, blue: 0.78, alpha: 1)
        )
        tower.position.y = -7
        lighthouseNode.addChild(tower)

        let stripe = makeRoundedRect(
            size: CGSize(width: 56, height: 15),
            radius: 2,
            fill: SKColor(red: 0.89, green: 0.44, blue: 0.38, alpha: 1)
        )
        stripe.position.y = -2
        lighthouseNode.addChild(stripe)

        let lantern = makeRoundedRect(
            size: CGSize(width: 42, height: 36),
            radius: 8,
            fill: SKColor(red: 0.41, green: 0.5, blue: 0.57, alpha: 1)
        )
        lantern.name = "lantern"
        lantern.position.y = 44
        lighthouseNode.addChild(lantern)

        let roof = makeTriangle(
            points: [CGPoint(x: -28, y: 62), CGPoint(x: 0, y: 86), CGPoint(x: 28, y: 62)],
            fill: SKColor(red: 0.42, green: 0.28, blue: 0.34, alpha: 1)
        )
        lighthouseNode.addChild(roof)
    }

    private func buildSigns() {
        let firstSign = makeSign(title: "FIRST FLIGHT")
        firstSign.position = spritePoint(x: 303, y: 545)
        decorationNode.addChild(firstSign)

        let vineSign = makeSign(title: "VINE GARDEN BED")
        vineSign.position = spritePoint(x: 2_940, y: 480)
        decorationNode.addChild(vineSign)
    }

    private func buildChick() {
        chickNode.position = spritePoint(x: 3_910, y: 499)
        chickNode.zPosition = 50

        let glow = makeCircle(radius: 44, fill: SKColor(red: 1, green: 0.88, blue: 0.39, alpha: 0.18))
        glow.name = "rescue-glow"
        glow.zPosition = -1
        chickNode.addChild(glow)

        let cage = SKSpriteNode(imageNamed: "ChickCage")
        cage.name = "chick-cage"
        cage.texture?.filteringMode = .linear
        cage.size = CGSize(width: 78, height: 94)
        cage.position.y = 4
        chickNode.addChild(cage)
    }

    private func buildPlayer() {
        let shadow = makeEllipse(
            size: CGSize(width: 42, height: 10),
            fill: SKColor.black.withAlphaComponent(0.16)
        )
        shadow.name = "shadow"
        shadow.position.y = -28
        playerNode.addChild(shadow)

        let playerArt = SKSpriteNode(imageNamed: "ClaraGlide")
        playerArt.name = "player-art"
        playerArt.texture?.filteringMode = .linear
        playerArt.size = CGSize(width: 108, height: 72)
        playerArt.position = CGPoint(x: -1, y: 5)
        playerArt.zPosition = 1
        playerNode.addChild(playerArt)
    }

    private func buildSeed() {
        let glow = makeCircle(radius: 15, fill: SKColor(red: 1, green: 0.93, blue: 0.53, alpha: 0.23))
        seedNode.addChild(glow)
        let seed = makeEllipse(
            size: CGSize(width: 12, height: 8),
            fill: SKColor(red: 0.95, green: 0.56, blue: 0.25, alpha: 1)
        )
        seedNode.addChild(seed)
        seedNode.isHidden = true
    }

    private func buildSecretEgg(at position: CGPoint) {
        secretEggNode.name = "secret-egg"
        secretEggNode.position = spritePoint(x: position.x, y: position.y)
        secretEggNode.zPosition = 48

        let glow = makeCircle(
            radius: 31,
            fill: SKColor(red: 1, green: 0.84, blue: 0.29, alpha: 0.2)
        )
        glow.name = "egg-glow"
        glow.zPosition = -2
        secretEggNode.addChild(glow)

        let shadow = makeEllipse(
            size: CGSize(width: 24, height: 7),
            fill: SKColor.black.withAlphaComponent(0.14)
        )
        shadow.name = "egg-shadow"
        shadow.position = CGPoint(x: 0, y: -19)
        shadow.zPosition = -1
        secretEggNode.addChild(shadow)

        let shell = makeEllipse(
            size: CGSize(width: 27, height: 37),
            fill: SKColor(red: 1, green: 0.93, blue: 0.6, alpha: 1),
            stroke: SKColor(red: 0.85, green: 0.54, blue: 0.23, alpha: 1),
            lineWidth: 2
        )
        shell.name = "egg-shell"
        secretEggNode.addChild(shell)

        let highlight = makeEllipse(
            size: CGSize(width: 7, height: 15),
            fill: SKColor.white.withAlphaComponent(0.78)
        )
        highlight.position = CGPoint(x: -6, y: 5)
        highlight.zRotation = -0.34
        secretEggNode.addChild(highlight)

        for (index, point) in [CGPoint(x: 4, y: 9), CGPoint(x: -2, y: -4), CGPoint(x: 7, y: -9)].enumerated() {
            let speckle = makeCircle(
                radius: index == 1 ? 2.2 : 2.8,
                fill: SKColor(red: 0.92, green: 0.48, blue: 0.26, alpha: 1)
            )
            speckle.position = point
            secretEggNode.addChild(speckle)
        }

        for (index, point) in [CGPoint(x: -23, y: 17), CGPoint(x: 24, y: 8), CGPoint(x: 16, y: 29)].enumerated() {
            let sparkle = makeCircle(
                radius: index == 2 ? 2 : 2.8,
                fill: SKColor.white.withAlphaComponent(0.9)
            )
            sparkle.name = "egg-sparkle-\(index)"
            sparkle.position = point
            secretEggNode.addChild(sparkle)
        }
    }

    private func updateSecretEgg(isFound: Bool, position: CGPoint, time: TimeInterval) {
        secretEggNode.isHidden = isFound
        guard !isFound else { return }

        secretEggNode.position = spritePoint(x: position.x, y: position.y)
        secretEggNode.position.y += CGFloat(sin(time * 3.2)) * 3
        secretEggNode.zRotation = CGFloat(sin(time * 1.7)) * 0.05

        if let glow = secretEggNode.childNode(withName: "egg-glow") as? SKShapeNode {
            glow.alpha = 0.72 + CGFloat(sin(time * 4.4)) * 0.2
            glow.setScale(0.92 + CGFloat(sin(time * 3.1)) * 0.08)
        }
        if let shadow = secretEggNode.childNode(withName: "egg-shadow") as? SKShapeNode {
            shadow.alpha = 0.12 + CGFloat(sin(time * 3.2)) * 0.03
        }
        for index in 0..<3 {
            let phase = time * 4.8 + Double(index) * 1.7
            let sparkle = secretEggNode.childNode(withName: "egg-sparkle-\(index)")
            sparkle?.alpha = 0.38 + CGFloat(sin(phase)) * 0.38
            sparkle?.setScale(0.72 + CGFloat(cos(phase)) * 0.22)
        }
    }

    private func makeSeedBed(for bed: SkySeedBed) -> SKNode {
        let node = SKNode()
        node.position = spriteCenter(for: bed.rect)
        node.zPosition = 25

        let halo = makeEllipse(
            size: CGSize(width: bed.rect.width + 36, height: bed.rect.height + 36),
            fill: SKColor(red: 1, green: 0.95, blue: 0.61, alpha: 0.24)
        )
        halo.name = "halo"
        halo.zPosition = -1
        node.addChild(halo)

        let soil = makeRoundedRect(
            size: CGSize(width: bed.rect.width, height: bed.rect.height),
            radius: 8,
            fill: SKColor(red: 0.55, green: 0.32, blue: 0.24, alpha: 1)
        )
        soil.name = "soil"
        node.addChild(soil)

        let inner = makeRoundedRect(
            size: CGSize(width: max(12, bed.rect.width - 8), height: max(8, bed.rect.height - 6)),
            radius: 6,
            fill: SKColor(red: 0.87, green: 0.6, blue: 0.36, alpha: 1)
        )
        inner.name = "inner"
        node.addChild(inner)

        let seeds = SKNode()
        seeds.name = "seeds"
        for index in 0..<3 {
            let seed = makeEllipse(size: CGSize(width: 8, height: 5), fill: seedColor(for: bed.kind))
            seed.position = CGPoint(x: -16 + CGFloat(index) * 16, y: 0)
            seeds.addChild(seed)
        }
        node.addChild(seeds)

        let prompt = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        prompt.name = "prompt"
        prompt.text = "PLANT"
        prompt.fontSize = 11
        prompt.fontColor = .white
        prompt.verticalAlignmentMode = .center
        prompt.horizontalAlignmentMode = .center
        prompt.position = CGPoint(x: 0, y: 32)
        prompt.alpha = 0
        node.addChild(prompt)
        return node
    }

    private func makePart(for part: SkyPart) -> SKNode {
        let node = SKNode()
        node.position = spritePoint(x: part.x, y: part.y)
        node.zPosition = 42

        let glow = makeCircle(radius: 27, fill: SKColor(red: 1, green: 0.9, blue: 0.37, alpha: 0.22))
        glow.name = "glow"
        node.addChild(glow)

        switch part.id {
        case "propeller":
            for index in 0..<3 {
                let blade = makeEllipse(
                    size: CGSize(width: 28, height: 11),
                    fill: SKColor(red: 0.9, green: 0.95, blue: 0.89, alpha: 1),
                    stroke: SKColor(red: 0.44, green: 0.6, blue: 0.58, alpha: 0.8),
                    lineWidth: 2
                )
                blade.position.x = 13
                blade.zRotation = CGFloat(index) * .pi * 2 / 3
                node.addChild(blade)
            }
            node.addChild(makeCircle(radius: 7, fill: SKColor(red: 0.94, green: 0.56, blue: 0.3, alpha: 1)))
        case "gear":
            for index in 0..<8 {
                let tooth = makeRoundedRect(
                    size: CGSize(width: 9, height: 14),
                    radius: 2,
                    fill: SKColor(red: 0.94, green: 0.68, blue: 0.29, alpha: 1)
                )
                let angle = CGFloat(index) * .pi / 4
                tooth.position = CGPoint(x: cos(angle) * 18, y: sin(angle) * 18)
                tooth.zRotation = angle
                node.addChild(tooth)
            }
            node.addChild(makeCircle(radius: 18, fill: SKColor(red: 0.98, green: 0.76, blue: 0.34, alpha: 1)))
            node.addChild(makeCircle(radius: 7, fill: SKColor(red: 0.65, green: 0.38, blue: 0.23, alpha: 1)))
        default:
            let frame = makeRoundedRect(
                size: CGSize(width: 18, height: 25),
                radius: 4,
                fill: SKColor(red: 0.42, green: 0.54, blue: 0.58, alpha: 1)
            )
            node.addChild(frame)
            let lantern = makeRoundedRect(
                size: CGSize(width: 14, height: 16),
                radius: 4,
                fill: SKColor(red: 1, green: 0.89, blue: 0.42, alpha: 1)
            )
            lantern.position.y = -2
            node.addChild(lantern)
            let cap = makeRoundedRect(
                size: CGSize(width: 12, height: 5),
                radius: 2,
                fill: SKColor(red: 0.3, green: 0.4, blue: 0.45, alpha: 1)
            )
            cap.position.y = 15
            node.addChild(cap)
        }
        return node
    }

    private func synchronizePlants(_ plants: [SkyGrownPlant]) {
        let visibleIDs = Set(plants.map(\.id))
        for id in plantNodes.keys.filter({ !visibleIDs.contains($0) }) {
            plantNodes.removeValue(forKey: id)?.removeFromParent()
        }

        for plant in plants {
            let node: SKNode
            if let existing = plantNodes[plant.id] {
                node = existing
            } else {
                node = makePlant(for: plant)
                plantNodes[plant.id] = node
                interactionNode.addChild(node)
            }
            node.alpha = plant.opacity
        }
    }

    private func makePlant(for plant: SkyGrownPlant) -> SKNode {
        let node = SKNode()
        node.zPosition = 28
        switch plant.kind {
        case .bridge:
            node.position = spriteCenter(for: plant.rect)
            let deck = makeRoundedRect(
                size: CGSize(width: plant.rect.width, height: plant.rect.height),
                radius: 14,
                fill: SKColor(red: 0.35, green: 0.69, blue: 0.36, alpha: 1),
                stroke: SKColor(red: 0.18, green: 0.48, blue: 0.27, alpha: 0.9),
                lineWidth: 2
            )
            node.addChild(deck)
            for x in stride(from: -plant.rect.width / 2 + 28, through: plant.rect.width / 2 - 18, by: 48) {
                let leaf = makeEllipse(
                    size: CGSize(width: 34, height: 20),
                    fill: SKColor(red: 0.59, green: 0.84, blue: 0.4, alpha: 1)
                )
                leaf.position = CGPoint(x: x, y: 8)
                node.addChild(leaf)
            }
        case .mushroom:
            node.position = spriteCenter(for: plant.rect)
            let stalk = makeRoundedRect(
                size: CGSize(width: 35, height: 45),
                radius: 14,
                fill: SKColor(red: 1, green: 0.9, blue: 0.73, alpha: 1)
            )
            stalk.position.y = -12
            node.addChild(stalk)
            let cap = makeEllipse(
                size: CGSize(width: 125, height: 52),
                fill: SKColor(red: 0.94, green: 0.43, blue: 0.36, alpha: 1),
                stroke: SKColor(red: 0.64, green: 0.25, blue: 0.24, alpha: 0.9),
                lineWidth: 2
            )
            cap.position.y = 12
            node.addChild(cap)
            for x in [-32.0, 0, 31] {
                let spot = makeCircle(radius: 5, fill: SKColor(red: 1, green: 0.91, blue: 0.67, alpha: 1))
                spot.position = CGPoint(x: x, y: 16)
                node.addChild(spot)
            }
        case .vine:
            node.position = spriteCenter(for: plant.rect)
            let stem = makeRoundedRect(
                size: CGSize(width: 17, height: plant.rect.height),
                radius: 8,
                fill: SKColor(red: 0.24, green: 0.58, blue: 0.31, alpha: 1)
            )
            stem.position.x = -plant.rect.width / 2 + 12
            node.addChild(stem)
            for leafRect in plant.leaves {
                let leaf = makeRoundedRect(
                    size: CGSize(width: leafRect.width, height: leafRect.height),
                    radius: 10,
                    fill: SKColor(red: 0.44, green: 0.76, blue: 0.38, alpha: 1),
                    stroke: SKColor(red: 0.18, green: 0.48, blue: 0.27, alpha: 0.9),
                    lineWidth: 2
                )
                leaf.position = CGPoint(
                    x: leafRect.x + leafRect.width / 2 - plant.rect.x - plant.rect.width / 2,
                    y: SkyFarmGame.worldHeight - (leafRect.y + leafRect.height / 2) - node.position.y
                )
                node.addChild(leaf)
            }
        }
        return node
    }

    private func synchronizeParts(_ parts: [SkyPart], time: TimeInterval) {
        for part in parts {
            guard let node = partNodes[part.id] else { continue }
            node.isHidden = part.isCollected
            node.zRotation = CGFloat(time * (part.id == "gear" ? 1.8 : 0.8))
            node.position = spritePoint(x: part.x, y: part.y)
            node.position.y += CGFloat(sin(time * 2.4 + Double(part.x) * 0.01)) * 3
        }
    }

    private func synchronizeRavens(_ ravens: [SkyRaven], time: TimeInterval) {
        let visibleIDs = Set(ravens.map(\.id))
        for id in ravenNodes.keys.filter({ !visibleIDs.contains($0) }) {
            ravenNodes.removeValue(forKey: id)?.removeFromParent()
        }

        for raven in ravens {
            let node: SKNode
            if let existing = ravenNodes[raven.id] {
                node = existing
            } else {
                node = makeRaven()
                ravenNodes[raven.id] = node
                characterNode.addChild(node)
            }
            node.position = spritePoint(x: raven.x, y: raven.y)
            node.zRotation = CGFloat(sin(time * 6 + raven.offset) * 0.08)
            node.xScale = CGFloat(cos(time * raven.speed + raven.offset) >= 0 ? 1 : -1)
        }
    }

    private func makeRaven() -> SKNode {
        let node = SKNode()
        node.zPosition = 76
        let raven = SKSpriteNode(imageNamed: "RavenThief")
        raven.name = "raven-art"
        raven.texture?.filteringMode = .linear
        raven.size = CGSize(width: 68, height: 46)
        raven.position.y = 2
        node.addChild(raven)
        return node
    }

    private func updateSeedBed(_ bed: SkySeedBed, isActive: Bool) {
        guard let node = bedNodes[bed.id] else { return }
        let seedFill: SKColor
        if bed.isPending {
            seedFill = SKColor(red: 1, green: 0.96, blue: 0.65, alpha: 1)
        } else if bed.isGrown {
            seedFill = SKColor(red: 0.53, green: 0.75, blue: 0.4, alpha: 1)
        } else {
            seedFill = seedColor(for: bed.kind)
        }
        (node.childNode(withName: "halo") as? SKShapeNode)?.alpha = isActive ? 1 : 0
        (node.childNode(withName: "prompt") as? SKLabelNode)?.alpha = isActive ? 1 : 0
        node.childNode(withName: "seeds")?.children.forEach { child in
            (child as? SKShapeNode)?.fillColor = seedFill
        }
    }

    private func updateMill(isActive: Bool, time: TimeInterval) {
        millBlades.zRotation = CGFloat(time * (isActive ? 1.4 : 0.32))
        let color = isActive
            ? SKColor(red: 1, green: 0.97, blue: 0.84, alpha: 1)
            : SKColor(red: 0.84, green: 0.88, blue: 0.84, alpha: 1)
        millBlades.children.compactMap { $0 as? SKShapeNode }.forEach { blade in
            if blade.frame.width > 20 { blade.fillColor = color }
        }
    }

    private func updateLighthouse(isLit: Bool, time: TimeInterval) {
        let opacity: CGFloat = isLit ? 0.22 + CGFloat(sin(time * 4)) * 0.05 : 0.04
        lighthouseBeam.fillColor = SKColor(red: 1, green: 0.96, blue: 0.67, alpha: opacity)
        (lighthouseNode.childNode(withName: "lantern") as? SKShapeNode)?.fillColor = isLit
            ? SKColor(red: 1, green: 0.95, blue: 0.6, alpha: 1)
            : SKColor(red: 0.41, green: 0.5, blue: 0.57, alpha: 1)
    }

    private func updateChick(isRescued: Bool, time: TimeInterval) {
        chickNode.isHidden = isRescued
        guard !isRescued else { return }
        chickNode.position = spritePoint(x: 3_910, y: 499)
        chickNode.position.y += CGFloat(sin(time * 4)) * 2
    }

    private func updateSeed(_ flight: SkySeedFlight?, time: TimeInterval) {
        guard let flight else {
            seedNode.isHidden = true
            return
        }
        seedNode.isHidden = false
        seedNode.position = spritePoint(x: flight.position.x, y: flight.position.y)
        seedNode.zRotation = CGFloat(time * 8)
    }

    private func updatePlayer(_ player: SkyPlayer, time: TimeInterval) {
        playerNode.position = spritePoint(x: player.center.x, y: player.center.y)
        playerNode.xScale = player.facing
        let hovering = player.isGrounded ? 0 : CGFloat(sin(time * 9)) * 1.7
        playerNode.position.y += hovering
        playerNode.alpha = player.invulnerability > 0
            ? 0.45 + CGFloat(sin(time * 20)) * 0.35
            : 1

        if let playerArt = playerNode.childNode(withName: "player-art") {
            playerArt.xScale = player.isGliding ? 1 : 0.84
            playerArt.yScale = player.isGliding ? 1 : 0.84
            playerArt.position = CGPoint(x: player.isGliding ? -1 : 0, y: player.isGliding ? 5 : 1)
            playerArt.zRotation = player.isGliding ? 0.03 : 0
        }
        if let shadow = playerNode.childNode(withName: "shadow") as? SKShapeNode {
            shadow.alpha = player.isGrounded ? 1 : 0.35
        }
    }

    private func updateCamera(using game: SkyFarmGame) {
        guard size.width > 0, size.height > 0 else { return }
        let cameraScale = SkyFarmGame.worldHeight * SkyFarmGame.cameraZoom / max(size.height, 1)
        cameraNode.setScale(cameraScale)
        let visibleWorldWidth = size.width * cameraScale
        cameraNode.position = CGPoint(
            x: game.cameraX + visibleWorldWidth / 2,
            y: SkyFarmGame.worldHeight / 2
        )
    }

    private func makeSkyGradientTexture() -> SKTexture {
        let canvasSize = CGSize(width: 18, height: 1_024)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: canvasSize, format: format).image { rendererContext in
            let context = rendererContext.cgContext
            context.setFillColor(Self.skyBlue.cgColor)
            context.fill(CGRect(origin: .zero, size: canvasSize))

            let colors = [
                SKColor(red: 0.29, green: 0.7, blue: 0.91, alpha: 1).cgColor,
                SKColor(red: 0.5, green: 0.84, blue: 0.95, alpha: 1).cgColor,
                SKColor(red: 0.82, green: 0.94, blue: 0.96, alpha: 1).cgColor,
                SKColor(red: 0.95, green: 0.97, blue: 0.9, alpha: 1).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0, 0.48, 0.76, 1]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: locations
            ) else {
                return
            }

            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: canvasSize.width / 2, y: 0),
                end: CGPoint(x: canvasSize.width / 2, y: canvasSize.height),
                options: []
            )
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private func makeCloud(scale: CGFloat, alpha: CGFloat) -> SKNode {
        let cloud = SKNode()
        let fill = SKColor.white.withAlphaComponent(alpha)
        let pieces: [(CGSize, CGPoint)] = [
            (CGSize(width: 58, height: 39), CGPoint(x: -44, y: -1)),
            (CGSize(width: 74, height: 62), CGPoint(x: -2, y: 15)),
            (CGSize(width: 58, height: 46), CGPoint(x: 42, y: 2)),
            (CGSize(width: 133, height: 34), CGPoint(x: 4, y: -15))
        ]
        for piece in pieces {
            let shape = makeEllipse(size: piece.0, fill: fill)
            shape.position = piece.1
            cloud.addChild(shape)
        }
        cloud.setScale(scale)
        return cloud
    }

    private func makeDistantIsland(scale: CGFloat) -> SKNode {
        let island = SKNode()
        let top = makeEllipse(
            size: CGSize(width: 224, height: 55),
            fill: SKColor(red: 0.32, green: 0.6, blue: 0.52, alpha: 0.28)
        )
        top.position.y = 22
        island.addChild(top)
        let underside = makeTriangle(
            points: [CGPoint(x: -90, y: 20), CGPoint(x: 0, y: -98), CGPoint(x: 90, y: 20)],
            fill: SKColor(red: 0.67, green: 0.46, blue: 0.33, alpha: 0.24)
        )
        island.addChild(underside)
        island.setScale(scale)
        return island
    }

    private func makeFlower(index: Int) -> SKNode {
        let flower = SKNode()
        let petalColor = index.isMultiple(of: 2)
            ? SKColor(red: 1, green: 0.89, blue: 0.43, alpha: 1)
            : SKColor(red: 1, green: 0.69, blue: 0.63, alpha: 1)
        let stem = makeRoundedRect(
            size: CGSize(width: 3, height: 10),
            radius: 1,
            fill: SKColor(red: 0.31, green: 0.67, blue: 0.4, alpha: 1)
        )
        stem.position.y = -4
        flower.addChild(stem)
        for petalIndex in 0..<5 {
            let petal = makeEllipse(size: CGSize(width: 6, height: 9), fill: petalColor)
            let angle = CGFloat(petalIndex) * .pi * 2 / 5
            petal.position = CGPoint(x: cos(angle) * 5, y: sin(angle) * 5 + 4)
            petal.zRotation = angle
            flower.addChild(petal)
        }
        let center = makeCircle(radius: 2.8, fill: SKColor(red: 0.95, green: 0.58, blue: 0.29, alpha: 1))
        center.position.y = 4
        flower.addChild(center)
        return flower
    }

    private func makeSign(title: String) -> SKNode {
        let sign = SKNode()
        sign.zPosition = 7
        let post = makeRoundedRect(
            size: CGSize(width: 7, height: 42),
            radius: 2,
            fill: SKColor(red: 0.6, green: 0.36, blue: 0.26, alpha: 1)
        )
        post.position.y = -18
        sign.addChild(post)
        let board = makeRoundedRect(
            size: CGSize(width: 112, height: 31),
            radius: 7,
            fill: SKColor(red: 0.96, green: 0.81, blue: 0.48, alpha: 1)
        )
        board.position.y = 14
        sign.addChild(board)
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        label.text = title
        label.fontSize = 10
        label.fontColor = SKColor(red: 0.53, green: 0.35, blue: 0.27, alpha: 1)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position.y = 14
        sign.addChild(label)
        return sign
    }

    private func makeIslandUnderside(size: CGSize, fill: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        let top = size.height / 2 - 13
        path.move(to: CGPoint(x: -size.width / 2 + 10, y: top))
        path.addLine(to: CGPoint(x: size.width / 2 - 10, y: top))
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.28, y: -size.height / 2),
            control: CGPoint(x: size.width / 2 - 28, y: -size.height * 0.05)
        )
        path.addQuadCurve(
            to: CGPoint(x: -size.width * 0.28, y: -size.height * 0.55),
            control: CGPoint(x: 0, y: -size.height / 2 - 20)
        )
        path.addQuadCurve(
            to: CGPoint(x: -size.width / 2 + 10, y: top),
            control: CGPoint(x: -size.width / 2 + 20, y: -size.height * 0.08)
        )
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = fill
        node.strokeColor = .clear
        return node
    }

    private func makeTrapezoid(topWidth: CGFloat, bottomWidth: CGFloat, height: CGFloat, fill: SKColor) -> SKShapeNode {
        makePolygon(
            points: [
                CGPoint(x: -bottomWidth / 2, y: -height / 2),
                CGPoint(x: bottomWidth / 2, y: -height / 2),
                CGPoint(x: topWidth / 2, y: height / 2),
                CGPoint(x: -topWidth / 2, y: height / 2)
            ],
            fill: fill
        )
    }

    private func makeTriangle(points: [CGPoint], fill: SKColor) -> SKShapeNode {
        makePolygon(points: points, fill: fill)
    }

    private func makePolygon(points: [CGPoint], fill: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        guard let first = points.first else { return SKShapeNode() }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = fill
        node.strokeColor = .clear
        return node
    }

    private func makeCircle(radius: CGFloat, fill: SKColor, stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth
        return node
    }

    private func makeEllipse(size: CGSize, fill: SKColor, stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(ellipseOf: size)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth
        return node
    }

    private func makeRoundedRect(
        size: CGSize,
        radius: CGFloat,
        fill: SKColor,
        stroke: SKColor = .clear,
        lineWidth: CGFloat = 0
    ) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth
        return node
    }

    private func beamPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: -300, y: 110))
        path.addLine(to: CGPoint(x: -300, y: -90))
        path.closeSubpath()
        return path
    }

    private func spritePoint(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: SkyFarmGame.worldHeight - y)
    }

    private func spriteCenter(for rect: SkyRect) -> CGPoint {
        spritePoint(x: rect.x + rect.width / 2, y: rect.y + rect.height / 2)
    }

    private func seedColor(for kind: SkyPlantKind) -> SKColor {
        switch kind {
        case .bridge:
            SKColor(red: 0.96, green: 0.66, blue: 0.34, alpha: 1)
        case .mushroom:
            SKColor(red: 0.94, green: 0.49, blue: 0.41, alpha: 1)
        case .vine:
            SKColor(red: 0.48, green: 0.75, blue: 0.4, alpha: 1)
        }
    }

    private static let skyBlue = SKColor(red: 0.46, green: 0.79, blue: 0.91, alpha: 1)
}
