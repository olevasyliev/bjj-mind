import SwiftUI

struct ClubInfoView: View {
    let onContinue: (ClubInfo?) -> Void

    @State private var country: String = ""
    @State private var city: String = ""
    @State private var clubName: String = ""

    private var clubInfo: ClubInfo? {
        guard !country.isEmpty || !city.isEmpty || !clubName.isEmpty else { return nil }
        return ClubInfo(country: country, city: city, clubName: clubName)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                AppProgressBar(progress: 0.7)
                CloseButton(action: {})
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.ClubInfoL10n.title)
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                Text(L10n.ClubInfoL10n.subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                ClubTextField(placeholder: L10n.ClubInfoL10n.countryPlaceholder,
                              text: $country)
                ClubTextField(placeholder: L10n.ClubInfoL10n.cityPlaceholder,
                              text: $city)
                ClubTextField(placeholder: L10n.ClubInfoL10n.clubPlaceholder,
                              text: $clubName)

                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text(L10n.ClubInfoL10n.detectLocation)
                            .font(.labelMd)
                    }
                    .foregroundColor(.brand)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: L10n.ClubInfoL10n.continueCta) {
                    onContinue(clubInfo)
                }
                Button(L10n.ClubInfoL10n.skip) { onContinue(nil) }
                    .font(.bodySm)
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct ClubTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.labelXL)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(Color.cardBg)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
