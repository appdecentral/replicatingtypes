//
//  SceneDelegate.swift
//  Decent Notes
//
//  Created by Drew McCormack on 03/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let contentView = ContentView()
            .environmentObject(appDelegate.dataStore)
            .accentColor(.purple)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStore.save()
        appDelegate.cloudStore.sync()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.cloudStore.sync()
    }
}

