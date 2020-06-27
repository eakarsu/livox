//
//  Tweaks.swift
//  Livo
//
//  Created by Deniz Acay on 23/06/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import Foundation

import Tweaks

class TweaksHelper : NSObject, FBTweakObserver {
    
    typealias ActionWithValue = ((currentValue: AnyObject) -> ())

    private static let instance : TweaksHelper = TweaksHelper()
    private static var actionsWithValue = [String:ActionWithValue]()

    class func collectionWithName(collectionName: String, categoryName: String) -> FBTweakCollection {
        
        let store = FBTweakStore.sharedInstance()
        
        var category = store.tweakCategoryWithName(categoryName)
        
        if (category == nil) {
            
            category = FBTweakCategory(name: categoryName)
            
            store.addTweakCategory(category)
        }
        
        var collection = category.tweakCollectionWithName(collectionName)
        
        if (collection == nil) {
            
            collection = FBTweakCollection(name: collectionName)
            
            category.addTweakCollection(collection)
        }
        
        return collection
    }
    
    class func tweakValue<T:AnyObject>(categoryName: String, collectionName: String, name: String, defaultValue: T, minimumValue: T? = nil, maximumValue: T? = nil) -> T {
        
        let id = categoryName.lowercaseString + "." + collectionName.lowercaseString + "." + name
        
        let collection = self.collectionWithName(collectionName, categoryName: categoryName)
        
        var tweak = collection.tweakWithIdentifier(id)
        
        if (tweak == nil) {
            
            tweak = FBTweak(identifier: id)
            tweak.name = name
            tweak.defaultValue = defaultValue
            
            if minimumValue != nil && maximumValue != nil {
                tweak.minimumValue = minimumValue
                tweak.maximumValue = maximumValue
            }
            
            collection.addTweak(tweak)
        }
        
        return (tweak.currentValue ?? tweak.defaultValue) as! T
    }
    
    class func tweakValue(categoryName: String, collectionName: String, name: String, defaultValue: String, minimumValue: String? = nil, maximumValue: String? = nil) -> String {
        
        let id = categoryName.lowercaseString + "." + collectionName.lowercaseString + "." + name
        
        let collection = self.collectionWithName(collectionName, categoryName: categoryName)
        
        var tweak = collection.tweakWithIdentifier(id)
        
        if (tweak == nil) {
            
            tweak = FBTweak(identifier: id)
            tweak.name = name
            tweak.defaultValue = defaultValue
            
            if minimumValue != nil && maximumValue != nil {
                tweak.minimumValue = minimumValue
                tweak.maximumValue = maximumValue
            }
            
            collection.addTweak(tweak)
        }
        
        return (tweak.currentValue ?? tweak.defaultValue) as! String
    }
    
    class func tweakAction<T where T:AnyObject>(categoryName: String, collectionName: String, name: String, action: (currentValue: AnyObject) -> (), defaultValue: T, minimumValue: T? = nil, maximumValue: T? = nil) {
        
        let id = categoryName.lowercaseString + "." + collectionName.lowercaseString + "." + name
        
        let collection = self.collectionWithName(collectionName, categoryName: categoryName)
        
        var tweak = collection.tweakWithIdentifier(id)
        
        if (tweak == nil) {
            
            tweak = FBTweak(identifier: id)
            tweak.name = name
            tweak.defaultValue = defaultValue
            
            if minimumValue != nil && maximumValue != nil {
                tweak.minimumValue = minimumValue
                tweak.maximumValue = maximumValue
            }
            
            tweak.addObserver(instance)
            
            collection.addTweak(tweak)
        }
        
        TweaksHelper.actionsWithValue[id] = action
        
        action(currentValue: tweak.currentValue ?? tweak.defaultValue)
    }
    
    func tweakDidChange(tweak: FBTweak!) {
        
        print("Tweak did change!")
        
        let action = TweaksHelper.actionsWithValue[tweak.identifier]
        
        action?(currentValue: tweak.currentValue ?? tweak.defaultValue)
    }
}