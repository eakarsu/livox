//
//  NoApplicationViewController.swift
//  Livo
//
//  Created by Deniz Acay on 13/08/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

class ApplicationHelpViewController: UIViewController {

    @IBOutlet private weak var imageView : UIImageView?;
    var initialApplicationId : String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the launch image
        let launchImage = UIImage(named: "LaunchImage-700-568h");
        
        // Set the image view's image to the launch image
        self.imageView?.image = launchImage;
        
        // Get the initial application ID
        self.initialApplicationId = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Application.Identifier)

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
        
        let currentApplicationId : String? = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Application.Identifier)
        
        if currentApplicationId != nil && currentApplicationId != initialApplicationId {
            
            //TODO Check for update again
        }
    }
    
    // MARK: - IBAction methods
    
    @IBAction func openSettings() {
        
        // Open application settings
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
}
