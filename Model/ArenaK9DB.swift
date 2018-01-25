//
//  ArenaK9DB.swift
//  PetData
//
//  Created by Cliff Malcolm Anderson on 1/23/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import Foundation
import CloudKit

class ArendK9DB {
    
    //MARK: Properties
    static let share = ArendK9DB()
    
    var container: CKContainer
    var publicDB: CKDatabase
    var privateDB: CKDatabase
    var sharedDB: CKDatabase
    
    // Use a consistent zone ID across the user's devices
    // CKCurrentUserDefaultName specifies the current user's ID when creating a zone ID
    let zoneID = CKRecordZoneID(zoneName: "ArenaK9", ownerName: CKCurrentUserDefaultName)
    
    //Create Zone Group
    let createZoneGroup = DispatchGroup()
    
    // Store these to disk so that they persist across launches
    var createdCustomZone = false
    var subscribedToPrivateChanges = false
    var subscribedToSharedChanges = false
    
    let privateSubscriptionId = "private-changes"
    let sharedSubscriptionId = "shared-changes"
    
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
    }
    
    func zoneSetup(){
        //print("DEBUG: Zone setup called")
        if !self.createdCustomZone {
            createZoneGroup.enter()
            
            let customZone = CKRecordZone(zoneID: zoneID)
            
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [] )
            
            createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                if (error == nil) { self.createdCustomZone = true }
                // else custom error handling
                self.createZoneGroup.leave()
            }
            createZoneOperation.qualityOfService = .userInitiated
            
            self.privateDB.add(createZoneOperation)
            //self.sharedDB.add(createZoneOperation)
        }
    }
    
    //MARK: Private functions
    
    func dbSubscribeToChange(){
        if !self.subscribedToPrivateChanges {
            let createSubscriptionOperation = createDatabaseSubscriptionOperation(subscriptionId: self.privateSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil {self.subscribedToPrivateChanges = true }
                // else custom error handling
            }
            self.privateDB.add(createSubscriptionOperation)
        }
        
        if !self.subscribedToSharedChanges {
            let createSubscriptionOperation = createDatabaseSubscriptionOperation(subscriptionId: self.sharedSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil { self.subscribedToSharedChanges = true }
                // else custom error handling
            }
            self.sharedDB.add(createSubscriptionOperation)
        }
    }
    
    func createDatabaseSubscriptionOperation(subscriptionId: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionId)
        
        //Silent Notification
        /*let notificationInfo = CKNotificationInfo()
         notificationInfo.shouldSendContentAvailable = true
         subscription.notificationInfo = notificationInfo*/
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertBody = "PetData has updated data available."
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        
        //print("called to create the database subscription")
        
        return operation
    }
    
    func fetchChanges(in databaseScope: CKDatabaseScope, completion: @escaping () -> Void) {
        
        //print("Debug: Fetching Changes")
        switch databaseScope {
        case .private:
            //print("Fetching from Private")
            fetchDatabaseChanges(database: ArendK9DB.share.privateDB, databaseTokenKey: "private", completion: completion)
        case .shared:
            //print("Fetcing from Shared")
            fetchDatabaseChanges(database: ArendK9DB.share.sharedDB, databaseTokenKey: "shared", completion: completion)
        case .public:
            fatalError()
        }
    }
    
    func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: String, completion: @escaping () -> Void) {
        
        var changedZoneIDs: [CKRecordZoneID] = []
        
        var changeToken: CKServerChangeToken?
        if database == ArendK9DB.share.privateDB {
            changeToken = UserDefaults.standard.privateDatabaseServerChangeToken // Read change token from disk
        }
        else if database == ArendK9DB.share.publicDB {
            changeToken = UserDefaults.standard.publicDatabaseServerChangeToken // Read change token from disk
        }
        else if database == ArendK9DB.share.sharedDB {
            changeToken = UserDefaults.standard.sharedDatabaseServerChangeToken // Read change token from disk
        }
        else {
            NSLog("ERROR: #3duNU§ \(database)")
            fatalError()
        }
        
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        
        //print("DEBUG: The new operation is \(operation)")
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
            fatalError()
        }
        
        operation.changeTokenUpdatedBlock = { (token) in
            // Flush zone deletions for this database to disk
            if database == self.privateDB {
                UserDefaults.standard.privateDatabaseServerChangeToken = token // Write this new database change token to memory
            }
            else if database == self.privateDB {
                UserDefaults.standard.publicDatabaseServerChangeToken = token // Write this new database change token to memory
            }
            else if database == self.sharedDB {
                UserDefaults.standard.sharedDatabaseServerChangeToken = token // Write this new database change token to memory
            }
            else {
                NSLog("ERROR: #1xh87hH§ \(database)")
                fatalError()
            }
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            if let error = error {
                print("Error during fetch shared database changes operation", error)
                completion()
                return
            }
            // Flush zone deletions for this database to disk
            if database == self.privateDB {
                UserDefaults.standard.privateDatabaseServerChangeToken = token // Write this new database change token to memory
            }
            else if database == self.privateDB {
                UserDefaults.standard.publicDatabaseServerChangeToken = token // Write this new database change token to memory
            }
            else if database == self.sharedDB {
                UserDefaults.standard.sharedDatabaseServerChangeToken = token // Write this new database change token to memory
            }
            else {
                NSLog("ERROR: #Q§D0=ZTdb4§ \(database)")
                fatalError()
            }
            
            self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {
                if database == self.privateDB {
                    UserDefaults.standard.privateDatabaseServerChangeToken = token // Write this new database change token to disk
                }
                else if database == self.privateDB {
                    UserDefaults.standard.publicDatabaseServerChangeToken = token // Write this new database change token to disk
                }
                else if database == self.sharedDB {
                    UserDefaults.standard.sharedDatabaseServerChangeToken = token // Write this new database change token to disk
                }
                else {
                    NSLog("ERROR: #3duNU§ \(database)")
                    fatalError()
                }
                completion()
            }
        }
        
        
        operation.qualityOfService = .userInitiated
        
        database.add(operation)
    }
    
    
    func fetchZoneChanges(database: CKDatabase, databaseTokenKey: String, zoneIDs: [CKRecordZoneID], completion: @escaping () -> Void) {
        
        // Look up the previous change token for each zone
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        for zoneID in zoneIDs {
            let options = CKFetchRecordZoneChangesOptions()
            switch zoneID.zoneName {
            case "ArenaK9":
                options.previousServerChangeToken = UserDefaults.standard.ArenaK9ServerChangeToken // Read change token from disk
            default:
                options.previousServerChangeToken = UserDefaults.standard.defaultZoneServerChangeToken // Read change token from disk
            }
            optionsByRecordZoneID[zoneID] = options
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
        
        operation.recordChangedBlock = { (record) in
            print("Record changed:", record)
            // Write this record change to memory
            switch record.recordType {
            case "Pet": break
            default:
                NSLog("ERROR: #5f67gJ2 unsupported type: \(record.recordType)")
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { (recordId, str) in
            print("Record deleted:", recordId)
            // Write this record deletion to memory
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            switch zoneId.zoneName {
            case "ArenaK9":
                UserDefaults.standard.ArenaK9ServerChangeToken = token // Write this new zone change token to disk
            default:
                UserDefaults.standard.defaultZoneServerChangeToken = token // Write this new zone change token to disk
            }
        }
        
        operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
            
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                return
            }
            // Flush record changes and deletions for this zone to disk
            switch zoneId.zoneName {
            case "ArenaK9":
                UserDefaults.standard.ArenaK9ServerChangeToken = changeToken // Write this new zone change token to disk
            default:
                UserDefaults.standard.defaultZoneServerChangeToken = changeToken // Write this new zone change token to disk
            }
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
            }
            completion()
        }
        
        database.add(operation)
    }
}

//MARK: Extension of UserDefaults to store Tokens
extension UserDefaults {
    
    public var sharedDatabaseServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "SharedDatabaseServerChangeToken") as? Data else {
                return nil
            }
            
            guard let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
                return nil
            }
            Swift.print("SharedDatabaseServerChangeToken: \(token)")
            
            return token
        }
        set {
            if let token = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                self.set(data, forKey: "SharedDatabaseServerChangeToken")
            } else {
                self.removeObject(forKey: "SharedDatabaseServerChangeToken")
            }
        }
    }
    
    public var publicDatabaseServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "PublicDatabaseServerChangeToken") as? Data else {
                return nil
            }
            
            guard let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
                return nil
            }
            Swift.print("PublicDatabaseServerChangeToken: \(token)")
            
            return token
        }
        set {
            if let token = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                self.set(data, forKey: "PublicDatabaseServerChangeToken")
            } else {
                self.removeObject(forKey: "PublicDatabaseServerChangeToken")
            }
        }
    }
    
    public var privateDatabaseServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "PrivateDatabaseServerChangeToken") as? Data else {
                return nil
            }
            
            guard let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
                return nil
            }
            Swift.print("PrivateDatabaseServerChangeToken: \(token)")
            
            return token
        }
        set {
            if let token = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                self.set(data, forKey: "PrivateDatabaseServerChangeToken")
            } else {
                self.removeObject(forKey: "PrivateDatabaseServerChangeToken")
            }
        }
    }
    
    public var ArenaK9ServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "ArenaK9ServerChangeToken") as? Data else {
                return nil
            }
            
            guard let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
                return nil
            }
            Swift.print("ArenaK9ServerChangeToken: \(token)")
            
            return token
        }
        set {
            if let token = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                self.set(data, forKey: "ArenaK9ServerChangeToken")
            } else {
                self.removeObject(forKey: "ArenaK9ServerChangeToken")
            }
        }
    }
    
    public var defaultZoneServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "DefaulZoneServerChangeToken") as? Data else {
                return nil
            }
            
            guard let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
                return nil
            }
            Swift.print("DefaulZoneServerChangeToken: \(token)")
            return token
        }
        set {
            if let token = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                self.set(data, forKey: "DefaultZoneServerChangeToken")
            } else {
                self.removeObject(forKey: "DefaultZoneServerChangeToken")
            }
        }
    }
}


