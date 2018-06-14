//
//  AppDelegate.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import CoreData
import SwiftyBeaver

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Public Properties
    var window: UIWindow?

    // MARK: - Public Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // SwiftyBeaver configuration
        let console = ConsoleDestination()
        console.format = "$DHH:mm:ss$d $N.$F - $C$L$c: $M"
        console.minLevel = .verbose
        log.addDestination(console)
        
        let file = FileDestination()
        let _ = file.deleteLogFile()
        file.format = "$DHH:mm:ss$d $L:\n$M\n"
        log.addDestination(file)
        
        // non-storyboard UI configuration
        window = UIWindow(frame: UIScreen.main.bounds)
        
        do {
            // dependency injection
            let container = try DependencyContainer()
        
            // set root view controller
            let accountsViewController = container.makeAccountsViewController()
            let rootViewController = UINavigationController(rootViewController: accountsViewController)
            
            if #available(iOS 11.0, *) {
                rootViewController.navigationBar.prefersLargeTitles = true
            }
            
            show(rootViewController)
        } catch {
            log.error("Failed to initialize dependency container: \(error)")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension AppDelegate {
    func show(_ viewController: UIViewController) {
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
}
