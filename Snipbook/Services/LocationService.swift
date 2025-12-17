import Foundation
import CoreLocation

/// Manages location services for capturing snip locations
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var currentPlaceName: String?
    @Published var isAuthorized = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        checkAuthorization()
    }

    func checkAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            isAuthorized = false
        }
    }

    func requestLocation() {
        guard isAuthorized else {
            checkAuthorization()
            return
        }
        locationManager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first else { return }

            DispatchQueue.main.async {
                // Build a nice place name
                var parts: [String] = []

                if let name = placemark.name {
                    parts.append(name)
                }
                if let locality = placemark.locality {
                    if !parts.contains(locality) {
                        parts.append(locality)
                    }
                }
                if let area = placemark.administrativeArea {
                    if !parts.contains(area) {
                        parts.append(area)
                    }
                }

                self?.currentPlaceName = parts.prefix(2).joined(separator: ", ")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = location
            self.reverseGeocode(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            locationManager.startUpdatingLocation()
        default:
            isAuthorized = false
        }
    }
}
