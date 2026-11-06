import CoreLocation

/// One current location fix using existing permission; Biz decides when and where it is uploaded.
final class DeviceLocation: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?
    private static var active: Set<DeviceLocation> = []

    @MainActor
    static func current() async -> [String: Any]? {
        let status = CLLocationManager().authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return nil }
        let request = DeviceLocation()
        active.insert(request)
        defer { active.remove(request) }
        guard let location = await request.fetch() else { return nil }
        return ["longitude": location.coordinate.longitude, "latitude": location.coordinate.latitude]
    }

    @MainActor
    private func fetch() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { self.complete(nil) }
        }
    }

    private func complete(_ location: CLLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        complete(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        complete(nil)
    }
}
