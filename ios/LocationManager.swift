import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var latestLocation: CLLocation?
    private var isGPSActiveState: Bool = false
    
    // Closure-ök a ViewController értesítésére
    var onLocationUpdated: ((CLLocation) -> Void)? // Új helyadatok érkezésekor hívódik
    var onError: ((Error) -> Void)? // Hiba esetén hívódik
    var onGPSStateChanged: ((Bool) -> Void)? // GPS állapotváltozás esetén hívódik
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 méterenként frissít
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false // Az iOS ne szüneteltesse a helyfrissítéseket
        locationManager.activityType = .other // Általános mozgásérzékelés, érzékenyebb
        
        // Jogosultságok kérése
        locationManager.requestAlwaysAuthorization()
        
        // GPS indítása azonnal
        startUpdatingLocation()
    }
    
    func startUpdatingLocation() {
        print("LocationManager: Helyfrissítések indítása")
        locationManager.startUpdatingLocation()
        isGPSActiveState = true
        onGPSStateChanged?(true) // Értesítjük a ViewController-t a GPS állapotváltozásról
    }
    
    func stopUpdatingLocation() {
        print("LocationManager: Helyfrissítések leállítása")
        locationManager.stopUpdatingLocation()
        isGPSActiveState = false
        onGPSStateChanged?(false) // Értesítjük a ViewController-t a GPS állapotváltozásról
    }
    
    func isGPSActive() -> Bool {
        return isGPSActiveState
    }
    
    func getLastKnownLocation() -> CLLocation? {
        return latestLocation
    }
    
    // CLLocationManagerDelegate metódusok
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latestLocation = location
        print("LocationManager: Új hely: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        isGPSActiveState = true
        onLocationUpdated?(location) // Értesítjük a ViewController-t az új helyadatokról
        onGPSStateChanged?(true) // Értesítjük a ViewController-t a GPS állapotváltozásról
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Hiba a helymeghatározás során: \(error)")
        isGPSActiveState = false
        onError?(error) // Értesítjük a ViewController-t a hibáról
        onGPSStateChanged?(false) // Értesítjük a ViewController-t a GPS állapotváltozásról
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: Helyfrissítések szüneteltetve (iOS által)")
        isGPSActiveState = false
        onGPSStateChanged?(false) // Értesítjük a ViewController-t a GPS állapotváltozásról
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: Helyfrissítések újraindítva (iOS által)")
        isGPSActiveState = true
        onGPSStateChanged?(true) // Értesítjük a ViewController-t a GPS állapotváltozásról
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("LocationManager: Helymeghatározás engedélyezve")
            startUpdatingLocation()
        case .denied, .restricted:
            print("LocationManager: Helymeghatározás megtagadva")
            isGPSActiveState = false
            onGPSStateChanged?(false) // Értesítjük a ViewController-t a GPS állapotváltozásról
        default:
            print("LocationManager: Helymeghatározás állapota: \(status.rawValue)")
        }
    }
}
