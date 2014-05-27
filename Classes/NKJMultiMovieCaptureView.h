//
//  NKJMultiMovieCaptureView.h
//
//  Created by nakajijapan.
//  Copyright 2014 nakajijapan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKJMultiMovieCaptureView : UIView

@property NSMutableArray *movieURLs;

- (void)setVideoSettingWithDictionary:(NSDictionary *)settings;
- (void)setAudioSettingWithDictionary:(NSDictionary *)settings;

@end
