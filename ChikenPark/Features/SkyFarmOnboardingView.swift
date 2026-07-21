import SwiftUI

/// A lightweight first-flight introduction. Persistence intentionally lives at
/// the app root so this view can also be reused from Settings or a preview flow.
struct SkyFarmOnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0

    private let pages = SkyFarmOnboardingStep.all

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 700
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack {
                SkyFarmOnboardingBackground(accent: pages[currentPage].accent)

                VStack(spacing: 0) {
                    navigationBar
                        .padding(.bottom, isCompact ? 2 : 10)

                    TabView(selection: $currentPage) {
                        ForEach(pages) { page in
                            SkyFarmOnboardingPage(
                                step: page,
                                isCompact: isCompact,
                                isLandscape: isLandscape
                            )
                                .tag(page.id)
                                .accessibilityElement(children: .contain)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .transaction { transaction in
                        if reduceMotion {
                            transaction.animation = nil
                        }
                    }

                    pageIndicators
                        .padding(.top, isCompact ? 4 : 10)
                        .padding(.bottom, isCompact ? 14 : 18)

                    primaryAction
                }
                .padding(.horizontal, isCompact ? 18 : 22)
                .padding(.top, isCompact ? 10 : 16)
                .padding(.bottom, isCompact ? 14 : 20)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.32), value: currentPage)
        }
        .preferredColorScheme(.light)
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            if currentPage > 0 {
                Button(action: showPreviousPage) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SkyFarmOnboardingPalette.ink)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.72), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Returns to the previous introduction step")
            } else {
                Color.clear
                    .frame(width: 76, height: 40)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            if currentPage < pages.count - 1 {
                Button(action: onComplete) {
                    Text("Skip")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SkyFarmOnboardingPalette.mutedInk)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.58), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Starts the game without viewing the remaining introduction steps")
            } else {
                Color.clear
                    .frame(width: 64, height: 40)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 44)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(pages) { page in
                Button {
                    showPage(page.id)
                } label: {
                    Capsule(style: .continuous)
                        .fill(page.id == currentPage ? SkyFarmOnboardingPalette.deepSky : .white.opacity(0.72))
                        .frame(width: page.id == currentPage ? 30 : 9, height: 9)
                        .overlay {
                            if page.id != currentPage {
                                Capsule(style: .continuous)
                                    .stroke(SkyFarmOnboardingPalette.deepSky.opacity(0.12), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Step \(page.id + 1) of \(pages.count): \(page.accessibilityTitle)")
                .accessibilityValue(page.id == currentPage ? "Current step" : "")
                .accessibilityHint(page.id == currentPage ? "Current introduction step" : "Opens this introduction step")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding progress")
    }

    private var primaryAction: some View {
        let isLastPage = currentPage == pages.count - 1

        return Button(action: isLastPage ? onComplete : showNextPage) {
            Label(
                isLastPage ? "Start flying" : "Continue",
                systemImage: isLastPage ? "paperplane.fill" : "arrow.right"
            )
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(SkyFarmOnboardingPrimaryButtonStyle())
        .accessibilityLabel(isLastPage ? "Start Chick Sky Farm" : "Continue to the next introduction step")
        .accessibilityHint(isLastPage ? "Closes the introduction and opens the game" : "Shows the next introduction step")
    }

    private func showPreviousPage() {
        showPage(max(0, currentPage - 1))
    }

    private func showNextPage() {
        showPage(min(pages.count - 1, currentPage + 1))
    }

    private func showPage(_ page: Int) {
        guard page != currentPage else { return }

        if reduceMotion {
            currentPage = page
        } else {
            withAnimation(.snappy(duration: 0.34, extraBounce: 0.08)) {
                currentPage = page
            }
        }
    }
}

private struct SkyFarmOnboardingPage: View {
    let step: SkyFarmOnboardingStep
    let isCompact: Bool
    let isLandscape: Bool

    private var heroSize: CGFloat {
        if isLandscape {
            return 138
        }
        return isCompact ? 184 : 238
    }

    var body: some View {
        Group {
            if isLandscape {
                landscapeContent
            } else {
                portraitContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.accessibilityTitle). \(step.subtitle). \(step.featureTitle): \(step.featureText)")
    }

    private var portraitContent: some View {
        VStack(spacing: isCompact ? 15 : 21) {
            Spacer(minLength: isCompact ? 4 : 12)

            hero

            VStack(spacing: 8) {
                Text(step.eyebrow)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.25)
                    .foregroundStyle(step.accent)

                Text(step.title)
                    .font(.system(size: isCompact ? 30 : 35, weight: .heavy, design: .rounded))
                    .tracking(-0.7)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SkyFarmOnboardingPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.subtitle)
                    .font(.system(size: isCompact ? 14 : 16, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SkyFarmOnboardingPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }

            featureCard

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, isCompact ? 6 : 12)
    }

    private var landscapeContent: some View {
        HStack(spacing: 24) {
            hero

            VStack(alignment: .leading, spacing: 10) {
                Text(step.eyebrow)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(step.accent)

                Text(step.title)
                    .font(.system(size: 27, weight: .heavy, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(SkyFarmOnboardingPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SkyFarmOnboardingPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                featureCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(step.accent.opacity(0.12))
                .frame(width: heroSize + 34, height: heroSize + 34)

            Image("logo-icon")
                .resizable()
                .scaledToFill()
                .frame(width: heroSize, height: heroSize)
                .clipShape(RoundedRectangle(cornerRadius: heroSize * 0.25, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: heroSize * 0.25, style: .continuous)
                        .stroke(.white.opacity(0.95), lineWidth: 4)
                }
                .shadow(color: SkyFarmOnboardingPalette.deepSky.opacity(0.22), radius: 22, y: 12)
                .accessibilityHidden(true)

            Image(systemName: step.icon)
                .font(.system(size: isCompact ? 19 : 23, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: isCompact ? 48 : 56, height: isCompact ? 48 : 56)
                .background(step.accent, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.9), lineWidth: 3)
                }
                .shadow(color: step.accent.opacity(0.34), radius: 10, y: 5)
                .offset(x: heroSize * 0.34, y: heroSize * 0.34)
                .accessibilityHidden(true)
        }
        .frame(width: heroSize + 44, height: heroSize + 44)
    }

    private var featureCard: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: step.featureIcon)
                .font(.system(size: isCompact ? 18 : 21, weight: .bold))
                .foregroundStyle(step.accent)
                .frame(width: isCompact ? 43 : 50, height: isCompact ? 43 : 50)
                .background(step.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(step.featureTitle)
                    .font(.system(size: isCompact ? 15 : 16, weight: .bold, design: .rounded))
                    .foregroundStyle(SkyFarmOnboardingPalette.ink)
                Text(step.featureText)
                    .font(.system(size: isCompact ? 12 : 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SkyFarmOnboardingPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(isCompact ? 13 : 16)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.98), lineWidth: 1)
        }
        .shadow(color: SkyFarmOnboardingPalette.deepSky.opacity(0.08), radius: 13, y: 6)
    }
}

private struct SkyFarmOnboardingBackground: View {
    let accent: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.66, green: 0.9, blue: 0.97),
                    Color(red: 0.88, green: 0.97, blue: 0.96),
                    Color(red: 1.0, green: 0.97, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.34))
                .frame(width: 290, height: 290)
                .blur(radius: 3)
                .offset(x: -138, y: -260)

            Circle()
                .fill(accent.opacity(0.15))
                .frame(width: 340, height: 340)
                .blur(radius: 12)
                .offset(x: 174, y: 286)

            Circle()
                .fill(.white.opacity(0.28))
                .frame(width: 190, height: 190)
                .blur(radius: 5)
                .offset(x: 170, y: -116)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct SkyFarmOnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [SkyFarmOnboardingPalette.coral, SkyFarmOnboardingPalette.coralDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: SkyFarmOnboardingPalette.coralDeep.opacity(0.34),
                        radius: configuration.isPressed ? 2 : 9,
                        y: configuration.isPressed ? 2 : 5
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct SkyFarmOnboardingStep: Identifiable {
    let id: Int
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    let featureIcon: String
    let featureTitle: String
    let featureText: String
    let accent: Color

    var accessibilityTitle: String {
        "Step \(id + 1), \(title)"
    }

    static let all: [SkyFarmOnboardingStep] = [
        SkyFarmOnboardingStep(
            id: 0,
            eyebrow: "WELCOME TO SKY FARM",
            title: "Clara needs a co-pilot",
            subtitle: "A wild wind scattered her flying farm across the clouds. Help her bring every piece home.",
            icon: "sparkles",
            featureIcon: "map.fill",
            featureTitle: "Short sky adventures",
            featureText: "Choose an island, fly for a few minutes, then use what you find to restore the farm.",
            accent: SkyFarmOnboardingPalette.coral
        ),
        SkyFarmOnboardingStep(
            id: 1,
            eyebrow: "FLY WITH THE WIND",
            title: "Jump, then spread your wings",
            subtitle: "Clara can glide softly through the clouds and catch rising air to reach high places.",
            icon: "wind",
            featureIcon: "arrow.up.circle.fill",
            featureTitle: "Hold to glide",
            featureText: "Use the jump control again in the air to open Clara’s wing-parachute and land safely.",
            accent: SkyFarmOnboardingPalette.deepSky
        ),
        SkyFarmOnboardingStep(
            id: 2,
            eyebrow: "GROW THE WAY HOME",
            title: "Save chicks. Restore the sky.",
            subtitle: "Plant seeds to grow helpful paths, rescue lost chicks, and rebuild each part of the farm.",
            icon: "leaf.fill",
            featureIcon: "house.and.flag.fill",
            featureTitle: "Every flight matters",
            featureText: "Parts, helpers, and Sky Points unlock new farm buildings, routes, and adventures.",
            accent: SkyFarmOnboardingPalette.leaf
        )
    ]
}

private enum SkyFarmOnboardingPalette {
    static let ink = Color(red: 0.10, green: 0.22, blue: 0.34)
    static let mutedInk = Color(red: 0.31, green: 0.45, blue: 0.57)
    static let deepSky = Color(red: 0.14, green: 0.42, blue: 0.62)
    static let leaf = Color(red: 0.25, green: 0.62, blue: 0.36)
    static let coral = Color(red: 0.94, green: 0.41, blue: 0.33)
    static let coralDeep = Color(red: 0.79, green: 0.28, blue: 0.25)
}
