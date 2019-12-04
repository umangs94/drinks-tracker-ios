//
//  ChooseDrinkTableViewController.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/29/17.
//
//

import UIKit

class ChooseDrinkTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate{
    
    //MARK: - Properties
    var savedDrinks: Dictionary<String, Array<Drink>> = [:]
    var filteredDrinks = [Drink]()
    
    let sections = ["★","↺","#","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        
        navigationItem.searchController?.searchBar.scopeButtonTitles = ["All", "Shot", "Beer", "Wine", "Mixed"]
        navigationItem.searchController?.searchBar.delegate = self
        navigationItem.searchController?.searchResultsUpdater = self
        navigationItem.searchController?.searchBar.placeholder = "Search or filter"
        navigationItem.searchController?.dimsBackgroundDuringPresentation = false
        navigationItem.searchController?.searchBar.tintColor = #colorLiteral(red: 0.9459478259, green: 0.7699176669, blue: 0.05561546981, alpha: 1)
        navigationItem.searchController?.searchBar.keyboardAppearance = .dark
        navigationItem.hidesSearchBarWhenScrolling = false
        self.definesPresentationContext = true
        
        if let drinks = readDrinks(){
            savedDrinks = drinks
            savedDrinks.updateValue(Drink.Favorites, forKey: "★")
            savedDrinks.updateValue(Drink.Recent.sorted { $0.name < $1.name }, forKey: "↺")
        }else{
            fatalError()
        }
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    //MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (navigationItem.searchController?.isActive)! ? 1 : sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (navigationItem.searchController?.isActive)! ? nil : sections[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return (navigationItem.searchController?.isActive)! ? nil : sections
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return (navigationItem.searchController?.isActive)! ? 0 : sections.index(of: title)!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (navigationItem.searchController?.isActive)! ? filteredDrinks.count : savedDrinks[sections[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseDrinkTableViewCell", for: indexPath) as! ChooseDrinkTableViewCell
        
        let drinks = (navigationItem.searchController?.isActive)! ? filteredDrinks : savedDrinks[sections[indexPath.section]]!
        let drink = drinks[indexPath.row]
        
        cell.nameLabel.text = drink.name
        if let vol = drink.volume{
            cell.volumeLabel.text = vol.inUserUnits.clean + " " + Drink.volumeUnit
        }else{
            cell.volumeLabel.text = ""
        }
        cell.abvLabel.text = drink.abv.clean + "%"
        
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section <= 1
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (indexPath.section == 0){
            if editingStyle == .delete {
                // Delete the row from the data source
                Drink.Favorites.remove(at: indexPath.row)
                savedDrinks.updateValue(Drink.Favorites, forKey: "★")
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        } else if (indexPath.section == 1){
            if editingStyle == .delete {
                // Delete the row from the data source
                let drink = (savedDrinks["↺"]?.remove(at: indexPath.row))!
                Drink.Recent = Drink.Recent.filter { !$0.isTheSameAs(drink: drink) }
                savedDrinks.updateValue(Drink.Recent, forKey: "↺")
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        UISelectionFeedbackGenerator().selectionChanged()
        
        switch segue.identifier ?? ""{
        case "Custom":
            return
        case "Add":
            guard let drinkDetailViewController = segue.destination as? DrinkViewController else{
                fatalError()
            }
            
            guard let selectedDrinkCell = sender as? ChooseDrinkTableViewCell else{
                fatalError()
            }
            
            guard let indexPath = tableView.indexPath(for: selectedDrinkCell) else{
                fatalError()
            }
            
            let drinks = (navigationItem.searchController?.isActive)! ? filteredDrinks : savedDrinks[sections[indexPath.section]]!
            let selectedDrink = drinks[indexPath.row]
            
            selectedDrink.timeDrankAt = Date()
            drinkDetailViewController.drink = selectedDrink
            drinkDetailViewController.addingCustomDrink = false
            drinkDetailViewController.addedToFavorites = indexPath.section == 0
        default:
            fatalError()
        }
    }
    
    //MARK: - Search
    func filterDrinks(for searchText: String, in kind: Drink.Kind? = nil){
        filteredDrinks = [Drink]()
        for letter in savedDrinks.keys {
            let drinks = savedDrinks[letter]!.filter {
                let drinkKind = $0.kind.rawValue.contains("Beer") ? Drink.Kind.Beer : $0.kind
                let kindMatch = (kind == nil || drinkKind == kind)
                
                let drinkName = $0.name.lowercased()
                let nameMatch = searchText.lowercased().components(separatedBy: " ").filter{ !$0.isEmpty }.reduce(true, { match, word in
                    match && drinkName.contains(word)
                })
                
                return kindMatch && nameMatch
            }
            
            filteredDrinks.insert(contentsOf: drinks, at: 0)
            filteredDrinks = filteredDrinks.sorted(by: {$0.name < $1.name})
        }
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let kind = searchController.searchBar.scopeButtonTitles![searchController.searchBar.selectedScopeButtonIndex]
        filterDrinks(for: searchController.searchBar.text ?? "", in: Drink.Kind(rawValue: kind == "Mixed" ? "Mixed Drink" : kind))
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let kind = searchBar.scopeButtonTitles![selectedScope]
        filterDrinks(for: searchBar.text ?? "", in: Drink.Kind(rawValue: kind == "Mixed" ? "Mixed Drink" : kind))
    }
    
    //MARK: - Read file
    private func readDrinks() -> Dictionary<String, Array<Drink>>! {
        guard let filePath = Bundle.main.path(forResource: "drinks", ofType: "csv") else{
            print("File not found")
            return nil
        }
        
        let file: String
        do{
            file = try String(contentsOfFile: filePath, encoding: String.Encoding.macOSRoman)
        } catch {
            print("File read error")
            return nil
        }
        
        var drinks: Dictionary<String, Array<Drink>> = [:]
        
        for drinkString in file.components(separatedBy: "\r\n") {
            let d = drinkString.components(separatedBy: ",")
            if d.count != 4{
                fatalError(drinkString)
            }
            
            let drink = Drink(name: d[0],
                              volume: d[2] == String(0) ? nil : Double(d[2]),
                              abv: Double(d[1])!,
                              timeDrankAt: nil,
                              kind: Drink.Kind(rawValue: d[3]) ?? .Beer)
            
            if var firstLetter = drink.name.first?.description.uppercased() {
                if (firstLetter.rangeOfCharacter(from: CharacterSet.uppercaseLetters) == nil) {
                    firstLetter = "#"
                }
                
                if var drinksWithLetter = drinks[firstLetter] {
                    drinksWithLetter.append(drink)
                    drinks.updateValue(drinksWithLetter, forKey: firstLetter)
                } else {
                    drinks.updateValue([drink], forKey: firstLetter)
                }
            }
            
        }
        
        return drinks
    }
}
