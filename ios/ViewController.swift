import UIKit
import CoreLocation
import UserNotifications
import Supabase
import WebKit
import Network
import BackgroundTasks

// MARK: - Adatmodell Supabase-hez
struct AirQualityData: Codable {
    let timestamp: String
    let location: String
    let pm1_0: Double
    let pm2_5: Double
    let pm4_0: Double
    let pm10_0: Double
    let humidity: Double
    let temperature: Double
    let voc: Double
    let nox: Double
    let co2: Double
    
    var uniqueIdentifier: String {
        return "\(timestamp)_\(location)"
    }
}

class ViewController: UIViewController {
    // MARK: - Komponensek
    private let bleManager = BLEManager()
    private let locationManager = LocationManager()
    
    private var latestLocation: CLLocation?
    private var latestBLEData: String?
    private var savedAirQualityData: [AirQualityData] = []
    private var autoSaveTimer: Timer?
    private var syncInterval: TimeInterval = 2.0
    private var lastSyncAttempt: Date?
    
    // MARK: - Supabase kliens
    private var supabase: SupabaseClient? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("AppDelegate nem található, Supabase kliens inicializálása sikertelen")
            return nil
        }
        return appDelegate.supabase
    }
    
    // MARK: - UI elemek
    private let dataLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = .systemGray6
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.font = .preferredFont(forTextStyle: .title2)
        label.text = "Várakozás adatokra..."
        return label
    }()
    
    private let gpsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .systemGray6
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.font = .preferredFont(forTextStyle: .title2)
        label.numberOfLines = 0
        label.text = "GPS adatok nem érhetők el."
        label.textColor = .systemCyan
        return label
    }()
    
    private let mfkLogoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "mfk_logo")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let emnlLogoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "emnl_logo")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Menü", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        button.showsMenuAsPrimaryAction = true
        button.menu = createMenu()
        return button
    }()
    
    private lazy var timerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Szinkronizáció: Autó (2 mp)", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemFill
        button.layer.cornerRadius = 10
        button.showsMenuAsPrimaryAction = true
        button.menu = createTimerMenu()
        return button
    }()
    
    private lazy var mapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Térkép", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(showMapTapped), for: .touchUpInside)
        return button
    }()
    
    private let syncStatusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .systemGreen
        label.text = "Szinkronizálva"
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Életciklus
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        startServices()
        loadDataFromFile()
        startAutoSaveTimer()
        scheduleBackgroundSync()
        NetworkMonitor.shared.startMonitoring { [weak self] isConnected in
            if isConnected, !(self?.savedAirQualityData.isEmpty ?? true) {
                self?.saveToSupabaseButtonTapped()
            }
        }
    }
    
    deinit {
        bleManager.stopScanning()
        locationManager.stopUpdatingLocation()
        NotificationCenter.default.removeObserver(self)
        autoSaveTimer?.invalidate()
        NetworkMonitor.shared.stopMonitoring()
    }
}

// MARK: - UI Setup
extension ViewController {
    private func setupUI() {
        view.backgroundColor = .lightGray
        
        // Add subviews
        [mfkLogoImageView, dataLabel, gpsLabel, menuButton, timerButton, mapButton, emnlLogoImageView, syncStatusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // MFK Logo
            mfkLogoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mfkLogoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mfkLogoImageView.widthAnchor.constraint(equalToConstant: 200),
            mfkLogoImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Data Label
            dataLabel.topAnchor.constraint(equalTo: mfkLogoImageView.bottomAnchor, constant: 20),
            dataLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dataLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dataLabel.heightAnchor.constraint(equalToConstant: 200),
            
            // GPS Label
            gpsLabel.topAnchor.constraint(equalTo: dataLabel.bottomAnchor, constant: 20),
            gpsLabel.leadingAnchor.constraint(equalTo: dataLabel.leadingAnchor),
            gpsLabel.trailingAnchor.constraint(equalTo: dataLabel.trailingAnchor),
            gpsLabel.heightAnchor.constraint(equalToConstant: 150),
            
            // Menu Button
            menuButton.topAnchor.constraint(equalTo: gpsLabel.bottomAnchor, constant: 20),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            menuButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            menuButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Timer Button
            timerButton.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 20),
            timerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timerButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Map Button
            mapButton.topAnchor.constraint(equalTo: timerButton.bottomAnchor, constant: 20),
            mapButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mapButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mapButton.heightAnchor.constraint(equalToConstant: 50),
            
            // EMNL Logo
            emnlLogoImageView.topAnchor.constraint(equalTo: mapButton.bottomAnchor, constant: 20),
            emnlLogoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emnlLogoImageView.widthAnchor.constraint(equalToConstant: 200),
            emnlLogoImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Sync Status Label
            syncStatusLabel.topAnchor.constraint(equalTo: emnlLogoImageView.bottomAnchor, constant: 10),
            syncStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            syncStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createMenu() -> UIMenu {
        return UIMenu(title: "Műveletek", children: [
            UIAction(title: "Adatok Mentése", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                self?.saveDataButtonTapped()
            },
            UIAction(title: "Mentés Supabase-be", image: UIImage(systemName: "cloud.upload")) { [weak self] _ in
                self?.saveToSupabaseButtonTapped()
            },
            UIAction(title: "Megosztás", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.shareDataButtonTapped()
            },
            UIAction(title: "Törlés", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.confirmDeleteData()
            }
        ])
    }
    
    private func createTimerMenu() -> UIMenu {
        return UIMenu(title: "Szinkronizációs időköz", children: [
            UIAction(title: "Autó (2 mp)", state: syncInterval == 2.0 ? .on : .off) { [weak self] _ in
                self?.setSyncInterval(2.0)
            },
            UIAction(title: "Kerékpár (10 mp)", state: syncInterval == 10.0 ? .on : .off) { [weak self] _ in
                self?.setSyncInterval(10.0)
            },
            UIAction(title: "Séta (60 mp)", state: syncInterval == 60.0 ? .on : .off) { [weak self] _ in
                self?.setSyncInterval(60.0)
            }
        ])
    }
    
    private func setSyncInterval(_ interval: TimeInterval) {
        syncInterval = interval
        let title: String
        switch interval {
        case 2.0: title = "Szinkronizáció: Autó (2 mp)"
        case 10.0: title = "Szinkronizáció: Kerékpár (10 mp)"
        case 60.0: title = "Szinkronizáció: Séta (60 mp)"
        default: title = "Szinkronizáció: \(Int(syncInterval)) mp"
        }
        timerButton.setTitle(title, for: .normal)
        restartAutoSaveTimer()
    }
    
    @objc private func showMapTapped() {
        let mapViewController = UIViewController()
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        mapViewController.view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: mapViewController.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: mapViewController.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: mapViewController.view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: mapViewController.view.bottomAnchor)
        ])
        
        if let url = URL(string: "https://szaaat.github.io/mfksensor/map.html") {
            webView.load(URLRequest(url: url))
        } else {
            print("Érvénytelen térkép URL")
        }
        
        mapViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Bezár",
            style: .done,
            target: self,
            action: #selector(dismissMapView)
        )
        
        let navController = UINavigationController(rootViewController: mapViewController)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func dismissMapView() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Adatkezelés
extension ViewController {
    private func startAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if let data = self.latestBLEData, let location = self.latestLocation {
                self.saveData(with: data, location: location)
            }
            
            if NetworkMonitor.shared.isConnected && !self.savedAirQualityData.isEmpty {
                self.uploadDataToSupabase(self.savedAirQualityData)
            }
        }
    }
    
    private func restartAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        startAutoSaveTimer()
    }
    
    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.airQualitySync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 perc
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Háttér szinkronizáció ütemezve")
        } catch {
            print("Háttér szinkronizáció ütemezési hiba: \(error)")
        }
    }
    
    private func handleBackgroundSync(task: BGTask) {
        scheduleBackgroundSync() // Újraütemezés a következő futtatáshoz
        
        guard NetworkMonitor.shared.isConnected, !savedAirQualityData.isEmpty else {
            task.setTaskCompleted(success: false)
            return
        }
        
        uploadDataToSupabase(savedAirQualityData) {
            task.setTaskCompleted(success: true)
        }
    }
    
    private func extractBLEValues(from data: String) -> [String] {
        return data.components(separatedBy: ", ")
            .compactMap { $0.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespaces) }
    }
    
    private func saveData(with data: String, location: CLLocation) {
        let cleanedValues = extractBLEValues(from: data)
        guard cleanedValues.count >= 8 else {
            print("Érvénytelen BLE adatok: \(data)")
            return
        }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        // Ellenőrizzük, hogy van-e már rekord ugyanazzal a timestamp-pel
        if savedAirQualityData.contains(where: { $0.timestamp == timestamp }) {
            print("Már létezik rekord ezzel a timestamp-pel: \(timestamp), kihagyás")
            return
        }
        
        let airData = AirQualityData(
            timestamp: timestamp,
            location: "POINT(\(location.coordinate.longitude) \(location.coordinate.latitude))",
            pm1_0: parseDouble(cleanedValues[0]),
            pm2_5: parseDouble(cleanedValues[1]),
            pm4_0: parseDouble(cleanedValues[2]),
            pm10_0: parseDouble(cleanedValues[3]),
            humidity: parseDouble(cleanedValues[4]),
            temperature: parseDouble(cleanedValues[5]),
            voc: parseDouble(cleanedValues[6]),
            nox: parseDouble(cleanedValues[7]),
            co2: cleanedValues.count > 8 ? parseDouble(cleanedValues[8]) : 0
        )
        
        guard let supabase = supabase else {
            print("Supabase kliens nem elérhető, adatok helyben mentve")
            savedAirQualityData.append(airData)
            saveDataToFile()
            updateSyncStatus("Offline - \(savedAirQualityData.count) adat vár")
            updateUI()
            return
        }
        
        if NetworkMonitor.shared.isConnected {
            uploadDataToSupabase([airData])
        } else {
            savedAirQualityData.append(airData)
            saveDataToFile()
            updateSyncStatus("Offline - \(savedAirQualityData.count) adat vár")
            updateUI()
        }
    }
    
    private func parseDouble(_ value: String) -> Double {
        guard let doubleValue = Double(value), !doubleValue.isNaN, !doubleValue.isInfinite else {
            print("Érvénytelen Double érték: \(value), 0-val helyettesítve")
            return 0
        }
        return doubleValue
    }
    
    private func uploadDataToSupabase(_ data: [AirQualityData], completion: (() -> Void)? = nil) {
        guard let supabase = supabase, !data.isEmpty else {
            print("Supabase kliens nem elérhető vagy üres adatlista")
            updateSyncStatus("Hiba - \(savedAirQualityData.count) adat vár")
            completion?()
            return
        }
        
        Task {
            var attempts = 0
            let maxAttempts = 3
            let batchSize = 10
            
            while attempts < maxAttempts {
                do {
                    let uniqueData = removeDuplicateRecords(data)
                    if uniqueData.isEmpty {
                        updateSyncStatus("Szinkronizálva \(Date().formatted())")
                        completion?()
                        return
                    }
                    
                    // Feldaraboljuk az adatokat batch-ekre
                    let batches = uniqueData.chunked(into: batchSize)
                    for batch in batches {
                        do {
                            try await supabase.from("air_quality")
                                .insert(batch)
                                .execute()
                            
                            // Töröljük a feltöltött adatokat
                            savedAirQualityData.removeAll { saved in
                                batch.contains { $0.timestamp == saved.timestamp }
                            }
                        } catch let error as PostgrestError where error.code == "23505" {
                            // Egyedi index megsértése (unique_violation)
                            print("Duplikált rekord észlelve, kihagyás: \(error)")
                            // Töröljük a duplikált rekordokat a helyi tárolóból
                            savedAirQualityData.removeAll { saved in
                                batch.contains { $0.timestamp == saved.timestamp }
                            }
                            continue // Folytatjuk a következő batch-csel
                        }
                    }
                    
                    saveDataToFile()
                    lastSyncAttempt = Date()
                    updateSyncStatus("Szinkronizálva \(Date().formatted())")
                    print("Szinkronizáció sikeres, \(uniqueData.count) adat feltöltve")
                    updateUI()
                    completion?()
                    return
                } catch {
                    attempts += 1
                    print("Szinkronizációs hiba (próbálkozás \(attempts)/\(maxAttempts)): \(error)")
                    if attempts < maxAttempts {
                        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 másodperc várakozás
                    }
                }
            }
            
            // Ha minden próbálkozás sikertelen, mentsük helyben
            savedAirQualityData.append(contentsOf: data)
            saveDataToFile()
            updateSyncStatus("Hiba - \(savedAirQualityData.count) adat vár")
            print("Szinkronizáció sikertelen, adatok helyben mentve")
            updateUI()
            completion?()
        }
    }
    
    private func removeDuplicateRecords(_ data: [AirQualityData]) -> [AirQualityData] {
        var uniqueData = [AirQualityData]()
        var timestamps = Set<String>()
        
        for item in data {
            if !timestamps.contains(item.timestamp) {
                timestamps.insert(item.timestamp)
                uniqueData.append(item)
            }
        }
        
        return uniqueData
    }
    
    @objc private func saveDataButtonTapped() {
        guard let data = latestBLEData, let location = latestLocation else {
            return
        }
        saveData(with: data, location: location)
    }
    
    @objc private func saveToSupabaseButtonTapped() {
        guard !savedAirQualityData.isEmpty else {
            return
        }
        uploadDataToSupabase(savedAirQualityData)
    }
    
    @objc private func shareDataButtonTapped() {
        guard !savedAirQualityData.isEmpty else {
            return
        }
        shareData()
    }
    
    private func confirmDeleteData() {
        let alert = UIAlertController(
            title: "Adatok törlése",
            message: "Biztosan törölni szeretnéd az összes lokálisan tárolt adatot?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Mégse", style: .cancel))
        alert.addAction(UIAlertAction(title: "Törlés", style: .destructive) { [weak self] _ in
            self?.deleteLocalData()
        })
        present(alert, animated: true)
    }
    
    private func shareData() {
        let dataString = savedAirQualityData.map { data in
            """
            Timestamp: \(data.timestamp)
            Location: \(data.location)
            PM1.0: \(data.pm1_0)
            PM2.5: \(data.pm2_5)
            PM4.0: \(data.pm4_0)
            PM10.0: \(data.pm10_0)
            Humidity: \(data.humidity)
            Temperature: \(data.temperature)
            VOC: \(data.voc)
            NOX: \(data.nox)
            CO2: \(data.co2)
            """
        }.joined(separator: "\n\n")
        
        let activityVC = UIActivityViewController(activityItems: [dataString], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    private func deleteLocalData() {
        savedAirQualityData.removeAll()
        saveDataToFile()
        updateSyncStatus("Szinkronizálva")
        updateUI()
    }
    
    private func saveDataToFile() {
        do {
            let data = try JSONEncoder().encode(savedAirQualityData)
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("air_quality_data.json")
            try data.write(to: url)
        } catch {
            print("Fájlmentési hiba: \(error)")
        }
    }
    
    private func loadDataFromFile() {
        do {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("air_quality_data.json")
            let data = try Data(contentsOf: url)
            savedAirQualityData = try JSONDecoder().decode([AirQualityData].self, from: data)
            updateSyncStatus(savedAirQualityData.isEmpty ? "Szinkronizálva" : "Offline - \(savedAirQualityData.count) adat vár")
            updateUI()
        } catch {
            print("Fájlbetöltési hiba: \(error)")
        }
    }
    
    private func updateSyncStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.syncStatusLabel.text = status
            self?.syncStatusLabel.textColor = status.contains("Hiba") || status.contains("Offline") ? .systemRed : .systemGreen
        }
    }
}

// MARK: - Segédmetódusok
extension ViewController {
    private func startServices() {
        bleManager.startScanning()
        locationManager.startUpdatingLocation()
        setupBindings()
    }
    
    private func setupBindings() {
        bleManager.onDataReceived = { [weak self] data in
            self?.latestBLEData = data
            self?.updateUI()
        }
        
        bleManager.onDisconnected = { [weak self] in
            self?.latestBLEData = nil
            self?.updateUI()
        }
        
        locationManager.onLocationUpdated = { [weak self] location in
            self?.latestLocation = location
            self?.updateUI()
        }
    }
    
    private func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let bleData = self.latestBLEData {
                let dataText = "\(bleData)\n\nMentett mérések: \(self.savedAirQualityData.count)"
                self.dataLabel.attributedText = NSAttributedString(
                    string: dataText,
                    attributes: self.textAttributes(for: bleData)
                )
            } else {
                self.dataLabel.text = "Várakozás adatokra...\nMentett mérések: \(self.savedAirQualityData.count)"
            }
            
            if let location = self.latestLocation {
                self.gpsLabel.text = String(format: "GPS:\n%.6f\n%.6f",
                                          location.coordinate.latitude,
                                          location.coordinate.longitude)
            }
        }
    }
    
    private func textAttributes(for data: String) -> [NSAttributedString.Key: Any] {
        if data.lowercased().contains("error") {
            return [.foregroundColor: UIColor.systemRed]
        }
        return [.foregroundColor: UIColor.systemGreen]
    }
}

// MARK: - Háttérkezelés
extension ViewController {
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Háttérfeladat regisztrálása
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.airQualitySync", using: nil) { [weak self] task in
            self?.handleBackgroundSync(task: task)
        }
    }
    
    @objc private func appDidEnterBackground() {
        scheduleBackgroundSync()
    }
}

// MARK: - Network Monitor
class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var statusChangeHandler: ((Bool) -> Void)?
    
    var isConnected: Bool = false {
        didSet {
            statusChangeHandler?(isConnected)
        }
    }
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    func startMonitoring(handler: @escaping (Bool) -> Void) {
        statusChangeHandler = handler
    }
    
    func stopMonitoring() {
        statusChangeHandler = nil
    }
}

// MARK: - Array segédmetódus
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
