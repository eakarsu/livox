//
//  CacheManager.swift
//  Livo
//
//  Created by Deniz Acay on 13/08/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

class CacheManager: NSObject {
   
    static var localProfile : Profile? {
        
        get {
        
            let localProfileData = NSUserDefaults.standardUserDefaults().dataForKey("LocalProfile")
        
            if localProfileData == nil {
        
                return nil
            }
        
            return NSKeyedUnarchiver.unarchiveObjectWithData(localProfileData!) as! Profile!
        }
        
        set(newVal) {
            
            if newVal == nil {
                
                NSUserDefaults.standardUserDefaults().removeObjectForKey("LocalProfile")
                
                NSUserDefaults.standardUserDefaults().synchronize()
                
                return
            }
            
            let localProfileData = NSKeyedArchiver.archivedDataWithRootObject(newVal!)
            
            NSUserDefaults.standardUserDefaults().setObject(localProfileData, forKey: "LocalProfile")
            
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    static var authenticationToken : AuthenticationToken? {
        
        get {
        
            let tokenData = NSUserDefaults.standardUserDefaults().dataForKey("AuthenticationToken")
        
            if tokenData == nil {
        
                return nil
            }
        
            return NSKeyedUnarchiver.unarchiveObjectWithData(tokenData!) as! AuthenticationToken!
        }
        
        set(newVal) {
            
            if newVal == nil {
                
                NSUserDefaults.standardUserDefaults().setNilValueForKey("AuthenticationToken")
                
                NSUserDefaults.standardUserDefaults().removeObjectForKey("AuthenticationToken")
                
                NSUserDefaults.standardUserDefaults().synchronize()
                
                return
            }
            
            let tokenData = NSKeyedArchiver.archivedDataWithRootObject(newVal!)
            
            NSUserDefaults.standardUserDefaults().setObject(tokenData, forKey: "AuthenticationToken")
            
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
}
