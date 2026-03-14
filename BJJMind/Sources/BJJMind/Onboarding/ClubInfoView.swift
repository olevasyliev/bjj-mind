import SwiftUI
import CoreLocation

// MARK: - Location Detector

@MainActor
final class LocationDetector: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isDetecting = false
    @Published var didFail = false

    var onResult: ((String, String) -> Void)?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func detect() {
        isDetecting = true
        didFail = false
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            isDetecting = false
            didFail = true
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // requestLocation() auto-stops after one update — no need to call stopUpdatingLocation()
        guard let loc = locations.first else { return }
        Task { @MainActor in
            do {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(loc)
                if let pm = placemarks.first {
                    let country = pm.country ?? ""
                    let city = pm.locality ?? pm.administrativeArea ?? ""
                    self.onResult?(country, city)
                }
            } catch {}
            self.isDetecting = false
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Capture status before crossing actor boundary — CLLocationManager is not Sendable
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            } else if status != .notDetermined {
                self.isDetecting = false
                self.didFail = true
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isDetecting = false
            self.didFail = true
        }
    }
}

// MARK: - ClubInfoView

struct ClubInfoView: View {
    let onContinue: (ClubInfo?) -> Void

    @State private var country: String = Self.deviceCountry
    @State private var city: String = ""
    @State private var clubName: String = ""
    @State private var showingCountryPicker = false
    @StateObject private var locationDetector = LocationDetector()

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
            Spacer()

            VStack(spacing: 6) {
                Text(L10n.ClubInfoL10n.title)
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                Text(L10n.ClubInfoL10n.subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
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

                // Detect location
                Button(action: {
                    locationDetector.onResult = { detectedCountry, detectedCity in
                        country = detectedCountry
                        if !detectedCity.isEmpty { city = detectedCity }
                    }
                    locationDetector.detect()
                }) {
                    HStack(spacing: 8) {
                        if locationDetector.isDetecting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.brand)
                        } else {
                            Image(systemName: locationDetector.didFail ? "location.slash.fill" : "location.fill")
                                .font(.system(size: 14))
                        }
                        Text(L10n.ClubInfoL10n.detectLocation)
                            .font(.labelMd)
                    }
                    .foregroundColor(locationDetector.didFail ? .red : .brand)
                }
                .disabled(locationDetector.isDetecting)
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
