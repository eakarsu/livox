//
//  Constants.swift
//  Livo
//
//  Created by Deniz Acay on 23/06/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import Foundation

struct Settings {
    
    struct Server {
    
        static let Host : String = "ServerHost"
        static let Port : String = "ServerPort"
    }
    
    struct Authentication {
        
        static let Level : String = "AuthenticationLevel"
        static let Silent : String = "AuthenticationSilent"
    }
    
    struct Application {
        
        static let Identifier : String = "ApplicationId"
    }
    
    struct Privacy {
    
        static let SendUsageData : String = "PrivacySendUsageData"
        static let ReportErrors : String = "PrivacyReportErrors"
    }
}

struct ErrorMessages {
    
    struct ServiceErrors {
        
        struct General {
        
            static var ClientInitializationError : String {
                
                get {
                    
                    return NSLocalizedString("Client initialization failed.", comment: "")
                }
            }
            
            static var ServerUnreachableError : String {
                
                get {
                    
                    return NSLocalizedString("Server is unreachable.", comment: "")
                }
            }
        }
        
        struct FileTransfer {
        
            static var SessionInitiationError : String {
                
                get {
                    
                    return NSLocalizedString("Failed to initiate file transfer session.", comment: "")
                }
            }
            
            static var BucketFetchError : String {
                
                get {
                    
                    return NSLocalizedString("Failed to fetch part of the file.", comment: "")
                }
            }
        }
        
        struct ServiceObjects {
            
            static var GeneralError : String {
                
                get {
                    
                    return NSLocalizedString("ServiceObjects plugin encountered an unexpected error.", comment: "")
                }
            }
            
            static var ServiceObjectNameError : String {
                
                get {
                    
                    return NSLocalizedString("A ServiceObject instance or a ServiceObject name is required.", comment: "")
                }
            }
            
            static var ServiceObjectOperationError : String {
                
                get {
                    
                    return NSLocalizedString("ServiceObject operation failed and returned no data.", comment: "")
                }
            }
        }
    }
    
    struct UpdateErrors {
        
        static var GeneralError : String {
            
            get {
                
                return NSLocalizedString("Update could not be completed.", comment: "")
            }
        }
        
        static var TemporaryDirectoryCreationError : String {
            
            get {
                
                return NSLocalizedString("Failed to create appropriate directory layout.", comment: "")
            }
        }
        
        static var FileWriteError : String {
            
            get {
                
                return NSLocalizedString("Failed to write file to the disk.", comment: "")
            }
        }
    }
    
}

struct EventNames {
    
    static let PlatformUsage = "platformUsed"
}
