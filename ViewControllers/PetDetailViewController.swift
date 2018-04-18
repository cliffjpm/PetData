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
        
        //Confirm connectivity with iCloud
        testForICloud()
        
        //Set custom zone
        ArendK9DB.share.zoneSetup()
        
        //Subscribe to change notifications
        ArendK9DB.share.dbSubscribeToChange()
        
        //Handle the text field's user input through delegate callbacks.
        petName.delegate = self
        
        
        //Debug item to show NSHome. Allow me to confirm token creation and updates
        //print("NS Home is: ")
        //print(NSHomeDirectory())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: Custom Functions
    func testForICloud() {
        //Test for iCloud Login
        ArendK9DB.share.container.accountStatus { (accountStatus, error) in
            switch accountStatus {
            case .available:
                print("iCloud Available")
                //simple alert dialog
                //let alert=UIAlertController(title: "Signed in to iCloud", message: "This application requires iCloud. You are successfully logged in. Thanks!", preferredStyle: UIAlertControllerStyle.alert);
                //no event handler (just close dialog box)
                //alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil));
                //show it
                //self.present(alert, animated: true, completion: nil)
            case .noAccount:
                print("No iCloud account")
                //simple alert dialog
                let alert=UIAlertController(title: "Sign in to iCloud", message: "This application requires iCloud. Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID", preferredStyle: UIAlertControllerStyle.alert);
                //no event handler (just close dialog box)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil));
                //show it
                self.present(alert, animated: true, completion: nil)
            case .restricted:
                print("iCloud restricted")
            case .couldNotDetermine:
                print("Unable to determine iCloud status")
            }
        }
    }
    

}


