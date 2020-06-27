//
//  WarningViewController.swift
//  Livo
//
//  Created by Deniz Acay on 26/07/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

class SettingsHelpViewController: UIViewController {

    @IBOutlet private weak var imageView : UIImageView?;
    @IBOutlet private weak var textView : UITextView?;

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the launch image
        let launchImage = UIImage(named: "LaunchImage-700-568h");
        
        // Set the image view's image to the launch image
        self.imageView?.image = launchImage;
        
        // Check settings initially
        self.checkSettings()
        
        // Register observer for the settings change event
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
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
    
    // MARK: - Notification handling
    func settingsChanged(notification: NSNotification) {
        
        print("Notification received")
        
        self.checkSettings()
    }

    // MARK: - IBAction methods
    
    @IBAction func openSettings() {
        
        // Open application settings
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
    
    // MARK: - Helper methods
    
    private func checkSettings() {
        
        if !serverHostConfigurationValid() {
            
            // Set the message text
            self.textView?.text = NSLocalizedString("Please configure a valid server host to proceed.", comment: "")
            
        } else if !serverPortConfigurationValid() {

            // Set the message text
            self.textView?.text = NSLocalizedString("Please configure a valid server port to proceed.", comment: "")
            
        } else {
            
            // Set the message text
            self.textView?.text = TweaksHelper.tweakValue("Settings", collectionName: "Help Screen", name: "Settings Complete", defaultValue: NSLocalizedString("Settings are complete.", comment: ""), minimumValue: nil, maximumValue: nil)

            // Dismiss this view controller as the settings are valid
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil);
                
                let nextViewController = mainStoryboard.instantiateViewControllerWithIdentifier("CompanyLoginViewController") as! CompanyLoginViewController
                
                self.navigationController?.pushViewController(nextViewController, animated: true)
            })
        }
    }
    
    private func serverHostConfigurationValid() -> Bool {
        
        let host = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)
        
        return host != nil && !(host!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty)
    }

    private func serverPortConfigurationValid() -> Bool {
        
        let port = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        print("Port: " + String(port))
        
        return port > 0
    }
}
