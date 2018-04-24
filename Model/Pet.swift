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
    var encodedSystemFields: Data?
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
        static let data = "data"
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
        photo = remoteRecord.object(forKey: RemotePet.photo) as? UIImage
    
      
        guard !petName.isEmpty else {
            return nil
        }

        self.petName = petName
        self.remoteRecord = remoteRecord
        

        //TODO: Initialize other properties
        /*self.dob = remoteRecord.object(forKey: RemotePet.dob) as? Date
        self.petSex = remoteRecord.object(forKey: RemotePet.petSex) as? String
        self.photo = remoteRecord.object(forKey: RemotePet.photo) as? UIImage
        
        
        //TODO: Need to sort out Vaccine Dates
        self.vaccineDates = remoteRecord.object(forKey: RemotePet.vaccineDates) as? Dictionary<String, Array<Date>>
        
 
        
        //TO DO: I need to investigate this one but I took out "|| (petSex == nil)" as the warning stated
        //"Comparing non-option value of type "String" to nil always returns false"
        guard (petSex == "Male") || (petSex == "Female") else{
            return nil
        }*/
        
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
    func save() {
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
         print("Pet Record Saved")
         }
         }*/
        
        
        let saveOperation = CKModifyRecordsOperation(recordsToSave: [remoteRecord!], recordIDsToDelete: nil)
        
        saveOperation.perRecordCompletionBlock = {
            record, error in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Record is \(record)")
                self.remoteRecord = record
            }
        }
        
        ArendK9DB.share.privateDB.add(saveOperation)
        
        // obtain the metadata from the CKRecord
        let data = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: data)
        coder.requiresSecureCoding = true
        remoteRecord?.encodeSystemFields(with: coder)
        coder.finishEncoding()
        
        // store this metadata on your local object
        self.encodedSystemFields = data as Data
        
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self, toFile: Pet.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Pets successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save pets...", log: OSLog.default, type: .error)
        }
        
    }
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("dogs")
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(petName, forKey: PropertyKey.petName)
        aCoder.encode(dob, forKey: PropertyKey.dob)
        aCoder.encode(petSex, forKey: PropertyKey.petSex)
        aCoder.encode(photo, forKey: PropertyKey.photo)
        aCoder.encode(vaccineDates, forKey: PropertyKey.vaccineDates)
        //os_log("Encoding the Vaccine Dictionary was successful.", log: OSLog.default, type: .debug)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
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
        //os_log("Decoding the Vaccine Dictionary was successful.>", log: OSLog.default, type: .debug)
        //print(vaccineDates)
        
        
        // Must call designated initializer.
        self.init(petName: petName, dob: dob, petSex: petSex, photo: photo, vaccineDates: vaccineDates)
        
    }
}

