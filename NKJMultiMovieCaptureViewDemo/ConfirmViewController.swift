//
//  ConfirmViewController.swift
//  NKJMultiMovieCaptureView
//
//  Created by nakajijapan on 6/19/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import UIKit
import MediaPlayer

class ConfirmViewController: UIViewController, MPMediaPickerControllerDelegate {

    var moviePlayerController:MPMoviePlayerController!
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
        
        self.moviePlayerController = MPMoviePlayerController(contentURL: movieURL)
        self.moviePlayerController.controlStyle = MPMovieControlStyle.Embedded
        self.moviePlayerController.scalingMode = MPMovieScalingMode.AspectFit
        
        self.moviePlayerController.shouldAutoplay = false
        self.moviePlayerController.view.backgroundColor = UIColor.lightGrayColor()
        self.moviePlayerController.view.frame = CGRectMake(0, 64, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds))
        self.moviePlayerController.prepareToPlay()
        
        self.view.addSubview(self.moviePlayerController.view)
    }

}
