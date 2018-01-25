//
//  ViewController.swift
//  PetData
//
//  Created by Cliff Malcolm Anderson on 1/23/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {

    //MARK: Properties
    @IBOutlet weak var petName: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    //MARK: Actions
    @IBAction func savePet(_ sender: Any) {
        let record = CKRecord(recordType: RemoteRecord.pet, zoneID: ArendK9DB.share.zoneID)
        //let record = CKRecord(recordType: RemoteRecord.pet)
        record[RemotePet.petName] = petName.text! as NSString
        
        ArendK9DB.share.privateDB.save(record) {
            record, error in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Pet Record Saved")
            }
        }    
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Confirm connectivity with iCloud
        testForICloud()
        
        //Set custom zone
        ArendK9DB.share.zoneSetup()
        
        //Subscribe to change notifications
        ArendK9DB.share.dbSubscribeToChange()
        
        
        
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


