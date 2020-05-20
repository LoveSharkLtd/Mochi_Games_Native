//
//  Camera.swift
//  Mochi Games
//
//  Created by Sam Weekes on 4/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreImage

protocol CameraDelegate {
    func cameraSessionDidBegin()
    func didUpdatePixelBuffer(pixelBuffer : CVPixelBuffer, formatDescription : CMFormatDescription, sampleBuffer: CMSampleBuffer)
}

class Camera : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var delegate : CameraDelegate?
    
    private var captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let videoQueue = DispatchQueue(label: "videoQueue")
    private var videoPreviewLayers : [AVCaptureVideoPreviewLayer] = []
    
    private static var sharedCamera : Camera = {
        let camera = Camera()
        
        return camera
    }()
    
    private override init() {
        super.init()
    }
    
    class func shared() -> Camera {
        return sharedCamera
    }
    
    public func setUp() {
        beginSession(nil)
    }
    
    public func setUp(layerForVideoPreviewLayer : UIView) {
        beginSession(layerForVideoPreviewLayer)
    }
    
    private func beginSession(_ view : UIView?) {
        do {
            
            let deviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
            
            var input : AVCaptureDeviceInput?
            
            if let device = deviceDiscovery.devices.last {
                self.captureDevice = device
                input = try AVCaptureDeviceInput(device: device)
            }
            
            if let _view = view {
                let player = AVCaptureVideoPreviewLayer(session: self.captureSession)
                player.videoGravity = .resizeAspectFill
                player.frame = _view.layer.bounds
                _view.layer.addSublayer(player)
                self.videoPreviewLayers.append(player)
            }

            self.captureSession.addInput(input!)
            
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
            // Discard late video frames as we are working with live data
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
            
            
            // Run the session at 720p.
            captureSession.sessionPreset = .hd1920x1080
            
            // Lock configurationss and cap the FPS at 30
            try! captureDevice!.lockForConfiguration()
            captureDevice!.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(30))
            captureDevice!.unlockForConfiguration()

            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            // We want the buffers to be in portrait orientation otherwise they are
            // rotated by 90 degrees. Need to set this _after_ addOutput()!
            videoDataOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
            
            captureSession.commitConfiguration()

            self.captureSession.startRunning()
            self.delegate?.cameraSessionDidBegin()
        } catch {
            print("!! - Error connecting to capture device. Video Capture will not occur")
        }
    }
    

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processVideo(sampleBuffer : sampleBuffer)
    }
    
    func processVideo(sampleBuffer : CMSampleBuffer) {
        
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        self.delegate?.didUpdatePixelBuffer(pixelBuffer: videoPixelBuffer, formatDescription : formatDescription, sampleBuffer: sampleBuffer)
        
    }
}
