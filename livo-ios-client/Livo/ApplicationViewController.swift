//
//  ApplicationViewController.swift
//  Livo
//
//  Created by Deniz Acay on 02/09/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

import Cordova

class ApplicationViewController: UIViewController {

    var authenticationToken : AuthenticationToken?
    private var cordovaViewController : CDVViewController?;
    private var lastProfile : Profile?
    private var timer : NSTimer?
    private var checkingForUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure that the authentication token is cached
        CacheManager.authenticationToken = self.authenticationToken
        
        // Set the initial profile
        self.lastProfile = CacheManager.localProfile

        // Initialize the CDVViewController
        self.cordovaViewController = CDVViewController()
        
        do {
            
            // Calculate application directory
            let applicationDirectory = try FileSystemHelper.applicationDirectory()

            // Set the application folder path
            self.cordovaViewController!.wwwFolderName = applicationDirectory.filePathURL!.absoluteString
            
        } catch {
            
            log.error("Failed to calculate the application directory.")
        }
        
        // Set the start page
        self.cordovaViewController!.startPage = self.calculateStartPage()
        
        // Set the Cordova view's frame
        self.cordovaViewController!.view.frame = self.view.frame
        
        // Disable scrolling on web view
        self.cordovaViewController!.webView.scrollView.bounces = false
        
        // Add the Cordova view to the view hierarchy
        self.view.addSubview(self.cordovaViewController!.view)
        
        // Get the splash screen plugin object
        let splashScreenPlugin : CDVSplashScreen? = self.cordovaViewController!.pluginObjects["CDVSplashScreen"] as? CDVSplashScreen
        
        // Hide the splash screen if any
        if splashScreenPlugin != nil {
            
            log.debug("Hiding splash screen...")
            
            splashScreenPlugin!.hide(nil)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // Set the start page
        self.cordovaViewController!.startPage = self.calculateStartPage()
        
        // Send the platform usage event
        ServiceHelper.logPlatformUsage(self.authenticationToken!)
        
        // Schedule the timer for checking updates
        self.timer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: "checkUpdate", userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        // Invalidate the timer
        self.timer!.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Helper method
    
    func checkUpdate() {
        
        if self.checkingForUpdate {
            
            return
        }
        
        self.checkingForUpdate = true
        
        log.debug("Checking for update...")
        
        ServiceHelper.checkProvision(self.authenticationToken!, applicationId: NSUserDefaults.standardUserDefaults().stringForKey(Settings.Application.Identifier)!, localProfile: self.lastProfile, success: { (remoteProfile: Profile?) -> Void in
            
            // Check if the remote profile is different
            if remoteProfile == nil || remoteProfile!.hash == "" || remoteProfile!.hash == self.lastProfile!.hash {
                
                self.checkingForUpdate = false
                
                return
                
            } else {
               
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    
                    // Create alert controller
                    let alert = UIAlertController(title: NSLocalizedString("Update Available", comment: ""), message: NSLocalizedString("Would you like to update your application?", comment: ""), preferredStyle: .Alert)
                    
                    // Add update action
                    let updateAction = UIAlertAction(title: NSLocalizedString("Update", comment: ""), style: .Default, handler: { (action : UIAlertAction!) -> Void in
                        
                        self.checkingForUpdate = false
                        
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil);
                        
                        let nextViewController = mainStoryboard.instantiateViewControllerWithIdentifier("UpdateViewController") as! UpdateViewController
                        
                        nextViewController.authenticationToken = self.authenticationToken
                        
                        self.lastProfile = remoteProfile
                        
                        self.navigationController!.setViewControllers([nextViewController], animated: true)
                    })

                    // Add ignore action
                    let ignoreAction = UIAlertAction(title: NSLocalizedString("Ignore", comment: ""), style: .Cancel, handler: { (action : UIAlertAction!) -> Void in

                        self.checkingForUpdate = false
                        
                        self.lastProfile = remoteProfile
                    })
                    
                    // Add actions
                    alert.addAction(updateAction)
                    alert.addAction(ignoreAction)
                    
                    // Show the alert
                    self.presentViewController(alert, animated: true, completion: nil)
                })
                
            }
            
        }) { (message) -> Void in
            
            log.error("Checking for updates failed: \(message)")
        }
    }
    
    private func calculateStartPage() -> String {
        
        // Get the local profile
        let profile = CacheManager.localProfile
        
        // Check profile
        if profile == nil {
            
            log.error("There are no profiles installed.")
        }

        // Filter out paths with no index.html string
        var indexFiles = Set<File>()
        for file in profile!.files {
            
            let file = file as! File
            
            if file.path.rangeOfString("index.html") != nil {
                
                indexFiles.insert(file)
            }
        }
        
        // Search for the file with lowest number of path components
        var result : File?
        for indexFile in indexFiles {
            
            if result == nil {
                
                result = indexFile
                
            } else if NSURL(fileURLWithPath: indexFile.path).pathComponents!.count < NSURL(fileURLWithPath: result!.path).pathComponents!.count {
                
                result = indexFile
            }
        }
        
        // Check for result
        if result == nil {
            
            log.error("No index.html file was found!")
            
            return "/"
        }
        
        // Calculate the page URL
        do {
            
            let pageUrl = try FileSystemHelper.applicationFile(result!.path)

            log.debug("Using '\(pageUrl.filePathURL!.absoluteString)' as start page...")
            
            // Return the result
            return pageUrl.filePathURL!.absoluteString

        } catch {
            
            log.error("Failed to calculate the start page.")
            
            return ""
        }
    }
}
