//
//  DrinkTableViewController.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/26/17.
//
//

import UIKit
import UserNotifications
import GoogleMobileAds
import MessageUI
import WatchConnectivity

class DrinkTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, GADBannerViewDelegate  {
    
    //MARK: - Properties
    @IBOutlet weak var navItem: UINavigationItem!
    
    var bannerView: GADBannerView!
    let tips = ["Can't find a drink in the list?\nCreate a custom drink and suggest it!",
                "Remove ads in the app for $0.99 from the Profile tab.",
                "Repeat an added drink by swiping in \nfrom the left.",
                "Favorite an added drink by swiping in \nfrom the left.\nUn-favorite a drink in the list by swiping in \nfrom the right.",
                "3D Touch an added drink to quickly see its details such as its impact.",
                "3D Touch the app icon to quickly add a drink \nand to see your BAC in the widget.",
                "Add the Drinks Tracker widget to monitor \nyour BAC from the Lock screen.",
                "Love using Drinks Tracker?\nBe sure to rate and review it from the \ntop right of the Profile tab.,",
                "Submit feedback to the developer from the \ntop left of the Profile tab."]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 100))
        
        if User.Current.name == "newUser" {
            showFirstTimeAlerts()
        }
        
        //show ads
        if (!UserDefaults.standard.bool(forKey: "adsHidden")) {
            bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
            
            bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //test ads
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            
            bannerView.frame = CGRect(x: 0, y: (tableView.bounds.height - bannerView.bounds.height) - (self.tabBarController?.tabBar.frame.height)!, width: self.view.bounds.width, height: bannerView.bounds.height)
            navigationController?.view.addSubview(bannerView)
        }
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        bannerView?.isHidden = false
        updateTableBackground()
        navigationController?.tabBarItem.badgeValue = Drink.CurrentList.count > 0 ? String(Drink.CurrentList.count) : nil
        
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Drink.CurrentList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "DrinkTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? DrinkTableViewCell else{
            fatalError()
        }
        
        let drink = Drink.CurrentList[indexPath.row]
        cell.nameLabel.text = drink.name
        cell.volumeLabel.text = drink.volume!.inUserUnits.clean + " " + Drink.volumeUnit
        cell.abvLabel.text = drink.abv.clean + "%"
        cell.timeLabel.text = drink.timeDrankAt!.clean
        
        switch drink.kind {
        case .Beer, .BeerBottle:
            cell.photoImageView.image = #imageLiteral(resourceName: "beerBottleSelected")
        case .BeerCan:
            cell.photoImageView.image = #imageLiteral(resourceName: "beerCanSelected")
        case .BeerWheat:
            cell.photoImageView.image = #imageLiteral(resourceName: "beerWheatSelected")
        case .BeerGlass:
            cell.photoImageView.image = #imageLiteral(resourceName: "beerGlassSelected")
        case .BeerMug:
            cell.photoImageView.image = #imageLiteral(resourceName: "beerMugSelected")
        case .Wine:
            cell.photoImageView.image = #imageLiteral(resourceName: "wineGlassSelected")
        case .Shot:
            cell.photoImageView.image = #imageLiteral(resourceName: "shotSelected")
        case .MixedDrink:
            cell.photoImageView.image = #imageLiteral(resourceName: "mixedDrinkSelected")
        }
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            Drink.CurrentList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateTableBackground()
        }
        
        navigationController?.tabBarItem.badgeValue = Drink.CurrentList.count > 0 ? String(Drink.CurrentList.count) : nil
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let repeatAction = UIContextualAction(style: .normal, title: "Repeat", handler: {_,_,completionHandler in
            let drink = Drink.CurrentList[indexPath.row]
            let repeatedDrink = Drink(name: drink.name, volume: drink.volume, abv: drink.abv, timeDrankAt: Date(), kind: drink.kind)
            
            Drink.CurrentList.append(repeatedDrink)
            
            tableView.insertRows(at: [IndexPath(row: Drink.CurrentList.count - 1, section: 0)], with: UITableViewRowAnimation.automatic)
            completionHandler(true)
        })
        repeatAction.backgroundColor = #colorLiteral(red: 0.9459478259, green: 0.7699176669, blue: 0.05561546981, alpha: 1)
        
        let favoriteDrink = UIContextualAction(style: .normal, title: "★", handler: {_,_,completionHandler in
            let drink = Drink.CurrentList[indexPath.row]
            if Drink.Favorites.filter({ $0.isTheSameAs(drink: drink) }).count == 0 {
                Drink.Favorites.append(drink)
                completionHandler(true)
            }
            
            completionHandler(false)
        })
        favoriteDrink.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [repeatAction, favoriteDrink])
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        bannerView?.isHidden = true
        
        UISelectionFeedbackGenerator().selectionChanged()
        
        switch(segue.identifier ?? ""){
        case "Add":
            print("Searching for drink")
        case "Custom":
            print("Adding custom drink")
        case "ShowDetail":
            guard let drinkDetailViewController = segue.destination as? DrinkViewController else{
                fatalError()
            }
            
            guard let selectedDrinkCell = sender as? DrinkTableViewCell else{
                fatalError()
            }
            
            guard let indexPath = tableView.indexPath(for: selectedDrinkCell) else {
                fatalError()
            }
            
            print("Showing drink details")
            drinkDetailViewController.drink = Drink.CurrentList[indexPath.row]
            drinkDetailViewController.indexPath = indexPath
            drinkDetailViewController.addingCustomDrink = false
        default:
            fatalError()
        }
    }
    
    //MARK: - Actions
    @IBAction func unwindToDrinkList(sender: UIStoryboardSegue){
        if let sourceViewController = sender.source as? DrinkViewController, let drink = sourceViewController.drink{
            if let selectedIndexPath = sourceViewController.indexPath{
                Drink.CurrentList[selectedIndexPath.row] = drink
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }else{
                let newIndexPath = IndexPath(row: Drink.CurrentList.count, section: 0)
                Drink.CurrentList.append(drink)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
                if Drink.Recent.filter({ $0.isTheSameAs(drink: drink) }).count == 0 {
                    Drink.Recent.append(drink)
                }
            }
            tableView.reloadData()
            
            if sourceViewController.addingCustomDrink {
                let alert = UIAlertController(title: "Suggest this drink to be added to the list?", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Sure!", style: .default, handler: {_ in self.suggestDrink(drink)}))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    //MARK: - Private methods
    func suggestDrink(_ drink: Drink) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["umangs94+app@gmail.com"])
        composeVC.setSubject("Drink suggestion!")
        var body = drink.name + "\n" + String(drink.abv) + "%\n" + String(drink.volume!) + " fl. oz"
        body += "\n" + drink.kind.rawValue
        composeVC.setMessageBody(body, isHTML: false)
        
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func updateTableBackground(){
        if Drink.CurrentList.count == 0 {
            let messageLabel = UILabel()
            messageLabel.text = "Search for drinks by tapping the search icon. \nAdd a custom drink by tapping the + icon!"
            messageLabel.textColor = #colorLiteral(red: 0.6642242074, green: 0.6642400622, blue: 0.6642315388, alpha: 1)
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.boldSystemFont(ofSize: 17)
            messageLabel.numberOfLines = 0
            messageLabel.sizeToFit()
            
            let tipsLabel = UILabel()
            tipsLabel.text = tips[Int(arc4random_uniform(UInt32(tips.count)))]
            tipsLabel.textColor = #colorLiteral(red: 0.9459478259, green: 0.7699176669, blue: 0.05561546981, alpha: 1)
            tipsLabel.textAlignment = .center
            tipsLabel.numberOfLines = 0
            tipsLabel.sizeToFit()
            
            let stack = UIStackView()
            stack.axis = .vertical
            stack.distribution = .fillEqually
            stack.addArrangedSubview(UIView())
            stack.addArrangedSubview(UIView())
            stack.addArrangedSubview(UIView())
            stack.addArrangedSubview(UIView())
            stack.addArrangedSubview(messageLabel)
            stack.addArrangedSubview(tipsLabel)
            stack.addArrangedSubview(UIView())
            stack.addArrangedSubview(UIView())
            stack.addArrangedSubview(UIView())
            stack.addArrangedSubview(UIView())
            
            tableView.backgroundView = stack
            tableView.separatorStyle = .none
            navigationItem.leftBarButtonItem = nil
        }else{
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            navigationItem.leftBarButtonItem = editButtonItem
        }
    }
    
    private func showFirstTimeAlerts(){
        let alertController = UIAlertController(title: "Drink responsibly!", message: "Drinks Tracker uses the Widmark formula and its variation to calculate the user's Blood Alcohol Content level. However, this value is just an approximation due to the number of outside factors, and hence, should be used as such and not as a determination of the user's ability to drive. Drinks Tracker does not accept any responsibility or liability for the accuracy of the BAC value and any other values shown.\n\nDon't drink and drive.", preferredStyle: .alert)
        
        let agreeAction = UIAlertAction(title: "I understand", style: .default, handler: {(action: UIAlertAction) in
            self.showNotificationsAlert()
        })
        alertController.addAction(agreeAction)
        
        present(alertController, animated: true, completion: {
            (self.tabBarController?.viewControllers?[2] as! UINavigationController).tabBarItem.badgeValue = "!"
            User.Current.name = "User"
        })
    }
    
    private func showNotificationsAlert(){
        let alertController = UIAlertController(title: "Enable notifications?", message: "You will get notifications when your BAC is at 0.08% and 0%. You will also get a notification after you add a drink to remind you to add your next drink.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Not now", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        let agreeAction = UIAlertAction(title: "Yep", style: .default, handler: {(action: UIAlertAction) in
            self.askAboutNotifications()
        })
        alertController.addAction(agreeAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func askAboutNotifications(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: {(granted, error) in
            User.Current.notificationsAllowed = granted
        })
    }
}
