//
//  MessageViewController.swift
//  Livo
//
//  Created by Deniz Acay on 14/08/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {
    
    @IBOutlet private weak var imageView : UIImageView?;
    @IBOutlet private weak var messageTextView : UITextView?;
    @IBOutlet private weak var actionButton : UIButton?;
    var message: String?
    var actionTitle: String?
    var actionClosure: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the launch image
        let launchImage = UIImage(named: "LaunchImage-700-568h");
        
        // Set the image view's image to the launch image
        self.imageView?.image = launchImage;

        // Set message text
        self.messageTextView!.text = self.message
        
        // Set action button title
        self.actionButton!.setTitle(self.actionTitle ?? NSLocalizedString("OK", comment: ""), forState: .Normal)
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

    // MARK: - IBAction
    
    @IBAction func performAction() {

    
        if self.actionClosure != nil {
            
            self.actionClosure!()
        }
    }
}
