//
//  ViewController.swift
//  NKJMultiMovieCaptureView
//
//  Created by nakajijapan on 06/19/2015.
//  Copyright (c) 06/19/2015 nakajijapan. All rights reserved.
//

import UIKit
import NKJMultiMovieCaptureView
import NKJMovieComposer
import AVFoundation
import AssetsLibrary

class ViewController: UIViewController {

    var previewView:NKJMultiMovieCaptureView!
    var loadingView:LoadingImageView?
    var composingTimer:NSTimer?
    var assetExportSession:AVAssetExportSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewView = NKJMultiMovieCaptureView(frame: CGRectMake(0, 20, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)))
        self.view.addSubview(self.previewView)
  
        let saveButton = UIButton(type: .Custom)
        saveButton.frame = CGRectMake(16, CGRectGetWidth(self.view.bounds) + 32, 120, 50)
        saveButton.setTitle("SAVE FILE", forState: UIControlState.Normal)
        saveButton.backgroundColor = UIColor.redColor()
        saveButton.addTarget(self, action: "saveFile:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(saveButton)
    }

    // MARK - Timer
    
    func saveFile(sender: UIButton) {
        self.loadingView = LoadingImageView(frame: self.view.bounds, useProgress: true)
        self.view.addSubview(self.loadingView!)
        self.loadingView?.start()
        
        // continue to proccess for a certain period
        self.composingTimer = NSTimer.scheduledTimerWithTimeInterval(
            0.1,
            target: self,
            selector: "updateExportDisplay:",
            userInfo: nil,
            repeats: true)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.saveComposedVideo()
        })
    }
    
    func updateExportDisplay(sender:AnyObject) {
        self.loadingView?.progressView.progress = self.assetExportSession.progress
        
        if self.assetExportSession.progress > 0.99 {
            self.composingTimer?.invalidate()
        }
    }
    
    // MARK - Composite Video
    
    func saveComposedVideo() {
        print("self.previewView.movieURLs = \(self.previewView.movieURLs)")

        if self.previewView.movieURLs.count < 1 {
            let alertController = UIAlertController(title: "Ooops", message: "no, movie file", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction:UIAlertAction = UIAlertAction(title: "OK",
                style: UIAlertActionStyle.Cancel,
                handler:{
                    (action:UIAlertAction!) -> Void in
                    print("OK")
            })
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        let movieComposition = NKJMovieComposer()
        movieComposition.videoComposition.renderSize = CGSize(width: 720, height: 720)
        
        var layerInstruction:AVMutableVideoCompositionLayerInstruction?
        
        for movieURL in self.previewView.movieURLs {
            layerInstruction = movieComposition.addVideo(movieURL)
            
            // fine adjustment
            let transformVideo = CGAffineTransformMakeTranslation(700.0, 0.0)
            let transformVideoRotate = CGAffineTransformRotate(transformVideo, CGFloat(M_PI * 0.5))
            let transformVideoMove = CGAffineTransformTranslate(transformVideoRotate, -300.0, 0.0)
            
            layerInstruction?.setTransform(transformVideoMove, atTime: kCMTimeZero)
        }
        
        // new file
        let composedMoviePath = "\(NSTemporaryDirectory())composed.mov"
        
        // save
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.composedMoviePath = composedMoviePath
        
        // compose
        self.assetExportSession = movieComposition.readyToComposeVideo(composedMoviePath)
        let composedMovieURL = NSURL.fileURLWithPath(composedMoviePath)
        
        // export
        self.assetExportSession.exportAsynchronouslyWithCompletionHandler { () -> Void in
            
            if self.assetExportSession.status == AVAssetExportSessionStatus.Completed {
                print("export session completed")
                
                // save to device
                let library = ALAssetsLibrary()
                
                if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(composedMovieURL) {
                    library.writeVideoAtPathToSavedPhotosAlbum(composedMovieURL, completionBlock: { (assetUrl, error) -> Void in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            if error != nil {
                                print("\(error.description)")
                            }
                            
                            self.loadingView?.stop()
                            
                            let alertController = UIAlertController(title: "Completion", message: "Saved in Photo Album", preferredStyle: UIAlertControllerStyle.Alert)
                            let cancelAction:UIAlertAction = UIAlertAction(title: "OK",
                                style: UIAlertActionStyle.Cancel,
                                handler:{
                                    (action:UIAlertAction!) -> Void in
                                    print("OK")
                                    
                                    let viewController = ConfirmViewController()
                                    self.navigationController?.pushViewController(viewController, animated: true)
                                    
                            })
                            alertController.addAction(cancelAction)
                            self.presentViewController(alertController, animated: true, completion: nil)
                        })
                    })
                }
                
                
            } else {
                print("export session error")
            }
            
            
        }
        

        
    }

    
}
