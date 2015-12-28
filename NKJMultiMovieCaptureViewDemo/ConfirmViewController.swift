//
//  ConfirmViewController.swift
//  NKJMultiMovieCaptureView
//
//  Created by nakajijapan on 6/19/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import UIKit
//import MediaPlayer
import AVKit
import AVFoundation

class ConfirmViewController: UIViewController, AVPlayerViewControllerDelegate {

    
    var avPlayerViewController:AVPlayerViewController!
    //var moviePlayerController:MPMoviePlayerController!
    var appDelegate:AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.whiteColor()
        self.appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        print("composedMoviePath = \(self.appDelegate.composedMoviePath)")
        
        if self.appDelegate.composedMoviePath == nil {
            print("No, Composed File.")
            return
        }
        
        let movieURL = NSURL(fileURLWithPath: self.appDelegate.composedMoviePath!)
        self.avPlayerViewController = AVPlayerViewController()
        self.avPlayerViewController.view.frame = CGRectMake(0, 64, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds))
        self.avPlayerViewController.player = AVPlayer(URL: movieURL)
        self.view.addSubview(self.avPlayerViewController.view)
        
        self.avPlayerViewController.player?.play()
 
    }

}
