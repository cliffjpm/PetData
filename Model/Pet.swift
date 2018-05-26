//
//  Pet.swift
//  PetData
//
//  Created by Cliff Anderson on 1/26/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import Foundation
import CloudKit
import UIKit
import os.log

class Pet: NSObject, NSCoding {
    
    //MARK: Properties
    var petName = ""
    var dob: Date?
    var petSex: String?
    var photo: UIImage?
    var remoteRecord: CKRecord? = nil
    var recordName: String?
    var recordChangeTag: String?
    
    static var pets = [Pet]()
    static var cloudPets = [CKRecord]()
    static var changedRecord: CKRecord? = nil
    
    //var changeRecords: [CKRecord]?
    //var newRecord: CKRecord? = nil
    //var userRecordName = ""
    
    //DICTIONARIES unordered pair of key, value pairs of vaccines
    var vaccineDates: [String: Array<Date>?]? = [:]
    
    static let documentsDirectoryPath:NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    static var imageURL: URL!
    static let tempImageName = "Image2.jpg"
    
    //MARK: Types
    struct PropertyKey {
        static let petName = "petName"
        static let dob = "dob"
        static let petSex = "petSex"
        static let photo = "photo"
        static let vaccineDates = "vaccineDates"
        static let recordName = "recordName"
        static let recordChangeTag = "recordChangeTag"
    }
    
    //MARK: Initialization
    
    //This init takes a remote record from iClound and creates a Pet
    init?(remoteRecord: CKRecord) {
        
        //print("DEBUG: Is remoteRecord nil when initiating the list? \(remoteRecord)")
        
        //Note that these values come from Constants
        guard let petName = remoteRecord.object(forKey: RemotePet.petName) as? String
            else {
                return nil
        }
        dob = remoteRecord.object(forKey: RemotePet.dob) as? Date
        petSex = remoteRecord.object(forKey: RemotePet.petSex) as? String
        
        // Get image from an asset
        if let asset = remoteRecord.object(forKey: RemotePet.photo)  as? CKAsset, let image = asset.image  {
            self.photo = image
        }
        else{
            self.photo = UIImage(named: "defaultPhoto")
        }
        
        guard !petName.isEmpty else {
            return nil
        }

        self.petName = petName
        self.remoteRecord = remoteRecord
        
        self.recordName = remoteRecord.recordID.recordName
        self.recordChangeTag = remoteRecord.recordChangeTag
        
        
        //TODO: Need to sort out Vaccine Dates
        //self.vaccineDates = remoteRecord.object(forKey: RemotePet.vaccineDates) as? Dictionary<String, Array<Date>>
        
    }
    
    
    init(petName: String) {
        self.petName = petName
        self.dob = Date()
        
    }
    
    init(petName: String, dob: Date) {
        self.petName = petName
        self.dob = dob
    }
    
    init?(petName: String, dob: Date?, petSex: String?, photo: UIImage?, vaccineDates: Dictionary<String, Array<Date>?>?, recordName: String?, recordChangeTag: String?) {
        //let formatter = DateFormatter()
        //formatter.dateFormat = "yyyy/MM/dd"
        //let day1 = formatter.date(from: "2016/10/08")
        //let day2 = formatter.date(from: "2017/11/09")
        //let day3 = formatter.date(from: "2018/12/010")
        //let vDates = ["Rabies": day1!, "HeartGuard": day2!, "Flea & Tick": day3!]
        
        //The name must not be empty
        guard !petName.isEmpty else {
            return nil
        }
        guard (petSex == "Male") || (petSex == "Female") || (petSex == nil) else{
            return nil
        }
        
        // Initialize stored properties.
        self.petName = petName
        self.dob = dob
        self.petSex = petSex
        self.photo = photo
        self.vaccineDates = vaccineDates
        
        //self.vaccineDates = ["": [day1!]]
        //print("DEBUG (Init) When creating a new dog the vaccine dictionary is: ")
        //print(self.vaccineDates)
        
       
        remoteRecord = CKRecord(recordType: RemoteRecords.pet, zoneID: ArendK9DB.share.zoneID)
        remoteRecord?[RemotePet.petName] = petName as NSString
        remoteRecord?[RemotePet.dob] = dob as NSDate?
        remoteRecord?[RemotePet.petSex] = petSex as NSString?
        //Some special handling to get the UIImage into a CKAsset
        if let photo = photo {
            let imageData:Data = UIImageJPEGRepresentation(photo, 1.0)!
            let path:String = Pet.documentsDirectoryPath.appendingPathComponent(Pet.tempImageName)
            try? UIImageJPEGRepresentation(photo, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
            Pet.imageURL = URL(fileURLWithPath: path)
            try? imageData.write(to: Pet.imageURL, options: [.atomic])
            let File:CKAsset?  = CKAsset(fileURL: URL(fileURLWithPath: path))
            remoteRecord?[RemotePet.photo] = File as! CKAsset
        }
        
        //MARK: Put in Local as the recordName for records created locally but not stored to Cloud. Need to Test this offline to see if it work
        if recordName == "" || recordName == nil {
            self.recordName = "Local"
        } else {
            self.recordName = recordName
            remoteRecord?[RemotePet.recordName] = recordName as NSString?
        }
        
        if recordChangeTag == "" || recordChangeTag == nil {
            self.recordChangeTag = ""
        } else {
            self.recordChangeTag = recordChangeTag
        }
        
        //print("DEBUG: When creating a record, the remote record is \(remoteRecord)")
        
    }
    
    convenience init?(petName: String, dob: Date?, petSex: String?, photo: UIImage?){
        
        
        let vDates: [String: Array<Date>?] = [:]
        //print("DEBUG (Convenience) When creating a new dog the vaccine dictionary is: ")
        //print(vDates)
        
        self.init(petName: petName, dob: dob, petSex: petSex, photo: photo, vaccineDates: vDates, recordName: "", recordChangeTag: nil)
        //os_log("These dogs were initialized with a Vaccine Dictionary.", log: OSLog.default, type: .debug)
    }
    
    //MARK: Recon Function
    static func recon(
            completion: @escaping (
                _ results: [Pet],
                _ error: NSError?) -> ())
        {
        
        var petsToDelete = [CKRecordID]()
        var petsToSave = [CKRecord]()
        
        //Empty any existing pet array
        //TODO: Test to see if you can remove this statement as I think it is not used
        pets = []
        
        //load local pets into an array
        if let localPets = loadPetsLocal()  {
            
        //print("DEBUG I have local pets in my RECON: \(localPets)")
        
        //Set up the array for CloudKit Pets
        fetchFromCloud(){ (results , error) -> () in
            cloudPets = results
            //print("DEBUG I have cloud pets in my RECON: \(cloudPets)")
        
        
            //Use records marked for deletion to mark the CKRecords for deletion and put them into an array for saving to CloudKit
            for localPet in localPets {
                //MARK: RECON DELETIONS (Offline deletions of CKRecords)
                //Check to see if the record is marked for deletion (marked while off the CloudKit)
                if localPet.petName.lowercased().range(of: "delete me") != nil{
                    //If the record is marked for deletion, iterate through the pets array to find the related CKRecord
                    for petToDelete in cloudPets{
                        //print("DEBUG Comparing Local Record with name \(localPet.petName), recordName \(localPet.recordName) and remote record \(petToDelete.petName), recordName \(petToDelete.remoteRecord?.recordID.recordName)")
                        if localPet.recordName == petToDelete.recordID.recordName{
                            //Put this record into the deletion array of CKRecordIDs
                            petsToDelete.append(petToDelete.recordID)
                        }
                    }
                }
            
            //Put all new records (recordName = "Local") into an array for saving to CloudKit
                if localPet.recordName == "Local" {
                    changedRecord = CKRecord(recordType: RemoteRecords.pet, zoneID: ArendK9DB.share.zoneID)
                    changedRecord?[RemotePet.petName] = localPet.petName as NSString
                    changedRecord?[RemotePet.dob] = localPet.dob as NSDate?
                    changedRecord?[RemotePet.petSex] = localPet.petSex as NSString?
                    //Some special handling to get the UIImage into a CKAsset
                    if let photo = localPet.photo {
                        let imageData:Data = UIImageJPEGRepresentation(photo, 1.0)!
                        let path:String = Pet.documentsDirectoryPath.appendingPathComponent(Pet.tempImageName)
                        try? UIImageJPEGRepresentation(photo, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                        Pet.imageURL = URL(fileURLWithPath: path)
                        try? imageData.write(to: Pet.imageURL, options: [.atomic])
                        let File:CKAsset?  = CKAsset(fileURL: URL(fileURLWithPath: path))
                        changedRecord?[RemotePet.photo] = File as! CKAsset
                    }
                    petsToSave.append(changedRecord!)
                }
            }
            //Take all changed records (recordChangeTag = "") and compare them against the CKRecord
            //UPdate the CKRecord values IF the last modificaiton date is more recent on the local record
            //Add updated CKRecords to the save array (started with the new records)
            
            print("DEBUG The array of records to delete contains \(petsToDelete)")
            print("DEBUG The array of records to save contains \(petsToSave)")
            
            if petsToDelete == [] && petsToSave == [] {
                print("DEBUG I have nothing to save")
                if error != nil {
                    print(error?.localizedDescription ?? "General Query Error: No Description")
                } else {
                    /*guard let records = results else {
                     return
                     }*/
                    for record in results {
                        if let pet = Pet(remoteRecord: record) {
                            self.pets.append(pet)
                        }
                    }
                    completion(pets, nil)
                }
            } else {
                saveUpdateCloud(petsToSave: petsToSave, recordIDsToDeleve: petsToDelete)
                    { (results , error) -> () in
                        if error != nil {
                            print(error?.localizedDescription ?? "General Query Error: No Description")
                        } else {
                            for pet in cloudPets{
                                pets.append(Pet(remoteRecord: pet)!)
                            }
                            for pet in results{
                                pets.append(Pet(remoteRecord: pet)!)
                            }
                            for pet in pets{
                                for deletedPet in petsToDelete{
                                    if pet.recordName == deletedPet.recordName{
                                        if let index = pets.index(of: pet){
                                            pets.remove(at: index)
                                        }
                                    }
                                }
                            }
                            //Save this new array locally
                            print("DEGUG Saving records to local store")
                            pets[0].saveToLocal(petsToSave: self.pets)
                            print("DEBUG I have a new reconciled array from CloudKit \(pets)")
                            completion(pets, nil)
                            //Grab the new, updated list of CKRecords
                            /*fetchFromCloud(){ (r , e) -> () in
                                print("DEBUG Loading new CloudKit array at \(Date())")
                                if e != nil {
                                    print(e?.localizedDescription ?? "General Query Error: No Description")
                                } else {
                                    for record in r {
                                        if let pet = Pet(remoteRecord: record) {
                                            pets.append(pet)
                                        }
                                    }
                                    //Save this new array locally
                                    print("DEGUG Saving records to local store")
                                    pets[0].saveToLocal(petsToSave: self.pets)
                                    print("DEBUG I have a new pet array from CloudKit \(pets)")
                                    completion(pets, nil)
                                }
                            }*/
                            
                        }
                        
                    }
            }
        }
        } else {
            fetchFromCloud(){ (r , e) -> () in
                print("DEBUG There is no local data so I am returning a new CloudKit array  \(r)")
                if e != nil {
                    print(e?.localizedDescription ?? "General Query Error: No Description")
                } else {
                    for record in r {
                        if let pet = Pet(remoteRecord: record) {
                            pets.append(pet)
                        }
                    }
                    //Save this new array locally
                    print("DEGUG Saving records to local store")
                    pets[0].saveToLocal(petsToSave: self.pets)
                    print("DEBUG I have a new pet array from CloudKit \(pets)")
                    completion(pets, nil)
                }
            }
        }
    }
    
    
    //MARK: Fetch current recrods from CloudKit
    static func fetchFromCloud(
        completion: @escaping (
        _ results: [CKRecord],
        _ error: NSError?) -> ())
    {
        
        print("Fetch from CloudKit... starting completion handler")
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: RemoteRecords.pet, predicate: predicate)
        
        ArendK9DB.share.privateDB.perform(query, inZoneWith: ArendK9DB.share.zoneID, completionHandler: {(records: [CKRecord]?, e: Error?)  in
            if e != nil {
                print(e?.localizedDescription ?? "General Query Error: No Description")
            } else {
                guard let records = records else {
                    return
                }
                //print("DEBUG Fetching from CloudKit... ending completion handler with records = \(records)")
                completion(records, nil)
                }
            }
        )
        
        
    }
    
    //MARK: Save new records and delete records for multiple Pets
    static func saveUpdateCloud(petsToSave: [CKRecord]?, recordIDsToDeleve: [CKRecordID]?,
        completion: @escaping (
        _ results: [CKRecord],
        _ error: NSError?) -> ())
    {
        //Execute the operation
        var savedRecords = [CKRecord]()
        var results = [CKRecord]()
        let saveOperation = CKModifyRecordsOperation(recordsToSave: petsToSave, recordIDsToDelete: recordIDsToDeleve)
        saveOperation.perRecordCompletionBlock = {
            record, error in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Saving Record to Cloud: \(record)")
                savedRecords.append(record)
            }
        }
        
        saveOperation.completionBlock = {
            results = savedRecords
            completion(results, nil)
        }
        
        ArendK9DB.share.privateDB.add(saveOperation)
        
    }
    
    //MARK: Save function for a single Pet to CloudKit
    func saveToCloud(
        completion: @escaping (
        _ results: Pet?,
        _ changeTag: String?,
        _ error: NSError?) -> ())
    {
        
        //print("Saving to CloudKit...")
        //print("DEBUG: Is remoteRecord nil when saving? \(remoteRecord)")
        
        if remoteRecord == nil {
            remoteRecord = CKRecord(recordType: RemoteRecords.pet, zoneID: ArendK9DB.share.zoneID)
            remoteRecord?[RemotePet.petName] = petName as NSString
            remoteRecord?[RemotePet.dob] = dob as NSDate?
            remoteRecord?[RemotePet.petSex] = petSex as NSString?
            //Some special handling to get the UIImage into a CKAsset
            remoteRecord?[RemotePet.photo] = photoConverter(photo: photo!)
        }
        
        //TODO: Figure out how to hande the refrence to vaccine dates or store a dictionary
        //remoteRecord?[RemotePet.vaccineDates] = vaccineDates as! Dictionary<String, Array<Date>>?
        
        let saveOperation = CKModifyRecordsOperation(recordsToSave: [remoteRecord!], recordIDsToDelete: nil)
        
        saveOperation.perRecordCompletionBlock = {
            record, error in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Saving Record to Cloud: \(record)")
                self.remoteRecord = record
                self.remoteRecord?[RemotePet.recordName] = record.recordID.recordName as NSString?
                self.recordName = record.recordID.recordName
                self.recordChangeTag = record.recordChangeTag as String?
                //print("Change tag:  \(String(describing: self.remoteRecord?.recordChangeTag))")
                
            }
            completion(self, self.recordChangeTag, nil)
        }
        
        
        ArendK9DB.share.privateDB.add(saveOperation)
        
        
        /*This code was designed for using NS data. I did not take this route
         // obtain the metadata from the CKRecord
         let data = NSMutableData()
         let coder = NSKeyedArchiver.init(forWritingWith: data)
         coder.requiresSecureCoding = true
         remoteRecord?.encodeSystemFields(with: coder)
         coder.finishEncoding()
         
         // store this metadata on your local object
         self.encodedSystemFields = data as Data*/
        
        /*ArendK9DB.share.privateDB.fetch(withRecordID: (self.remoteRecord?.recordID)!, completionHandler: { (record: CKRecord?, e: Error?) in
         if e != nil {
         print("ERROR: \(String(describing: e))")
         return
         }
         else {
         //Change a value
         self.recordChangeTag = record?.recordChangeTag
         }
         }
         )*/
        
    }
    
    
    //MARK: Delete function for iCloud
    func deleteFromCloud(
        completion: @escaping (
        _ error: NSError?) -> ())
    {
        
        print("Deleting from CloudKit record for \(remoteRecord)")
        //print("DEBUG: Is remoteRecord nil when deleting? \(remoteRecord)")
        
        
        //TODO: Figure out how to hande the refrence to vaccine dates or store a dictionary
        //remoteRecord?[RemotePet.vaccineDates] = vaccineDates as! Dictionary<String, Array<Date>>?
        
        let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [remoteRecord!.recordID])
        
        deleteOperation.perRecordCompletionBlock = {
            record, error in
            if error != nil {
                print(error!.localizedDescription)
                completion(error as! NSError)
            } else {
                print("Deleting Record from Cloud: \(record)")
                completion(nil)
            }
        }
        
        ArendK9DB.share.privateDB.add(deleteOperation)
        
        completion(nil)
    }
    
    
    //MARK: Save to local
    @objc func saveToLocal(petsToSave: [Pet]) {
        print("Processing local save ...")
        
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(petsToSave, toFile: Pet.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("Pets successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save pets...", log: OSLog.default, type: .error)
        }
    
    }
    
    //MARK: Try to load records from the local archive if no iCloud connectivity exists
    static private func loadPetsLocal() -> [Pet]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Pet.ArchiveURL.path) as? [Pet]
    }
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("pets")
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        //print("DEBUG: called the encoder")
        aCoder.encode(petName, forKey: PropertyKey.petName)
        aCoder.encode(dob, forKey: PropertyKey.dob)
        aCoder.encode(petSex, forKey: PropertyKey.petSex)
        aCoder.encode(photo, forKey: PropertyKey.photo)
        aCoder.encode(vaccineDates, forKey: PropertyKey.vaccineDates)
        aCoder.encode(recordName, forKey: PropertyKey.recordName)
        aCoder.encode(recordChangeTag, forKey: PropertyKey.recordChangeTag)
        //print("ENCODING: \(petName) with recordName \(recordName) and  change tag \(recordChangeTag) but what I really need is the ID called \(remoteRecord?.recordID.recordName)")
        //os_log("Encoding the Vaccine Dictionary was successful.", log: OSLog.default, type: .debug)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        //print("DEBUG: called the decoder")
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let petName = aDecoder.decodeObject(forKey: PropertyKey.petName) as? String else {
            //os_log("Unable to decode the name for a Dog object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Because photo, dob and sex are optional properties of Dog,  use conditional cast.
        let photo = aDecoder.decodeObject(forKey: PropertyKey.photo) as? UIImage
        let dob = aDecoder.decodeObject(forKey: PropertyKey.dob) as? Date
        let petSex = aDecoder.decodeObject(forKey: PropertyKey.petSex) as? String
        let vaccineDates = aDecoder.decodeObject(forKey: PropertyKey.vaccineDates) as? Dictionary<String, Array<Date>>
        let recordName = aDecoder.decodeObject(forKey: PropertyKey.recordName) as? String
        let recordChangeTag = aDecoder.decodeObject(forKey: PropertyKey.recordChangeTag) as? String
         //os_log("Decoding the Vaccine Dictionary was successful.>", log: OSLog.default, type: .debug)
        //print(vaccineDates)
        
        /*let decoRemoteRecord = CKRecord(recordType: RemoteRecords.pet, zoneID: ArendK9DB.share.zoneID)
        decoRemoteRecord[RemotePet.petName] = petName as NSString
        decoRemoteRecord[RemotePet.dob] = dob as NSDate?
        decoRemoteRecord[RemotePet.petSex] = petSex as NSString?
        decoRemoteRecord[RemotePet.recordName] = recordName as NSString?
        //decoRemoteRecord[RemotePet.recordChangeTag] = recordChangeTag as NSString?
        //Some special handling to get the UIImage into a CKAsset
        if let photo = photo {
            let imageData:Data = UIImageJPEGRepresentation(photo, 1.0)!
            let path:String = self.documentsDirectoryPath.appendingPathComponent(self.tempImageName)
            try? UIImageJPEGRepresentation(photo, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
            self.imageURL = URL(fileURLWithPath: path)
            try? imageData.write(to: self.imageURL, options: [.atomic])
            let File:CKAsset?  = CKAsset(fileURL: URL(fileURLWithPath: path))
            decoRemoteRecord[RemotePet.photo] = File as! CKAsset
        }*/
        
        //print("DEBUG Decoding record for \(petName) with recordName \(recordName) and  change tag \(recordChangeTag)")
        
        // Must call designated initializer.
        self.init(petName: petName, dob: dob, petSex: petSex, photo: photo, vaccineDates: vaccineDates, recordName: recordName, recordChangeTag: recordChangeTag)
        //self.init(remoteRecord: decoRemoteRecord)
    }
    
    //MARK: Photo conversion
    func photoConverter(photo: UIImage) -> CKAsset{
        //Some special handling to get the UIImage into a CKAsset
            
            let imageData:Data = UIImageJPEGRepresentation(photo, 1.0)!
            let path:String = Pet.documentsDirectoryPath.appendingPathComponent(Pet.tempImageName)
            try? UIImageJPEGRepresentation(photo, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
            Pet.imageURL = URL(fileURLWithPath: path)
            try? imageData.write(to: Pet.imageURL, options: [.atomic])
            let File:CKAsset?  = CKAsset(fileURL: URL(fileURLWithPath: path))
        
        return File!
    }
    
}

