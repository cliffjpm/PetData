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
    
    // Store these to disk so that they persist across launches
    var createdCustomZone = false
    var subscribedToPrivateChanges = false
    var subscribedToSharedChanges = false
    
    let privateSubscriptionId = "private-changes"
    let sharedSubscriptionId = "shared-changes"
    
    //Create Custom Zone
    let createZoneGroup = DispatchGroup()
    
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
    }
    
    func zoneSetup(){
        print("DEBUG: Zone setup called")
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
        
        print("called to create the database subscription")
        
        return operation
    }

    func fetchChanges(in databaseScope: CKDatabaseScope, completion: @escaping () -> Void) {
        
        print("Debug: Fetching Changes")
        switch databaseScope {
        case .private:
            print("Fetching from Private")
            fetchDatabaseChanges(database: ArendK9DB.share.privateDB, databaseTokenKey: "private", completion: completion)
        case .shared:
            print("Fetcing from Shared")
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
        
        print("DEBUG: The new operation is \(operation)")
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
    
    public var customZone1ServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "CustomZone1ServerChangeToken") as? Data else {
                return nil
            }
            
            guard let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
                return nil
            }
            Swift.print("CustomZone1ServerChangeToken: \(token)")
            
            return token
        }
        set {
            if let token = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                self.set(data, forKey: "CustomZone1ServerChangeToken")
            } else {
                self.removeObject(forKey: "CustomZone1ServerChangeToken")
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


