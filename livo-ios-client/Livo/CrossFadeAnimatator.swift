//
//  CrossFadeAnimatator.swift
//  Livo
//
//  Created by Deniz Acay on 04/08/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

import UIKit

import pop

class CrossFadeAnimatator: NSObject, UIViewControllerAnimatedTransitioning {
   
    // MARK: - View controller animated transitioning protocol
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            // Get the view controllers
            let targetViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
            let sourceViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
            
            // Get the container view
            let containerView = transitionContext.containerView()
            
            // Set the alpha of target view controller to 0
            targetViewController.view.alpha = 0.0
            
            // Add the target view contoller's view to the container view
            containerView!.addSubview(targetViewController.view)
            
            // Create the animation object
            let fadeInAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
            fadeInAnimation.duration = 0.5
            fadeInAnimation.toValue = 1.0
            fadeInAnimation.completionBlock = {(animation, finished) in
                
                sourceViewController.view.removeFromSuperview()
                
                transitionContext.completeTransition(finished)
            }
            fadeInAnimation.removedOnCompletion = true
            
            // Add the animation to target view controller's view
            targetViewController.view.pop_addAnimation(fadeInAnimation, forKey: "fadeInAnimation")
        }
    }
}
