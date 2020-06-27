//
//  ServiceObjectsPlugin.swift
//  Livo
//
//  Created by Deniz Acay on 15/10/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

import Cordova

@objc(ServiceObjectsPlugin) class ServiceObjectsPlugin: CDVPlugin {
    
    let ServiceObjectName = "name"
    let ServiceObjectType = "type"
    let ServiceObjectOperationNames = "operationNames"
   
    func listServiceObjects(command: CDVInvokedUrlCommand) {
        
        log.debug("Listing service objects...")
        
        self.commandDelegate.runInBackground { () -> Void in
            
            // Get the currently cached token
            let token = CacheManager.authenticationToken
            
            // Check if token is nil
            if token == nil {
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: ErrorMessages.ServiceErrors.ServiceObjects.GeneralError)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Create a variable for error
            var error : NSError?
            
            // Get service objects
            let serviceObjects = ServiceHelper.listServiceObjects(token!, error: &error)
            
            // Check for error
            if error != nil {
                
                log.error(error!.localizedDescription)
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error!.localizedDescription)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Create a set for result dictionary objects
            var serviceObjectDicts = NSMutableSet()
            
            // Iterate through the service objects
            for serviceObject in serviceObjects {
                
                serviceObjectDicts.addObject([
                        "name": serviceObject.name,
                        "type": serviceObject.type,
                        "operationNames": serviceObject.operationNames
                    ])
            }
            
            // Create result object
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArray: Array(serviceObjectDicts))
            
            // Send the result
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
        }
    }
    
    func getServiceObject(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate.runInBackground { () -> Void in
            
            // Get arguments
            var serviceObjectName = command.argumentAtIndex(0) as! String?
            var serviceObjectConfiguration = command.argumentAtIndex(1) as! NSDictionary?
            
            // Check service object name
            if serviceObjectName == nil || serviceObjectName!.isEmpty {
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: ErrorMessages.ServiceErrors.ServiceObjects.ServiceObjectNameError)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Sanity check for configuration
            if serviceObjectConfiguration == nil {
                
                log.debug("Substituting an empty configuration for null ServiceObject configuration passed.")
                
                serviceObjectConfiguration = NSDictionary()
            }
            
            log.debug("Configuring service object of type '\(serviceObjectName)'...")
            
            // Get the currently cached token
            let token = CacheManager.authenticationToken
            
            // Check if token is nil
            if token == nil {
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: ErrorMessages.ServiceErrors.ServiceObjects.GeneralError)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Create a variable for error
            var error : NSError?
            
            // Get service objects
            let serviceObject = ServiceHelper.getServiceObject(token!, name: serviceObjectName!, configuration: serviceObjectConfiguration!, error: &error)
            
            // Check for error
            if error != nil {
                
                log.error(error!.localizedDescription)
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error!.localizedDescription)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Convert result ServiceObject to dictionary
            let serviceObjectDict = [
                    "name": serviceObject!.name,
                    "type": serviceObject!.type,
                    "operationNames": serviceObject!.operationNames
                    ]
            
            // Create result object
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: serviceObjectDict)
            
            // Send the result
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
        }
    }
    
    func performOperation(command: CDVInvokedUrlCommand) {

        self.commandDelegate.runInBackground { () -> Void in
            
            // Get arguments
            var serviceObjectDict = command.argumentAtIndex(0) as! NSDictionary?
            var serviceObjectOperationName = command.argumentAtIndex(1) as! String?
            var serviceObjectInputPayloadString = command.argumentAtIndex(2, withDefault: "{}") as! String
            
            // Check service object dictionary
            if serviceObjectDict == nil {
                
                log.error("ServiceObjects to perform operation on is nil.")
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: ErrorMessages.ServiceErrors.ServiceObjects.GeneralError)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Check service object name
            if serviceObjectOperationName == nil || serviceObjectOperationName!.isEmpty {
                
                log.error("Name of the service object operation to perform is nil or empty.")
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: ErrorMessages.ServiceErrors.ServiceObjects.GeneralError)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Get service object name
            let serviceObjectName = serviceObjectDict?.objectForKey("name") as! String
            
            log.debug("Performing operation '\(serviceObjectOperationName)' on ServiceObject of type '\(serviceObjectName)'...")
            
            // Get the currently cached token
            let token = CacheManager.authenticationToken
            
            // Check if token is nil
            if token == nil {
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: ErrorMessages.ServiceErrors.ServiceObjects.GeneralError)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Create a variable for error
            var error : NSError?
            
            // Parse the input payload string
            NSJSONSerialization.JSONObjectWithData(serviceObjectInputPayloadString.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.allZeros, error: &error)
            
            // Check for error
            if error != nil {
                
                log.error("Payload is malformed.")
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error!.localizedDescription)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Create a ServiceObject from the dictionary
            let serviceObject = ServiceObject(name: serviceObjectDict!.objectForKey("name") as! String, type: serviceObjectDict!.objectForKey("type") as! String, operationNames: NSMutableSet(array: serviceObjectDict!.objectForKey("operationNames") as! Array))
            
            // Create input payload
            let inputPayload = ServiceObjectOperationPayload(content: serviceObjectInputPayloadString, contentType: "application/json", rootElement: nil)
            
            // Perform the service object operation
            let resultPayload = ServiceHelper.performOperation(token!, serviceObject: serviceObject, operationName: serviceObjectOperationName!, payload: inputPayload, error: &error)
            
            // Check for error
            if error != nil {
                
                log.debug("ServiceObject operation '\(serviceObjectOperationName)' failed.")
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error!.localizedDescription)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Parse the result dictionary
            let resultDict = NSJSONSerialization.JSONObjectWithData(resultPayload!.content.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.allZeros, error: &error) as! NSDictionary
            
            // Create result object
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: resultDict as [NSObject : AnyObject])
            
            // Check for error
            if error != nil {
                
                log.error("Failed to parse remote payload for operation '\(serviceObjectOperationName)'.")
                
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error!.localizedDescription)
                
                return self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
            
            // Return the result payload
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
        }
    }
}
