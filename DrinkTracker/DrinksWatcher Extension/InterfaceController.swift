//
//  InterfaceController.swift
//  DrinksWatcher Extension
//
//  Created by Umang Sharaf on 4/15/18.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var bac1Label: WKInterfaceLabel!
    @IBOutlet var bac2Label: WKInterfaceLabel!
    @IBOutlet var bacGroup: WKInterfaceGroup!
    @IBOutlet var soberTimeLabel: WKInterfaceLabel!
    @IBOutlet var soberTimeGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    
    var initialBAC = 0.0
    var metabolism = 0.0
    var initialBACTime = Date()
    var soberTime = ""
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        bacGroup.setHidden(true)
        statusLabel.setHidden(false)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        var bac = initialBAC - metabolism * Date().timeIntervalSince(initialBACTime)/3600.0
        bac = bac > 0 ? bac : 0
        
        bac1Label.setText(String(format: "%02d", Int(100*bac)))
        bac1Label.setTextColor(bac > 0.075 ? #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1) : #colorLiteral(red: 0.9459478259, green: 0.7699176669, blue: 0.05561546981, alpha: 1))
        bac2Label.setText(String(format: "%02d", Int((10000*bac).truncatingRemainder(dividingBy: 100))))
        
        if !soberTime.isEmpty {
            soberTimeGroup.setHidden(false)
            soberTimeLabel.setText(soberTime)
        } else {
            soberTimeGroup.setHidden(true)
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        initialBAC = applicationContext["initialBAC"] as! Double
        metabolism = applicationContext["metabolism"] as! Double
        initialBACTime = applicationContext["initialBACTime"] as! Date
        soberTime = applicationContext["soberTime"] as! String
        
        statusLabel.setHidden(true)
        bacGroup.setHidden(false)
        
        willActivate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activated")
    }

}
