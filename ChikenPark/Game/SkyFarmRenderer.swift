import SwiftUI

enum SkyFarmRenderer {
    static func draw(_ context: inout GraphicsContext, size: CGSize, game: SkyFarmGame) {
        drawSky(&context, size: size, animationTime: game.animationTime, cameraX: game.cameraX)

        let scale = max(size.height / SkyFarmGame.worldHeight, 0.01)
        var world = context
        world.scaleBy(x: scale, y: scale)
        world.translateBy(x: -game.cameraX, y: 0)

        drawWindZones(&world, winds: game.winds, animationTime: game.animationTime)
        for platform in game.platforms {
            drawIsland(&world, platform: platform)
        }
        drawStaticDecorations(&world, game: game)
        drawSeedBeds(&world, game: game)
        drawGrownPlants(&world, game: game)
        drawParts(&world, game: game)
        for raven in game.ravens {
            drawRaven(&world, raven: raven, animationTime: game.animationTime)
        }
        drawChick(&world, game: game)
        drawGoal(&world, game: game)
        if let flight = game.seedFlight {
            drawSeed(&world, position: flight.position, animationTime: game.animationTime)
        }
        drawPlayer(&world, player: game.player, animationTime: game.animationTime)
    }

    private static func drawSky(
        _ context: inout GraphicsContext,
        size: CGSize,
        animationTime: TimeInterval,
        cameraX: CGFloat
    ) {
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(
            Path(bounds),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.46, green: 0.79, blue: 0.91),
                    Color(red: 0.75, green: 0.92, blue: 0.95),
                    Color(red: 0.98, green: 0.90, blue: 0.69)
                ]),
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )

        let sunCenter = CGPoint(x: size.width * 0.83, y: size.height * 0.17)
        context.fill(
            Path(ellipseIn: CGRect(x: sunCenter.x - 78, y: sunCenter.y - 78, width: 156, height: 156)),
            with: .color(Color(red: 1, green: 0.95, blue: 0.63).opacity(0.18))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: sunCenter.x - 35, y: sunCenter.y - 35, width: 70, height: 70)),
            with: .color(Color(red: 1, green: 0.94, blue: 0.62))
        )

        drawCloud(&context, at: CGPoint(x: size.width * 0.13, y: size.height * 0.19), scale: 0.95, color: .white.opacity(0.6))
        drawCloud(&context, at: CGPoint(x: size.width * 0.55, y: size.height * 0.12), scale: 0.62, color: .white.opacity(0.5))
        drawCloud(&context, at: CGPoint(x: size.width * 0.91, y: size.height * 0.37), scale: 0.82, color: .white.opacity(0.46))
        drawCloud(&context, at: CGPoint(x: size.width * 0.38, y: size.height * 0.62), scale: 0.68, color: .white.opacity(0.34))

        for index in 0..<5 {
            let drift = (CGFloat(index) * 254 - cameraX * 0.12).truncatingRemainder(dividingBy: size.width + 280)
            let x = drift < -120 ? drift + size.width + 280 : drift - 90
            let y = size.height * (0.47 + CGFloat(index % 3) * 0.12)
            drawCloud(&context, at: CGPoint(x: x, y: y), scale: 0.36 + CGFloat(index % 2) * 0.12, color: .white.opacity(0.25))
        }

        let islands = [
            (x: size.width * 0.32 - cameraX * 0.16, y: size.height * 0.75, scale: CGFloat(0.48)),
            (x: size.width * 0.80 - cameraX * 0.12, y: size.height * 0.68, scale: CGFloat(0.34)),
            (x: size.width * 1.28 - cameraX * 0.18, y: size.height * 0.80, scale: CGFloat(0.56))
        ]
        for island in islands {
            drawDistantIsland(&context, at: CGPoint(x: island.x, y: island.y), scale: island.scale)
        }
    }

    private static func drawCloud(
        _ context: inout GraphicsContext,
        at origin: CGPoint,
        scale: CGFloat,
        color: Color
    ) {
        var cloud = Path()
        cloud.addEllipse(in: CGRect(x: origin.x - 48 * scale, y: origin.y - 2 * scale, width: 58 * scale, height: 39 * scale))
        cloud.addEllipse(in: CGRect(x: origin.x - 17 * scale, y: origin.y - 25 * scale, width: 74 * scale, height: 62 * scale))
        cloud.addEllipse(in: CGRect(x: origin.x + 30 * scale, y: origin.y - 8 * scale, width: 58 * scale, height: 46 * scale))
        cloud.addRoundedRect(in: CGRect(x: origin.x - 48 * scale, y: origin.y + 5 * scale, width: 133 * scale, height: 34 * scale), cornerSize: CGSize(width: 18 * scale, height: 18 * scale))
        context.fill(cloud, with: .color(color))
    }

    private static func drawDistantIsland(_ context: inout GraphicsContext, at origin: CGPoint, scale: CGFloat) {
        var top = Path()
        top.addEllipse(in: CGRect(x: origin.x - 112 * scale, y: origin.y - 24 * scale, width: 224 * scale, height: 55 * scale))
        context.fill(top, with: .color(Color(red: 0.32, green: 0.60, blue: 0.52).opacity(0.32)))

        var underside = Path()
        underside.move(to: CGPoint(x: origin.x - 90 * scale, y: origin.y))
        underside.addQuadCurve(to: CGPoint(x: origin.x, y: origin.y + 118 * scale), control: CGPoint(x: origin.x - 45 * scale, y: origin.y + 95 * scale))
        underside.addQuadCurve(to: CGPoint(x: origin.x + 90 * scale, y: origin.y), control: CGPoint(x: origin.x + 45 * scale, y: origin.y + 92 * scale))
        underside.closeSubpath()
        context.fill(underside, with: .color(Color(red: 0.67, green: 0.46, blue: 0.33).opacity(0.28)))
    }

    private static func drawWindZones(_ context: inout GraphicsContext, winds: [SkyWind], animationTime: TimeInterval) {
        for wind in winds {
            let rect = wind.rect.cgRect
            context.fill(
                Path(roundedRect: rect, cornerRadius: 46),
                with: .color(.white.opacity(0.08 + sin(animationTime * 2) * 0.02))
            )
            context.stroke(
                Path(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: 46),
                with: .color(.white.opacity(0.35)),
                style: StrokeStyle(lineWidth: 2, dash: [10, 11])
            )
            for column in stride(from: wind.rect.x + 58, through: wind.rect.maxX - 44, by: 122) {
                let baseline = wind.rect.y + 94 + (column / 122).truncatingRemainder(dividingBy: 3) * 83
                let sway = CGFloat(sin(animationTime * 2.2 + Double(column) * 0.013) * 16)
                var curl = Path()
                curl.move(to: CGPoint(x: column, y: baseline))
                curl.addCurve(
                    to: CGPoint(x: column + 84, y: baseline - 2),
                    control1: CGPoint(x: column + 25, y: baseline - 30 - sway),
                    control2: CGPoint(x: column + 58, y: baseline + 32 + sway)
                )
                context.stroke(curl, with: .color(.white.opacity(0.7)), lineWidth: 4)
                var arrow = Path()
                arrow.move(to: CGPoint(x: column + 77, y: baseline - 8))
                arrow.addLine(to: CGPoint(x: column + 89, y: baseline - 1))
                arrow.addLine(to: CGPoint(x: column + 77, y: baseline + 8))
                context.stroke(arrow, with: .color(.white.opacity(0.7)), lineWidth: 3)
            }
        }
    }

    private static func drawIsland(_ context: inout GraphicsContext, platform: SkyPlatform) {
        let rect = platform.rect
        let dirt = platform.style == .branch ? Color(red: 0.73, green: 0.47, blue: 0.32) : Color(red: 0.79, green: 0.51, blue: 0.35)
        let shadow = platform.style == .branch ? Color(red: 0.56, green: 0.31, blue: 0.24) : Color(red: 0.65, green: 0.34, blue: 0.26)

        var baseShadow = Path()
        baseShadow.move(to: CGPoint(x: rect.x + 8, y: rect.y + 17))
        baseShadow.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.y + 17))
        baseShadow.addQuadCurve(to: CGPoint(x: rect.x + rect.width * 0.79, y: rect.maxY), control: CGPoint(x: rect.maxX - 18, y: rect.y + rect.height * 0.35))
        baseShadow.addQuadCurve(to: CGPoint(x: rect.x + rect.width * 0.2, y: rect.y + rect.height * 0.7), control: CGPoint(x: rect.x + rect.width * 0.48, y: rect.maxY + 35))
        baseShadow.addQuadCurve(to: CGPoint(x: rect.x + 8, y: rect.y + 17), control: CGPoint(x: rect.x + 18, y: rect.y + rect.height * 0.43))
        baseShadow.closeSubpath()
        context.fill(baseShadow, with: .color(shadow))

        var base = Path()
        base.move(to: CGPoint(x: rect.x + 12, y: rect.y + 11))
        base.addLine(to: CGPoint(x: rect.maxX - 12, y: rect.y + 11))
        base.addQuadCurve(to: CGPoint(x: rect.x + rect.width * 0.78, y: rect.maxY - 18), control: CGPoint(x: rect.maxX - 30, y: rect.y + rect.height * 0.29))
        base.addQuadCurve(to: CGPoint(x: rect.x + rect.width * 0.23, y: rect.y + rect.height * 0.58), control: CGPoint(x: rect.x + rect.width * 0.5, y: rect.maxY + 6))
        base.addQuadCurve(to: CGPoint(x: rect.x + 12, y: rect.y + 11), control: CGPoint(x: rect.x + 24, y: rect.y + rect.height * 0.35))
        base.closeSubpath()
        context.fill(base, with: .color(dirt))

        context.fill(
            Path(roundedRect: CGRect(x: rect.x, y: rect.y - 8, width: rect.width, height: 27), cornerRadius: 14),
            with: .color(Color(red: 0.39, green: 0.73, blue: 0.43))
        )
        context.fill(
            Path(roundedRect: CGRect(x: rect.x + 7, y: rect.y - 6, width: rect.width - 14, height: 10), cornerRadius: 8),
            with: .color(Color(red: 0.66, green: 0.84, blue: 0.42))
        )

        let marksCount = max(2, Int(rect.width / 125))
        for index in 0..<marksCount {
            let markX = rect.x + 38 + CGFloat((index * 83 + platform.id.count * 17) % Int(rect.width - 72))
            let markY = rect.y + 54 + CGFloat(index % 3) * 30
            context.fill(
                Path(ellipseIn: CGRect(x: markX - 12, y: markY - 5, width: 24, height: 10)),
                with: .color(Color(red: 0.45, green: 0.25, blue: 0.19).opacity(0.32))
            )
        }

        for index in 0..<platform.flowers {
            let flowerX = rect.x + 34 + CGFloat((index * 73 + platform.id.count * 19) % Int(rect.width - 70))
            let flowerY = rect.y - 11 - CGFloat(index % 2) * 3
            drawFlower(&context, at: CGPoint(x: flowerX, y: flowerY), color: index.isMultiple(of: 2) ? Color(red: 1, green: 0.89, blue: 0.43) : Color(red: 1, green: 0.69, blue: 0.63))
        }
    }

    private static func drawFlower(_ context: inout GraphicsContext, at center: CGPoint, color: Color) {
        var stem = Path()
        stem.addRect(CGRect(x: center.x - 1.5, y: center.y + 2, width: 3, height: 10))
        context.fill(stem, with: .color(Color(red: 0.31, green: 0.67, blue: 0.4)))
        for index in 0..<5 {
            let angle = CGFloat(index) * .pi * 2 / 5
            let petalCenter = CGPoint(x: center.x + CGFloat(cos(Double(angle))) * 5, y: center.y + CGFloat(sin(Double(angle))) * 5)
            context.fill(Path(ellipseIn: CGRect(x: petalCenter.x - 3, y: petalCenter.y - 4.6, width: 6, height: 9.2)), with: .color(color))
        }
        context.fill(Path(ellipseIn: CGRect(x: center.x - 2.8, y: center.y - 2.8, width: 5.6, height: 5.6)), with: .color(Color(red: 0.95, green: 0.58, blue: 0.29)))
    }

    private static func drawStaticDecorations(_ context: inout GraphicsContext, game: SkyFarmGame) {
        drawCoop(&context, at: CGPoint(x: 102, y: 485))
        drawMill(&context, at: CGPoint(x: 1_452, y: 456), isActive: game.checkpointIsActive, animationTime: game.animationTime)
        drawGardenMachine(&context, at: CGPoint(x: 2_085, y: 326))
        drawLighthouse(&context, at: CGPoint(x: 4_370, y: 442), isLit: game.isGoalReady, animationTime: game.animationTime)
        drawSign(&context, at: CGPoint(x: 303, y: 526), title: "FIRST FLIGHT")
        drawSign(&context, at: CGPoint(x: 2_940, y: 457), title: "VINE GARDEN BED")
    }

    private static func drawCoop(_ context: inout GraphicsContext, at point: CGPoint) {
        context.fill(Path(roundedRect: CGRect(x: point.x, y: point.y, width: 122, height: 85), cornerRadius: 12), with: .color(Color(red: 0.94, green: 0.55, blue: 0.39)))
        var roof = Path()
        roof.move(to: CGPoint(x: point.x - 12, y: point.y + 4))
        roof.addLine(to: CGPoint(x: point.x + 61, y: point.y - 47))
        roof.addLine(to: CGPoint(x: point.x + 134, y: point.y + 4))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(red: 0.45, green: 0.25, blue: 0.31)))
        context.fill(Path(roundedRect: CGRect(x: point.x + 47, y: point.y + 42, width: 29, height: 43), cornerRadius: 12), with: .color(Color(red: 1, green: 0.95, blue: 0.79)))
        context.fill(Path(ellipseIn: CGRect(x: point.x + 53, y: point.y + 24, width: 18, height: 18)), with: .color(Color(red: 1, green: 0.82, blue: 0.39)))
    }

    private static func drawMill(_ context: inout GraphicsContext, at point: CGPoint, isActive: Bool, animationTime: TimeInterval) {
        var tower = Path()
        tower.move(to: CGPoint(x: point.x + 16, y: point.y + 84))
        tower.addLine(to: CGPoint(x: point.x + 76, y: point.y + 84))
        tower.addLine(to: CGPoint(x: point.x + 64, y: point.y))
        tower.addLine(to: CGPoint(x: point.x + 29, y: point.y))
        tower.closeSubpath()
        context.fill(tower, with: .color(Color(red: 0.96, green: 0.83, blue: 0.54)))
        var roof = Path()
        roof.move(to: CGPoint(x: point.x + 16, y: point.y + 2))
        roof.addLine(to: CGPoint(x: point.x + 47, y: point.y - 29))
        roof.addLine(to: CGPoint(x: point.x + 76, y: point.y + 2))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(red: 0.88, green: 0.49, blue: 0.38)))

        var blades = context
        blades.translateBy(x: point.x + 47, y: point.y + 20)
        blades.rotate(by: .radians(animationTime * (isActive ? 1.4 : 0.32)))
        for _ in 0..<4 {
            var blade = Path()
            blade.move(to: CGPoint(x: 4, y: -4))
            blade.addLine(to: CGPoint(x: 34, y: -19))
            blade.addLine(to: CGPoint(x: 31, y: 2))
            blade.closeSubpath()
            blades.fill(blade, with: .color(isActive ? Color(red: 1, green: 0.97, blue: 0.84) : Color(red: 0.84, green: 0.88, blue: 0.84)))
            blades.rotate(by: .radians(.pi / 2))
        }
        blades.fill(Path(ellipseIn: CGRect(x: -8, y: -8, width: 16, height: 16)), with: .color(Color(red: 0.93, green: 0.6, blue: 0.4)))
    }

    private static func drawGardenMachine(_ context: inout GraphicsContext, at point: CGPoint) {
        context.fill(Path(roundedRect: CGRect(x: point.x, y: point.y + 16, width: 76, height: 44), cornerRadius: 10), with: .color(Color(red: 0.47, green: 0.72, blue: 0.63)))
        var frame = Path()
        frame.move(to: CGPoint(x: point.x + 17, y: point.y + 16))
        frame.addLine(to: CGPoint(x: point.x + 12, y: point.y - 5))
        frame.addLine(to: CGPoint(x: point.x + 50, y: point.y - 5))
        frame.addLine(to: CGPoint(x: point.x + 57, y: point.y + 16))
        context.stroke(frame, with: .color(Color(red: 0.88, green: 0.97, blue: 0.85)), lineWidth: 4)
        context.fill(Path(ellipseIn: CGRect(x: point.x + 25, y: point.y + 24, width: 26, height: 26)), with: .color(Color(red: 1, green: 0.84, blue: 0.42)))
    }

    private static func drawLighthouse(_ context: inout GraphicsContext, at point: CGPoint, isLit: Bool, animationTime: TimeInterval) {
        let beamOpacity = isLit ? 0.18 + sin(animationTime * 4) * 0.04 : 0.03
        var beam = Path()
        beam.move(to: CGPoint(x: point.x + 49, y: point.y + 18))
        beam.addLine(to: CGPoint(x: point.x - 250, y: point.y - 82))
        beam.addLine(to: CGPoint(x: point.x - 250, y: point.y + 112))
        beam.closeSubpath()
        context.fill(beam, with: .color(Color(red: 1, green: 0.96, blue: 0.67).opacity(beamOpacity)))
        var tower = Path()
        tower.move(to: CGPoint(x: point.x + 12, y: point.y + 110))
        tower.addLine(to: CGPoint(x: point.x + 85, y: point.y + 110))
        tower.addLine(to: CGPoint(x: point.x + 72, y: point.y + 32))
        tower.addLine(to: CGPoint(x: point.x + 26, y: point.y + 32))
        tower.closeSubpath()
        context.fill(tower, with: .color(Color(red: 0.97, green: 0.91, blue: 0.78)))
        var stripe = Path()
        stripe.addRect(CGRect(x: point.x + 22, y: point.y + 46, width: 55, height: 15))
        context.fill(stripe, with: .color(Color(red: 0.89, green: 0.44, blue: 0.38)))
        context.fill(Path(roundedRect: CGRect(x: point.x + 28, y: point.y + 1, width: 42, height: 36), cornerRadius: 8), with: .color(isLit ? Color(red: 1, green: 0.95, blue: 0.6) : Color(red: 0.41, green: 0.5, blue: 0.57)))
        var roof = Path()
        roof.move(to: CGPoint(x: point.x + 21, y: point.y + 4))
        roof.addLine(to: CGPoint(x: point.x + 49, y: point.y - 20))
        roof.addLine(to: CGPoint(x: point.x + 77, y: point.y + 4))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(red: 0.42, green: 0.28, blue: 0.34)))
    }

    private static func drawSign(_ context: inout GraphicsContext, at point: CGPoint, title: String) {
        var post = Path()
        post.addRect(CGRect(x: point.x - 4, y: point.y + 2, width: 7, height: 42))
        context.fill(post, with: .color(Color(red: 0.6, green: 0.36, blue: 0.26)))
        context.fill(Path(roundedRect: CGRect(x: point.x - 58, y: point.y - 24, width: 112, height: 31), cornerRadius: 7), with: .color(Color(red: 0.96, green: 0.81, blue: 0.48)))
        drawText(&context, title, at: CGPoint(x: point.x - 3, y: point.y - 8), size: 10, color: Color(red: 0.53, green: 0.35, blue: 0.27))
    }

    private static func drawSeedBeds(_ context: inout GraphicsContext, game: SkyFarmGame) {
        for bed in game.beds {
            let rect = bed.rect.cgRect
            if !bed.isGrown, !bed.isPending {
                context.fill(Path(ellipseIn: rect.insetBy(dx: -18, dy: -18)), with: .color(Color(red: 1, green: 0.95, blue: 0.61).opacity(0.2)))
            }
            context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(Color(red: 0.55, green: 0.32, blue: 0.24)))
            context.fill(Path(roundedRect: rect.insetBy(dx: 4, dy: 3), cornerRadius: 6), with: .color(Color(red: 0.87, green: 0.6, blue: 0.36)))
            let seedColor = bed.isPending ? Color(red: 1, green: 0.96, blue: 0.65) : (bed.isGrown ? Color(red: 0.53, green: 0.75, blue: 0.4) : bed.tint)
            for index in 0..<3 {
                let x = bed.rect.x + 17 + CGFloat(index) * 16
                context.fill(Path(ellipseIn: CGRect(x: x - 4, y: bed.rect.y + 6.5, width: 8, height: 5)), with: .color(seedColor))
            }

            if game.phase == .running,
               let active = game.activeBed,
               active.id == bed.id {
                drawWorldPrompt(&context, text: "Plant: \(bed.title)", at: CGPoint(x: rect.midX, y: rect.minY - 30), color: .white)
            }
        }
    }

    private static func drawGrownPlants(_ context: inout GraphicsContext, game: SkyFarmGame) {
        for plant in game.grownPlants {
            var plantContext = context
            plantContext.opacity = Double(plant.opacity)
            switch plant.kind {
            case .bridge:
                drawBridge(&plantContext, plant: plant)
            case .mushroom:
                drawMushroom(&plantContext, plant: plant)
            case .vine:
                drawVine(&plantContext, plant: plant)
            }
        }
    }

    private static func drawBridge(_ context: inout GraphicsContext, plant: SkyGrownPlant) {
        var vine = Path()
        vine.move(to: CGPoint(x: plant.rect.x + 4, y: plant.rect.y + 9))
        vine.addQuadCurve(to: CGPoint(x: plant.rect.maxX - 4, y: plant.rect.y + 9), control: CGPoint(x: plant.rect.x + plant.rect.width / 2, y: plant.rect.y - 20))
        context.stroke(vine, with: .color(Color(red: 0.43, green: 0.54, blue: 0.32)), lineWidth: 6)
        for index in 0..<11 {
            let plankWidth = plant.rect.width / 11
            let rect = CGRect(x: plant.rect.x + CGFloat(index) * plankWidth + 1, y: plant.rect.y + 4, width: plankWidth - 3, height: plant.rect.height - 7)
            context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(index.isMultiple(of: 2) ? Color(red: 0.88, green: 0.65, blue: 0.4) : Color(red: 0.84, green: 0.57, blue: 0.34)))
            context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(Color(red: 0.43, green: 0.27, blue: 0.18).opacity(0.35)), lineWidth: 1)
        }
    }

    private static func drawMushroom(_ context: inout GraphicsContext, plant: SkyGrownPlant) {
        let rect = plant.rect
        context.fill(Path(roundedRect: CGRect(x: rect.x + 40, y: rect.y + 24, width: 53, height: 33), cornerRadius: 19), with: .color(Color(red: 0.98, green: 0.9, blue: 0.74)))
        var cap = Path()
        cap.addEllipse(in: CGRect(x: rect.x, y: rect.y - 13, width: rect.width, height: 62))
        context.fill(cap, with: .color(Color(red: 0.94, green: 0.47, blue: 0.41)))
        for (x, y, radius) in [(35 as CGFloat, 16 as CGFloat, 6 as CGFloat), (70, 8, 8), (99, 21, 5)] {
            context.fill(Path(ellipseIn: CGRect(x: rect.x + x - radius, y: rect.y + y - radius, width: radius * 2, height: radius * 2)), with: .color(Color(red: 1, green: 0.92, blue: 0.72)))
        }
    }

    private static func drawVine(_ context: inout GraphicsContext, plant: SkyGrownPlant) {
        var vine = Path()
        vine.move(to: CGPoint(x: plant.rect.x + 20, y: plant.rect.maxY))
        vine.addCurve(
            to: CGPoint(x: plant.rect.x + 168, y: plant.rect.y + 8),
            control1: CGPoint(x: plant.rect.x + 65, y: plant.rect.maxY - 80),
            control2: CGPoint(x: plant.rect.x + 80, y: plant.rect.y + 70)
        )
        context.stroke(vine, with: .color(Color(red: 0.31, green: 0.62, blue: 0.39)), lineWidth: 8)
        for leaf in plant.leaves {
            context.fill(Path(roundedRect: leaf.cgRect, cornerRadius: 10), with: .color(Color(red: 0.36, green: 0.7, blue: 0.4)))
            context.fill(Path(roundedRect: leaf.cgRect.insetBy(dx: 7, dy: 3), cornerRadius: 5), with: .color(Color(red: 0.61, green: 0.83, blue: 0.43)))
        }
    }

    private static func drawParts(_ context: inout GraphicsContext, game: SkyFarmGame) {
        for part in game.parts where !part.isCollected {
            let bob = CGFloat(sin(game.animationTime * 3.2 + Double(part.x) * 0.01) * 5)
            let center = CGPoint(x: part.x, y: part.y + bob)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 28, y: center.y - 28, width: 56, height: 56)), with: .color(Color(red: 1, green: 0.95, blue: 0.52).opacity(0.24)))
            for tooth in 0..<6 {
                let angle = CGFloat(tooth) * .pi / 3 + CGFloat(game.animationTime) * 1.8
                let toothCenter = CGPoint(x: center.x + CGFloat(cos(Double(angle))) * 15, y: center.y + CGFloat(sin(Double(angle))) * 15)
                context.fill(Path(roundedRect: CGRect(x: toothCenter.x - 6, y: toothCenter.y - 5, width: 12, height: 10), cornerRadius: 3), with: .color(Color(red: 1, green: 0.78, blue: 0.38)))
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)), with: .color(Color(red: 0.94, green: 0.54, blue: 0.3)))
            context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(Color(red: 1, green: 0.93, blue: 0.62)))
        }
    }

    private static func drawRaven(_ context: inout GraphicsContext, raven: SkyRaven, animationTime: TimeInterval) {
        let flap = CGFloat(sin(animationTime * 14 + Double(raven.offset)) * 9)
        var wings = Path()
        wings.move(to: CGPoint(x: raven.x - 4, y: raven.y + 1))
        wings.addQuadCurve(to: CGPoint(x: raven.x - 41, y: raven.y - 4), control: CGPoint(x: raven.x - 27, y: raven.y - 22 - flap))
        wings.addQuadCurve(to: CGPoint(x: raven.x - 7, y: raven.y + 11), control: CGPoint(x: raven.x - 22, y: raven.y - 5))
        wings.closeSubpath()
        context.fill(wings, with: .color(Color(red: 0.24, green: 0.31, blue: 0.44)))
        var rightWing = Path()
        rightWing.move(to: CGPoint(x: raven.x + 4, y: raven.y + 1))
        rightWing.addQuadCurve(to: CGPoint(x: raven.x + 43, y: raven.y - 1), control: CGPoint(x: raven.x + 25, y: raven.y - 24 + flap))
        rightWing.addQuadCurve(to: CGPoint(x: raven.x + 7, y: raven.y + 11), control: CGPoint(x: raven.x + 22, y: raven.y - 3))
        rightWing.closeSubpath()
        context.fill(rightWing, with: .color(Color(red: 0.24, green: 0.31, blue: 0.44)))
        context.fill(Path(ellipseIn: CGRect(x: raven.x - 16, y: raven.y - 7, width: 32, height: 24)), with: .color(Color(red: 0.35, green: 0.4, blue: 0.51)))
        var beak = Path()
        beak.move(to: CGPoint(x: raven.x + 12, y: raven.y + 3))
        beak.addLine(to: CGPoint(x: raven.x + 24, y: raven.y + 8))
        beak.addLine(to: CGPoint(x: raven.x + 12, y: raven.y + 11))
        beak.closeSubpath()
        context.fill(beak, with: .color(Color(red: 0.96, green: 0.76, blue: 0.35)))
    }

    private static func drawChick(_ context: inout GraphicsContext, game: SkyFarmGame) {
        guard !game.chickIsRescued else { return }
        let bob = CGFloat(sin(game.animationTime * 5) * 2)
        let center = CGPoint(x: 3_910, y: 499 + bob)
        context.stroke(Path(roundedRect: CGRect(x: center.x - 24, y: center.y - 18, width: 48, height: 43), cornerRadius: 9), with: .color(Color(red: 0.54, green: 0.4, blue: 0.3)), lineWidth: 4)
        context.fill(Path(ellipseIn: CGRect(x: center.x - 16, y: center.y - 8, width: 30, height: 30)), with: .color(Color(red: 1, green: 0.94, blue: 0.62)))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 16, width: 24, height: 24)), with: .color(Color(red: 1, green: 0.94, blue: 0.62)))
        context.fill(Path(ellipseIn: CGRect(x: center.x + 8, y: center.y - 12, width: 4.5, height: 4.5)), with: .color(Color(red: 0.22, green: 0.24, blue: 0.3)))
        var beak = Path()
        beak.move(to: CGPoint(x: center.x + 17, y: center.y - 5))
        beak.addLine(to: CGPoint(x: center.x + 27, y: center.y))
        beak.addLine(to: CGPoint(x: center.x + 17, y: center.y + 5))
        beak.closeSubpath()
        context.fill(beak, with: .color(Color(red: 0.94, green: 0.58, blue: 0.3)))
        if game.phase == .running, game.isChickNearby {
            drawWorldPrompt(&context, text: "Rescue Pip", at: CGPoint(x: center.x, y: center.y - 46), color: .white)
        }
    }

    private static func drawGoal(_ context: inout GraphicsContext, game: SkyFarmGame) {
        let rect = game.goalRect
        let lit = game.isGoalReady
        context.fill(Path(ellipseIn: CGRect(x: rect.x - 37, y: rect.y - 39, width: 172, height: 172)), with: .color((lit ? Color(red: 1, green: 0.95, blue: 0.56) : Color(red: 0.4, green: 0.55, blue: 0.62)).opacity(lit ? 0.24 : 0.13)))
        var arch = Path()
        arch.move(to: CGPoint(x: rect.x + 13, y: rect.maxY - 4))
        arch.addLine(to: CGPoint(x: rect.x + 13, y: rect.y + 46))
        arch.addQuadCurve(to: CGPoint(x: rect.x + 49, y: rect.y + 2), control: CGPoint(x: rect.x + 49, y: rect.y + 2))
        arch.addQuadCurve(to: CGPoint(x: rect.x + 85, y: rect.y + 46), control: CGPoint(x: rect.x + 49, y: rect.y + 2))
        arch.addLine(to: CGPoint(x: rect.x + 85, y: rect.maxY - 4))
        context.stroke(arch, with: .color(lit ? Color(red: 1, green: 0.91, blue: 0.46) : Color(red: 0.45, green: 0.53, blue: 0.6)), lineWidth: 8)
        context.fill(Path(ellipseIn: CGRect(x: rect.x + 37, y: rect.y + 31, width: 24, height: 24)), with: .color(lit ? Color(red: 1, green: 0.95, blue: 0.58) : Color(red: 0.46, green: 0.57, blue: 0.63)))
        if !lit {
            drawWorldPrompt(&context, text: "lighthouse awaits parts and Pip", at: CGPoint(x: rect.x + 49, y: rect.y - 23), color: Color(red: 0.91, green: 0.96, blue: 0.95))
        }
    }

    private static func drawSeed(_ context: inout GraphicsContext, position: CGPoint, animationTime: TimeInterval) {
        context.fill(Path(ellipseIn: CGRect(x: position.x - 7, y: position.y - 5, width: 14, height: 10)), with: .color(Color(red: 1, green: 0.89, blue: 0.45)))
        context.fill(Path(ellipseIn: CGRect(x: position.x - 9, y: position.y - 10, width: 9, height: 5)), with: .color(Color(red: 0.55, green: 0.73, blue: 0.37)))
    }

    private static func drawPlayer(_ context: inout GraphicsContext, player: SkyPlayer, animationTime: TimeInterval) {
        var playerContext = context
        if player.invulnerability > 0, Int(animationTime * 16).isMultiple(of: 2) {
            playerContext.opacity = 0.38
        }
        let center = player.center
        let running = player.isGrounded && abs(player.velocityX) > 25
        let bob = running ? CGFloat(sin(animationTime * 19) * 1.5) : 0
        let legSwing = running ? CGFloat(sin(animationTime * 19) * 3) : 0
        var bodyContext = playerContext
        bodyContext.translateBy(x: center.x, y: center.y + bob)
        bodyContext.scaleBy(x: player.facing, y: 1)

        if player.isGliding {
            var leftWing = Path()
            leftWing.move(to: CGPoint(x: -9, y: -1))
            leftWing.addQuadCurve(to: CGPoint(x: -73, y: -10), control: CGPoint(x: -52, y: -37))
            leftWing.addQuadCurve(to: CGPoint(x: -17, y: 9), control: CGPoint(x: -50, y: 11))
            leftWing.closeSubpath()
            bodyContext.fill(leftWing, with: .color(Color(red: 0.98, green: 0.93, blue: 0.82)))
            bodyContext.stroke(leftWing, with: .color(Color(red: 0.85, green: 0.71, blue: 0.55)), lineWidth: 2)
            var rightWing = Path()
            rightWing.move(to: CGPoint(x: 8, y: -2))
            rightWing.addQuadCurve(to: CGPoint(x: 67, y: -6), control: CGPoint(x: 40, y: -33))
            rightWing.addQuadCurve(to: CGPoint(x: 15, y: 8), control: CGPoint(x: 42, y: 11))
            rightWing.closeSubpath()
            bodyContext.fill(rightWing, with: .color(Color(red: 0.98, green: 0.93, blue: 0.82)))
            bodyContext.stroke(rightWing, with: .color(Color(red: 0.85, green: 0.71, blue: 0.55)), lineWidth: 2)
        }

        var legs = Path()
        legs.move(to: CGPoint(x: -8, y: 23))
        legs.addLine(to: CGPoint(x: -8, y: 29 + legSwing))
        legs.move(to: CGPoint(x: 9, y: 23))
        legs.addLine(to: CGPoint(x: 9, y: 29 - legSwing))
        bodyContext.stroke(legs, with: .color(Color(red: 0.9, green: 0.59, blue: 0.3)), lineWidth: 3)

        bodyContext.fill(Path(ellipseIn: CGRect(x: -24, y: -10, width: 42, height: 36)), with: .color(Color(red: 1, green: 0.97, blue: 0.9)))
        bodyContext.stroke(Path(ellipseIn: CGRect(x: -24, y: -10, width: 42, height: 36)), with: .color(Color(red: 0.84, green: 0.72, blue: 0.55)), lineWidth: 2)
        bodyContext.fill(Path(ellipseIn: CGRect(x: -24, y: -5, width: 20, height: 27)), with: .color(Color(red: 0.96, green: 0.9, blue: 0.81)))
        bodyContext.fill(Path(ellipseIn: CGRect(x: -7, y: -25, width: 32, height: 30)), with: .color(Color(red: 1, green: 0.97, blue: 0.9)))
        bodyContext.stroke(Path(ellipseIn: CGRect(x: -7, y: -25, width: 32, height: 30)), with: .color(Color(red: 0.84, green: 0.72, blue: 0.55)), lineWidth: 2)
        for index in 0..<3 {
            bodyContext.fill(Path(ellipseIn: CGRect(x: 1 + CGFloat(index) * 7, y: -29 - (index == 1 ? 3 : 0), width: 10, height: 10)), with: .color(Color(red: 0.94, green: 0.45, blue: 0.37)))
        }
        bodyContext.fill(Path(ellipseIn: CGRect(x: 11, y: -16, width: 5, height: 5)), with: .color(Color(red: 0.2, green: 0.25, blue: 0.34)))
        var beak = Path()
        beak.move(to: CGPoint(x: 23, y: -11))
        beak.addLine(to: CGPoint(x: 34, y: -7))
        beak.addLine(to: CGPoint(x: 23, y: -3))
        beak.closeSubpath()
        bodyContext.fill(beak, with: .color(Color(red: 0.94, green: 0.61, blue: 0.31)))
    }

    private static func drawWorldPrompt(_ context: inout GraphicsContext, text: String, at point: CGPoint, color: Color) {
        let estimatedWidth = CGFloat(text.count) * 7.4 + 24
        let rect = CGRect(x: point.x - estimatedWidth / 2, y: point.y - 18, width: estimatedWidth, height: 29)
        context.fill(Path(roundedRect: rect, cornerRadius: 12), with: .color(Color(red: 0.12, green: 0.22, blue: 0.31).opacity(0.72)))
        drawText(&context, text, at: CGPoint(x: point.x, y: point.y - 3), size: 14, color: color)
    }

    private static func drawText(_ context: inout GraphicsContext, _ value: String, at point: CGPoint, size: CGFloat, color: Color) {
        context.draw(
            Text(value)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .foregroundStyle(color),
            at: point,
            anchor: .center
        )
    }
}
