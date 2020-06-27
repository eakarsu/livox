//
//  FileSystemHelper.swift
//  Livo
//
//  Created by Deniz Acay on 21/10/15.
//  Copyright © 2015 Livo Mobile. All rights reserved.
//

import UIKit

class FileSystemHelper: NSObject {
    
    enum FileSystemError : ErrorType {
        
        case NoApplicationSupportDirectory
        case FailedToRemoveFile(file: NSURL)
        case FailedToCreateDirectory(directory: NSURL)
        case FailedToListDirectoryContents(directory: NSURL)
        case FailedToCopyFile(source: NSURL, target: NSURL)
        case FileNotUnderDirectory(file: NSURL, directory: NSURL)
    }
    
    static func applicationDirectory() throws -> NSURL {
        
        // Get application support directory
        let appSupportDirectory = try applicationSupportDirectory()
        
        // Calculate path relative to the support directory
        let appDirectory = appSupportDirectory.URLByAppendingPathComponent("app", isDirectory: true)
        
        log.info("Using application directory '\(appDirectory)'...")
        
        // Ensure that the directory exists
        try ensureDirectoryExists(appDirectory)
        
        // Return the directory
        return appDirectory
    }
    
    static func applicationFile(filePath: String) throws -> NSURL {
        
        // Get the application base directory
        let appDirectory = try applicationDirectory()
        
        // Calculate the file URL
        let fileUrl = appDirectory.URLByAppendingPathComponent(filePath)
        
        log.debug("Calculated application file path for '\(filePath)' is '\(fileUrl.relativePath)'.")
        
        // Return the URL
        return fileUrl
    }
    
    static func copyContentsOfDirectory(sourceDirectory: NSURL, targetDirectory: NSURL) throws {
        
        // Ensure that the target directory exists
        try ensureDirectoryExists(targetDirectory)
        
        // Get the contents of the source directory
        let sourceFiles = try contentsOfDirectory(sourceDirectory)
        
        // Copy each source file to the target directory
        for sourceFile in sourceFiles {
            
            do {
                
                // Get the path of the source file relative to the source directory
                let relativePath = try pathRelativeToDirectory(sourceFile, directory: sourceDirectory)
                
                // Calculate the target URL
                let targetFile = targetDirectory.URLByAppendingPathComponent(relativePath)
                
                try NSFileManager.defaultManager().copyItemAtURL(sourceFile, toURL: targetFile)
                
            } catch let error as NSError {
                
                log.error("Failed to copy file '\(sourceFile.relativePath)' to the destination directory '\(targetDirectory.relativePath)'.")
                
                log.error("\(error)")
                
                throw FileSystemError.FailedToCopyFile(source: sourceFile, target: targetDirectory)
            }
        }
    }
    
    static func clearApplicationDirectory() throws {
        
        log.debug("Clearing application directory...")
        
        // Get the application directory
        let appDirectory = try applicationDirectory()
        
        // Clear the application directory
        try clearDirectory(appDirectory)
    }
    
    static func clearTemporaryDirectory() throws {
        
        log.debug("Clearing temporary directory...")
        
        // Get the application temporary directory
        let temporaryDirectory = applicationTemporaryDirectory()
        
        // Clear the application temporary directory
        try clearDirectory(temporaryDirectory)
    }
    
    static func createRandomTemporaryDirectory() throws -> NSURL {
        
        // Get a globally unique string for process
        let uniqueString = NSProcessInfo.processInfo().globallyUniqueString
        
        // Calculate path relative to the application temporary directory
        let temporaryDirectory = applicationTemporaryDirectory().URLByAppendingPathComponent(uniqueString, isDirectory: true)
        
        log.debug("Creating temporary directory at '\(temporaryDirectory)'...")
        
        // Try to create the directory
        do {
            
            try NSFileManager.defaultManager().createDirectoryAtURL(temporaryDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Return the temporary directory
            return temporaryDirectory
            
        } catch let error as NSError {
            
            log.error("Failed to create temporary directory at '\(temporaryDirectory.relativePath)'.")
            
            log.error("\(error.description)")
            
            throw FileSystemError.FailedToCreateDirectory(directory: temporaryDirectory)
        }
    }
    
    private static func pathRelativeToDirectory(file: NSURL, directory: NSURL) throws -> String {
        
        // Calculate the common prefix of paths
        let prefix = file.path!.commonPrefixWithString(directory.path!, options: .AnchoredSearch)
        
        // Sanity check
        if prefix != directory.path! {
            
            log.error("File '\(file.path!)' is not under the directory '\(directory.path!)'.")
            
            throw FileSystemError.FileNotUnderDirectory(file: file, directory: directory)
        }
        
        // Create an index to extract substring from
        let index = file.path!.startIndex.advancedBy(prefix.characters.count)
        
        // Extract the substring
        let relativePath = file.path!.substringFromIndex(index)
        
        // Return the relative path
        return relativePath
    }
    
    private static func ensureDirectoryExists(directory: NSURL) throws {
        
        log.debug("Ensuring directory '\(directory.relativePath)' exists...")
        
        // Check if directory exists
        var isDirectory : ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(directory.path!, isDirectory: &isDirectory) && isDirectory {
            
            log.debug("Directory '\(directory.relativePath) exists.'")
            
            return
        }
        
        log.debug("Creating directory at '\(directory.relativePath)'...")

        // Try to create the directory
        do {
            
            try NSFileManager.defaultManager().createDirectoryAtURL(directory, withIntermediateDirectories: true, attributes: nil)
            
        } catch let error as NSError {
            
            log.error("Failed to create directory at '\(directory.relativePath)'.")
            
            log.error("\(error.description)")
            
            throw FileSystemError.FailedToCreateDirectory(directory: directory)
        }
    }
    
    private static func clearDirectory(directory: NSURL) throws {
        
        // List the contents of the directory
        let files = try contentsOfDirectory(directory)
        
        // Iterate through the directory files
        for file in files {
            
            do {
                
                try NSFileManager.defaultManager().removeItemAtURL(file)
                
            } catch let error as NSError {
                
                log.error("Failed to remove file at '\(file)'.")
                
                log.error("\(error)")
                
                throw FileSystemError.FailedToRemoveFile(file: file)
            }
        }
    }
    
    private static func contentsOfDirectory(directory: NSURL) throws -> Array<NSURL> {
        
        // List the contents of the directory
        do {
            
            let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(directory, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.init(rawValue: 0))
            
            return contents
            
        } catch let error as NSError {
            
            log.error("Failed to list the contents of the directory '\(directory)'.")
            
            log.error("\(error)")
            
            throw FileSystemError.FailedToListDirectoryContents(directory: directory)
        }
    }

    private static func applicationSupportDirectory() throws -> NSURL {
        
        // Get possible application support directories
        let appSupportDirectories = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        
        // Sanity check
        guard !appSupportDirectories.isEmpty else {
            
            log.error("No application support directory was found.")
            
            throw FileSystemError.NoApplicationSupportDirectory
        }
        
        log.debug("Found \(appSupportDirectories.count) possible application support directories.")
        
        // Get the first application support directory
        let appSupportDirectory = appSupportDirectories[0].URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!)
        
        log.debug("Using application support directory '\(appSupportDirectory.relativePath)'...")
        
        // Return the directory
        return appSupportDirectory
    }
    
    private static func applicationTemporaryDirectory() -> NSURL {
        
        // Get application temporary directory
        let applicationTemporaryDirectory = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true)
        
        log.debug("Using application temporary directory '\(applicationTemporaryDirectory)'...")
        
        // Return the directory
        return applicationTemporaryDirectory
    }
}
