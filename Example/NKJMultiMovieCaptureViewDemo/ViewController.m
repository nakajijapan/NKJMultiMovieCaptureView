//
//  ViewController.m
//
//  Created by nakajijapan.
//  Copyright 2014 nakajijapan. All rights reserved.
//

#import "ViewController.h"
#import "NKJMultiMovieCaptureView.h"
#import "NKJMovieComposer.h"
#import "LoadingImageView.h"
#import "AppDelegate.h"
#import "ConfirmViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController () <UIAlertViewDelegate>

@property NKJMultiMovieCaptureView *previewView;
@property LoadingImageView *loadingView;
@property NSTimer *composingTimer;
@property AVAssetExportSession *assetExportSession;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    self.previewView = [[NKJMultiMovieCaptureView alloc] initWithFrame:CGRectMake(0, 20, 320, 320)];
    [self.view addSubview:self.previewView];
    
    
    UIButton* saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveButton setFrame:CGRectMake(20, 400, 120, 50)];
    [saveButton setTitle:@"SAVE FILE" forState:UIControlStateNormal];
    [saveButton setBackgroundColor:[UIColor redColor]];
    [saveButton addTarget:self action:@selector(saveFile:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    
}

#pragma mark - Timer

- (void)saveFile:(id)sender
{
    self.loadingView = [[LoadingImageView alloc] initWithFrame:self.view.bounds withProgress:YES];
    [self.view addSubview:self.loadingView];
    [self.loadingView start];
    
    // continue to proccess for a certain period
    self.composingTimer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                           target:self
                                                         selector:@selector(updateExportDisplay:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveComposedVideo];
    });
    
}


- (void)updateExportDisplay:(id)sender
{
    self.loadingView.progressView.progress = self.assetExportSession.progress;
    
    if (self.assetExportSession.progress > .99) {
        [self.composingTimer invalidate];
    }
}


#pragma mark - Composite Video

- (void)saveComposedVideo
{
    NSLog(@"%@", self.previewView.movieURLs);
    
    if (self.previewView.movieURLs.count < 1) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ooops"
                                                            message:@"No, Movie File"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView setTag:1];
        [alertView show];
        return;
        
    }
    
    NKJMovieComposer* movieComposition = [[NKJMovieComposer alloc] init];
    [movieComposition.videoComposition setRenderSize:CGSizeMake(720, 720)];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction;
    for (NSURL *movieURL in self.previewView.movieURLs) {
        layerInstruction = [movieComposition addVideoWithURL:movieURL];
        
        //fine adjustment
        CGAffineTransform transformVideo       = CGAffineTransformMakeTranslation(700, 0.0);
        CGAffineTransform transformVideoRotate = CGAffineTransformRotate(transformVideo, M_PI * 0.5);
        CGAffineTransform transformVideoMove   = CGAffineTransformTranslate(transformVideoRotate, -300, 0);
        
        
        [layerInstruction setTransform:transformVideoMove atTime:kCMTimeZero];
    }
    
    // new file
    NSString *composedMoviePath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"composed.mov"];
    
    // save
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.composedMoviePath = composedMoviePath;
    
    // compose
    self.assetExportSession = [movieComposition readyToComposeVideoWithFilePath:composedMoviePath];
    NSURL *composedMovieUrl = [NSURL fileURLWithPath:composedMoviePath];
    
    // export
    [self.assetExportSession exportAsynchronouslyWithCompletionHandler: ^(void ) {
        
        if (self.assetExportSession.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"export session completed");
        } else {
            NSLog(@"export session error");
        }
        
        // 端末に保存
        ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:composedMovieUrl]) {
            [library writeVideoAtPathToSavedPhotosAlbum:composedMovieUrl
                                        completionBlock:^(NSURL *assetURL, NSError *assetError) {
                                            // メインスレッドをやめないため
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (assetError) { }
                                                
                                                // hide
                                                [self.loadingView stop];
                                                
                                                // show success message
                                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Completion"
                                                                                                    message:@"saved in Photo Album"
                                                                                                   delegate:self
                                                                                          cancelButtonTitle:@"OK"
                                                                                          otherButtonTitles:nil];
                                                [alertView setTag:2];
                                                [alertView show];
                                                
                                                
                                                
                                            });
                                        }];
        }
        
    }];
    
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 2) {
        NSLog(@"Completion!!!");
        ConfirmViewController* vc = [[ConfirmViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
