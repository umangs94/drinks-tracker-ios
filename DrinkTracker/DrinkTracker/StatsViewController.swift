//
//  StatsViewController.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/29/17.
//
//

import UIKit
import NotificationCenter

class StatsViewController: UIViewController{
    @IBOutlet weak var bac1Label: UILabel!
    @IBOutlet weak var bac2Label: UILabel!
    @IBOutlet weak var soberTimeLabel: UILabel!
    @IBOutlet weak var drinkingSinceLabel: UILabel!
    @IBOutlet weak var feeling1Label: UILabel!
    @IBOutlet weak var feeling2Label: UILabel!
    @IBOutlet weak var timesStackView: UIStackView!
    @IBOutlet weak var feelingStackView: UIStackView!
    @IBOutlet weak var feelingTextLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let infoButton = UIButton(type: .detailDisclosure)
        infoButton.tintColor = #colorLiteral(red: 0.9459478259, green: 0.7699176669, blue: 0.05561546981, alpha: 1)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateView()
    }
    
    @objc func updateView(){
        let bac = Drink.CurrentBAC
        bac1Label.text = String(format: "%02d", Int(100*bac))
        bac2Label.text = String(format: "%02d", Int((10000*bac).truncatingRemainder(dividingBy: 100)))
        
        if (bac > 0.075) {
            bac1Label.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            bac1Label.textColor = #colorLiteral(red: 0.9459478259, green: 0.7699176669, blue: 0.05561546981, alpha: 1)
        }
        
        if bac <= 0 {
            timesStackView.isHidden = true
            feelingStackView.isHidden = true
            feelingTextLabel.isHidden = true
        }else{
            timesStackView.isHidden = false
            drinkingSinceLabel.text = Drink.DrinkingSince?.onlyShowTime
            soberTimeLabel.text = Drink.SoberTime?.onlyShowTime
            
            feelingStackView.isHidden = false
            feelingTextLabel.isHidden = false
            switch bac{
            case 0..<0.02:
                feeling1Label.text = Drink.Desc.Two1.rawValue
                feeling2Label.text = Drink.Desc.Two2.rawValue
            case 0.02..<0.06:
                feeling1Label.text = Drink.Desc.Six1.rawValue
                feeling2Label.text = Drink.Desc.Six2.rawValue
            case 0.06..<0.1:
                feeling1Label.text = Drink.Desc.Ten1.rawValue
                feeling2Label.text = Drink.Desc.Ten2.rawValue
            case 0.1...0.2:
                feeling1Label.text = Drink.Desc.Twenty1.rawValue
                feeling2Label.text = Drink.Desc.Twenty2.rawValue
            default:
                feelingStackView.isHidden = true
                feelingTextLabel.isHidden = true
            }
        }
    }
    
    @objc private func showInfo(){
        let alertController = UIAlertController(title: "Drink responsibly!", message: "Drinks Tracker uses the Widmark formula and its variation to calculate the user's Blood Alcohol Content level. However, this value is just an approximation due to the number of outside factors, and hence, should be used as such and not as a determination of the user's ability to drive. Drinks Tracker does not accept any responsibility or liability for the accuracy of the BAC value and any other values shown.\n\nDon't drink and drive.", preferredStyle: .alert)
        
        let agreeAction = UIAlertAction(title: "I understand", style: .default, handler: nil)
        alertController.addAction(agreeAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
