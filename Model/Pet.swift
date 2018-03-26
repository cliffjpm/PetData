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
    var remoteRecord: CKRecord? = nil
    var dob: Date?
    var encodedSystemFields: Data?
    //var newRecord: CKRecord? = nil
    //var userRecordName = ""
    
    //MARK: Types
    struct PropertyKey {
        static let petName = "petName"
        static let dob = "dob"
        static let data = "data"
    }
    
    init?(remoteRecord: CKRecord) {
        
        //Note that these values come from Constants
        guard let petName = remoteRecord.object(forKey: RemotePet.petName) as? String
            else {
                return nil
        }
        
        self.petName = petName
        self.remoteRecord = remoteRecord
        
    }
    
    
    init(petName: String) {
        self.petName = petName
        self.dob = Date()
        
    }
    
    init(petName: String, dob: Date) {
        self.petName = petName
        self.dob = dob
    }
    
    func save() {
        if remoteRecord == nil {
            remoteRecord = CKRecord(recordType: RemoteRecords.pet, zoneID: ArendK9DB.share.zoneID)
        }
        remoteRecord?[RemotePet.petName] = petName as NSString
        remoteRecord?[RemotePet.dob] = dob as NSDate?
        
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
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("pets")
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(petName, forKey: PropertyKey.petName)
        aCoder.encode(dob, forKey: PropertyKey.dob)
        aCoder.encode(encodedSystemFields, forKey: PropertyKey.data)
        
        os_log("Encoding the pet was successful.", log: OSLog.default, type: .debug)
        print("The pet record contains \(String(describing: encodedSystemFields))")
        
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let petName = aDecoder.decodeObject(forKey: PropertyKey.petName) as? String else {
            //os_log("Unable to decode the name for a Dog object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let dob = aDecoder.decodeObject(forKey: PropertyKey.dob) as? Date
        
        // Must call designated initializer.
        self.init(petName: petName, dob: dob!)
        
    }
    
}

