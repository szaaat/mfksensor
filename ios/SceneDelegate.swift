//
//  SceneDelegate.swift
//  SEN55gpsapp012
//
//  Created by Szamosi Attila on 2025. 01. 10..
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("SceneDelegate: willConnectTo called with connectionOptions: \(connectionOptions)")
        guard let windowScene = (scene as? UIWindowScene) else {
            print("SceneDelegate: Nem sikerült a UIWindowScene inicializálása")
            return
        }

        let window = UIWindow(windowScene: windowScene)
        print("SceneDelegate: UIWindow inicializálva")

        let viewController = ViewController()
        window.rootViewController = viewController
        print("SceneDelegate: ViewController beállítva rootViewController-ként")

        window.makeKeyAndVisible()
        print("SceneDelegate: UIWindow láthatóvá téve")

        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("SceneDelegate: sceneDidDisconnect called")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("SceneDelegate: sceneDidBecomeActive called")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("SceneDelegate: sceneWillResignActive called")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("SceneDelegate: sceneWillEnterForeground called")
        if window?.rootViewController is ViewController {
            print("SceneDelegate: ViewController megtalálva az előtérbe lépéskor")
            // Ellenőrizzük, hogy rögzítsen-e adatokat
            if UserDefaults.standard.bool(forKey: "shouldRecordData") {
                print("SceneDelegate: Adatrögzítés engedélyezve")
            } else {
                print("SceneDelegate: Adatrögzítés leállítva")
            }
        }
    }
}
