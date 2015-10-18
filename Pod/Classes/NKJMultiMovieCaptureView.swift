//
//  NKJMultiMovieCaptureView.swift
//  Pods
//
//  Created by nakajijapan on 6/19/15.
//
//

import UIKit
import CoreFoundation
import AVFoundation
import AudioToolbox

public class NKJMultiMovieCaptureView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    public var movieURLs:[NSURL] = []
    
    var touching:Bool = false
    var captureSession = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer!
    var assetWriter:AVAssetWriter?
    var assetWriterInputVideo:AVAssetWriterInput!
    var assetWriterInputAudio:AVAssetWriterInput!
    var captureVideoOutput:AVCaptureVideoDataOutput!
    var captureAudioOutput:AVCaptureAudioDataOutput!
    
    var videoSettings = [NSObject : AnyObject]()
    var audioSettings = [NSObject : AnyObject]()
    
    var recordStartTime = kCMTimeZero
    var outputURL:NSURL?
    var movieWritingQueue:dispatch_queue_t?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.userInteractionEnabled = true
        self.backgroundColor = UIColor.blackColor()
        
        // device
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        // video
        var videoInput: AVCaptureDeviceInput!
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch var error as NSError {
            videoInput = nil
            fatalError("error: \(error!.localizedDescription)")
        }

        var videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]

        // audio
        var audioCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        var audioInput: AVCaptureDeviceInput!
        do {
            audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
        } catch var error as NSError {
            audioInput = nil
            fatalError("error: \(error!.localizedDescription)")
        }

        var audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())

        // setting camera
        var videoConnection:AVCaptureConnection? = nil
        self.captureSession.beginConfiguration()
        
        for connection in videoOutput.connections {
            
            if let captureConnection = connection as? AVCaptureConnection {

                for port in captureConnection.inputPorts {
                    
                    print("\(port)")
                    if let inputPort = port as? AVCaptureInputPort {
                        
                        if inputPort.mediaType == AVMediaTypeVideo {
                            videoConnection = captureConnection
                        }
                    }
                }
                
            }
            
        }
        
        // portrait orientation
        videoConnection?.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        // initialize capture session
        if self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput)
        }
        
        if self.captureSession.canAddOutput(videoOutput) {
            self.captureSession.addOutput(videoOutput)
        }
        
        if self.captureSession.canAddInput(audioInput) {
            self.captureSession.addInput(audioInput)
        }
        
        if self.captureSession.canAddOutput(audioOutput) {
            self.captureSession.addOutput(audioOutput)
        }
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        
        // PreviewLayer
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        
        // aspect
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        // display size
        var rootLayer = self.layer
        rootLayer.masksToBounds = true
        self.previewLayer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height)
        rootLayer.addSublayer(self.previewLayer)
        
        // reflection a changes
        self.captureSession.commitConfiguration()
        
        // session start
        self.captureSession.startRunning()
        
        // video setting
        self.videoSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: 1280,
            AVVideoHeightKey: 720,
            AVVideoCompressionPropertiesKey: [AVVideoMaxKeyFrameIntervalKey: 30]
        ]
        
        self.audioSettings = [
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVChannelLayoutKey: NSData()
        ]
        
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Method
    
    public func setVideoSettingWithDictionary(settings: Dictionary<NSObject, AnyObject>) {
        for keyName in settings.keys {
            self.videoSettings[keyName] = settings[keyName]
        }
    }

    public func setAudioSettingWithDictionary(settings: Dictionary<NSObject, AnyObject>) {
        for keyName in settings.keys {
            self.audioSettings[keyName] = settings[keyName]
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
    
        if CMSampleBufferDataIsReady(sampleBuffer) == 0 {
            print("sampleBuffer data is not ready")
        }
        
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if self.touching {

            if captureOutput.isKindOfClass(AVCaptureVideoDataOutput.self) { // video
                self.addSamplebuffer(sampleBuffer, assetWriterInput: self.assetWriterInputVideo as AVAssetWriterInput)
            } else if captureOutput.isKindOfClass(AVCaptureAudioDataOutput.self) { // audio
                self.addSamplebuffer(sampleBuffer, assetWriterInput: self.assetWriterInputAudio as AVAssetWriterInput)
            }
            
        }
        
        self.recordStartTime = currentTime;
    }
    
    func addSamplebuffer(sampleBuffer: CMSampleBufferRef, assetWriterInput: AVAssetWriterInput) {

        var formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)

        dispatch_async(self.movieWritingQueue!) { () -> Void in
            
            if !assetWriterInput.readyForMoreMediaData {
                print("Not ready for data")
            }
            
            if self.assetWriter?.status == AVAssetWriterStatus.Unknown {
                print("AVAssetWriterStatus.Unknown")
            }

            if self.assetWriter?.status == AVAssetWriterStatus.Writing {
                //println("AVAssetWriterStatus.Writing")
                
                if assetWriterInput.readyForMoreMediaData {

                    if !assetWriterInput.appendSampleBuffer(sampleBuffer) {
                        print("\(self.assetWriter?.error)");
                    }
                    
                }

            } else if self.assetWriter?.status == AVAssetWriterStatus.Failed {
                print("AVAssetWriterStatus.Failed")
            } else if self.assetWriter?.status == AVAssetWriterStatus.Cancelled {
                print("AVAssetWriterStatus.Cancelled")
            } else if self.assetWriter?.status == AVAssetWriterStatus.Completed {
                print("AVAssetWriterStatus.Completed")
            }
            
        }
        
    }

    // MARK: - Touch Events
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        self.touching = true
        
        let fileName = String(format: "output%02d.mov", arguments: [self.movieURLs.count + 1])
        let outputPath = NSTemporaryDirectory().stringByAppendingString(fileName)
        self.outputURL = NSURL(fileURLWithPath: outputPath)
        
        // delete file before save the one
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(outputPath) {
            
            do {
                try fileManager.removeItemAtPath(outputPath)
            } catch let error as NSError {
                print("failed deleting file (\(error.localizedDescription))")
            }
        }

        // AVAssetWriter
        do {

            self.assetWriter = try AVAssetWriter(URL: self.outputURL, fileType: AVFileTypeQuickTimeMovie)
        } catch let error as NSError {
            self.assetWriter = nil
            print("creation of assetWriter resulting in a non-nil error ((\(error.localizedDescription)))")
        }
        
        // movie
        self.assetWriterInputVideo = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: self.videoSettings)
        self.assetWriterInputVideo.expectsMediaDataInRealTime = true
        if self.assetWriterInputVideo == nil {
            print("assetWriterInputVideo is nil")
        }
        
        // audio
        self.assetWriterInputAudio = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: self.audioSettings)
        self.assetWriterInputAudio.expectsMediaDataInRealTime = true
        if self.assetWriterInputAudio == nil {
            print("assetWriterInputAudio is nil")
        }
        
        self.assetWriter?.addInput(self.assetWriterInputVideo)
        self.assetWriter?.addInput(self.assetWriterInputAudio)
        
        // queue
        self.movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL)

        // record
        dispatch_async(self.movieWritingQueue!, { () -> Void in
            self.assetWriter?.startWriting()
            self.assetWriter?.startSessionAtSourceTime(self.recordStartTime)
        })
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        self.touching = false
        
        //println("[stopping recording] duration :\(CMTimeGetSeconds(self.recordStartTime))")
        self.assetWriterInputVideo.markAsFinished()
        self.assetWriterInputAudio.markAsFinished()
        self.assetWriter?.endSessionAtSourceTime(self.recordStartTime)
        self.assetWriter?.finishWritingWithCompletionHandler({ () -> Void in

            //println("self.assetWriter finishWritingWithCompletionHandler")
            self.movieURLs.append(self.outputURL!)
            //println("\(self.outputURL)")
        })
        
    }

}
