//
//  SilentLoginViewController.swift
//  Livo
//
//  Created by Deniz Acay on 15/08/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

import Shimmer
import SSKeychain

class SilentLoginViewController: UIViewController {

    @IBOutlet private weak var imageView : UIImageView?;
    @IBOutlet private weak var label : UILabel?;
    private lazy var shimmeringView : FBShimmeringView = {
        
        // Create the FBShimmeringView instance
        let shimmeringView = FBShimmeringView(frame: self.label!.frame)
        
        // Add the shimmering view to the hierarchy
        self.view.addSubview(shimmeringView)
        
        // Set the content view of the shimmering view
        shimmeringView.contentView = self.label!
        
        // Delegate the user interaction to button
        shimmeringView.userInteractionEnabled = false
        
        // Adjust shimmering effect
        shimmeringView.shimmeringHighlightLength = 0.66
        shimmeringView.shimmeringPauseDuration = 0.8
        shimmeringView.shimmeringSpeed = 160
        
        // Return the shimmering view
        return shimmeringView
        
        }()
    private var authenticationToken : AuthenticationToken?

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
        
        // Check if information is complete
        if informationComplete() {
            
            // Perform authentication
            self.performAuthentication()
            
        } else {
            
            // Instantiate a CompanyLoginViewController
            let nextViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("CompanyLoginViewController") as! CompanyLoginViewController
            
            // Show the next view controller
            self.navigationController!.pushViewController(nextViewController, animated: true)
        }
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
    
    private func performAuthentication() {
        
        // Get the authentication level
        let authenticationLevel = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Authentication.Level)
        
        // Check if authentication is disabled
        if authenticationLevel <= 0 {
            
            // Pop this view controller
            self.navigationController!.popViewControllerAnimated(true)
            
            // Stop further execution
            return
        }
        
        // Perform company authentication if enabled
        if authenticationLevel >= 1 {
            
            self.performCompanyAuthentication(authenticationLevel)
        }
    }
    
    private func performCompanyAuthentication(level: Int) {
        
        // Get the server settings
        let host = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)!
        let port = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        // Construct the service address string
        let serviceAddress = "\(host):\(port)"
        
        // Get accounts for the service
        let accounts = SSKeychain.accountsForService("CA:\(serviceAddress)")
        
        // Get the first account available
        let accountDict = accounts.first as! NSDictionary
        
        // Get the company ID from the account
        let companyId = accountDict[NSString(format: kSecAttrAccount)] as! String
        
        log.debug("Authenticating company '\(companyId)' against '\(serviceAddress)'...")
        
        // Get the company secret
        let companySecret = SSKeychain.passwordForService("CA:\(serviceAddress)", account: companyId)
        
        // Perform authentication
        ServiceHelper.authenticateCompany(companyId, companySecret: companySecret, success: { (token) -> Void in
            
            log.debug("Successfully completed company authentication with ID '\(companyId)'.")
            
            self.authenticationToken = token
            
            // Perform user authentication if enabled
            if level >= 2 {
                
                self.performUserAuthentication(level)
                
            } else {
                
                self.authenticationCompleted()
            }

        }) { (message) -> Void in
            
            log.debug("Company authentication failed for ID '\(companyId)'.")
           
            self.handleError(message!, nextViewControllerIdentifier:"CompanyLoginViewController")
        }
    }
    
    private func performUserAuthentication(level: Int) {
        
        // Get the server settings
        let host = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)!
        let port = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        // Construct the service address string
        let serviceAddress = "\(host):\(port)"
        
        // Get accounts for the service
        let accounts = SSKeychain.accountsForService("UA:\(serviceAddress)")
        
        // Get the first account available
        let accountDict = accounts.first as! NSDictionary
        
        // Get the user principal from the account
        let userPrincipal = accountDict[NSString(format: kSecAttrAccount)] as! String
        
        log.debug("Authenticating user '\(userPrincipal)' against '\(serviceAddress)'...")
        
        // Get the user credentials
        let userCredentials = SSKeychain.passwordForService("UA:\(serviceAddress)", account: userPrincipal)
        
        // Perform authentication
        ServiceHelper.authenticateUser(self.authenticationToken!, userPrincipal: userPrincipal, userCredentials: userCredentials, success: { (token) -> Void in
            
            log.debug("Successfully completed user authentication with principal '\(userPrincipal)'.")
            
            self.authenticationToken = token
            
            // Perform device authentication if enabled
            if level >= 3 {
                
                self.performDeviceAuthentication()
                
            } else {
                
                self.authenticationCompleted()
            }
            
            
        }) { (message) -> Void in
            
            log.debug("User authentication failed for principal '\(userPrincipal)'.")
            
            self.handleError(message!, nextViewControllerIdentifier: "UserLoginViewController")
        }
    }
    
    private func performDeviceAuthentication() {

        // Get the server settings
        let host = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)!
        let port = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        // Construct the service address string
        let serviceAddress = "\(host):\(port)"
        
        log.debug("Authenticating device against '\(serviceAddress)'...")
        
        // Perform authentication
        ServiceHelper.authenticateDevice(self.authenticationToken!, success: { (token) -> Void in
            
            log.debug("Successfully completed device authentication.")
            
            self.authenticationToken = token
            
            self.authenticationCompleted()
         
        }) { (message) -> Void in
                
                log.debug("Device authentication failed.")
                
                self.handleError(message!, nextViewControllerIdentifier: "DeviceLoginViewController")
        }
    }
    
    private func authenticationCompleted() {
        
        // Cache the authentication token
        CacheManager.authenticationToken = self.authenticationToken
        
        // Instantiate an UpdateViewController
        let nextViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("UpdateViewController") as! UpdateViewController
        
        // Set the authentication token on update view controller
        nextViewController.authenticationToken = self.authenticationToken
        
        // Show the next view controller
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            self.navigationController!.pushViewController(nextViewController, animated: true)
        }
    }
    
    private func handleError(message: String, nextViewControllerIdentifier: String) {
        
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            
            let alert = UIAlertController(title: NSLocalizedString("Authentication Failed", comment: ""), message: message, preferredStyle: .Alert)
            
            let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action : UIAlertAction!) -> Void in
                
                alert.dismissViewControllerAnimated(true, completion: nil)
                
                // Instantiate the next view controller
                let nextViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(nextViewControllerIdentifier) as! UIViewController
                
                // Check if the next view controller expects an authentication token
                if nextViewController.respondsToSelector(NSSelectorFromString("authenticationToken")) {
                    
                    nextViewController.setValue(self.authenticationToken, forKey: "authenticationToken")
                }

                // Present the view controller
                self.navigationController!.pushViewController(nextViewController, animated: true)
            })
            
            alert.addAction(alertAction)
            alert.view.tintColor = UIColor.grayColor()
            
            self.presentViewController(alert, animated: true, completion: {
                
                self.navigationController!.popViewControllerAnimated(true)
            })
        })
    }
    
    private func informationComplete() -> Bool {
        
        // Get the server settings
        let host = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)!
        let port = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        // Construct the service address string
        let serviceAddress = "\(host):\(port)"
        
        NSLog("Service address is '%@'.", serviceAddress)
        
        // Get the authentication level
        let authenticationLevel = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Authentication.Level)
        
        // Check if authentication is disabled
        if authenticationLevel <= 0 {
            
            NSLog("Authentication is disabled with level %d but tried to perform silent authentication.", authenticationLevel)
            
            // Pop this view controller
            self.navigationController!.popViewControllerAnimated(true)
            
            // Return true to skip authentication in the performAuthentication method
            return false
        }
        
        // Check company authentication information
        if authenticationLevel >= 1 {
            
            // Get accounts for the service
            let accounts = SSKeychain.accountsForService("CA:\(serviceAddress)")
            
            // Check if a company ID for the service address is available
            if accounts == nil || accounts.count == 0 { return false }
            
            // Get the first account available
            let accountDict = accounts.first as! NSDictionary
            
            // Get the company ID from the account
            let companyId = accountDict[NSString(format: kSecAttrAccount)] as! String
            
            // Check if a company secret is available
            if SSKeychain.passwordForService("CA:\(serviceAddress)", account: companyId) == nil { return false }
        }
        
        // Check user authentication information
        if authenticationLevel >= 2 {
            
            // Get accounts for the service
            let accounts = SSKeychain.accountsForService("UA:\(serviceAddress)")
            
            // Check if a user principal for the service address is available
            if accounts == nil || accounts.count == 0 { return false }
            
            // Get the first account available
            let accountDict = accounts.first as! NSDictionary
            
            // Get the user principal from the account
            let userPrincipal = accountDict[NSString(format: kSecAttrAccount)] as! String
            
            // Check if a user credentials is available
            if SSKeychain.passwordForService("UA:\(serviceAddress)", account: userPrincipal) == nil { return false }
        }
        
        // At this point we have every information we need
        return true
    }
}
