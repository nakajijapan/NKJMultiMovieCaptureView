//
//  NKJMultiMovieCaptureView.m
//
//  Created by nakajijapan.
//  Copyright 2014 nakajijapan. All rights reserved.
//

#import "NKJMultiMovieCaptureView.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>



@interface NKJMultiMovieCaptureView () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property BOOL touching;
@property AVCaptureSession *captureSession;
@property AVCaptureVideoPreviewLayer *previewLayer;
@property AVAssetWriter *assetWriter;
@property AVAssetWriterInput *assetWriterInputVideo;
@property AVAssetWriterInput *assetWriterInputAudio;
@property AVCaptureVideoDataOutput *captureVideoOutput;
@property AVCaptureAudioDataOutput *captureAudioOutput;

@property NSMutableDictionary *videoSettings;
@property NSMutableDictionary *audioSettings;


@property CMTime recordStartTime;
@property NSURL *outputURL;
@property dispatch_queue_t movieWritingQueue;

@end

@implementation NKJMultiMovieCaptureView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor        = [UIColor blackColor];
        self.userInteractionEnabled = YES;
        self.movieURLs              = [NSMutableArray array];
        self.touching               = NO;
        self.recordStartTime        = kCMTimeZero;

        // device
        AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        // Video
        AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
        AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        [videoOutput setVideoSettings: [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                       nil]];


        // Audio
        NSError *error = nil;
        AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
        AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];


        // Setting Camera
        AVCaptureConnection *videoConnection = NULL;
        [self.captureSession beginConfiguration];

        for ( AVCaptureConnection *connection in [videoOutput connections] ) {
            for ( AVCaptureInputPort *port in [connection inputPorts] ) {

                NSLog(@"%@", port);
                if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
                    videoConnection = connection;
                }
            }
        }

        // portrait orientation
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];

        // initialize capture session
        self.captureSession = [[AVCaptureSession alloc] init];
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
        }
        if ([self.captureSession canAddOutput:videoOutput]) {
            [self.captureSession addOutput:videoOutput];
        }
        if ([self.captureSession canAddInput:audioInput]) {
            [self.captureSession addInput:audioInput];
        }
        if ([self.captureSession canAddOutput:audioOutput]) {
            [self.captureSession addOutput:audioOutput];
        }
        [self.captureSession setSessionPreset: AVCaptureSessionPreset1280x720];


        // PreviewLayer
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];

        // aspect
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

        // display size
        CALayer *rootLayer = [self layer];
        [rootLayer setMasksToBounds:YES];
        [self.previewLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [rootLayer addSublayer:self.previewLayer];

        // reflection a changes
        [self.captureSession commitConfiguration];

        // session start
        [self.captureSession startRunning];


        // video setting
        self.videoSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              AVVideoCodecH264, AVVideoCodecKey,
                              @1280, AVVideoWidthKey,
                              @720,  AVVideoHeightKey,
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               @30, AVVideoMaxKeyFrameIntervalKey,
                               nil], AVVideoCompressionPropertiesKey,
                              nil];

        // audio setting
        self.audioSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @44100.0, AVSampleRateKey,
                              @2,       AVNumberOfChannelsKey,
                              @16,      AVLinearPCMBitDepthKey,
                              [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                              [NSData data], AVChannelLayoutKey,
                              nil];
    }
    return self;
}

- (void)setVideoSettingWithDictionary:(NSDictionary *)settings
{
    for (id keyName in [settings allKeys]) {
        [self.videoSettings setObject:[settings objectForKey:keyName] forKey:keyName];
    }
}

- (void)setAudioSettingWithDictionary:(NSDictionary *)settings
{
    for (id keyName in [settings allKeys]) {
        [self.audioSettings setObject:[settings objectForKey:keyName] forKey:keyName];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"sampleBuffer data is not ready");
    }

    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    if (self.touching) {

        // Video
        if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
            [self addSamplebuffer:sampleBuffer withWriterInput:(AVAssetWriterInput *)self.assetWriterInputVideo];
        }
        // Audio
        else if ([captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]]) {
            [self addSamplebuffer:sampleBuffer withWriterInput:(AVAssetWriterInput *)self.assetWriterInputAudio];
        }

    }

    self.recordStartTime = currentTime;
}

- (void)addSamplebuffer:(CMSampleBufferRef)sampleBuffer withWriterInput:(AVAssetWriterInput *)assetWriterInput
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

    CFRetain(sampleBuffer);
    CFRetain(formatDescription);
    dispatch_async(self.movieWritingQueue, ^{
        if (![assetWriterInput isReadyForMoreMediaData]) {
            NSLog(@"Not ready for data :(");
        }
        //NSLog(@"Trying to append");

        if (_assetWriter.status == AVAssetWriterStatusUnknown) {
            NSLog(@"AVAssetWriterStatusUnknown");
        }
        if (_assetWriter.status == AVAssetWriterStatusWriting) {
            //NSLog(@"AVAssetWriterStatusWriting");

            if (assetWriterInput.readyForMoreMediaData) {

                if (![assetWriterInput appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"%@",[self.assetWriter error]);
                }

            }
        }
        else if (_assetWriter.status == AVAssetWriterStatusFailed) {
            NSLog(@"AVAssetWriterStatusFailed");
            NSLog(@"%@",[self.assetWriter error]);
        }
        else if (_assetWriter.status == AVAssetWriterStatusCancelled) {
            NSLog(@"AVAssetWriterStatusCancelled");
        }
        else if (_assetWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"AVAssetWriterStatusCompleted");
        }

        CFRelease(sampleBuffer);
        CFRelease(formatDescription);
    });
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touching = YES;

    // Output
    NSError *error;
    NSString *fileName   = [NSString stringWithFormat:@"output%02d.mov", (int)[self.movieURLs count] + 1];
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    self.outputURL       = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSLog(@"outputPath = %@", outputPath);

    // delete file before save the one
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {

        if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
            //NSLog(@"failed deleting file");
        }

    }

    // AVAssetWriter
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error != nil) {
        //NSLog(@"Creation of assetWriter resulting in a non-nil error");
    }

    // movie
    NSDictionary *videoSetting = self.videoSettings;
    self.assetWriterInputVideo = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSetting];
    [self.assetWriterInputVideo setExpectsMediaDataInRealTime:YES];
    if (self.assetWriterInputVideo == nil) {
        NSLog(@"assetWriterInput is nil");
    }

    // audio
    NSDictionary *audioSetting = self.audioSettings;
    self.assetWriterInputAudio = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSetting];
    [self.assetWriterInputAudio setExpectsMediaDataInRealTime:YES];
    if (self.assetWriterInputAudio == nil) {
        NSLog(@"assetWriterInputAudio is nil");
    }

    [self.assetWriter addInput:self.assetWriterInputVideo];
    [self.assetWriter addInput:self.assetWriterInputAudio];

    // queue
    self.movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);

    // Record
    NSLog(@"[Starting to record]");
    dispatch_async(self.movieWritingQueue, ^{
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:self.recordStartTime];
    });

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touching = NO;

    NSLog(@"[Stopping recording] duration : %f", CMTimeGetSeconds(self.recordStartTime));

    [self.assetWriterInputVideo markAsFinished];
    [self.assetWriterInputAudio markAsFinished];
    [self.assetWriter endSessionAtSourceTime:self.recordStartTime];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        NSLog(@"self.assetWriter finishWritingWithCompletionHandler");

        [self.movieURLs addObject:self.outputURL];
        NSLog(@"%@", self.movieURLs);

    }];

    NSLog(@"Export done");
}
@end
