//
//  UpdateViewController.swift
//  Livo
//
//  Created by Deniz Acay on 05/08/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit
import pop

import Shimmer

class UpdateViewController: UIViewController {

    @IBOutlet private weak var imageView : UIImageView?;
    @IBOutlet private weak var overallProgressView : UIProgressView?
    @IBOutlet private weak var fileProgressView : UIProgressView?
    @IBOutlet private weak var mainLabel : UILabel?
    @IBOutlet private weak var fileLabel : UILabel?
    var authenticationToken : AuthenticationToken?
    private var updateCompletedFlag : Bool = false
    private var applicationId : String?
    private var remoteProfile : Profile?
    private var filesToDownload : Set<File>?
    private var filesToMove : Set<File>?
    private var temporaryDirectory : NSURL?
    private lazy var shimmeringView : FBShimmeringView = {
        
        // Create the FBShimmeringView instance
        let shimmeringView = FBShimmeringView(frame: self.mainLabel!.frame)
        
        // Add the shimmering view to the hierarchy
        self.view.addSubview(shimmeringView)
        
        // Set the content view of the shimmering view
        shimmeringView.contentView = self.mainLabel!
        
        // Delegate the user interaction to button
        shimmeringView.userInteractionEnabled = false
        
        // Adjust shimmering effect
        shimmeringView.shimmeringHighlightLength = 0.66
        shimmeringView.shimmeringPauseDuration = 0.8
        shimmeringView.shimmeringSpeed = 160
        
        // Return the shimmering view
        return shimmeringView
        
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the launch image
        let launchImage = UIImage(named: "LaunchImage-700-568h");
        
        // Set the image view's image to the launch image
        self.imageView?.image = launchImage;
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // Start shimmering
        shimmeringView.shimmering = true
        
        // Check authentication token
        if self.authenticationToken == nil {
            
            NSLog("Failed to find any cached authentication token.")
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
            return
        }
        
        // Get the configured application ID
        self.applicationId = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Application.Identifier)
        
        // Get the local profile data
        let localProfile = CacheManager.localProfile
        
        // Perform the provision check
        ServiceHelper.checkProvision(self.authenticationToken!, applicationId: applicationId!, localProfile: localProfile, success: { (remoteProfile) -> Void in
            
            // Check remote profile
            if remoteProfile == nil {
                
                // If local profile is not nil, show the local application
                if localProfile != nil {
                    
                    // Save as the remote profile to call update completed
                    self.remoteProfile = localProfile
                    
                    // Indicate that the update is completed
                    self.updateCompleted()
                    
                    // Return to stop further execution
                    return
                }
                
                // Clear the local application directory
                do {
                    
                    try FileSystemHelper.clearApplicationDirectory()

                } catch {
                    
                    log.error("Failed to clear application directory.")
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    
                    // Instantiate a message view controller
                    let nextViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("MessageViewController") as! MessageViewController
                    
                    // Configure message view controller
                    nextViewController.message = NSLocalizedString("Please check your application ID and ensure it is deployed via the Administration Panel.", comment: "")
                    nextViewController.actionTitle = NSLocalizedString("Retry", comment: "")
                    nextViewController.actionClosure = {
                        
                        self.navigationController!.popViewControllerAnimated(true)
                    }
                    
                    // Present the next view controller
                    self.navigationController!.pushViewController(nextViewController, animated: true)
                })
                
                // Stop further execution
                return
                
            } else {
                
                // Save the remote profile
                self.remoteProfile = remoteProfile
                
                // Perform the update
                self.performUpdate()
            }
            
        }) { (message) -> Void in
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                let alert = UIAlertController(title: NSLocalizedString("Authentication Failed", comment: ""), message: message, preferredStyle: .Alert)
                
                let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action : UIAlertAction!) -> Void in
                    
                    alert.dismissViewControllerAnimated(true, completion: nil)
                })
                
                alert.addAction(alertAction)
                alert.view.tintColor = UIColor.grayColor()
                
                self.presentViewController(alert, animated: true, completion: nil)
            })
        }
    }

    override func shouldAutorotate() -> Bool {
        
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        
        return .Portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Helper methods
    
    private func performUpdate() {
        
        // Get local profile
        let localProfile = CacheManager.localProfile
        
        // Calculate the files to download
        self.filesToDownload = self.calculateFilesToDownload(localProfile)
        
        log.debug("Number of files to download is \(self.filesToDownload!.count).")
        
        // Calculate the files to move
        self.filesToMove = self.calculateFilesToMove(localProfile)
        
        log.debug("Number of files to move is \(self.filesToMove!.count).")
        
        // If we have no job to do, we should pop the view controller
        if self.filesToDownload!.count == 0 && self.filesToMove!.count == 0 {
            
            // Complete the update
            self.updateCompleted()
            
            // Stop further execution
            return
        }
        
        // Create a random temporary directory for update
        do {
            
            self.temporaryDirectory = try FileSystemHelper.createRandomTemporaryDirectory()

        } catch {
            
            log.error("Failed to create a temporary file for update.")
            
            self.handleError()
            
            return
        }
        
        // Download files
        self.downloadFiles()
    }
    
    private func calculateFilesToDownload(localProfile: Profile?) -> Set<File> {
        
        // Create a Set for results
        var diff = Set<File>()
        
        // If the local profile is null, return all files from the remote profile
        if localProfile == nil {
            
            // Add files from the remote profile
            for file in self.remoteProfile!.files {
                
                diff.insert(file as! File)
            }
            
            // Return the results
            return diff
        }
        
        // Add only the different files from the remote profile
        for file in self.remoteProfile!.files {
            
            if !profileContainsFile(localProfile!, file: file as! File) {
                
                diff.insert(file as! File)
            }
        }
        
        // Return the result
        return diff
    }
    
    private func calculateFilesToMove(localProfile: Profile?) -> Set<File> {

        // Create a Set for results
        var filesToMove = Set<File>()
        
        // If the local profile is null, no files should be moved
        if localProfile == nil {
            
            // Return the results
            return filesToMove
        }
        
        // Add only the files that are locally available
        for file in self.remoteProfile!.files {
            
            if profileContainsFile(localProfile!, file: file as! File) {
                
                filesToMove.insert(file as! File)
            }
        }
        
        // Return the result
        return filesToMove
    }
    
    private func profileContainsFile(profile: Profile, file: File) -> Bool {
        
        for f in profile.files {
            
            if (f as! File).hash == file.hash {
                
                return true
            }
        }
        
        return false
    }
    
    private func localFileForHash(hash: String) -> File {
        
        var file : File?
        
        for f in CacheManager.localProfile!.files {
            
            if (f as! File).hash == hash {
                
                file = f as? File
            }
        }
        
        return file!
    }
    
    private func updateCompleted() {
        
        log.debug("Completing update process...")
        
        objc_sync_enter(self.updateCompletedFlag)
        if self.updateCompletedFlag {
            
            objc_sync_exit(self.updateCompletedFlag)
            return
        }

        self.updateCompletedFlag = true
        objc_sync_exit(self.updateCompletedFlag)
        
        // Save the remote profile
        CacheManager.localProfile = self.remoteProfile!
        
        // Clear temporary directories
        do {
            
            try FileSystemHelper.clearTemporaryDirectory()

        } catch {
            
            log.warning("Failed to clear temporary directory.")
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            
            // Stop shimmering
            self.shimmeringView.shimmering = false
        
            // Update the label
            self.mainLabel!.text = NSLocalizedString("Application is up-to-date.", comment: "")
        
            // Pop the view controller to the root
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
                
                // Create an ApplicationViewController instance
                let applicationViewController = ApplicationViewController()
                
                // Set the authentication token
                applicationViewController.authenticationToken = self.authenticationToken
                
                // Set the application view controller as the root
                self.navigationController!.setViewControllers([applicationViewController], animated: true)
            })
        })
    }
    
    private func handleError() {
        
        // Create alert controller
        let alert = UIAlertController(title: NSLocalizedString("Update Error", comment: ""), message: ErrorMessages.UpdateErrors.GeneralError, preferredStyle: .Alert)
        
        // Add default action
        let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action : UIAlertAction!) -> Void in
            
            alert.dismissViewControllerAnimated(true, completion: nil)
        })
        
        // Add the action
        alert.addAction(alertAction)
        
        // Set tint color
        alert.view.tintColor = UIColor.grayColor()
        
        // Remove the local profile to prevent file problems with future updates
        CacheManager.localProfile = nil
        
        // Show the alert
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            self.presentViewController(alert, animated: true) { () -> Void in
                
                // Stop shimmering
                self.shimmeringView.shimmering = false
                
                // Update the label
                self.mainLabel!.text = NSLocalizedString("Update failed.", comment: "")
                
                // Clear temporary directories
                do {
                    
                    try FileSystemHelper.clearTemporaryDirectory()
                    
                } catch {
                    
                    log.warning("Failed to clear temporary directory.")
                }
                
                // Pop the view controller
                self.navigationController!.popViewControllerAnimated(true)
            }
        }
    }
    
    private func downloadFiles() {
        
        // Check if there are any files to download
        if self.filesToDownload!.isEmpty {
            
            // Start moving files
            self.moveFiles()
            
            // Stop further execution
            return
        }
        
        // Variable for checking for stop state
        var stopped = false
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            // Set the label text
            self.mainLabel!.text = NSLocalizedString("Downlading updates...", comment: "")
            
            // Set the progress
            self.overallProgressView!.progress = 0.0
        }

        // Calculate the step of progress
        let step = Float(1.0) / Float(self.filesToDownload!.count)
        
        // Iterate through files
        for file in self.filesToDownload! {
            
            // Queue operation to download file
            ServiceHelper.downloadFile(file, directory: self.temporaryDirectory!, progress: { (session) -> Void in
                
                log.debug("Fetched bucket \(session.currentIndex+1) of \(session.bucketCount) for file '\(session.file.path)'.")
                
            }, success: { (file) -> Void in
                
                objc_sync_enter(self.filesToDownload!)
                self.filesToDownload!.remove(file)
                objc_sync_exit(self.filesToDownload!)
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    
                    // Increment the progress view
                    self.overallProgressView!.progress += Float(step)
                    
                    // Check if all downloads are completed
                    objc_sync_enter(self.filesToDownload!)
                    if self.filesToDownload!.isEmpty {
                        
                        objc_sync_exit(self.filesToDownload!)
                        
                        // Start moving files
                        self.moveFiles()

                    } else {

                        objc_sync_exit(self.filesToDownload!)
                    }
                })
                
            }, error: { (message) -> Void in
                
                // Indicate that we should stop
                stopped = true
                
                // Handle the error
                self.handleError()
            })
        }
    }
    
    private func moveFiles() {

        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            // Set the label text
            self.mainLabel!.text = NSLocalizedString("Preparing for installation...", comment: "")
            
            // Reset the progress view
            self.overallProgressView!.progress = 0.0
        }
        
        // Iterate through files to move
        for file in self.filesToMove! {
            
            // Calculate current file URL
            var currentPath : NSURL
            do {
                
                currentPath = try FileSystemHelper.applicationFile(self.localFileForHash(file.hash).path)

            } catch {
                
                log.error("Failed to calculate the application file URL for '\(self.localFileForHash(file.hash).path)'.")
                
                self.handleError()
                
                return
            }
            
            // Calculate target file path
            let targetPath = self.temporaryDirectory!.URLByAppendingPathComponent(file.path)
            
            // Create appropriate intermediate directories
            do {
                
                try NSFileManager.defaultManager().createDirectoryAtURL(targetPath.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)

            } catch let error as NSError {
                
                log.error("\(error.description)")
                
                self.handleError()
                
                return
            }
            
            log.debug("Copying local file '\(currentPath)' to '\(targetPath)'...")
            
            // Copy the file
            do {
                
                try NSFileManager.defaultManager().copyItemAtURL(currentPath, toURL: targetPath)

            } catch let error as NSError {
                
                log.error("\(error.description)")
                
                self.handleError()
                
                return
            }
        }
        
        // Install the update
        self.installUpdate()
    }
    
    private func installUpdate() {
        
        log.debug("Installing updates...")
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            // Set the label text
            self.mainLabel!.text = NSLocalizedString("Installing updates...", comment: "")
            
            // Reset the progress view
            self.overallProgressView!.progress = 0.0
        }

        log.debug("Clearing application directory...")

        // Clear the application directory
        do {
            
            try FileSystemHelper.clearApplicationDirectory()

        } catch {
            
            log.error("Failed to clear application directory.")
            
            self.handleError()
            
            return
        }
        
        // Set the progress
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            self.overallProgressView!.progress = 0.5
        }
        
        log.debug("Copying files to application directory...")
        
        defer {
            
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            self.overallProgressView!.progress = 1.0
            }
        }
        
        // Install the files
        do {
            
            try FileSystemHelper.copyContentsOfDirectory(self.temporaryDirectory!, targetDirectory: FileSystemHelper.applicationDirectory())
            
            // Update is completed
            self.updateCompleted()

        } catch {
            
            log.error("Failed to install updates for application '\(self.applicationId!)'.")
            
            // Handle the error
            self.handleError()
        }
    }
}
