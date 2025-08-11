//
//  AppDelegate.swift
//  SEN55gpsapp012
//
//  Created by Szamosi Attila on 2025. 01. 10..
//

import UIKit
import CoreData
import UserNotifications
import Supabase


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // Javított Supabase inicializálás
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://yuamroqhxrflusxeyylp.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1YW1yb3FoeHJmbHVzeGV5eWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjA2ODgsImV4cCI6MjA2MTQzNjY4OH0.GOzgzWLxQnT6YzS8z2D4OKrsHkBnS55L7oRTMsEKs8U",
        options: SupabaseClientOptions()
    )
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("AppDelegate: didFinishLaunchingWithOptions called with launchOptions: \(String(describing: launchOptions))")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("AppDelegate: Értesítési engedély megadva.")
            } else if let error = error {
                print("AppDelegate: Értesítési engedély hiba: \(error)")
            } else {
                print("AppDelegate: Értesítési engedély megtagadva.")
            }
        }
        UNUserNotificationCenter.current().delegate = self
        print("AppDelegate: Értesítési delegate beállítva")

        // Alapértelmezett érték beállítása a shouldRecordData-hoz
        if UserDefaults.standard.object(forKey: "shouldRecordData") == nil {
            UserDefaults.standard.set(true, forKey: "shouldRecordData")
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("AppDelegate: applicationDidEnterBackground called")
        backgroundTask = application.beginBackgroundTask(withName: "SaveDataTask") { [weak self] in
            self?.endBackgroundTask(application)
        }

        saveContext()
        NotificationCenter.default.post(name: Notification.Name("appDidEnterBackground"), object: nil)

        DispatchQueue.global(qos: .background).async { [weak self] in
            Thread.sleep(forTimeInterval: 1)
            self?.endBackgroundTask(application)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("AppDelegate: applicationWillEnterForeground called")
        endBackgroundTask(application)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                print("AppDelegate: Értesítési engedély visszavonva.")
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("AppDelegate: applicationWillTerminate called")
        // Jelző beállítása, hogy ne rögzítsen több adatot
        UserDefaults.standard.set(false, forKey: "shouldRecordData")
        saveContext()
    }

    private func endBackgroundTask(_ application: UIApplication) {
        if backgroundTask != .invalid {
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            print("AppDelegate: Háttérfeladat befejezve")
        }
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("AppDelegate: configurationForConnecting called")
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("AppDelegate: didDiscardSceneSessions called")
    }

    lazy var persistentContainer: NSPersistentContainer = {
        print("AppDelegate: persistentContainer inicializálása")
        let container = NSPersistentContainer(name: "SEN55gpsapp012")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("AppDelegate: Core Data betöltési hiba: \(error), \(error.userInfo)")
            } else {
                print("AppDelegate: Core Data sikeresen betöltve")
            }
        })
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("AppDelegate: Core Data kontextus sikeresen mentve.")
            } catch {
                let nserror = error as NSError
                print("AppDelegate: Nem sikerült menteni a Core Data kontextust: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("AppDelegate: Értesítés megjelenítése: \(notification.request.content.body)")
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("AppDelegate: Értesítés megnyitva: \(response.notification.request.content.body)")
        completionHandler()
    }
}
