//
//  RootViewController.swift
//  Livo
//
//  Created by Deniz Acay on 11/06/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

import Tweaks

class RootViewController: UINavigationController, UINavigationControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        log.debug("Loaded root view controller!")
        
        self.delegate = self
        
        self.showAppropriateViewController()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        log.debug("Root view controller appeared!")
    }
    
    override func shouldAutorotate() -> Bool {
        
        if self.topViewController != nil {
            
            return self.topViewController!.shouldAutorotate()
            
        } else {
            
            return super.shouldAutorotate()
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        
        if self.topViewController != nil {
            
            return self.topViewController!.supportedInterfaceOrientations()

        } else {
            
            return super.supportedInterfaceOrientations()
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
    
    // MARK: - Navigation controller delegate
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return CrossFadeAnimatator()
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        
        log.debug("Showing view controller '\(viewController.description)'...")
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        
        log.debug("Did show view controller '\(viewController.description)'...")
    }

    // MARK: - Helper methods
    
    func showAppropriateViewController() -> Void {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil);
        
        var targetViewController : UIViewController
        
        if !serverSettingsValid() {
            
            targetViewController = mainStoryboard.instantiateViewControllerWithIdentifier("SettingsHelpViewController") as! SettingsHelpViewController
            
        } else if authenticationRequired() {
            
            if authenticationSilent() {
                
                targetViewController = mainStoryboard.instantiateViewControllerWithIdentifier("SilentLoginViewController") as! SilentLoginViewController
                
            } else {
                
                //TODO Should we remove silent auth information?
                
                targetViewController = mainStoryboard.instantiateViewControllerWithIdentifier("CompanyLoginViewController") as! CompanyLoginViewController
            }
            
        } else if updateRequired() {
            
            targetViewController = mainStoryboard.instantiateViewControllerWithIdentifier("UpdateViewController") as! UpdateViewController
        
        } else {
            
            print("No eligible target view controller found.")
            
            targetViewController = UIViewController()
        }
        
        self.pushViewController(targetViewController, animated: true)
    }
    
    private func serverSettingsValid() -> Bool {
        
        let host = NSUserDefaults.standardUserDefaults().stringForKey(Settings.Server.Host)
        let port = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Server.Port)
        
        return host != nil && !(host!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty) && port > 0
    }
    
    private func authenticationRequired() -> Bool {
        
        let authenticationEnabled = NSUserDefaults.standardUserDefaults().integerForKey(Settings.Authentication.Level) > 0
        
        return authenticationEnabled
    }
    
    private func authenticationSilent() -> Bool {
        
        let authenticationSilent = NSUserDefaults.standardUserDefaults().boolForKey(Settings.Authentication.Silent)

        return authenticationSilent
    }

    private func updateRequired() -> Bool {
        
        return true
    }
}
