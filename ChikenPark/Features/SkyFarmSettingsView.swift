import SwiftUI

struct SkyFarmSettingsView: View {
    @ObservedObject var progress: SkyFarmProgress

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                progressCard
                legalSection
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .accessibilityIdentifier("sky-farm-settings")
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.98, blue: 0.97),
                Color(red: 1, green: 0.97, blue: 0.89)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.2))
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sky Farm")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Your adventure at a glance")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            HStack(spacing: 10) {
                SkyFarmSettingsStat(
                    value: "\(progress.skyPoints)",
                    label: "Sky Points",
                    icon: "sparkles"
                )
                SkyFarmSettingsStat(
                    value: "\(progress.completedLevels)",
                    label: "Islands",
                    icon: "flag.checkered"
                )
                SkyFarmSettingsStat(
                    value: "\(progress.unlockedAchievementCount)",
                    label: "Achievements",
                    icon: "rosette"
                )
            }
        }
        .padding(19)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [SkyFarmSettingsPalette.deepSky, SkyFarmSettingsPalette.blueberry],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 27, style: .continuous)
        )
        .shadow(color: SkyFarmSettingsPalette.deepSky.opacity(0.22), radius: 15, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Sky Farm. \(progress.skyPoints) Sky Points, \(progress.completedLevels) islands, \(progress.unlockedAchievementCount) achievements."
        )
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SkyFarmSettingsSectionTitle(
                title: "Legal",
                subtitle: "Policies for using Sky Farm"
            )

            VStack(spacing: 1) {
                SkyFarmLegalLinkRow(
                    title: "Privacy Policy",
                    subtitle: "How your information is handled",
                    icon: "hand.raised.fill",
                    tint: SkyFarmSettingsPalette.leaf,
                    destination: SkyFarmAppLinks.privacyPolicy
                )

                Divider()
                    .padding(.leading, 68)

                SkyFarmLegalLinkRow(
                    title: "Terms of Use",
                    subtitle: "Rules for using Sky Farm",
                    icon: "doc.text.fill",
                    tint: SkyFarmSettingsPalette.coral,
                    destination: SkyFarmAppLinks.termsOfUse
                )
            }
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(.white.opacity(0.95), lineWidth: 1)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SkyFarmSettingsSectionTitle(
                title: "About",
                subtitle: "App information"
            )

            HStack(spacing: 13) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(SkyFarmSettingsPalette.deepSky)
                    .frame(width: 40, height: 40)
                    .background(SkyFarmSettingsPalette.deepSky.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Version")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SkyFarmSettingsPalette.ink)
                    Text(versionText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SkyFarmSettingsPalette.mutedInk)
                }

                Spacer()
            }
            .padding(15)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(.white.opacity(0.95), lineWidth: 1)
            }
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct SkyFarmSettingsStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.82))
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SkyFarmSettingsSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(SkyFarmSettingsPalette.ink)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SkyFarmSettingsPalette.mutedInk)
        }
    }
}

private struct SkyFarmLegalLinkRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SkyFarmSettingsPalette.ink)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SkyFarmSettingsPalette.mutedInk)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkyFarmSettingsPalette.mutedInk)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens in your browser")
    }
}

private enum SkyFarmSettingsPalette {
    static let deepSky = Color(red: 0.15, green: 0.46, blue: 0.62)
    static let blueberry = Color(red: 0.27, green: 0.32, blue: 0.67)
    static let leaf = Color(red: 0.2, green: 0.6, blue: 0.37)
    static let coral = Color(red: 0.91, green: 0.39, blue: 0.31)
    static let ink = Color(red: 0.12, green: 0.22, blue: 0.37)
    static let mutedInk = Color(red: 0.32, green: 0.45, blue: 0.57)
}
