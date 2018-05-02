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
    
    //var changeRecords: [CKRecord]?
    //var newRecord: CKRecord? = nil
    //var userRecordName = ""
    
    //DICTIONARIES unordered pair of key, value pairs of vaccines
    var vaccineDates: [String: Array<Date>?]? = [:]
    
    let documentsDirectoryPath:NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    var imageURL: URL!
    let tempImageName = "Image2.jpg"
    
    //MARK: Types
    struct PropertyKey {
        static let petName = "petName"
        static let dob = "dob"
        static let petSex = "petSex"
        static let photo = "photo"
        static let vaccineDates = "vaccineDates"
        static let recordName = "recordID"
        static let recordChangeTag = "recordChangeTag"
    }
    
    //MARK: Initialization
    
    //This init takes a remote record from iClound and creates a Pet
    init?(remoteRecord: CKRecord) {
        
        
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
        
        //print("DEBUG: ID is \(remoteRecord.recordID.recordName)  and record Change Tag is \(remoteRecord.recordChangeTag)")
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
    
    init?(petName: String, dob: Date?, petSex: String?, photo: UIImage?, vaccineDates: Dictionary<String, Array<Date>?>?) {
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
        
    }
    
    convenience init?(petName: String, dob: Date?, petSex: String?, photo: UIImage?){
        
        
        let vDates: [String: Array<Date>?] = [:]
        //print("DEBUG (Convenience) When creating a new dog the vaccine dictionary is: ")
        //print(vDates)
        
        self.init(petName: petName, dob: dob, petSex: petSex, photo: photo, vaccineDates: vDates)
        //os_log("These dogs were initialized with a Vaccine Dictionary.", log: OSLog.default, type: .debug)
    }
    
    //MARK: Save function for iCloud
    //func saveToCloud() -> Pet {
    func saveToCloud(
        completion: @escaping (
        _ results: Pet?,
        _ changeTag: String?,
        _ error: NSError?) -> ())
    {
        
        print("Saving to CloudKit...")
        
        if remoteRecord == nil {
            remoteRecord = CKRecord(recordType: RemoteRecords.pet, zoneID: ArendK9DB.share.zoneID)
        }
        remoteRecord?[RemotePet.petName] = petName as NSString
        remoteRecord?[RemotePet.dob] = dob as NSDate?
        remoteRecord?[RemotePet.petSex] = petSex as NSString?
        
        //TODO: Figure out how to hande the refrence to vaccine dates or store a dictionary
        //remoteRecord?[RemotePet.vaccineDates] = vaccineDates as! Dictionary<String, Array<Date>>?
        
        
        //Some special handling to get the UIImage into a CKAsset
        if let photo = photo {
            
            let imageData:Data = UIImageJPEGRepresentation(photo, 1.0)!
            let path:String = self.documentsDirectoryPath.appendingPathComponent(self.tempImageName)
            try? UIImageJPEGRepresentation(photo, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
            self.imageURL = URL(fileURLWithPath: path)
            try? imageData.write(to: self.imageURL, options: [.atomic])
            
            let File:CKAsset?  = CKAsset(fileURL: URL(fileURLWithPath: path))
            
            remoteRecord?[RemotePet.photo] = File as CKAsset?
        }
        
        
        /*ArendK9DB.share.privateDB.save(remoteRecord!) {
         record, error in
         if let errorDescription = error?.localizedDescription {
         print("Record error: \(errorDescription)")
         } else {
            print("Record is \(record)")
            self.remoteRecord = record
            self.remoteRecord?[RemotePet.recordName] = record?.recordID.recordName as NSString?
            self.recordChangeTag = record?.recordChangeTag as String?
            print("Change tag is \(String(describing: self.remoteRecord?.recordChangeTag))")
            //self.changeRecords = [record] as! [CKRecord]
            }
         }*/
        
        
        let saveOperation = CKModifyRecordsOperation(recordsToSave: [remoteRecord!], recordIDsToDelete: nil)
    
        saveOperation.perRecordCompletionBlock = {
            record, error in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Saving Record to Cloud: \(record)")
                self.remoteRecord = record
                self.remoteRecord?[RemotePet.recordName] = record.recordID.recordName as NSString?
                self.recordChangeTag = record.recordChangeTag as String?
                print("Change tag:  \(String(describing: self.remoteRecord?.recordChangeTag))")
                
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
    
    @objc func saveToLocal(petsToSave: [Pet]) {
        print("Processing local save ...")
        
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(petsToSave, toFile: Pet.ArchiveURL.path)
        
        
        if isSuccessfulSave {
            os_log("Pets successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save pets...", log: OSLog.default, type: .error)
        }
    
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
        print("ENCODING: \(petName) with change tag \(recordChangeTag)")
        //os_log("Encoding the Vaccine Dictionary was successful.", log: OSLog.default, type: .debug)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        print("DEBUG: called the decoder")
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
        
        
        // Must call designated initializer.
        self.init(petName: petName, dob: dob, petSex: petSex, photo: photo, vaccineDates: vaccineDates)
        
    }
}

