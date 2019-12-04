//
//  ProfileViewController.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/30/17.
//
//

import UIKit
import UserNotifications
import GoogleMobileAds
import StoreKit
import MessageUI

class ProfileViewController: UITableViewController, UITextFieldDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    //MARK: - Properties
    @IBOutlet var toolbar: UIToolbar!
    var bannerView: GADBannerView!
    
    @IBOutlet weak var genderControl: UISegmentedControl!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var ebacControl: UISegmentedControl!
    @IBOutlet weak var metabolismControl: UISegmentedControl!
    @IBOutlet weak var unitsControl: UISegmentedControl!
    @IBOutlet weak var notifySwitch: UISwitch!
    @IBOutlet weak var weightUnitLabel: UILabel!
    
    private var adsHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weightTextField.inputAccessoryView = toolbar
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        let infoButton = UIButton(type: .detailDisclosure)
        infoButton.addTarget(self, action: #selector(showAboutView), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        //show ads
        adsHidden = UserDefaults.standard.bool(forKey: "adsHidden")
        if (adsHidden) {
            tableView.cellForRow(at: [0, 0])?.isHidden = true
        } else {
            bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
            
            bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //test ads
            
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            
            bannerView.frame = CGRect(x: 0, y: (tableView.bounds.height - bannerView.bounds.height) - (self.tabBarController?.tabBar.frame.height)!, width: self.view.bounds.width, height: bannerView.bounds.height)
            navigationController?.view.addSubview(bannerView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        genderControl.selectedSegmentIndex = User.Current.gender == "M" ? 0 : 1
        weightTextField.text = String(User.Current.weight.clean)
        ebacControl.selectedSegmentIndex = User.Current.useEBAC ? 1 : 0
        metabolismControl.selectedSegmentIndex = User.Current.metabolism == 0.013 ? 0 : User.Current.metabolism == 0.015 ? 1 : 2
        
        if (!User.Current.usesImperialUnits){
            unitsControl.selectedSegmentIndex = 1
            weightUnitLabel.text = "kg"
        }
        
        if User.Current.notificationsAllowed {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {s in
                DispatchQueue.main.async {
                    self.notifySwitch.isOn = s.alertSetting == .enabled
                }
            })
        }
    }
    
    //MARK: - Table rows
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (adsHidden) {
            if indexPath.section == 0 && indexPath.row == 1{
                weightTextField.becomeFirstResponder()
            }
        } else {
            if indexPath.section == 0 && indexPath.row == 0 {
                //remove ads
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Remove ads for $0.99", style: .default, handler: {_ in self.removeAds()}))
                alert.addAction(UIAlertAction(title: "Restore prior purchase", style: .default, handler: {_ in self.restoreRemoveAdsIAP()}))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.preferredAction = alert.actions[0]
                
                present(alert, animated: true)
            } else if indexPath.section == 1 && indexPath.row == 1{
                weightTextField.becomeFirstResponder()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (adsHidden && section == 1) ? 0.01 : super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (adsHidden && section == 0) ? 0.01 : super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return adsHidden ? 0 : 1
        case 1:
            return 4
        default:
            return 1
        }
    }
    
    //MARK: - Text Fields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text != ""{
            saveUser()
            textField.resignFirstResponder()
            return true
        }
        return false
    }
    
    @IBAction func dismissKeyboard(_ sender: UIBarButtonItem) {
        if weightTextField.text != ""{
            saveUser()
            weightTextField.resignFirstResponder()
        }
    }
    
    //MARK: - Segmented Controls
    @IBAction func genderChanged(_ sender: UISegmentedControl) {
        User.Current.gender = sender.selectedSegmentIndex == 0 ? "M" : "F"
        saveUser()
        
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @IBAction func ebacChanged(_ sender: UISegmentedControl) {
        User.Current.useEBAC = sender.selectedSegmentIndex == 1
        saveUser()
        
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @IBAction func metabolismChanged(_ sender: UISegmentedControl) {
        User.Current.metabolism = Double(sender.selectedSegmentIndex) * 0.002 + 0.013
        saveUser()
        
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @IBAction func unitsChanged(_ sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == 0){
            User.Current.usesImperialUnits = true
            weightUnitLabel.text = "lbs"
        } else {
            User.Current.usesImperialUnits = false
            weightUnitLabel.text = "kg"
        }
        
        weightTextField.text = String(User.Current.weight.clean)
        
        saveUser()
        
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @IBAction func notifySwitched(_ sender: UISwitch) {
        if sender.isOn {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: {(granted, error) in
                User.Current.notificationsAllowed = granted
                
                DispatchQueue.main.async {
                    self.saveUser()

                    usleep(250000)
                    self.notifySwitch.setOn(granted, animated: true)
                    
                    if !granted {
                        guard let settingsURL = URL(string: UIApplicationOpenSettingsURLString) else{
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(settingsURL){
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                }
            })
        }else{
            User.Current.notificationsAllowed = false
            saveUser()
        }
    }
    
    //MARK: - Private functions
    
    @IBAction func openAppStoreReview(_ sender: UIBarButtonItem) {
        UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/id1232956137?ls=1&mt=8&action=write-review")!)
    }
    
    private func saveUser(){
        navigationController?.tabBarItem.badgeValue = nil
        if (weightTextField.text != "") {
            User.Current.weight = Double(weightTextField.text!)!
        }
        User.Current.save()
    }
    
    private func removeAds(){
        if (SKPaymentQueue.canMakePayments()){
            let removeAdsIAPId = "com.MangoWorks.DrinkTracker.RemoveAds"
            let productsRequest = SKProductsRequest(productIdentifiers: [removeAdsIAPId])
            productsRequest.delegate = self
            productsRequest.start()
        } else {
            print("Device can't make payments")
            let alert = UIAlertController(title: "Your device does not support making payments.", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func buyProduct(_ product: SKProduct){
        print("Requesting IAP purchase")
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(SKPayment(product: product))
    }
    
    private func restoreRemoveAdsIAP(){
        if (SKPaymentQueue.canMakePayments()){
            print("Requesting IAP restore")
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().restoreCompletedTransactions()
        } else {
            let alert = UIAlertController(title: "Your device does not support making payments.", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: - SKProductRequest delegate method
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if (response.products.count == 1){
            print("Received IAP: " + response.products[0].localizedTitle)
            buyProduct(response.products[0])
        }
    }
    
    //MARK: - SKPaymentTransactionObserver delegate methods
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("Purchase completed!")
                
                UserDefaults.standard.set(true, forKey: "adsHidden")
                print("Ads hidden")
                
                let alert = UIAlertController(title: "Ads will be removed upon restarting Drinks Tracker", message: "Thanks for supporting the developer!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Awesome!", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .failed:
                print("Purchase failed: " + ((transaction.error != nil) ? (transaction.error?.localizedDescription)! : "no details"))
                
                let alert = UIAlertController(title: "Purchase failed", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .restored:
                print("Restore completed!")
                
                UserDefaults.standard.set(true, forKey: "adsHidden")
                print("Ads hidden")
                
                let alert = UIAlertController(title: "Ads have been removed from Drinks Tracker", message: "Thanks for supporting the developer!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Awesome!", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            default:
                break
            }
        }
        
        func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error){
            print("Restore failed: " + error.localizedDescription)
            
            let alert = UIAlertController(title: "Restoring purchase failed", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func showAboutView(){
        performSegue(withIdentifier: "About", sender: nil)
    }
}

class ProfileAboutViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    //MARK: - Table rows
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && indexPath.row == 0 {
            if !MFMailComposeViewController.canSendMail() { return }
            
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            
            composeVC.setToRecipients(["umangs94+app@gmail.com"])
            composeVC.setSubject("Feedback!")
            composeVC.setMessageBody("", isHTML: false)
            
            self.present(composeVC, animated: true, completion: nil)
        } else if indexPath.section == 0 && indexPath.row == 1 {
            UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/id1232956137?ls=1&mt=8&action=write-review")!)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
