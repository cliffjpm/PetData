//
//  PetDetailViewController.swift
//  PetData
//
//  Created by Cliff Malcolm Anderson on 1/23/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import UIKit
import CloudKit
import os.log

class PetDetailViewController: UIViewController, UITextFieldDelegate {

    //MARK: Properties
    @IBOutlet weak var petName: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var pet: Pet?
    //var pets = [Pet]()
    
    //MARK: Actions
    /*@IBAction func savePet(_ sender: Any) {
        let pet = Pet(petName: petName.text!)
        pet.save()
    }*/
    
    //MARK: Navigation
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        //Set the pet that will be saved locally and to iCloud
        pet = Pet(petName: petName.text!)
        
        //Save the pet to iCloud if available. This needs to move the unwind area of the TableView
        
        //pet.save()
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //PUT YOUR CODE HERE
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}


