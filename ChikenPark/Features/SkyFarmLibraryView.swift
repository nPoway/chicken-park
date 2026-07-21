import SwiftUI

/// A companion screen for gameplay knowledge and long-term goals.
///
/// The screen deliberately receives the shared progress store instead of maintaining
/// a second copy of achievement state, so newly unlocked rewards are reflected at
/// once when the player returns from a level.
struct SkyFarmLibraryView: View {
    @ObservedObject var progress: SkyFarmProgress

    private let articles = SkyFarmArticle.sampleArticles

    private var unlockedCount: Int {
        progress.achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                journalHero

                articleSection

                achievementSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(SkyFarmLibraryBackground())
        .navigationTitle("Flight Log")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Label("Clara's Journal", systemImage: "book.closed.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(SkyFarmLibraryPalette.ink)
                    .accessibilityLabel("Clara's Journal")
            }
        }
    }

    private var journalHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.27))
                        .frame(width: 62, height: 62)
                    Image(systemName: "feather.fill")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-18))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Clara's Notes")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Tips for flying, gardening, and saving the farm")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "rosette")
                    .font(.system(size: 15, weight: .bold))
                Text("Achievements unlocked: \(unlockedCount) of \(progress.achievements.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(.black.opacity(0.14), in: Capsule())
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SkyFarmLibraryPalette.sky,
                            SkyFarmLibraryPalette.blueberry
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.14))
                        .frame(width: 116, height: 116)
                        .offset(x: 35, y: -42)
                }
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 57))
                        .foregroundStyle(.white.opacity(0.15))
                        .offset(x: -7, y: 22)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: SkyFarmLibraryPalette.blueberry.opacity(0.22), radius: 16, y: 9)
        .accessibilityElement(children: .combine)
    }

    private var articleSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SkyFarmLibrarySectionHeader(
                title: "Flight School",
                subtitle: "Quick notes before your next island",
                icon: "graduationcap.fill",
                tint: SkyFarmLibraryPalette.sunflower
            )

            ForEach(articles) { article in
                NavigationLink {
                    SkyFarmArticleDetailView(article: article)
                } label: {
                    SkyFarmArticleRow(article: article)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Open article")
            }
        }
    }

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SkyFarmLibrarySectionHeader(
                title: "Achievements",
                subtitle: "Small feats make the farm stronger",
                icon: "rosette",
                tint: SkyFarmLibraryPalette.coral
            )

            if progress.achievements.isEmpty {
                SkyFarmEmptyAchievementsCard()
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(progress.achievements, id: \.id) { achievement in
                        SkyFarmAchievementCard(achievement: achievement)
                    }
                }
            }
        }
    }
}

private struct SkyFarmLibrarySectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(SkyFarmLibraryPalette.ink)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SkyFarmLibraryPalette.mutedInk)
            }
        }
    }
}

private struct SkyFarmArticleRow: View {
    let article: SkyFarmArticle

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(article.tint.opacity(0.16))
                Image(systemName: article.icon)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(article.tint)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(SkyFarmLibraryPalette.ink)
                    .lineLimit(1)
                Text(article.summary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SkyFarmLibraryPalette.mutedInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Label(article.readingTime, systemImage: "clock")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(article.tint)
                    .padding(.top, 1)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SkyFarmLibraryPalette.mutedInk.opacity(0.72))
        }
        .padding(12)
        .background(.white.opacity(0.87), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(.white.opacity(0.94), lineWidth: 1)
        }
        .shadow(color: SkyFarmLibraryPalette.ink.opacity(0.06), radius: 10, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
    }
}

private struct SkyFarmAchievementCard: View {
    let achievement: SkyAchievement

    private var completion: Double {
        guard achievement.target > 0 else { return achievement.isUnlocked ? 1 : 0 }
        return min(max(Double(achievement.progress) / Double(achievement.target), 0), 1)
    }

    private var accent: Color {
        achievement.isUnlocked ? SkyFarmLibraryPalette.mint : SkyFarmLibraryPalette.mutedInk
    }

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent.opacity(achievement.isUnlocked ? 0.18 : 0.12))
                Image(systemName: achievement.icon)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(accent)
                    .symbolEffect(.pulse, options: .repeating, value: achievement.isUnlocked)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SkyFarmLibraryPalette.ink)
                        .lineLimit(1)

                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SkyFarmLibraryPalette.mint)
                    }
                }

                Text(achievement.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SkyFarmLibraryPalette.mutedInk)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    ProgressView(value: completion)
                        .tint(accent)
                        .scaleEffect(x: 1, y: 0.82, anchor: .center)

                    Text(achievement.isUnlocked ? "Complete" : "\(achievement.progress)/\(achievement.target)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                }
            }
        }
        .padding(13)
        .background(.white.opacity(achievement.isUnlocked ? 0.96 : 0.78), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(achievement.isUnlocked ? SkyFarmLibraryPalette.mint.opacity(0.22) : .white.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: SkyFarmLibraryPalette.ink.opacity(0.045), radius: 9, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title). \(achievement.detail). \(achievement.isUnlocked ? "Achievement unlocked" : "Progress \(achievement.progress) of \(achievement.target)")")
    }
}

private struct SkyFarmEmptyAchievementsCard: View {
    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: "sparkles")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(SkyFarmLibraryPalette.sunflower)
            Text("Your first achievements are on the way")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(SkyFarmLibraryPalette.ink)
            Text("Complete an island, rescue Pip, or grow your first vine.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SkyFarmLibraryPalette.mutedInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct SkyFarmArticleDetailView: View {
    let article: SkyFarmArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(article.tint.opacity(0.17))
                        Image(systemName: article.icon)
                            .font(.system(size: 45, weight: .bold))
                            .foregroundStyle(article.tint)
                    }
                    .frame(height: 142)

                    Label(article.readingTime, systemImage: "clock")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(article.tint)

                    Text(article.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(SkyFarmLibraryPalette.ink)
                    Text(article.summary)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(SkyFarmLibraryPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .background(.white.opacity(0.87), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                ForEach(article.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(SkyFarmLibraryPalette.ink)

                        Text(section.text)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(SkyFarmLibraryPalette.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                    .padding(18)
                    .background(.white.opacity(0.83), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(SkyFarmLibraryPalette.sunflower)
                    Text(article.tip)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(SkyFarmLibraryPalette.ink)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SkyFarmLibraryPalette.sunflower.opacity(0.16), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(20)
            .padding(.bottom, 26)
        }
        .background(SkyFarmLibraryBackground())
        .navigationTitle("Clara's Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SkyFarmLibraryBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.91, green: 0.97, blue: 0.98),
                Color(red: 0.99, green: 0.96, blue: 0.86)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.45))
                .frame(width: 180, height: 180)
                .offset(x: 68, y: -62)
        }
        .ignoresSafeArea()
    }
}

private struct SkyFarmArticle: Identifiable {
    struct Section: Identifiable {
        let id = UUID()
        let title: String
        let text: String
    }

    let id: String
    let title: String
    let summary: String
    let icon: String
    let tint: Color
    let readingTime: String
    let sections: [Section]
    let tip: String

    static let sampleArticles: [SkyFarmArticle] = [
        SkyFarmArticle(
            id: "glide",
            title: "Wings Like a Parachute",
            summary: "How to catch an updraft and land softly on a small island.",
            icon: "wind",
            tint: SkyFarmLibraryPalette.sky,
            readingTime: "1 min",
            sections: [
                Section(title: "Don't Spread Your Wings Too Early", text: "A jump gives Clara height. Wait a moment after leaving the ground, then hold the jump button — her wings become a light parachute."),
                Section(title: "Listen to the Wind", text: "Air currents lift Clara higher and extend her flight. Fly into a current diagonally to keep your speed and spot the next island."),
                Section(title: "Easy Landings", text: "Release your wings before the platform's edge. A short descent is safer than a long glide, especially near ravens.")
            ],
            tip: "Clara's tip: a wind current is not just a lift; it's also a safe way over a chasm."
        ),
        SkyFarmArticle(
            id: "seeds",
            title: "Seeds for Every Occasion",
            summary: "A bridge, mushroom, or vine can appear when you need one more step.",
            icon: "leaf.fill",
            tint: SkyFarmLibraryPalette.mint,
            readingTime: "1 min",
            sections: [
                Section(title: "Look for Garden Beds", text: "A seed only works in a prepared garden bed. Walk up to one and toss a seed: in a few seconds, a helpful plant will grow."),
                Section(title: "Choose the Right Moment", text: "A bridge helps you cross a gap, a mushroom sends you back up, and a vine leads to secret platforms. Before you toss a seed, look at the obstacle ahead."),
                Section(title: "Save Your Seeds", text: "You only have a few seeds, but you'll find more throughout the level. Don't use your last one on flat ground — you might need it at the lighthouse.")
            ],
            tip: "Clara's tip: if you see a garden bed before a wide gap, it almost certainly holds the way forward."
        ),
        SkyFarmArticle(
            id: "ravens",
            title: "Thieving Ravens",
            summary: "They love shiny parts, but hate a headwind.",
            icon: "bird.fill",
            tint: SkyFarmLibraryPalette.coral,
            readingTime: "45 sec",
            sections: [
                Section(title: "Watch Their Flight Path", text: "Ravens fly short routes and turn around at the edge. Watch them for a second to see when a clear path opens beneath them."),
                Section(title: "Don't Fly Into Their Beaks", text: "A collision costs you a heart and sends Clara back to the checkpoint. It's safer to go underneath or use the air current above the bird."),
                Section(title: "Parts Before Speed", text: "A raven may guard a shiny part. First find a safe spot to land, then collect it in one short flight.")
            ],
            tip: "Clara's tip: the wind around a raven's wing usually warns you before it turns."
        ),
        SkyFarmArticle(
            id: "restoration",
            title: "How the Farm Comes Alive",
            summary: "Every part you find brings a little bit of sky back to Clara's home.",
            icon: "house.and.flag.fill",
            tint: SkyFarmLibraryPalette.sunflower,
            readingTime: "1 min",
            sections: [
                Section(title: "Parts Matter", text: "Collected gears and mechanisms go toward the coop, garden, mill, and hot-air balloon. Each new building not only decorates the base but also unlocks useful upgrades."),
                Section(title: "Chicks Help Out", text: "Rescued chicks become helpers. Some find more seeds, others point out secret routes or speed up restoration."),
                Section(title: "Return to Base", text: "After an island, stop by the farm: that's where you'll see the real results of the journey. When a building comes alive, a new route appears on the map.")
            ],
            tip: "Clara's tip: restore whatever helps you fly farther first — then new islands will be closer."
        )
    ]
}

private enum SkyFarmLibraryPalette {
    static let sky = Color(red: 0.28, green: 0.64, blue: 0.88)
    static let blueberry = Color(red: 0.20, green: 0.34, blue: 0.61)
    static let mint = Color(red: 0.23, green: 0.68, blue: 0.51)
    static let sunflower = Color(red: 0.95, green: 0.62, blue: 0.18)
    static let coral = Color(red: 0.91, green: 0.35, blue: 0.32)
    static let ink = Color(red: 0.12, green: 0.22, blue: 0.31)
    static let mutedInk = Color(red: 0.36, green: 0.45, blue: 0.52)
}
