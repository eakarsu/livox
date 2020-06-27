//
//  ServiceHelper.swift
//  Livo
//
//  Created by Deniz Acay on 31/07/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit
import CoreData

import Tweaks

class ServiceHelper: NSObject {
    
    private static var serviceClient : ServiceClient?
    private static var authenticationQueue : NSOperationQueue = {
        
        var queue = NSOperationQueue()
        
        queue.name = "AuthenticationQueue"
        
        return queue
        }()
    private static var updateQueue : NSOperationQueue = {
        
        var queue = NSOperationQueue()
        
        queue.name = "UpdateQueue"
        queue.maxConcurrentOperationCount = 3
        
        return queue
        }()
    private static var once = dispatch_once_t()
    
    static func authenticateCompany(companyId: String, companySecret: String, success: (token: AuthenticationToken!) -> Void, error: (message: String?) -> Void) -> NSOperation? {
        
        if !serverReachable() {
            
            error(message: ErrorMessages.ServiceErrors.General.ServerUnreachableError)
            
            return nil
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                let message = ErrorMessages.ServiceErrors.General.ClientInitializationError
                
                error(message: message)
                
                return nil
            }
        }
        
        let authenticationOperation = CompanyAuthenticationOperation(serviceClient: serviceClient, companyId: companyId, companySecret: companySecret, success: success, error: error)
        
        authenticationQueue.addOperation(authenticationOperation)
        
        return authenticationOperation
    }
    
    static func authenticateUser(token: AuthenticationToken, userPrincipal: String, userCredentials: String, success: (token: AuthenticationToken!) -> Void, error: (message: String?) -> Void) -> NSOperation? {
        
        if !serverReachable() {
            
            error(message: ErrorMessages.ServiceErrors.General.ServerUnreachableError)
            
            return nil
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                let message = ErrorMessages.ServiceErrors.General.ClientInitializationError
                
                error(message: message)
                
                return nil
            }
        }
        
        let authenticationOperation = UserAuthenticationOperation(serviceClient: serviceClient, token: token, userPrincipal: userPrincipal, userCredentials: userCredentials, success: success, error: error)
        
        authenticationQueue.addOperation(authenticationOperation)
        
        return authenticationOperation
    }
    
    static func authenticateDevice(token: AuthenticationToken, success: (token: AuthenticationToken!) -> Void, error: (message: String?) -> Void) -> NSOperation? {
        
        if !serverReachable() {
            
            error(message: ErrorMessages.ServiceErrors.General.ServerUnreachableError)
            
            return nil
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                let message = ErrorMessages.ServiceErrors.General.ClientInitializationError
                
                error(message: message)
                
                return nil
            }
        }
        
        let deviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
        
        log.debug("Using device ID '\(deviceId)' for authenticationg...")
        
        let authenticationOperation = DeviceAuthenticationOperation(serviceClient: serviceClient, token: token, deviceId: deviceId, success: success, error: error);
        
        authenticationQueue.addOperation(authenticationOperation)
        
        return authenticationOperation
    }
    
    static func checkProvision(token: AuthenticationToken, applicationId: String, localProfile: Profile?, success: (remoteProfile: Profile?) -> Void, error: (message: String?) -> Void) -> NSOperation? {
        
        if !serverReachable() {
            
            error(message: ErrorMessages.ServiceErrors.General.ServerUnreachableError)
            
            return nil
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                let message = ErrorMessages.ServiceErrors.General.ClientInitializationError
                
                error(message: message)
                
                return nil
            }
        }
        
        let provisionCheckOperation = ProvisionCheckOperation(serviceClient: serviceClient, token: token, applicationId: applicationId, localProfile: localProfile, success: success, error: error)
        
        updateQueue.addOperation(provisionCheckOperation)
        
        return provisionCheckOperation
    }
    
    static func downloadFile(file: File, directory: NSURL, progress: (session: FileTransferSession!) -> Void, success: (file: File!) -> Void, error: (message: String?) -> Void) -> NSOperation? {
        
        if !serverReachable() {
            
            error(message: ErrorMessages.ServiceErrors.General.ServerUnreachableError)
            
            return nil
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                let message = ErrorMessages.ServiceErrors.General.ClientInitializationError
                
                error(message: message)
                
                return nil
            }
        }
        
        let fileDownloadOperation = FileDownloadOperation(serviceClient: serviceClient, file: file, directory: directory, progress: progress, success: success, error: error)
        
        updateQueue.addOperation(fileDownloadOperation)
        
        return fileDownloadOperation
    }
    
    static func listServiceObjects(token: AuthenticationToken, inout error: NSError?) -> Set<ServiceObject> {
        
        if !serverReachable() {
            
            error = NSError(domain: "ServiceErrors.General", code: 1, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.ServiceErrors.General.ServerUnreachableError])
            
            return Set()
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                error = NSError(domain: "ServiceErrors.General", code: 0, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.ServiceErrors.General.ClientInitializationError])
                
                return Set()
            }
        }
        
        let objs = self.serviceClient!.listServiceObjects(token)
        
        return objs as! Set<ServiceObject>
    }
    
    static func getServiceObject(token: AuthenticationToken, name: String, configuration: NSDictionary, inout error: NSError?) -> ServiceObject? {
        
        if !serverReachable() {
            
            error = NSError(domain: "ServiceErrors.General", code: 1, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.ServiceErrors.General.ServerUnreachableError])
            
            return nil
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                error = NSError(domain: "ServiceErrors.General", code: 0, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.ServiceErrors.General.ClientInitializationError])
                
                return nil
            }
        }
        
        return self.serviceClient!.getServiceObject(token, name: name, configuration: configuration as [NSObject : AnyObject])
    }
    
    static func performOperation(token: AuthenticationToken, serviceObject: ServiceObject, operationName: String, payload: ServiceObjectOperationPayload, inout error: NSError?) -> ServiceObjectOperationPayload? {
        
        if !serverReachable() {
            
            error = NSError(domain: "ServiceErrors.General", code: 1, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.ServiceErrors.General.ServerUnreachableError])
            
            return nil
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
                
                error = NSError(domain: "ServiceErrors.General", code: 0, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.ServiceErrors.General.ClientInitializationError])
                
                return nil
            }
        }
        
        let resultPayload : ServiceObjectOperationPayload? = self.serviceClient!.performOperation(token, object: serviceObject, operationName: operationName, payload: payload)
        
        if resultPayload == nil {
            
            error = NSError(domain: "ServiceErrors.ServiceObjects", code: 1, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.ServiceErrors.ServiceObjects.ServiceObjectOperationError])
        }
        
        return resultPayload
    }
    
    static func isOptedIn(token: AuthenticationToken) -> Bool {
        
        objc_sync_enter(serviceClient)

        let result = self.serviceClient!.isOptedIn(token);
        
        objc_sync_exit(serviceClient)
        
        return result
    }
    
    static func logPlatformUsage(token: AuthenticationToken) -> Void {
        
        if !serverReachable() {
            
            return
        }
        
        if serviceClient == nil || clientOutOfDate() {
            
            if !initializeClient() {
    
                return
            }
        }
        
        if !isOptedIn(token) {
            
            log.debug("User is opted out; ignoring analytics requests.")
            
            return
        }
        
        if !queueEvent(UIDevice.currentDevice().identifierForVendor!.UUIDString, name: EventNames.PlatformUsage, startDate: NSDate(), endDate: nil, parameters: ["platform": "iOS"]) {
            
            log.error("Failed to queue event for platform usage.")
        }
    }
    
    static func synchronizeEvents() {
        
        log.debug("Synchronizing events...")
    }
    
    private static func initializeClient() -> Bool {
        
        let serverHost : String? = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)
        let serverPort : Int? = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        if serverHost == nil || serverPort == nil || serverPort <= 0 {
            
            NSLog("Server settings are invalid.")
            
            return false
        }
        
        serviceClient = ServiceClient(serverHost: serverHost, serverPort: serverPort)
        
        // Schedule the timer once
        dispatch_once(&once) {
            
            NSTimer.scheduledTimerWithTimeInterval(60, target: ServiceHelper.self, selector: "synchronizeEvents", userInfo: nil, repeats: true)
        }
        
        return true
    }
    
    private static func serverReachable() -> Bool {
        
        let serverHost : String? = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)
        
        return Reachability(hostname: serverHost).isReachable()
    }
    
    private static func clientOutOfDate() -> Bool {
        
        let serverHost : String? = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)
        let serverPort : Int? = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        return serviceClient?.serverHost != serverHost || serviceClient?.serverPort != serverPort
    }
    
    private static func queueEvent(id: String, name: String, startDate: NSDate, endDate: NSDate?, parameters: Dictionary<String,String>?) -> Bool {
        
        log.debug("Creating event record for type '\(name)' with ID '\(id)'...")
        
        log.debug("Retrieving managed object context...")
        
        let objectCtx = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        log.debug("Creating EventRecord managed object inserted into the context created...")
        
        let entity = NSEntityDescription.entityForName("EventRecord", inManagedObjectContext: objectCtx)
        let record = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: objectCtx) as! EventRecord

        log.debug("Setting record properties...")

        record.id = id
        record.name = name
        record.startDate = startDate
        
        if endDate != nil {
            
            record.endDate = endDate!
        }
        
        if parameters != nil {
            
            record.parameters = NSKeyedArchiver.archivedDataWithRootObject(parameters!)
        }
        
        log.debug("Saving record of type '\(name)' with ID '\(id)'...")
        
        do {
            
            try objectCtx.save()
            
        } catch let error as NSError {
            
            log.error("Failed to save record with ID '\(id)'.")
            
            log.error("\(error)")
            
            return false
            
        } catch {
            
            log.error("Failed to save record with ID '\(id)'.")
            
            return false
        }
        
        log.debug("Successfully saved event record with ID '\(id)'.")
        
        return true
    }
}

class CompanyAuthenticationOperation : NSBlockOperation {
    
    private let serviceClient : ServiceClient!
    private let companyId : String!
    private let companySecret : String!
    private let success : (token: AuthenticationToken!) -> Void
    private let error : (message: String?) -> Void
    
    init(serviceClient: ServiceClient!, companyId: String!, companySecret: String!, success: (token: AuthenticationToken!) -> Void, error: (message: String?) -> Void) {
        
        self.serviceClient = serviceClient
        
        self.companyId = companyId
        self.companySecret = companySecret
        
        self.success = success
        self.error = error
    }
    
    override func main() {
        
        objc_sync_enter(self.serviceClient)
        
        self.serviceClient.authenticateCompany(self.companyId, companySecret: self.companySecret, success: { (token: AuthenticationToken!) -> Void in
            
            if !self.cancelled {
                
                self.success(token: token)
            }
            
        }) { (message: String!) -> Void in
                
            if !self.cancelled {
                    
                self.error(message: message)
            }
        }
        
        objc_sync_exit(self.serviceClient)
    }
}

class UserAuthenticationOperation : NSBlockOperation {
    
    private let serviceClient : ServiceClient!
    private let authenticationToken : AuthenticationToken!
    private let userPrincipal : String!
    private let userCredentials : String!
    private let success : (token: AuthenticationToken!) -> Void
    private let error : (message: String?) -> Void
    
    init(serviceClient: ServiceClient!, token: AuthenticationToken!, userPrincipal: String!, userCredentials: String!, success: (token: AuthenticationToken!) -> Void, error: (message: String?) -> Void) {
        
        self.serviceClient = serviceClient
        
        self.authenticationToken = token
        
        self.userPrincipal = userPrincipal
        self.userCredentials = userCredentials
        
        self.success = success
        self.error = error
    }
    
    override func main() {
        
        objc_sync_enter(self.serviceClient)
        
        self.serviceClient.authenticateUser(self.authenticationToken, userPrincipal: self.userPrincipal, userCredentials: self.userCredentials, success: { (token: AuthenticationToken!) -> Void in
            
            if !self.cancelled {
                
                self.success(token: token)
            }
            
            }) { (message: String!) -> Void in
                
                if !self.cancelled {
                    
                    self.error(message: message)
                }
        }
        
        objc_sync_exit(self.serviceClient)
    }
}

class DeviceAuthenticationOperation : NSBlockOperation {
    
    private let serviceClient : ServiceClient!
    private let authenticationToken : AuthenticationToken!
    private let deviceId : String!
    private let success : (token: AuthenticationToken!) -> Void
    private let error : (message: String?) -> Void
    
    init(serviceClient: ServiceClient!, token: AuthenticationToken!, deviceId: String!, success: (token: AuthenticationToken!) -> Void, error: (message: String?) -> Void) {
        
        self.serviceClient = serviceClient
        
        self.authenticationToken = token
        
        self.deviceId = deviceId
        
        self.success = success
        self.error = error
    }
    
    override func main() {
        
        objc_sync_enter(self.serviceClient)
        
        self.serviceClient.authenticateDevice(self.authenticationToken, deviceId: self.deviceId, success: { (token: AuthenticationToken!) -> Void in
            
            if !self.cancelled {
                
                self.success(token: token)
            }
            
            }) { (message: String!) -> Void in
                
                if !self.cancelled {
                    
                    self.error(message: message)
                }
        }
        
        objc_sync_exit(self.serviceClient)
    }
}

class ProvisionCheckOperation : NSBlockOperation {
    
    private let serviceClient : ServiceClient!
    private let authenticationToken : AuthenticationToken!
    private let applicationId : String!
    private let localProfile : Profile!
    private let success : (remoteProfile: Profile!) -> Void
    private let error : (message: String?) -> Void
    
    init(serviceClient: ServiceClient!, token: AuthenticationToken!, applicationId: String!, localProfile: Profile!, success: (remoteProfile: Profile!) -> Void, error: (message: String?) -> Void) {
        
        self.serviceClient = serviceClient
        
        self.authenticationToken = token
        
        self.applicationId = applicationId
        
        self.localProfile = localProfile
        
        self.success = success
        self.error = error
    }
    
    override func main() {
        
        objc_sync_enter(self.serviceClient)

        self.serviceClient.checkProvision(self.authenticationToken, applicationId: self.applicationId, localProfile: self.localProfile, success: { (remoteProfile: Profile!) -> Void in
            
            if !self.cancelled {
                
                self.success(remoteProfile: remoteProfile)
            }
            
        }) { (message: String!) -> Void in
            
            if !self.cancelled {
                
                self.error(message: message)
            }
        }
        
        objc_sync_exit(self.serviceClient)
    }
}

class FileDownloadOperation : NSBlockOperation {
    
    private let serviceClient : ServiceClient!
    private let directory : NSURL!
    private let file : File!
    private let progressBlock : (session: FileTransferSession!) -> Void
    private let errorBlock : (message: String?) -> Void
    private let successBlock : (file: File!) -> Void
    private var error : NSError?
    
    init(serviceClient: ServiceClient!, file: File!, directory: NSURL!, progress: (session: FileTransferSession!) -> Void, success: (file: File!) -> Void, error: (message: String?) -> Void) {
        
        self.serviceClient = serviceClient
        
        self.file = file
        
        self.directory = directory
        
        self.progressBlock = progress
        
        self.errorBlock = error
        
        self.successBlock = success
        
        super.init()
        
        self.completionBlock = {
            
            if self.error == nil {
                
                self.successBlock(file: self.file)
            }
        }
    }
    
    override func main() {
        
        // Check if the operation is cancelled
        if self.cancelled { return }
        
        // Calculate the file URL
        let fileUrl = calculateFileURL()
        
        // Create parent directories for file
        do {
            
            try NSFileManager.defaultManager().createDirectoryAtURL(fileUrl.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)

        } catch let error as NSError {
            
            log.error("Failed to create intermediate directories for file '\(self.file.path)'.")
            
            log.error("\(error.description)")
            
            return
            
        } catch {
            
            log.error("Failed to create intermediate directories for file '\(self.file.path)'.")
            
            return
        }
        
        // Check if the operation is cancelled
        if self.cancelled { return }
        
        // Initiate session
        let session = self.initiateSession()
        
        // Check the session
        if session == nil {
            
            NSLog("Failed to initiate session for file '%@'.", self.file.path)
            
            // Handle the error
            self.handleError(ErrorMessages.ServiceErrors.FileTransfer.SessionInitiationError, error: nil)
            
            // Stop further execution
            return
        }

        // Check if the operation is cancelled
        if self.cancelled {
            
            NSLog("Download operation cancelled file for file '%@'; stopping further execution.", self.file.path);
            
            // Destroy the session
            self.destroySession(session!)
            
            return
        }
        
        NSLog("File '%@' will be downloaded to local path '%@'.", self.file.path, fileUrl);
        
        // Create the file stream
        let stream = NSOutputStream(toFileAtPath: fileUrl.path!, append: false)
        
        // Open the stream
        stream!.open()
        
        // Start fetching buckets
        for session!.currentIndex; session!.currentIndex < session!.bucketCount; session!.currentIndex++ {
            
            // Check if the operation is cancelled
            if self.cancelled {
                
                NSLog("Operation is cancelled; stopping downloading file '%@'...", self.file.path)
                
                // Close stream
                stream!.close()
                
                // Destroy session
                self.destroySession(session!)
                
                return
            }
            
            // Fetch the current bucket
            let data = self.fetchBucket(session!)
            
            // Check data
            if data.length == 0 {
                
                NSLog("Failed to fetch bucket %ld of %ld for file '%@'.", session!.currentIndex, session!.bucketCount, session!.file.hash)
                
                // Close stream
                stream!.close()
                
                // Destroy the session
                self.destroySession(session!)
                
                // Handle the error
                self.handleError(ErrorMessages.ServiceErrors.FileTransfer.BucketFetchError, error: nil)
                
                // Stop further execution
                return
            }
            
            NSLog("Writing bucket %lld of %lld...", session!.currentIndex, session!.bucketCount)
            
            // Write data to the file stream
            let bw = stream!.write(UnsafePointer(data.bytes), maxLength: data.length)
            
            log.debug("Number of bytes written: \(bw)")
            
            if bw == -1 {
                
                log.error("Failed to write to stream.")
                
                break
            }
            
            // Call the progress block
            self.progressBlock(session: session)
        }
        
        // Close stream
        stream!.close()
        
        NSLog("Completed downloading file '%@'.", self.file.path)
        
        // Destroy the session
        self.destroySession(session!)
    }
    
    private func initiateSession() -> FileTransferSession? {
        
        NSLog("Initiating transfer session for file '%@'...", self.file.path)
        
        objc_sync_enter(self.serviceClient)
        
        let session = self.serviceClient.initiateSession(self.file, bucketSize: TweaksHelper.tweakValue("Update", collectionName: "Downloads", name: "Bucket Size", defaultValue: 1000000, minimumValue: 1000, maximumValue: 1000000000).longLongValue);
        
        objc_sync_exit(self.serviceClient)
        
        return session
    }
    
    private func destroySession(session: FileTransferSession) {
        
        NSLog("Destroying transfer session for file '%@'...", self.file.path)
        
        objc_sync_enter(self.serviceClient)
        
        self.serviceClient.destroySession(session)

        objc_sync_exit(self.serviceClient)
    }
    
    private func fetchBucket(session: FileTransferSession) -> NSData! {
        
        NSLog("Fetching bucket %lld of %lld for file '%@'...", session.currentIndex+1, session.bucketCount, session.file.path)

        objc_sync_enter(self.serviceClient)
        
        let data = self.serviceClient.fetchBucket(session)
        
        objc_sync_exit(self.serviceClient)
        
        return data
    }
    
    private func handleError(message: String, error: NSError?) {
        
        NSLog("Handling error encountered during download operation of file '%@'...", self.file.path)
        
        // Cancel this operation
        self.cancel()
        
        // Set the error field to indicate an error
        self.error = error ?? NSError(domain: "", code: 0, userInfo: nil)
        
        // Call the error block
        self.errorBlock(message: message)
    }
    
    private func calculateFileURL() -> NSURL {
        
        return self.directory.URLByAppendingPathComponent(self.file.path)
    }
}