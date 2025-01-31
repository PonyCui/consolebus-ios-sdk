//
//  AppDelegate.swift
//  ios-sdk-sample
//
//  Created by PonyCui on 2025/1/30.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var timer: Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if UserDefaults.standard.string(forKey: "fooKey") == nil {
            UserDefaults.standard.set("console-bus-test", forKey: "fooKey")
        }
        if UserDefaults.standard.dictionary(forKey: "barDict") == nil {
            UserDefaults.standard.set(["a": "b", "c": "d"], forKey: "barDict")
        }
        // 启动定时器，每5秒更新一次 timerKey
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            let randomValue = Int.random(in: 1...1000)
            UserDefaults.standard.set(randomValue, forKey: "timerKey")
        }
        return true
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

