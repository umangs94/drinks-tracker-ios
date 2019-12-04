//
//  AppDelegate.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/25/17.
//
//

import UIKit
import StoreKit
import GoogleMobileAds
import UserNotifications
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        User.LoadCurrent()
        Drink.Load()
        
        let runCount = UserDefaults.standard.integer(forKey: "runCount")
        if (runCount > 0 && (runCount % 10 == 0)) {
            SKStoreReviewController.requestReview()
        }
        
        UserDefaults.standard.set(runCount + 1, forKey: "runCount")
        
        GADMobileAds.configure(withApplicationID: "ca-app-pub-3940256099942544/2934735716")
        
        let bacCategory0 = UNNotificationCategory(identifier: "soberTime0", actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "BAC Alert", options: [])
        let bacCategory8 = UNNotificationCategory(identifier: "soberTime0.08", actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "BAC Alert", options: [])
        let postDrinkCategory = UNNotificationCategory(identifier: "postDrink", actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "Drink Alert", options: [])
        UNUserNotificationCenter.current().setNotificationCategories([bacCategory0, bacCategory8, postDrinkCategory])
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        
        return true
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if session.isPaired && session.isWatchAppInstalled {
            User.Current.usesAppleWatch = true
            if WCSession.default.applicationContext.isEmpty {
                User.Current.updateAppleWatch(for: Drink.CurrentBAC)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession became deactivated.")
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
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(shouldPerformActionFor(shortcutItem: shortcutItem))
    }
    
    private func shouldPerformActionFor(shortcutItem: UIApplicationShortcutItem) -> Bool{
        guard let tabBar = self.window?.rootViewController as? UITabBarController else{
            return false
        }
        
        tabBar.selectedIndex = 0
        guard let tvc = (tabBar.selectedViewController as? UINavigationController)?.viewControllers.first as? DrinkTableViewController else{
            return false
        }
        
        switch shortcutItem.type{
        case "AddCustomDrink":
            tvc.performSegue(withIdentifier: "Custom", sender: nil)
        case "SearchDrink":
            tvc.performSegue(withIdentifier: "Add", sender: nil)
        default:
            return false
        }
        
        return true
    }
    
}

