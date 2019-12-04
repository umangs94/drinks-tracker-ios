//
//  DrinkViewController.swift
//  DrinkTracker
//
//  Created by Umang Sharaf on 4/25/17.
//
//

import UIKit
import MessageUI

class DrinkViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate {
    //MARK: - Properties
    @IBOutlet var volumeToolbar: UIToolbar!
    @IBOutlet var abvToolbar: UIToolbar!
    
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var suggestButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var wineGlass: UIImageView!
    @IBOutlet weak var beer: UIImageView!
    @IBOutlet weak var shot: UIImageView!
    @IBOutlet weak var mixedDrink: UIImageView!
    
    @IBOutlet weak var selectDrinkLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var abvTextField: UITextField!
    @IBOutlet weak var abvTextFieldConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var volumeTextField: UITextField!
    @IBOutlet weak var volumeUnitButton: UIButton!
    @IBOutlet weak var volumeUnitButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var volumeButton1: UIBarButtonItem!
    @IBOutlet weak var volumeButton2: UIBarButtonItem!
    @IBOutlet weak var volumeButton3: UIBarButtonItem!
    @IBOutlet weak var volumeButton4: UIBarButtonItem!
    
    @IBOutlet weak var beerCan: UIButton!
    @IBOutlet weak var beerBottle: UIButton!
    @IBOutlet weak var beerWheat: UIButton!
    @IBOutlet weak var beerGlass: UIButton!
    @IBOutlet weak var beerMug: UIButton!
    
    @IBOutlet weak var impactLabel: UILabel!
    @IBOutlet weak var impactBACLabel: UILabel!
    @IBOutlet weak var projectedBACLabel: UILabel!
    @IBOutlet weak var impactTimeLabel: UILabel!
    @IBOutlet weak var projectedSoberTimeLabel: UILabel!
    @IBOutlet weak var timeTextLabel: UILabel!
    
    var drink: Drink?
    var drinkType = ""
    var datePickerVisible = false
    var beerPickerVisible = false
    var impactVisible = false
    var indexPath: IndexPath?
    var addedToFavorites = false
    
    //adding drink from the list and NOT viewing an already-added drink
    var addingCustomDrink = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        volumeTextField.delegate = self
        
        volumeTextField.inputAccessoryView = volumeToolbar
        abvTextField.inputAccessoryView = abvToolbar
        
        datePicker.setValue(UIColor.white, forKey: "textColor")
        
        if let drink = drink{
            navigationItem.title = drink.name
            nameTextField.text = drink.name
            dateLabel.text = drink.timeDrankAt?.clean
            if let vol = drink.volume{
                volumeTextField.text = vol.inUserUnits.clean
            }
            datePicker.date = drink.timeDrankAt ?? Date()
            abvTextField.text = drink.abv.clean
            
            if drink.kind.rawValue.contains("Beer"){
                beer.isHighlighted = true
                beerPickerVisible = true
            }
            
            drinkType = drink.kind.rawValue
            
            switch drink.kind{
            case .Beer:
                break
            case .BeerCan:
                beerCan.isSelected = true
            case .BeerBottle:
                beerBottle.isSelected = true
            case .BeerWheat:
                beerWheat.isSelected = true
            case .BeerGlass:
                beerGlass.isSelected = true
            case .BeerMug:
                beerMug.isSelected = true
            case .Wine:
                wineGlass.isHighlighted = true
            case .Shot:
                shot.isHighlighted = true
            case .MixedDrink:
                mixedDrink.isHighlighted = true
            }
            
            selectDrinkLabel.isHidden = true
        }else{
            dateLabel.text = datePicker.date.clean
            
            navItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel(_:))), animated: true)
            
            selectDrinkLabel.isHidden = false
        }
        
        datePicker.minimumDate = Date().addingTimeInterval(-24*3600)
        datePicker.maximumDate = Date()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        volumeUnitButton.setTitle(Drink.volumeUnit, for: .normal)
        volumeUnitButtonConstraint.constant = User.Current.usesImperialUnits ? 8 : -12
        updateVolumeButtons(for: Drink.volumeUnit)
        
        //indexPath will be nil when viewing an added drink, so overall (NOT projectected) impact is shown
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: indexPath == nil)
    }
    
    //MARK: - Text Fields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func dismissKeyboard(_ sender: UIBarButtonItem) {
        volumeTextField.resignFirstResponder()
        abvTextField.resignFirstResponder()
    }
    
    @IBAction func nameTextFieldEdited(_ textField: UITextField) {
        navigationItem.title = textField.text
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: true)
    }
    
    @IBAction func volumeTextFieldEdited(_ sender: UITextField) {
        unselectAllBeerImages()
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: true)
    }
    
    @IBAction func abvTextFieldEdited(_ sender: UITextField) {
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: true)
    }
    
    @IBAction func clearAllFields(_ sender: UIButton) {
        navigationItem.title = "Add Drink"
        nameTextField.text = ""
        datePicker.date = Date()
        volumeTextField.text = ""
        abvTextField.text = ""
        unhighlightAllImages()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    @IBAction func suggestDrink(_ sender: UIBarButtonItem) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["umangs94+app@gmail.com"])
        composeVC.setSubject("Drink suggestion!")
        var body = nameTextField.text! + "\n" + abvTextField.text! + "%\n" + volumeTextField.text! + " " + volumeUnitButton.currentTitle!
        body += "\n" + drinkType
        composeVC.setMessageBody(body, isHTML: false)
        
        addingCustomDrink = false
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Table rows
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row{
        case 0:
            return 140
        case 2:
            return impactVisible ? ((impactTimeLabel.text == "–") ? 105 : 155) : 0
        case 3:
            return datePickerVisible ? 260 : UITableViewAutomaticDimension
        case 4:
            return beerPickerVisible ? 115 : 44
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row{
        case 1:
            nameTextField.becomeFirstResponder()
        case 3:
            self.tableView.beginUpdates()
            datePickerVisible = !datePickerVisible
            self.tableView.endUpdates()
            self.view.endEditing(true)
        case 4:
            volumeTextField.becomeFirstResponder()
        case 5:
            abvTextField.becomeFirstResponder()
        default:
            return
        }
    }
    
    //MARK: - DatePicker
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        dateLabel.text = sender.date.clean
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: true)
    }
    
    //MARK: - Volume and ABV buttons
    @IBAction func setVolumeFromToolbar(_ sender: UIBarButtonItem) {
        setVolumeTo(sender.tag)
    }
    
    @IBAction func setVolumeFromBeerKinds(_ sender: UIButton) {
        setVolumeTo(sender.tag)
        sender.isSelected = true
    }
    
    private func setVolumeTo(_ tag: Int){
        unselectAllBeerImages()
        
        volumeTextField.text = {
            switch tag {
            case 1: return "1.5"
            case 17: return "16.9"
            case 19: return "19.2"
            default: return String(tag)
            }
        }()
        
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: true)
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @IBAction func setabv(_ sender: UIBarButtonItem) {
        abvTextField.text = String(sender.tag)
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: true)
        
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @IBAction func volumeUnitButtonTouched(_ sender: UIButton) {
        tableView.beginUpdates()
        let newUnit = (sender.currentTitle == "fl. oz" ? "ml" : "fl. oz")
        sender.setTitle(newUnit, for: .normal)
        updateVolumeButtons(for: newUnit)
        
        if let volumeInString = volumeTextField.text, let volume = Double(volumeInString) {
            let convertedVolume = newUnit == "fl. oz" ? (volume * Drink.Constants.MLToFlOz) : (volume * Drink.Constants.FlOzToML).rounded()
            volumeTextField.text = convertedVolume.clean
        }
        
        volumeUnitButtonConstraint.constant = newUnit == "fl. oz" ? 8 : -12
        tableView.endUpdates()
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    private func updateVolumeButtons(for unit: String){
        let imperial = unit == "fl. oz"
        
        if imperial {
            volumeButton1.title = "1.5"
            volumeButton1.tag = 1
            
            updateVolumeButton(volumeButton2, volume: 5)
            updateVolumeButton(volumeButton3, volume: 8)
            updateVolumeButton(volumeButton4, volume: 12)
            
            beerCan.tag = 12
            beerWheat.tag = 17
            beerGlass.tag = User.Current.usesImperialUnits ? 16 : 19
        } else {
            updateVolumeButton(volumeButton1, volume: 25)
            updateVolumeButton(volumeButton2, volume: 60)
            updateVolumeButton(volumeButton3, volume: 330)
            updateVolumeButton(volumeButton4, volume: User.Current.usesImperialUnits ? 473 : 568)
            
            beerCan.tag = 355
            beerWheat.tag = 500
            beerGlass.tag = User.Current.usesImperialUnits ? 473 : 568
        }
        
        beerBottle.tag = beerCan.tag
        beerMug.tag = beerGlass.tag
    }
    
    private func updateVolumeButton(_ button: UIBarButtonItem, volume: Int){
        button.title = String(volume)
        button.tag = volume
    }
    
    //MARK: - Photos/Type
    private func unhighlightAllImages(){
        wineGlass.isHighlighted = false
        beer.isHighlighted = false
        shot.isHighlighted = false
        mixedDrink.isHighlighted = false
        selectDrinkLabel.isHidden = false
        
        self.tableView.beginUpdates()
        beerPickerVisible = false
        self.tableView.endUpdates()
        unselectAllBeerImages()
        
        updateFavoriteSuggestSaveButtonsAndImpact()
    }
    
    private func unselectAllBeerImages(){
        beerCan.isSelected = false
        beerBottle.isSelected = false
        beerWheat.isSelected = false
        beerGlass.isSelected = false
        beerMug.isSelected = false
    }
    
    private func typeSelected(volume: Double, abv: Double, name: String, imageToHighlight: UIImageView){
        unhighlightAllImages()
        imageToHighlight.isHighlighted=true
        selectDrinkLabel.isHidden = true
        if volumeTextField.text!.isEmpty {
            if volume == 12{
                setVolumeFromBeerKinds(beerBottle)
            } else if volume == 568 {
                setVolumeFromBeerKinds(beerGlass)
            } else {
                volumeTextField.text = (volume * (volumeUnitButton.currentTitle == "fl. oz" ? 1 : Drink.Constants.FlOzToML)).clean
            }
        }
        if abvTextField.text!.isEmpty {
            abvTextField.text = String(abv)
        }
        
        drinkType = name
        if nameTextField.text!.isEmpty {
            nameTextField.text = name
            navigationItem.title = name
        }
        
        updateFavoriteSuggestSaveButtonsAndImpact(projecting: true)
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @IBAction func wineGlassSelected(_ sender: UITapGestureRecognizer) {
        typeSelected(volume: 5, abv: 12, name: "Wine", imageToHighlight: wineGlass)
    }
    
    @IBAction func beerSelected(_ sender: UITapGestureRecognizer) {
        typeSelected(volume: User.Current.usesImperialUnits ? 12 : 568, abv: 5, name: "Beer", imageToHighlight: beer)
        self.tableView.beginUpdates()
        beerPickerVisible = true
        self.tableView.endUpdates()
    }
    
    @IBAction func shotSelected(_ sender: UITapGestureRecognizer) {
        typeSelected(volume: User.Current.usesImperialUnits ? 1.5 : 0.845351, abv: 40, name: "Shot", imageToHighlight: shot)
    }
    
    @IBAction func mixedDrinkSelected(_ sender: UITapGestureRecognizer) {
        typeSelected(volume: 7, abv: 22, name: "Mixed Drink", imageToHighlight: mixedDrink)
    }
    
    //MARK: - Navigation
    @objc func cancel(_ sender: UIBarButtonItem) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button ===  saveButton else{
            print("The save button was not pressed, cancelling")
            return
        }
        
        updateDrink()
    }
    
    //MARK: - Private methods
    @IBAction func favoriteDrink(_ sender: UIBarButtonItem) {
        updateDrink()
        if Drink.Favorites.filter({ $0.isTheSameAs(drink: drink!) }).count == 0 {
            Drink.Favorites.append(drink!)
            addedToFavorites = true
        }
        favoriteButton.isEnabled = false
    }
    
    private func updateFavoriteSuggestSaveButtonsAndImpact(projecting: Bool = false){
        let allFieldsFilled = !((nameTextField.text ?? "").isEmpty || (volumeTextField.text ?? "").isEmpty || (abvTextField.text ?? "").isEmpty || (!wineGlass.isHighlighted && !beer.isHighlighted && !shot.isHighlighted && !mixedDrink.isHighlighted))
        saveButton.isEnabled = allFieldsFilled
        suggestButton.isEnabled = allFieldsFilled
        favoriteButton.isEnabled = !addedToFavorites && allFieldsFilled
        
        updateImpact(show: allFieldsFilled, projecting: projecting)
        
        abvTextFieldConstraint.constant = abvTextField.text?.isEmpty ?? true ? 8 : 0
    }
    
    private func updateImpact(show: Bool, projecting: Bool) {
        //hide Impact row if drink details are missing i.e. like the Save button
        self.tableView.beginUpdates()
        impactVisible = show
        self.tableView.endUpdates()
        
        if (show){
            //update drink variable from text fields
            updateDrink()
            
            var drinks = [Drink]()
            if (projecting){
                //get sorted drinks list with new drink
                drinks = Drink.CurrentList + [drink!]
                if (indexPath != nil) { drinks.remove(at: indexPath!.row) }
                drinks.sort { $0.timeDrankAt! < $1.timeDrankAt! }
            } else {
                //get impact for just current drink when viewing an added drink's details
                drinks = [drink!]
                drinks[0].timeDrankAt = Date()
            }
            
            //get projected (new) BAC
            var projectedSoberTime: Date?
            let projectedBAC = Drink.CalculateBAC(for: drinks, soberTime: &projectedSoberTime)
            let currentBAC = Drink.CurrentBAC
            
            //get impact of new drink
            let impactBAC = projectedBAC - (projecting ? currentBAC : 0)
            
            //display impact data
            impactBACLabel.text = abs(impactBAC) > 0.0001 ? String(format: "%+.4f", impactBAC) + "%" : "–"
            
            impactLabel.text = (projecting ? "Projected " : "") + "Impact"
            projectedBACLabel.text = String(format: "%.4f", projecting ? projectedBAC : currentBAC) + "%"
            
            //get sober time
            let currentSoberTime = Drink.SoberTime
            
            //get change in sober time in hours and minutes
            let impactSeconds = projectedSoberTime?.timeIntervalSince(projecting ? currentSoberTime ?? Date() : Date()).rounded()
            let hours = Int((impactSeconds ?? 0)/3600)
            let minutes = Int((impactSeconds ?? 0).truncatingRemainder(dividingBy: 3600)/60)
            
            tableView.beginUpdates()
            if (hours == 0){
                impactTimeLabel.text = (abs(minutes) > 0 ? String(format: "%+dm", minutes) : "–")
            } else {
                impactTimeLabel.text = String(format: "%+dh", hours) + (abs(minutes) > 0 ? String(format: " %dm", abs(minutes)) : "")
            }
            tableView.endUpdates()
            
            //display impact data
            projectedSoberTimeLabel.text = (projecting ? projectedSoberTime : currentSoberTime)?.onlyShowTime ?? "–"
        }
    }
    
    private func updateDrink() {
        let name = nameTextField.text ?? ""
        var kind = Drink.Kind.Wine
        if beer.isHighlighted{
            if beerCan.isSelected{
                kind = .BeerCan
            }else if beerBottle.isSelected{
                kind = .BeerBottle
            }else if beerWheat.isSelected{
                kind = .BeerWheat
            }else if beerGlass.isSelected{
                kind = .BeerGlass
            }else if beerMug.isSelected{
                kind = .BeerMug
            }else{
                kind = .Beer
            }
        }else if shot.isHighlighted{
            kind = .Shot
        }else if mixedDrink.isHighlighted{
            kind = .MixedDrink
        }
        
        let volume = Double(volumeTextField.text!)! * (volumeUnitButton.currentTitle! == "ml" ? Drink.Constants.MLToFlOz : 1)
        let abv = Double(abvTextField.text!)
        
        drink = Drink(name: name, volume: volume , abv: abv!, timeDrankAt: datePicker.date, kind: kind)
    }
    
}

