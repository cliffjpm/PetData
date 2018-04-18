//
//  PetTableViewController.swift
//  PetData
//
//  Created by Cliff Anderson on 1/26/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import UIKit
import CloudKit

class PetTableViewController: UITableViewController {

    //MARK: Properties and create an array of the new objects
    var pets = [Pet]()
    var pet: Pet?
    
    //var tb: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Using loadPets from viewDidLoad")
        loadPets()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PetTableViewController.loadPets), name: NSNotification.Name(rawValue: "load"), object: nil)
        
        /*tb = self.tableView
        tb?.dataSource = self
        tb?.delegate = self
        super.view.addSubview((tb)!)*/
        
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
       
        // Configure the cell...
        cell.petNameLabel.text = pet.petName
        
        return cell
    }
    
   

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: Actions
    @IBAction func unwindToPetList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? PetDetailViewController, let pet = sourceViewController.pet {
            
            // Add a new pet.
            //let newIndexPath = IndexPath(row: pets.count, section: 0)
            
            //pets.append(pet)
            //tableView.insertRows(at: [newIndexPath], with: .automatic)
            
            //TODO: This only saved to iCloud for now. Need to add local copy and any conflict resolution
            self.pet = pet
            pet.save()
            
            perform(#selector(loadPets), with: nil, afterDelay: 4.0)
            
            /*self.pets.append(pet)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }*/
            
            /*print("Using loadPets from unwindToPetList")
            sleep(1)
            loadPets()*/
        }
    }
    
    //MARK: Properties and create an array of the new objects
    @objc func loadPets() {
        
        print("DEBUG: loadPets was called")
        
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
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        else{
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
    }


}
