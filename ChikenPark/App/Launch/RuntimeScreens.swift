import SwiftUI

struct FeatherwindLoadingView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        FeatherwindRuntimeBackground {
            Group {
                if verticalSizeClass == .compact {
                    HStack(spacing: 28) {
                        logo(size: 132)
                        loadingCopy
                    }
                } else {
                    VStack(spacing: 22) {
                        logo(size: 190)
                        loadingCopy
                    }
                }
            }
            .frame(maxWidth: 620)
            .padding(28)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Featherwind Isles is loading")
    }

    private func logo(size: CGFloat) -> some View {
        Image("logo-icon")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 3)
            }
            .shadow(color: FeatherwindRuntimePalette.skyInk.opacity(0.2), radius: 24, y: 12)
            .accessibilityHidden(true)
    }

    private var loadingCopy: some View {
        VStack(spacing: 10) {
            Text("Featherwind Isles")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(FeatherwindRuntimePalette.ink)
                .multilineTextAlignment(.center)

            Text("Catching the next breeze…")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(FeatherwindRuntimePalette.mutedInk)
                .multilineTextAlignment(.center)

            ProgressView()
                .controlSize(.large)
                .tint(FeatherwindRuntimePalette.coral)
                .padding(.top, 5)
        }
    }
}

struct FeatherwindNoInternetView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let message: String
    let retryAction: () -> Void

    var body: some View {
        FeatherwindRuntimeBackground {
            Group {
                if verticalSizeClass == .compact {
                    HStack(spacing: 24) {
                        statusIllustration(size: 132)
                        content
                    }
                } else {
                    VStack(spacing: 20) {
                        statusIllustration(size: 172)
                        content
                    }
                }
            }
            .padding(verticalSizeClass == .compact ? 20 : 28)
            .frame(maxWidth: verticalSizeClass == .compact ? 700 : 440)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.92), lineWidth: 2)
            }
            .shadow(color: FeatherwindRuntimePalette.skyInk.opacity(0.18), radius: 24, y: 12)
            .padding(24)
        }
    }

    private func statusIllustration(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image("ChickCage")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Image(systemName: "wifi.slash")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(FeatherwindRuntimePalette.coral, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 3))
        }
        .accessibilityHidden(true)
    }

    private var content: some View {
        VStack(spacing: 12) {
            Text(message == "App configuration is unavailable." ? "Setup needed" : "The wind went quiet")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(FeatherwindRuntimePalette.ink)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(FeatherwindRuntimePalette.mutedInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(FeatherwindRuntimePrimaryButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: 360)
    }
}

struct FeatherwindNotificationOptInView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let allowAction: () -> Void
    let skipAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack {
                primerBackground(isLandscape: isLandscape)

                ScrollView(showsIndicators: false) {
                    Group {
                        if isLandscape {
                            landscapeLayout(in: proxy.size)
                        } else {
                            portraitLayout(in: proxy.size)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .safeAreaPadding(.horizontal, isLandscape ? 30 : 24)
                    .safeAreaPadding(.vertical, isLandscape ? 16 : 20)
                }
            }
        }
        .background(FeatherwindRuntimePalette.ink)
    }

    private func primerBackground(isLandscape: Bool) -> some View {
        GeometryReader { proxy in
            Image(isLandscape ? "SkyFarmBackdrop" : "NotificationPrimerBackdrop")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay {
                    if isLandscape {
                        LinearGradient(
                            colors: [
                                FeatherwindRuntimePalette.ink.opacity(0.08),
                                FeatherwindRuntimePalette.ink.opacity(0.22),
                                FeatherwindRuntimePalette.ink.opacity(0.94)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                FeatherwindRuntimePalette.skyInk.opacity(0.08),
                                FeatherwindRuntimePalette.ink.opacity(0.08),
                                FeatherwindRuntimePalette.ink.opacity(0.78),
                                FeatherwindRuntimePalette.ink.opacity(0.97)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func portraitLayout(in size: CGSize) -> some View {
        VStack(spacing: 14) {
            brandLockup(compact: false)

            Spacer(minLength: 4)

            illustration(
                maxWidth: min(size.width * 0.94, 520),
                maxHeight: min(size.height * 0.38, 390)
            )

            Spacer(minLength: 4)

            messageAndActions
                .frame(maxWidth: 480)
        }
        .padding(.vertical, 4)
    }

    private func landscapeLayout(in size: CGSize) -> some View {
        HStack(spacing: min(48, size.width * 0.05)) {
            illustration(
                maxWidth: min(size.width * 0.48, 560),
                maxHeight: min(size.height * 0.86, 420)
            )
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                brandLockup(compact: true)
                messageAndActions
            }
            .frame(maxWidth: 440)
        }
        .padding(.vertical, 4)
    }

    private func illustration(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        Image("ClaraGlide")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .shadow(color: FeatherwindRuntimePalette.ink.opacity(0.35), radius: 22, y: 14)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func brandLockup(compact: Bool) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    brandIcon(compact: compact)
                    brandTitle(compact: compact)
                }
            } else {
                HStack(spacing: compact ? 10 : 12) {
                    brandIcon(compact: compact)
                    brandTitle(compact: compact)
                }
            }
        }
        .padding(.horizontal, compact ? 14 : 16)
        .padding(.vertical, compact ? 8 : 10)
        .background(FeatherwindRuntimePalette.ink.opacity(0.62), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: FeatherwindRuntimePalette.ink.opacity(0.36), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Featherwind Isles")
    }

    private func brandIcon(compact: Bool) -> some View {
        Image("logo-icon")
            .resizable()
            .scaledToFill()
            .frame(width: compact ? 48 : 58, height: compact ? 48 : 58)
            .clipShape(RoundedRectangle(cornerRadius: compact ? 13 : 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 13 : 16, style: .continuous)
                    .stroke(.white.opacity(0.86), lineWidth: 2)
            }
    }

    private func brandTitle(compact: Bool) -> some View {
        Text("Featherwind Isles")
            .font(.system(compact ? .title2 : .title, design: .rounded, weight: .heavy))
            .foregroundStyle(.white)
            .lineLimit(2)
            .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.78)
            .multilineTextAlignment(.center)
    }

    private var messageAndActions: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Text("Never miss your next flight")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)

                Text("Turn on notifications for island updates and a quick path back to Featherwind Isles.")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: allowAction) {
                Label("Turn On Notifications", systemImage: "bell.badge.fill")
            }
            .buttonStyle(FeatherwindRuntimePrimaryButtonStyle())
            .accessibilityHint("Shows the system notification permission request")

            Button(action: skipAction) {
                Text("Not Now")
            }
            .buttonStyle(FeatherwindRuntimeDarkSecondaryButtonStyle())
            .accessibilityHint("Continues without requesting notification permission")
        }
    }
}

private struct FeatherwindRuntimeBackground<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.66, green: 0.9, blue: 0.97),
                    Color(red: 0.88, green: 0.97, blue: 0.96),
                    Color(red: 1, green: 0.97, blue: 0.89)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.38))
                .frame(width: 280, height: 280)
                .blur(radius: 2)
                .offset(x: -150, y: -300)
                .accessibilityHidden(true)

            content()
        }
    }
}

private enum FeatherwindRuntimePalette {
    static let ink = Color(red: 0.1, green: 0.22, blue: 0.34)
    static let mutedInk = Color(red: 0.28, green: 0.43, blue: 0.56)
    static let skyInk = Color(red: 0.14, green: 0.42, blue: 0.62)
    static let coral = Color(red: 0.94, green: 0.41, blue: 0.33)
    static let coralDeep = Color(red: 0.72, green: 0.23, blue: 0.16)
}

private struct FeatherwindRuntimePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.vertical, 2)
            .background(FeatherwindRuntimePalette.coralDeep, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .shadow(color: FeatherwindRuntimePalette.coralDeep.opacity(0.4), radius: 0, y: configuration.isPressed ? 2 : 5)
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct FeatherwindRuntimeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(FeatherwindRuntimePalette.mutedInk)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .padding(.vertical, 2)
            .background(.white.opacity(configuration.isPressed ? 0.92 : 0.62), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(FeatherwindRuntimePalette.skyInk.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct FeatherwindRuntimeDarkSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.72 : 0.9))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .padding(.vertical, 2)
            .background(
                FeatherwindRuntimePalette.ink.opacity(configuration.isPressed ? 0.7 : 0.52),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
    }
}

#Preview("Loading") {
    FeatherwindLoadingView()
}

#Preview("No Internet") {
    FeatherwindNoInternetView(message: "Internet connection is required.", retryAction: {})
}

#Preview("Notification Primer") {
    FeatherwindNotificationOptInView(allowAction: {}, skipAction: {})
}
