//
//  NKJMultiMovieCaptureView.swift
//  Pods
//
//  Created by nakajijapan on 6/19/15.
//
//

import UIKit
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
        var error:NSError?
        var videoInput = AVCaptureDeviceInput(device: device, error: &error)
        if error != nil {
            fatalError("error: \(error!.localizedDescription)")
        }
        var videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]

        // audio
        var audioCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        var audioInput = AVCaptureDeviceInput(device: audioCaptureDevice, error: &error)
        var audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())

        // setting camera
        var videoConnection:AVCaptureConnection? = nil
        self.captureSession.beginConfiguration()
        
        for connection in videoOutput.connections {
            
            if let captureConnection = connection as? AVCaptureConnection {

                for port in captureConnection.inputPorts {
                    
                    println("\(port)")
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

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
