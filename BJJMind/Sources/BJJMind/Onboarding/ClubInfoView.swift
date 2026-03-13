import SwiftUI

struct ClubInfoView: View {
    let onContinue: (ClubInfo?) -> Void

    @State private var country: String = Self.deviceCountry
    @State private var city: String = ""
    @State private var clubName: String = ""
    @State private var showingCountryPicker = false

    private static var deviceCountry: String {
        guard let code = Locale.current.region?.identifier else { return "" }
        return Locale.current.localizedString(forRegionCode: code) ?? ""
    }

    private var clubInfo: ClubInfo? {
        guard !country.isEmpty || !city.isEmpty || !clubName.isEmpty else { return nil }
        return ClubInfo(country: country, city: city, clubName: clubName)
    }

    var body: some View {
        VStack(spacing: 0) {
            AppProgressBar(progress: 0.7)
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
                // Country — Picker
                Button(action: { showingCountryPicker = true }) {
                    HStack {
                        Text(country.isEmpty ? L10n.ClubInfoL10n.countryPlaceholder : country)
                            .font(.labelXL)
                            .foregroundColor(country.isEmpty ? Color(hex: "#9ca3af") : .textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(Color.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                ClubTextField(placeholder: L10n.ClubInfoL10n.cityPlaceholder, text: $city)
                ClubTextField(placeholder: L10n.ClubInfoL10n.clubPlaceholder, text: $clubName)

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
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerSheet(selected: $country)
        }
    }
}

// MARK: - Country Picker Sheet

private struct CountryPickerSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var countries: [String] {
        let names = Locale.Region.isoRegions.compactMap {
            Locale.current.localizedString(forRegionCode: $0.identifier)
        }.sorted()
        guard !search.isEmpty else { return names }
        return names.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(countries, id: \.self) { country in
                Button(action: {
                    selected = country
                    dismiss()
                }) {
                    HStack {
                        Text(country).foregroundColor(.textPrimary)
                        Spacer()
                        if country == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.brand)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $search)
            .navigationTitle(L10n.ClubInfoL10n.countryPlaceholder)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Text Field

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
