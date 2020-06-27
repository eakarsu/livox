//
//  DeviceLoginViewController.swift
//  Livo
//
//  Created by Deniz Acay on 28/09/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

import Tweaks
import Shimmer

class DeviceLoginViewController: UIViewController {

    @IBOutlet private weak var imageView : UIImageView?;
    @IBOutlet private weak var label: UILabel?;
    @IBOutlet private weak var button: UIButton?;
    var authenticationToken : AuthenticationToken?
    private var operation : NSOperation?
    private lazy var labelShimmeringView : FBShimmeringView = {
        
        // Create the FBShimmeringView instance
        let shimmeringView = FBShimmeringView(frame: self.label!.frame)
        
        // Add the shimmering view as a subview of view
        self.view.addSubview(shimmeringView)
        
        // Set the content view of the shimmering view
        shimmeringView.contentView = self.label!
        
        // Delegate the user interaction to underlying views
        shimmeringView.userInteractionEnabled = false
        
        // Adjust shimmering effect
        shimmeringView.shimmeringHighlightLength = CGFloat(TweaksHelper.tweakValue("Animations", collectionName: "Shimmering", name: "Highlight Length", defaultValue: 0.66, minimumValue: 0.0, maximumValue: 1.0))
        shimmeringView.shimmeringPauseDuration = CFTimeInterval(TweaksHelper.tweakValue("Animations", collectionName: "Shimmering", name: "Pause Duration", defaultValue: 0.8, minimumValue: 0.0, maximumValue: 10.0))
        shimmeringView.shimmeringSpeed = CGFloat(TweaksHelper.tweakValue("Animations", collectionName: "Shimmering", name: "Speed", defaultValue: 160.0, minimumValue: 0.0, maximumValue: 1000.0))
        
        // Return the shimmering view
        return shimmeringView
        
        }()
    private lazy var buttonShimmeringView : FBShimmeringView = {
        
        // Create the FBShimmeringView instance
        let shimmeringView = FBShimmeringView(frame: self.button!.bounds)
        
        // Add the shimmering view as a subview of cancel button
        self.button!.addSubview(shimmeringView)
        
        // Set the cancel button label alignment
        self.button!.titleLabel!.textAlignment = NSTextAlignment.Center
        
        // Set the content view of the shimmering view
        shimmeringView.contentView = self.button!.titleLabel
        
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
        
        // Start authentication
        self.performAuthentication()
    }

    override func viewWillDisappear(animated: Bool) {

        // Stop shimmering
        self.labelShimmeringView.shimmering = false
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
    
    // MARK: - IBAction methods
    
    @IBAction func buttonAction() {
        
        // Sanity check
        if self.operation == nil {
            
            log.debug("Retrying authentication...")
            
            self.performAuthentication()

        } else {
            
            log.debug("Cancelling current authentication operation...")

            // Cancel operation
            self.operation!.cancel()
            
            // Nil the operation
            self.operation = nil

            // Stop shimmering effects
            self.labelShimmeringView.shimmering = false
            self.buttonShimmeringView.shimmering = false
            
            // Change the label text
            UIView.animateWithDuration(1.0, animations: { () -> Void in
                
                self.label!.text = NSLocalizedString("Your device could not be authenticated. Please contact your administration and retry.", comment: "")
                
                self.button!.setTitle(NSLocalizedString("Retry", comment: ""), forState: .Normal)
            })
        }
    }

    // MARK: - Helper methods
    
    private func performAuthentication() {

        //TODO Check token

        // Start shimmering
        self.labelShimmeringView.shimmering = true
        
        // Try to authenticate
        self.operation = ServiceHelper.authenticateDevice(self.authenticationToken!, success: { (token) -> Void in
            
            log.info("Device authentication succeeded.")
            
            if self.operation == nil {
                
                log.debug("Authentication was cancelled but the result was successful.")
                
                return
            }
            
            // Show update view controller
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                let nextViewController : UpdateViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("UpdateViewController") as! UpdateViewController
                
                nextViewController.authenticationToken = token
                
                self.navigationController?.pushViewController(nextViewController, animated: true)
            })
            
        }) { (message) -> Void in
            
            log.info("Device authentication failed.")
            
            if self.operation == nil {
                
                log.debug("Authentication was cancelled but the result was not successful.")
                
                return
            }
            
            // Nil the operation
            self.operation = nil
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                // Stop shimmering effects
                self.labelShimmeringView.shimmering = false
                self.buttonShimmeringView.shimmering = false
                
                // Change the label text
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    
                    self.label!.text = NSLocalizedString("Your device could not be authenticated. Please contact your administration and retry.", comment: "")
                    
                    self.button!.setTitle(NSLocalizedString("Retry", comment: ""), forState: .Normal)
                })
            })
        }
    }
}
