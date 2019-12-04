//
//  User.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/29/17.
//
//

import UIKit
import WatchConnectivity

class User {
    //MARK: - Properties -
    var name = "newUser"
    var gender = "M"
    var weight = 121.0
    var useEBAC = true
    var metabolism = 0.015
    var usesImperialUnits = true {
        didSet {
            if oldValue != usesImperialUnits {
                weight *= (usesImperialUnits ? 2.20462 : 0.453592)
            }
        }
    }
    var notificationsAllowed = false

    var weightInGrams: Double {
        return weight * (usesImperialUnits ? Constants.LbsToGrams : 1000)
    }
    
    var weightInLbs: Double {
        return weight * (usesImperialUnits ? 1 : 2.20462)
    }
    
    var usesAppleWatch = false
    
    static var Current: User!
    
    //MARK: - Loading and saving -
    static func LoadCurrent(){
        Current = User()
        
        if let userName = UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.string(forKey: "CurrentUserName")  {
            if let user = UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.array(forKey: "User" + userName)  {
                Current.name = userName
                Current.gender = user[0] as! String
                Current.weight = user[1] as! Double
                Current.useEBAC = user[2] as! Bool
                Current.metabolism = user[3] as! Double
                Current.usesImperialUnits = user[4] as! Bool
                Current.notificationsAllowed = user[5] as! Bool
            }
        } else if let user = UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.array(forKey: "User.Current")  {
            // TODO: - MIGRATION, Remove eventually -
            Current.gender = user[0] as! String
            Current.weight = user[1] as! Double
            Current.useEBAC = user[2] as! Bool
            Current.metabolism = user[3] as! Double
            
            let b = user.count > 4 ? user[4] as! Bool : true
            if !b { Current.weight *= 2.20462 }
            
            Current.usesImperialUnits = b
            
            Current.name = "User"
            Current.notificationsAllowed = UserDefaults.standard.bool(forKey: "notificationsTurnedOn")
            
            Current.save()
            UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.set(Current.name, forKey: "CurrentUserName")
            
            UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.removeObject(forKey: "User.Current")
            UserDefaults.standard.removeObject(forKey: "firstTimeAlertsShown")
            UserDefaults.standard.removeObject(forKey: "notificationsTurnedOn")
            
            print("Migrated user details successfully")
        }
    }
    
    func save(){
        let bac = Drink.CurrentBAC
        Drink.createBACNotifications(for: bac)
        updateAppleWatch(for: bac)
        
        UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.set([gender, weightInLbs, useEBAC, metabolism, usesImperialUnits, notificationsAllowed], forKey: "User" + name)
        
        print("User '\(name)' saved: \([gender, weightInLbs, useEBAC, metabolism, usesImperialUnits, notificationsAllowed])")
    }
    
    func updateAppleWatch(for bac: Double){
        if User.Current.usesAppleWatch {
            do {
                try WCSession.default.updateApplicationContext(["initialBAC": bac, "metabolism": metabolism, "initialBACTime": Date(), "soberTime": Drink.SoberTime?.onlyShowTime ?? ""])
                print("Sent data to Apple Watch")
            } catch {
                print("Error when sending data using WCSession: " + error.localizedDescription)
            }
        }
    }
    
    //MARK: - Types -
    struct Constants{
        static let BodyWaterInBloodXGrams = 0.9672 //0.806*1.2
        static let R: [String: Double] = ["M": 0.68,"F": 0.55]
        static let BodyWater: [String: Double] = ["M": 0.58,"F": 0.49]
        static let LbsToGrams = 454.0
    }
}
