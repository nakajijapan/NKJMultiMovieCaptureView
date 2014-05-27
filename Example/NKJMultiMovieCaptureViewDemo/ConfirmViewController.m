//
//  ConfirmViewController.m
//
//  Created by nakajijapan.
//  Copyright 2014 nakajijapan. All rights reserved.
//

#import "ConfirmViewController.h"

@interface ConfirmViewController ()
@property MPMoviePlayerController *movielayer;
@property AppDelegate *appDelegate;
@end

@implementation ConfirmViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.appDelegate = [[UIApplication sharedApplication]delegate];
    NSLog(@"composedMoviePath = %@", self.appDelegate.composedMoviePath);
    
    if (!self.appDelegate.composedMoviePath) {
        NSLog(@"No, Composed File.");
        return;
    }
    
    NSURL* movieUrl = [NSURL fileURLWithPath:self.appDelegate.composedMoviePath];
    
    self.movielayer = [[MPMoviePlayerController alloc] initWithContentURL:movieUrl];
    self.movielayer.controlStyle = MPMovieControlStyleEmbedded;
    self.movielayer.scalingMode  = MPMovieScalingModeAspectFit;
    
    [self.movielayer setShouldAutoplay:NO];
    [[self.movielayer view] setBackgroundColor:[UIColor lightGrayColor]];
    [self.movielayer.view setFrame:CGRectMake(0.0f, 64.0f, 320, 320)];
    [self.movielayer prepareToPlay];
    
    [self.view addSubview:self.movielayer.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
