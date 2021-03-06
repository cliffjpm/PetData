//
//  PetTableViewController.swift
//  PetData
//
//  Created by Cliff Anderson on 1/26/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import UIKit
import CloudKit
import os.log

class PetTableViewController: UITableViewController {

    //MARK: Properties and create an array of the new objects
    var pets = [Pet]()
    var pet: Pet?
    var onTheCloud = false
    var CKPet: Pet?
    var localPets = [Pet]()
    
    //var tb: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        //Confirm connectivity with iCloud AND this calls to createDataSet()
        testForICloud()
        
        //Set custom zone
        ArendK9DB.share.zoneSetup()
        
        //Subscribe to change notifications
        ArendK9DB.share.dbSubscribeToChange()
        
        //Debug item to show NSHome. Allow me to confirm token creation and updates
        //print("NS Home is: ")
        //print(NSHomeDirectory())
        
        NotificationCenter.default.addObserver(self, selector: #selector(PetTableViewController.loadPets), name: NSNotification.Name(rawValue: "load"), object: nil)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PetTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PetTableViewCell  else {
            fatalError("The dequeued cell is not an instance of PetTableViewCell.")
        }

        let pet = pets[indexPath.row]
        
        // Date Formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        cell.petName.text = pet.petName
        cell.petImage.image = pet.photo
        cell.petName.text = pet.petName
        if pet.dob == nil {
            cell.petDOB.text = ""
        } else {
            cell.petDOB.text = dateFormatter.string(from: pet.dob!)
        }
        cell.petSex.text = pet.petSex
        cell.petImage.image = pet.photo
        
        return cell
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //Handle a deletion
        if editingStyle == .delete {
           
            //Reset to onTheCloud before starting this check
            self.onTheCloud = false
            //The Deletion is wrapped with a completion handler checking for CloudKit status
            ArendK9DB.share.container.accountStatus { (accountStatus, error) in
                switch accountStatus {
                case .available:
                    print("Since you are on the Cloud, start to delete from CloudKit")
                    self.onTheCloud = true
                    self.pets[indexPath.row].deleteFromCloud()
                        { (error) -> () in
                            print("Starting completion block")
                            self.pets.remove(at: indexPath.row)
                            self.pets[0].saveToLocal(petsToSave: self.pets)
                            DispatchQueue.main.async {
                                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                            }
                            print("Exiting completion block")
                    }
                case .noAccount:
                    print("Delete from local data store - No Account")
                    //Delete the pet locally if not on the Cloud or mark with "Delete Me" if already saved to cloud
                    if self.pets[indexPath.row].recordName == "Local" {
                        self.pets.remove(at: indexPath.row)
                        //print("DEBUG: What is the new set of pets \(self.pets)")
                        self.pets[0].saveToLocal(petsToSave: self.pets)
                        //Remove the pet from the table
                        DispatchQueue.main.async {
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                    else{
                        self.pets[indexPath.row].petName.append(" Delete Me")
                        self.pets[0].saveToLocal(petsToSave: self.pets)
                        //Remove the pet from the table
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                case .restricted:
                    print("Delete from local data store")
                    //Delete the pet locally if not on the Cloud or mark with "Delete Me" if already saved to cloud
                    if self.pets[indexPath.row].recordName == "Local" {
                        self.pets.remove(at: indexPath.row)
                        //print("DEBUG: What is the new set of pets \(self.pets)")
                        self.pets[0].saveToLocal(petsToSave: self.pets)
                        //Remove the pet from the table
                        DispatchQueue.main.async {
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                    else{
                        self.pets[indexPath.row].petName.append(" Delete Me")
                        self.pets[0].saveToLocal(petsToSave: self.pets)
                        //Remove the pet from the table
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                case .couldNotDetermine:
                    print("Delete from local data store")
                    //Delete the pet locally if not on the Cloud or mark with "Delete Me" if already saved to cloud
                    if self.pets[indexPath.row].recordName == "Local" {
                        self.pets.remove(at: indexPath.row)
                        self.pets[0].saveToLocal(petsToSave: self.pets)
                        //Remove the pet from the table
                        DispatchQueue.main.async {
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                    else{
                        self.pets[indexPath.row].petName.append(" Delete Me")
                        self.pets[0].saveToLocal(petsToSave: self.pets)
                        //Remove the pet from the table
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            
            os_log("Pets successfully deleted.", log: OSLog.default, type: .debug)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddPet":
            os_log("Adding a new pet.", log: OSLog.default, type: .debug)
            
        case "ShowDetail":
            guard let petDetailViewController = segue.destination as? PetDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedPetCell = sender as? PetTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedPetCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedPet = pets[indexPath.row]
            petDetailViewController.pet = selectedPet
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    
    @IBAction func unwindToPetList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? PetDetailViewController, let pet = sourceViewController.pet {
            
            //NOTE: Taking the approach to update the UI first and then execture all the saves in the background
            
            pet.remoteRecord?.setValue(pet.petName, forKey: RemotePet.petName)
            pet.remoteRecord?.setValue(pet.dob, forKey: RemotePet.dob)
            pet.remoteRecord?.setValue(pet.petSex, forKey: RemotePet.petSex)
            pet.remoteRecord?.setValue(pet.photoConverter(photo: pet.photo!), forKey: RemotePet.photo)
            
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing pet
    
                //Reset to onTheCloud before starting this check
                self.onTheCloud = false
                //Try to save to the CloudKit (creates recordName and recordChangeTag)
                ArendK9DB.share.container.accountStatus { (accountStatus, error) in
                    switch accountStatus {
                    case .available:
                        //print("Saving pet to CloudKit")
                        self.onTheCloud = true
                        //print("When Saving, the remote record is \(pet.remoteRecord)")
                        pet.saveToCloud()
                            { (results , changeTag, error) -> () in
                                //print("Starting completion block")
                                self.pets[selectedIndexPath.row] = results!
                                //print("DEBUG: inside block is \(results) with changeTag \(changeTag) and an error of \(error)")
                                //print("Pets: \(self.pets)")
                                //print("DEBUG: Pet remoteRecord returned is \(pet.remoteRecord)")
                                pet.saveToLocal(petsToSave: self.pets)
                                DispatchQueue.main.async {
                                    self.tableView.reloadRows(at: [selectedIndexPath], with: .none)
                                }
                                //print("Exiting completion block")
                        }
                    case .noAccount:
                        //print("Saving pet to local data store")
                        //Update the pet in the array
                        self.pets[selectedIndexPath.row] = pet
                        //Save the record
                        pet.saveToLocal(petsToSave: self.pets)
                        DispatchQueue.main.async {
                            self.tableView.reloadRows(at: [selectedIndexPath], with: .none)
                        }
                    case .restricted:
                        self.pets[selectedIndexPath.row] = pet
                        pet.saveToLocal(petsToSave: self.pets)
                        DispatchQueue.main.async {
                            self.tableView.reloadRows(at: [selectedIndexPath], with: .none)
                        }
                    case .couldNotDetermine:
                        self.pets[selectedIndexPath.row] = pet
                        pet.saveToLocal(petsToSave: self.pets)
                        DispatchQueue.main.async {
                            self.tableView.reloadRows(at: [selectedIndexPath], with: .none)
                        }
                    }
                }
            }
            else {
                //Add a new pet
                
                //Reset to onTheCloud before starting this check
                self.onTheCloud = false
                //Try to save to the CloudKit (creates recordName and recordChangeTag)
                ArendK9DB.share.container.accountStatus { (accountStatus, error) in
                    switch accountStatus {
                    case .available:
                        //print("Saving pet to CloudKit")
                        self.onTheCloud = true
                        pet.saveToCloud()
                            { (results , changeTag, error) -> () in
                                //print("Starting completion block")
                                self.pets.append(results!)
                                //print("DEBUG: inside block is \(results) with changeTag \(changeTag) and an error of \(error)")
                                //print("Pets: \(self.pets)")
                                //print("DEBUG: Pet remoteRecord returned is \(pet.remoteRecord)")
                                pet.saveToLocal(petsToSave: self.pets)
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                                //print("Exiting completion block")
                            }
                    case .noAccount:
                        //print("Saving pet to local data store")
                        //Add the pet to the array
                        self.pets.append(pet)
                        //Save the record
                        pet.saveToLocal(petsToSave: self.pets)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    case .restricted:
                        self.pets.append(pet)
                        pet.saveToLocal(petsToSave: self.pets)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    case .couldNotDetermine:
                        self.pets.append(pet)
                        pet.saveToLocal(petsToSave: self.pets)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
                //TODO: test to see if all the table reloads can be done here
                //self.perform(#selector(self.createDataSet), with: nil, afterDelay: 5.0)
            }
        }
    }
    
    
    //MARK: Custom Functions
    func testForICloud() {
        //Test for iCloud Login
        ArendK9DB.share.container.accountStatus { (accountStatus, error) in
            switch accountStatus {
            case .available:
                print("iCloud Available")
                self.onTheCloud = true
                self.createDataSet()
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
                self.createDataSet()
            case .restricted:
                print("iCloud restricted")
                self.createDataSet()
            case .couldNotDetermine:
                print("Unable to determine iCloud status")
                self.createDataSet()
            }
        }
    }
    
    //MARK: Try to load pets from iCloud
    @objc private func loadPets() -> [Pet]? {
        
        //print("DEBUG Calling the recon function in PET")
        //Pet.recon()
        
        //print("DEBUG: loadPets was called")
        if pets.count == 0 {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: RemoteRecords.pet, predicate: predicate)
            ArendK9DB.share.privateDB.perform(query, inZoneWith: ArendK9DB.share.zoneID) {
                records, error in
                if error != nil {
                    print(error?.localizedDescription ?? "General Query Error: No Description")
                } else {
                    guard let records = records else {
                        return
                    }
                    for record in records {
                        if let pet = Pet(remoteRecord: record) {
                            self.pets.append(pet)
                        }
                    }
                    //If these is local data, load it for comparison
                    if var localPets = self.loadPetsLocal() {
                        print("DEBUG There is a local data store in addition to a Cloud data")
                        //print("DEBUG Local data is \(localPets)")
                        //Iterate through the local data
                        for localPet in localPets {
                            //MARK: RECON DELETIONS (Offline deletions of CKRecords)
                            //Check to see if the record is marked for deletion (marked while off the CloudKit)
                            if localPet.petName.lowercased().range(of: "delete me") != nil{
                                //If the record is marked for deletion, iterate through the pets array to find the related CKRecord
                                for petToDelete in self.pets{
                                    //print("DEBUG Comparing Local Record with name \(localPet.petName), recordName \(localPet.recordName) and remote record \(petToDelete.petName), recordName \(petToDelete.remoteRecord?.recordID.recordName)")
                                    if localPet.recordName == petToDelete.remoteRecord?.recordID.recordName {
                                        //Send the CKRecord for deletion
                                        petToDelete.deleteFromCloud()
                                            { (error) -> () in
                                                //Remove the record from the local list and save the new list
                                                //print("Deleted local record during recon \(petToDelete.petName)")
                                                if let indexLocal = localPets.index(of: localPet){
                                                    localPets.remove(at: indexLocal)
                                                }
                                                //Remone the record from the pets arrary before displaying the table
                                                if let index = self.pets.index(of: petToDelete){
                                                    self.pets.remove(at: index)
                                                }
                                        }
                                    }
                                }
                            }
                            //MARK: RECON NEW RECORDS (Offline creation of new recoreds)
                            
                            //Save the deletion to the localPets array
                            self.localPets = localPets
                        }
                    }
                    //Save the update localPet and update the table
                    self.localPets[0].saveToLocal(petsToSave: self.localPets)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        else{
            print("DEBUG As you already had data and pets was not empty, NO recon was performed. This is just a full refresh of the CKRecords.")
            
            pets = []
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: RemoteRecords.pet, predicate: predicate)
            ArendK9DB.share.privateDB.perform(query, inZoneWith: ArendK9DB.share.zoneID) {
                records, error in
                if error != nil {
                    print(error?.localizedDescription ?? "General Query Error: No Description")
                } else {
                    guard let records = records else {
                        return
                    }
                    for record in records {
                        if let pet = Pet(remoteRecord: record) {
                            self.pets.append(pet)
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        return pets
    }
    
    //MARK: Try to load records from the local archive if no iCloud connectivity exists
    private func loadPetsLocal() -> [Pet]?  {
            return NSKeyedUnarchiver.unarchiveObject(withFile: Pet.ArchiveURL.path) as? [Pet]
    }
    
    
    //If no records exist, supply sample data for testing.
    private func loadSamples(){
        let photo1 = UIImage(named: "win")
        let photo2 = UIImage(named: "suki")
        let photo3 = UIImage(named: "albus")
        let today = Date()
        
        /*  Set up three data types:
         an array of Vaccine Types
         and array of the Dates of Occurance and
         Dictionary of the types (String) and the array of days (Dates) they occurred*/
        var vaccineTypes = [String]()
        var vaccineOccurances = [Date]()
        var vaccines: [String: Array<Date>?] = [:]
        
        //Date formatter with default dates for testing
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let day1 = formatter.date(from: "2016/10/08")
        let day2 = formatter.date(from: "2018/11/10")
        let day3 = formatter.date(from: "2017/12/09")
        
        
        //Set up the types available
        vaccineTypes = ["Rabies",  "Flea & Tick", "HeartGuard"]
        
        //Create an emply array of Dictionary
        vaccines = [vaccineTypes[0]: nil, vaccineTypes[1]: nil, vaccineTypes[2]: nil]
        
        //Use the dates to set up an array of vaccine occurances
        vaccineOccurances = [day1!, day2!, day3!]
        //sort the dates
        vaccineOccurances.sort()
        
        //vaccineOccurances.max()
        /*for dateOfOccurances in vaccineOccurances{
         //print(dateOfOccurances)
         }*/
        
        
        //Set up some a sample of vaccines and occurances as Dictionary (String of  types + arrays of occurances)
        vaccines = [vaccineTypes[0]: vaccineOccurances, vaccineTypes[1]: vaccineOccurances, vaccineTypes[2]: vaccineOccurances]
        
        //Add a date to one in the array
        vaccines["Rabies"]??.append(formatter.date(from: "2020/10/08")!)
        
        /*for meds in vaccines{
         print(meds.key + "")
         
         let dateFormatter = DateFormatter()
         dateFormatter.dateStyle = .short
         dateFormatter.timeStyle = .none
         
         var latestMed: String
         latestMed = dateFormatter.string(from: (meds.value?.max())!)
         
         print(latestMed)
         }*/
        
        guard let pet1 = Pet(petName: "Winnie", dob: today, petSex: "Female", photo: photo1, vaccineDates: vaccines, recordName: "Local", recordChangeTag: nil) else {
            fatalError("Unable to instantiate pet1")
        }
        
        //Sample of creating a new type of vaccine
        let newMed = "MyNewMed"
        let dayNew = formatter.date(from: "1961/01/11")
        vaccines[newMed] = [dayNew!]
        
        guard let pet2 = Pet(petName: "Suzi", dob: nil, petSex: "Female", photo: photo2, vaccineDates: vaccines,recordName: "Local", recordChangeTag: nil) else {
            fatalError("Unable to instantiate dog2")
        }
        
        guard let pet3 = Pet(petName: "Albus", dob: nil, petSex: nil, photo: photo3, vaccineDates: vaccines, recordName: "Local", recordChangeTag: nil) else {
            fatalError("Unable to instantiate dog3")
        }
        
        pets += [pet1, pet2, pet3]
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    @objc private func createDataSet(){
        
        //Start with an empty array
        pets = []
        
        //If CONNECTED to iCloud, load the data into the pets array
         if self.onTheCloud == true {
            Pet.recon(){ (results , error) -> () in
                //print("DEBUG This is where I need to load in the new array of pets from CloudKit")
                if error != nil {
                    print(error?.localizedDescription ?? "General Query Error: No Description")
                } else {
                    self.pets = results
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                    /*This was the method used before I came up with Recon
                    if let savedPets = self.loadPets() {
                     print("DEBUG: Getting pets from iCloud")
                     self.pets += savedPets
                     }*/
                    
                }
            }
            
        }
        //If NOT CONNECTED to iCloud...
        else {
            if let savedPets = loadPetsLocal() {
                print("DEBUG: Getting pets from Local Cache")
                pets = savedPets
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            //There is NO LOCAL data
            else {
                // LOAD SAMPLE data.
                print("DEBUG: Getting pets from Samples")
                loadSamples()
                //TODO: Call save to local and try save to iCloud
            }
        }
    }
 
}
