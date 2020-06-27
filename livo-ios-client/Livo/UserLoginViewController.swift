//
//  UserLoginViewController.swift
//  Livo
//
//  Created by Deniz Acay on 20/07/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

import Tweaks
import Shimmer
import SSKeychain
import pop

class UserLoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet private weak var imageView : UIImageView?
    @IBOutlet private weak var userPrincipalTextField : UITextField?
    @IBOutlet private weak var userCredentialsTextField : UITextField?
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var continueButton: UIButton?;
    @IBOutlet private weak var signingInLabel: UILabel?;
    @IBOutlet private weak var cancelButton: UIButton?;
    var authenticationToken : AuthenticationToken?
    private var operation : NSOperation?
    private var authenticationContext = 0
    private var keyboardShown : Bool = false
    private dynamic var authenticating : Bool = false
    private lazy var signingInShimmeringView : FBShimmeringView = {
        
        // Create the FBShimmeringView instance
        let shimmeringView = FBShimmeringView(frame: self.signingInLabel!.frame)
        
        // Add the shimmering view as a subview of view
        self.view.addSubview(shimmeringView)
        
        // Set the content view of the shimmering view
        shimmeringView.contentView = self.signingInLabel!
        
        // Delegate the user interaction to underlying views
        shimmeringView.userInteractionEnabled = false
        
        // Adjust shimmering effect
        shimmeringView.shimmeringHighlightLength = CGFloat(TweaksHelper.tweakValue("Animations", collectionName: "Shimmering", name: "Highlight Length", defaultValue: 0.66, minimumValue: 0.0, maximumValue: 1.0))
        shimmeringView.shimmeringPauseDuration = CFTimeInterval(TweaksHelper.tweakValue("Animations", collectionName: "Shimmering", name: "Pause Duration", defaultValue: 0.8, minimumValue: 0.0, maximumValue: 10.0))
        shimmeringView.shimmeringSpeed = CGFloat(TweaksHelper.tweakValue("Animations", collectionName: "Shimmering", name: "Speed", defaultValue: 160.0, minimumValue: 0.0, maximumValue: 1000.0))
        
        // Return the shimmering view
        return shimmeringView
        
        }()
    private lazy var cancelShimmeringView : FBShimmeringView = {
        
        // Create the FBShimmeringView instance
        let shimmeringView = FBShimmeringView(frame: self.cancelButton!.bounds)
        
        // Add the shimmering view as a subview of cancel button
        self.cancelButton!.addSubview(shimmeringView)
        
        // Set the cancel button label alignment
        self.cancelButton!.titleLabel!.textAlignment = NSTextAlignment.Center
        
        // Set the content view of the shimmering view
        shimmeringView.contentView = self.cancelButton!.titleLabel
        
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
        
        // Add observer for authenticating property
        self.addObserver(self, forKeyPath: "authenticating", options: NSKeyValueObservingOptions.New, context: &authenticationContext)
        
        // Load the launch image
        let launchImage = UIImage(named: "LaunchImage-700-568h");
        
        // Set the image view's image to the launch image
        self.imageView?.image = launchImage;
        
        // Configure the placeholders
        TweaksHelper.tweakAction("Authentication", collectionName: "User Authentication", name: "Principal Placeholder", action: { (currentValue) -> () in
            
            userPrincipalTextField?.placeholder = currentValue as? String
            
            }, defaultValue: "User Principal", minimumValue: nil, maximumValue: nil)
        TweaksHelper.tweakAction("Authentication", collectionName: "User Authentication", name: "Credentials Placeholder", action: { (currentValue) -> () in
            
            userCredentialsTextField?.placeholder = currentValue as? String
            
            }, defaultValue: "User Credentials", minimumValue: nil, maximumValue: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // Register for keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        // Unregister from the keyboard notifications
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
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
    
    // MARK: - Key-value observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if context == &authenticationContext {
            
            let authenticatingVal: Bool = change![NSKeyValueChangeNewKey] as! Bool
            
            if authenticatingVal {
                
                // Start shimmering
                self.signingInShimmeringView.shimmering = true
                self.cancelShimmeringView.shimmering = true
                
                // Disable text inputs
                self.userPrincipalTextField!.enabled = false
                self.userCredentialsTextField!.enabled = false
                
                // Animate visibility changes
                UIView.animateWithDuration(NSTimeInterval(TweaksHelper.tweakValue("Animations", collectionName: "Login View", name: "Fade Duration", defaultValue: 0.33, minimumValue: 0.0, maximumValue: 1.0)), animations: { () -> Void in
                    
                    // Fade out the continue button
                    self.continueButton!.alpha = 0.0
                    
                    // Fade in the signing in label
                    self.signingInLabel!.alpha = 1.0
                    
                    // Fade in the cancel button
                    self.cancelButton!.alpha = 1.0
                    
                    // Layout if needed
                    self.view.layoutIfNeeded()
                    
                    }, completion: { (completed: Bool) -> Void in
                        
                        // Hide the continue button
                        self.continueButton!.hidden = true
                        
                        // Show the signing in label
                        self.signingInLabel!.hidden = false
                        
                        // Show the cancel button
                        self.cancelButton?.hidden = false
                })
                
            } else {
                
                // Stop shimmering the buttons
                self.signingInShimmeringView.shimmering = false
                self.cancelShimmeringView.shimmering = false
                
                // Enable text inputs
                self.userPrincipalTextField!.enabled = true
                self.userCredentialsTextField!.enabled = true
                
                // Animate visibility changes
                UIView.animateWithDuration(NSTimeInterval(TweaksHelper.tweakValue("Animations", collectionName: "Login View", name: "Fade Duration", defaultValue: 0.33, minimumValue: 0.0, maximumValue: 1.0)), animations: { () -> Void in
                    
                    // Fade in the continue button
                    self.continueButton!.alpha = 1.0
                    
                    // Fade out the signing in label
                    self.signingInLabel!.alpha = 0.0
                    
                    // Fade out the cancel button
                    self.cancelButton!.alpha = 0.0
                    
                    // Layout if needed
                    self.view.layoutIfNeeded()
                    
                    }, completion: { (completed: Bool) -> Void in
                        
                        // Show continue button
                        self.continueButton!.hidden = false
                        
                        // Hide signing in label
                        self.signingInLabel!.hidden = true
                        
                        // Hide the cancel button
                        self.cancelButton!.hidden = true
                })
            }
            
        } else {
            
            // Delegate to the super method
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        
        self.removeObserver(self, forKeyPath: "authenticating")
    }
    
    // MARK: - Text field delegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        textField.placeholder = ""
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        if textField == self.userPrincipalTextField {
            
            textField.placeholder = String(TweaksHelper.tweakValue("Authentication", collectionName: "User Authentication", name: "Principal Placeholder", defaultValue: "User Principal", minimumValue: nil, maximumValue: nil))
            
        } else {
            
            textField.placeholder = String(TweaksHelper.tweakValue("Authentication", collectionName: "User Authentication", name: "Credentials Placeholder", defaultValue: "User Credentials", minimumValue: nil, maximumValue: nil))
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        return string.rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if (textField == self.userPrincipalTextField) {
            
            self.userCredentialsTextField?.becomeFirstResponder()
            
        } else {
            
            textField.resignFirstResponder()
            
            self.performAuthentication()
        }
        
        return true
    }
    
    // MARK: - Keyboard notification handling
    
    func keyboardWillShow(notification: NSNotification) {
        
        if self.keyboardShown {
            
            return
        }
        
        let info:NSDictionary = notification.userInfo!
        
        let kbSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        
        let currentSize = self.contentView!.frame.size
        
        let newSize = CGRectMake(0.0, 0.0, currentSize.width, currentSize.height - kbSize.height)
        
        self.contentView!.frame = newSize
        
        self.contentView!.layoutIfNeeded()
        
        self.keyboardShown = true
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if !self.keyboardShown {
            
            return
        }
        
        let info:NSDictionary = notification.userInfo!
        
        let kbSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        
        let currentSize = self.contentView!.frame.size
        
        let newSize = CGRectMake(0.0, 0.0, currentSize.width, currentSize.height + kbSize.height)
        
        self.contentView!.frame = newSize
        
        self.view.layoutIfNeeded()
        
        self.keyboardShown = false
    }

    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - IBAction methods
    
    @IBAction func performAuthentication() {
        
        if self.operation != nil {
            
            NSLog("Attempted perform authentication while another operation is in progress.")
            
            return
        }
        
        let userPrincipal = (self.userPrincipalTextField?.text ?? "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let userCredentials = (self.userCredentialsTextField?.text ?? "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if !inputValid(userPrincipal, userCredentials: userCredentials) {
            
            var shakeAnimation: POPSpringAnimation? = self.continueButton?.layer.pop_animationForKey("shakeButton") as? POPSpringAnimation
            
            if shakeAnimation == nil {
                
                shakeAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPositionX)
                shakeAnimation!.springBounciness = CGFloat(TweaksHelper.tweakValue("Animations", collectionName: "Login View", name: "Bounciness", defaultValue: 20.0, minimumValue: 1.0, maximumValue: 100.0))
                shakeAnimation!.velocity = CGFloat(TweaksHelper.tweakValue("Animations", collectionName: "Login View", name: "Velocity", defaultValue: 3000.0, minimumValue: 100.0, maximumValue: 10000.0))
                shakeAnimation?.removedOnCompletion = true
                
                self.continueButton?.layer.pop_addAnimation(shakeAnimation, forKey: "shakeButton")
            }
            
        } else {
            
            self.authenticating = true
            
            self.operation = ServiceHelper.authenticateUser(self.authenticationToken!, userPrincipal: userPrincipal, userCredentials: userCredentials, success: { (token) -> Void in
                
                // Should not matter, added as a precaution
                self.operation = nil
                
                self.authenticating = false
                
                // Save login information if silent authentication is enabled
                if NSUserDefaults.standardUserDefaults().boolForKey(Settings.Authentication.Silent) {
                    
                    // Get the server settings
                    let host = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)!
                    let port = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
                    
                    // Construct the service address string
                    let serviceAddress = "\(host):\(port)"
                    
                    // Clear previous values
                    self.clearKeychainAccounts("UA:\(serviceAddress)")
                    
                    // Save the user principal and credentials
                    SSKeychain.setPassword(userCredentials, forService: "UA:\(serviceAddress)", account: userPrincipal)
                }
                
                let level = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Authentication.Level)
                
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil);

                if level >= 3 {
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        
                        let nextViewController : DeviceLoginViewController = mainStoryboard.instantiateViewControllerWithIdentifier("DeviceLoginViewController") as! DeviceLoginViewController
                        
                        nextViewController.authenticationToken = token
                        
                        self.navigationController?.pushViewController(nextViewController, animated: true)
                    })
                    
                } else {
                    
                    CacheManager.authenticationToken = token
                                        
                    //TODO Maybe add a task to check a token??? Like periodic userActive analytic send to check?
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        
                        let nextViewController : UpdateViewController = mainStoryboard.instantiateViewControllerWithIdentifier("UpdateViewController") as! UpdateViewController
                        
                        nextViewController.authenticationToken = token
                        
                        self.navigationController?.pushViewController(nextViewController, animated: true)
                    })
                }
                
                }, error: { (message) -> Void in
                    
                    // Nil the operation to allow future operations//
                    self.operation = nil
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        
                        let alert = UIAlertController(title: NSLocalizedString("Authentication Failed", comment: ""), message: message, preferredStyle: .Alert)
                        
                        let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action : UIAlertAction!) -> Void in
                            
                            alert.dismissViewControllerAnimated(true, completion: nil)
                        })
                        
                        alert.addAction(alertAction)
                        alert.view.tintColor = UIColor.grayColor()
                        
                        self.authenticating = false

                        self.presentViewController(alert, animated: true, completion: nil)
                    })
                    
                    if message != nil {
                        
                        NSLog("Authentication error: %@", message!)
                    }
            })
        }
    }
    
    @IBAction func cancelAuthentication() {
        
        // Sanity check
        if self.operation == nil {
            
            // Should not end up here
            NSLog("Attempted to cancel while no operation is in progress.")
            
            return
        }
        
        // Cancel operation
        self.operation!.cancel()
        
        // Nil the operation
        self.operation = nil
        
        // Return to the normal UI
        self.authenticating = false
    }
    
    // MARK: - Helper methods
    
    private func inputValid(userPrincipal: String, userCredentials: String) -> Bool {
        
        return !userPrincipal.isEmpty && !userCredentials.isEmpty
    }
    
    private func clearKeychainAccounts(serviceName: String) {
    
        // Get accounts for service
        let accounts = SSKeychain.accountsForService(serviceName) ?? NSArray()
        
        // Iterate through the accounts
        for account in accounts {
            
            // Get the first account available
            let accountDict = account as! NSDictionary
            
            // Get the account string from the account
            let accountStr = accountDict[NSString(format: kSecAttrAccount)] as! String

            // Delete account data
            SSKeychain.deletePasswordForService(serviceName, account: accountStr)
        }
    }
}
