//
//  TodayViewController.swift
//  DrinksWidget
//
//  Created by Umang Sharaf on 5/11/17.
//
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var bac1Label: UILabel!
    @IBOutlet weak var bac2Label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        User.LoadCurrent()
        Drink.runningFromWidget = true
        Drink.Load()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let bac = Drink.CurrentBAC
        let bac1Text = String(format: "%02d", Int(100*bac))
        let bac2Text = String(format: "%02d", Int((10000*bac).truncatingRemainder(dividingBy: 100)))
        if bac1Text != bac1Label.text && bac2Text != bac2Label.text {
            bac1Label.text = bac1Text
            bac1Label.textColor = bac > 0.075 ? #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1) : #colorLiteral(red: 0.9459478259, green: 0.7699176669, blue: 0.05561546981, alpha: 1)
            bac2Label.text = bac2Text
            completionHandler(NCUpdateResult.newData)
        }else{
            completionHandler(NCUpdateResult.noData)
        }
    }
    
    @IBAction func openApp(_ sender: UITapGestureRecognizer) {
        extensionContext?.open(URL(string: "drinkstracker://")!, completionHandler: nil)
    }
}
