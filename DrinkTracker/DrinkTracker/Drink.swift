//
//  Drink.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/25/17.
//
//

import UIKit
import UserNotifications

class Drink: NSObject {
    //MARK: - Properties -
    var name: String
    var volume: Double?
    static var volumeUnit: String {
        return User.Current.usesImperialUnits ? "fl. oz" : "ml"
    }
    var abv: Double
    var timeDrankAt: Date?
    var kind: Kind
    
    static var runningFromWidget = false
    
    static var DrinkingSince: Date?
    static var SoberTime: Date?
    
    static var CurrentList: [Drink]! {
        didSet{
            if !runningFromWidget{
                CurrentList.sort { $0.timeDrankAt! < $1.timeDrankAt! }
                
                DrinkingSince = CurrentList.first?.timeDrankAt
                
                let bac = CurrentBAC
                createBACNotifications(for: bac)
                
                User.Current.updateAppleWatch(for: bac)
                
                if let latestDrink = CurrentList.last {
                    createPostDrinkNotifications(at: latestDrink.timeDrankAt!.addingTimeInterval(latestDrink.kind == .Shot ? 600 : 1200), drinkName: latestDrink.name)
                } else {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["soberTime0" + User.Current.name, "soberTime0.08" + User.Current.name, "postDrink" + User.Current.name])
                }
                
                SaveList("CurrentList", from: CurrentList)
            }
        }
    }
    
    static var Favorites: [Drink]! {
        didSet{
            Favorites.sort { $0.name < $1.name }
            SaveList("Favorites", from: Favorites)
        }
    }
    
    static var Recent: [Drink]! {
        didSet{
            if Recent.count > 5 { Recent.removeFirst() }
            SaveList("Recent", from: Recent)
        }
    }
    
    //MARK: - Loading and saving -
    init(name: String, volume: Double?, abv: Double, timeDrankAt: Date?, kind: Kind){
        self.name = name
        self.volume = volume
        self.abv = abv
        self.timeDrankAt = timeDrankAt
        self.kind = kind
    }
    
    static func Load(){
        LoadList("CurrentList", in: &CurrentList)
        if !runningFromWidget { LoadList("Favorites", in: &Favorites) }
        if !runningFromWidget { LoadList("Recent", in: &Recent) }
    }
    
    static func LoadList(_ name: String, in list: inout [Drink]!){
        if let drinks = UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.array(forKey: name + User.Current.name) as? [[Any]] {
            list = drinks.map({(drink: [Any]) -> Drink in
                return Drink(name: drink[0] as! String,
                             volume: drink[1] as? Double,
                             abv: drink[2] as! Double,
                             timeDrankAt: drink[3] as? Date,
                             kind: Kind(rawValue: drink[4] as! String) ?? .Beer)
            })
            
            print("Loaded \(list.count) drink(s) from " + name + " for " + User.Current.name)
        }else if let drinks = UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.array(forKey: name) as? [[Any]] {
            // TODO: - MIGRATION, Remove eventually -
            list = drinks.map({(drink: [Any]) -> Drink in
                return Drink(name: drink[0] as! String,
                             volume: drink[1] as? Double,
                             abv: drink[2] as! Double,
                             timeDrankAt: drink[3] as? Date,
                             kind: Kind(rawValue: drink[4] as! String) ?? .Beer)
            })
            
            SaveList(name, from: list)
            UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.removeObject(forKey: name)
            
            print("Migrated \(name) successfully")
        }else{
            list = [Drink]()
        }
    }
    
    static func SaveList(_ name: String, from list: [Drink]){
        UserDefaults(suiteName: "group.com.MangoWorks.DrinkTracker.shared")?.set(
            list.map({(drink: Drink) -> [Any] in
                return [drink.name, drink.volume!, drink.abv, drink.timeDrankAt ?? "", drink.kind.rawValue]
            }),
            forKey: name + User.Current.name)
        
        print("Saved \(list.count) drink(s) to " + name + " for " + User.Current.name)
    }
    
    //MARK: - BAC methods -
    func isTheSameAs(drink: Drink) -> Bool {
        return name == drink.name && abs(volume! - drink.volume!) < 0.1 && abs(abv - drink.abv) < 0.1 && kind == drink.kind
    }
    
    private var alcGrams: Double{
        return volume! * abv * 29.5735 * 0.789
    }
    
    private var startBAC: Double{
        //1 fl. oz = 29.5735 mL
        //1 mL = 0.789 grams
        //Dividing by 100 to convert ABV percent to a decimal value is not necessary as the next calculation has to be multiplied by 100
        return alcGrams/(User.Constants.R[User.Current.gender]!*User.Current.weightInGrams)
    }
    
    private var startEBAC: Double{
        //1 fl. oz = 29.5735 mL
        //1 mL = 0.789 grams
        return (alcGrams*User.Constants.BodyWaterInBloodXGrams/1000)/(User.Constants.BodyWater[User.Current.gender]!*User.Current.weightInGrams/1000)
    }
    
    private func cumeBAC(previousBAC: Double, at time: Date) -> Double {
        let bac = previousBAC + (User.Current.useEBAC ? startEBAC : startBAC) - User.Current.metabolism * time.timeIntervalSince(timeDrankAt!)/3600.0
        return bac > 0 ? bac : 0
    }
    
    static var CurrentBAC: Double {
        return CurrentList != nil ? CalculateBAC(for: CurrentList, soberTime: &SoberTime) : 0.0
    }
    
    static func CalculateBAC(for drinks: [Drink], soberTime: inout Date?) -> Double {
        var bac = 0.0
        
        if drinks.isEmpty {
            soberTime = nil
            return bac
        }
        
        for (i, drink) in drinks.enumerated(){
            if drinks.last == drink {
                bac = drink.cumeBAC(previousBAC: bac, at: Date())
                soberTime = Drink.time(with: bac)
                return bac
            }
            
            bac = drink.cumeBAC(previousBAC: bac, at: drinks[i+1].timeDrankAt!)
        }
        
        fatalError()
    }
    
    static func time(with bac: Double, to target: Double = 0.0) -> Date? {
        return bac > 0 ? Date().addingTimeInterval(60.0+3600.0*(bac-target)/User.Current.metabolism) : nil
    }
    
    //MARK - Notifications -
    static func createBACNotifications(for bac: Double){
        if User.Current.notificationsAllowed {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {s in
                if s.alertSetting == .enabled{
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["soberTime0" + User.Current.name, "soberTime0.08" + User.Current.name])
                    
                    bac > 0 ? notify(at: Drink.SoberTime!, title: "Your BAC is at 0%", body: "You started drinking at \(Drink.DrinkingSince?.clean ?? "")", identifier: "soberTime0") : ()
                    bac > 0.08 ? notify(at: Drink.time(with: bac, to: 0.08)!, title: "Your BAC is at 0.08%", body: "At \(Drink.SoberTime?.onlyShowTime ?? ""), your BAC will be at 0%", identifier: "soberTime0.08") : ()
                    
                    UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                        for request in requests {
                            print("Pending notification \(request.identifier): " + (request.trigger?.description)!)
                        }
                    })
                }
            })
        }
    }
    
    static func createPostDrinkNotifications(at time: Date, drinkName: String){
        if User.Current.notificationsAllowed {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {s in
                if s.alertSetting == .enabled{
                    notify(at: time, title: "Done with your \(drinkName)?", body: "Be sure to add your next drink!", identifier: "postDrink")
                    
                    UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                        for request in requests {
                            print("Pending notification \(request.identifier): " + (request.trigger?.description)!)
                        }
                    })
                }
            })
        }
    }
    
    static private func notify(at time: Date, title: String, body: String, identifier: String){
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = identifier
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute, .day, .month], from: time), repeats: false)
        let request = UNNotificationRequest(identifier: identifier + User.Current.name, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        print("Notification scheduled for \(User.Current.name) at " + time.description + ": " + identifier)
    }
    
    //MARK: - Types -
    enum Kind: String {
        case Wine = "Wine"
        case Beer = "Beer"
        case BeerCan = "Beer Can"
        case BeerBottle = "Beer Bottle"
        case BeerWheat = "Beer Wheat"
        case BeerGlass = "Beer Glass"
        case BeerMug = "Beer Mug"
        case Shot = "Shot"
        case MixedDrink = "Mixed Drink"
    }
    
    enum Desc: String{
        case Two1 = "not much"
        case Two2 = "of a difference"
        case Six1 = "relaxed"
        case Six2 = "talkative"
        case Ten1 = "euphoric"
        case Ten2 = "extraverted"
        case Twenty1 = "boisterous"
        case Twenty2 = "over-expressive"
    }
    
    struct Constants{
        static let FlOzToML = 29.5735
        static let MLToFlOz = 0.033814
    }
}

//MARK: - Extensions -
extension Double{
    var inUserUnits: Double {
        return self * (User.Current.usesImperialUnits ? 1 : Drink.Constants.FlOzToML)
    }
    
    var clean: String{
        let remainder = self.truncatingRemainder(dividingBy: 1)
        return String(format: (remainder < 0.05 || remainder >= 0.95) ? "%.0f" : "%.1f", self)
    }
}

extension Date{
    var clean: String{
        let cal = Calendar.current
        return self.onlyShowTime + (cal.isDateInToday(self) ? "" : (cal.isDateInYesterday(self) ? " (yesterday)" : " (" + self.onlyShowDate + ")"))
    }
    
    var onlyShowTime: String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        
        return dateFormatter.string(from: self)
    }
    
    var onlyShowDate: String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        return dateFormatter.string(from: self)
    }
}
