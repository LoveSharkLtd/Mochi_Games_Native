//
//  CVInterface.swift
//  Mochi Games
//
//  Created by Richmond Alake on 11/05/2020.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import CoreImage
import CoreMedia
import UIKit


protocol CVInterfaceDelegate {
    func didUpdatePixelBuffer(pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription)
    func didUpdateGestureRecognitionData(gestureRecognitionData: Any)
    func didUpdatePoseEstimationData(poseEstimationData: Any, bodyTrackingData: BodyTrackingData, points: [PredictedPoint?], gestureInformation: GestureRecongnitionInformation)
    func didUpdateFaceDetectionData(faceDetectionData: FaceDetectionData)
    func didUpdateSemanticSegmentationData(semanticSegmentationData: SemanticSegmentationInformation)
}

class CVInterface {
    
    var cvInterfaceDelegate: CVInterfaceDelegate?
        
    // Instances of CV techniques
    private var gestureRecognition : GestureRecognition? // GestureRecognition()
    private var poseEstimation : PoseEstimation? // PoseEstimation()
    private var faceDetection : FaceAndFacialFeaturesDetection? // FaceAndFacialFeaturesDetection()
    private var semanticSegmentation : SemanticSegementation? // SemanticSegementation()
    
    var framesSinceLastPass : Int = 0
    var frameInterval : Int = 1
    var isInferencing : Bool = false
    
    func loadAll() {
        self.loadCameraAndRun()
        self.loadFaceDetection()
        self.loadPoseEstimation()
        self.loadGestureRecognition()
        self.loadSemanticSegmentation()
    }
    
    // MARK: - GestureRecognition
    
    func loadGestureRecognition() {
        self.gestureRecognition = GestureRecognition()
        self.gestureRecognition?.gestureRecognitionDelegate = self
    }
    
    func destroyGestureRecognition() {
        // TODO: - Add a func inside Gesture Recognition to remove and release from memory
    }
    
    // MARK: - PoseEstimation
    
    func loadPoseEstimation() {
        self.poseEstimation = PoseEstimation()
        self.poseEstimation?.poseEstimationDelegate = self
    }
    
    func destroyPoseEstimation() {
        // TODO: - Add a func inside Pose Estimation to remove and release from memory
    }
    
    // MARK: - FaceDetection
    
    func loadFaceDetection() {
        self.faceDetection = FaceAndFacialFeaturesDetection()
        self.faceDetection?.faceAndFacialFeaturesDetectionDelegate = self
    }
    
    func destroyFaceDetection() {
        // TODO: - Add a func inside Pose Estimation to remove and release from memory
    }
    
    // MARK: - SemanticSegmentation
    
    func loadSemanticSegmentation() {
        self.semanticSegmentation = SemanticSegementation()
        self.semanticSegmentation?.semanticSegmenationDelegate = self
    }
    
    func destroySemanticSegmentation() {
        // TODO: - Add a func inside Semantic Segmentation to remove and release from memory
    }
    
    // MARK: - Camera Controls
    
    // - Loads Camera and sets delegate
    // - !! Doesn't run session - will need to call self.startCameraRunning
    func loadCamera() {
        Camera.shared().delegate = self
        Camera.shared().setUp()
    }
    
    // - Loads Camera, sets delegate and begins the session running
    func loadCameraAndRun() {
        Camera.shared().delegate = self
        Camera.shared().setUpAndRunCamera()
    }
    
    // - Runs Camera session either if set up using loadCamera() or after having been paused
    func startCameraRunning() {
        Camera.shared().runCameraSession()
    }
    
    // - Stops Camera session
    func stopCameraRunning() {
        Camera.shared().stopCameraSession()
    }
    
    // - Will remove and release Camera from memory
    func destroyCameraSession() {
        Camera.shared().destroyCaptureSession()
    }
}


extension CVInterface: CameraDelegate {
    
    // MARK: - Camera Delegates
    
    
    // - Delegate when Camera session has stopped running
    func cameraSessionDidEnd() {
        
    }
    
    // - Delegate when Camera session has started running
    func cameraSessionDidBegin() {

    }

    func didUpdatePixelBuffer(pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, sampleBuffer: CMSampleBuffer) {
         
        let duplicateBuffer = pixelBuffer.duplicatePixelBuffer()
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)

        self.cvInterfaceDelegate?.didUpdatePixelBuffer(pixelBuffer: duplicateBuffer!, formatDescription: formatDescription)
        
        self.gestureRecognition?.runGestureRecognition(pixelBuffer: pixelBuffer)
        self.poseEstimation?.runPoseEstimation(pixelBuffer: pixelBuffer)
        self.faceDetection?.runFaceAndFacialFeatureDetection(sampleBuffer: sampleBuffer)

        /**
            // TODO: Semantic Segmentation
            //        self.frameInterval = -100
            //        if self.framesSinceLastPass > self.frameInterval {
            //            if !self.isInferencing {
            //                self.semanticSegmentation.runSemanticSegmentation(pixelBuffer)
            ////                self.isInferencing = true
            //            }
            //            self.framesSinceLastPass = 0
            //        }

            //        self.framesSinceLastPass += 1
        // */
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }

}
extension CVPixelBuffer {
    func duplicatePixelBuffer() -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let format = CVPixelBufferGetPixelFormatType(self)
        var pixelBufferCopyOptional:CVPixelBuffer?
        let attributes: [String:Any] = [kCVPixelBufferMetalCompatibilityKey as String:kCFBooleanTrue]
        CVPixelBufferCreate(nil, width, height, format, attributes as CFDictionary, &pixelBufferCopyOptional)
        if let pixelBufferCopy = pixelBufferCopyOptional {
            CVPixelBufferLockBaseAddress(self,CVPixelBufferLockFlags.readOnly)
            CVPixelBufferLockBaseAddress(pixelBufferCopy, CVPixelBufferLockFlags(rawValue: 0))
            let baseAddress = CVPixelBufferGetBaseAddress(self)
            let dataSize = CVPixelBufferGetDataSize(self)
            let target = CVPixelBufferGetBaseAddress(pixelBufferCopy)
            memcpy(target, baseAddress, dataSize)
            CVPixelBufferUnlockBaseAddress(pixelBufferCopy, CVPixelBufferLockFlags(rawValue: 0))
            CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        }
        return pixelBufferCopyOptional
    }
}

extension CVInterface: GestureRecognitionDelegate {
    func didUpdateGestureData(gestureResult: Any) {
        self.cvInterfaceDelegate?.didUpdateGestureRecognitionData(gestureRecognitionData: gestureResult)
    }
}

extension CVInterface: PoseEstimationDelegate {
    func didUpdatePoseEstimationData(poseEstimationData: String, bodyTrackingData: BodyTrackingData, points: [PredictedPoint?], gestureInformation: [String : Bool?]) {
//        <#code#>
    }
    
    func didUpdatePoseEstimationData(poseEstimationData: String, bodyTrackingData: BodyTrackingData, points: [PredictedPoint?], gestureInformation: GestureRecongnitionInformation) {
        self.cvInterfaceDelegate?.didUpdatePoseEstimationData(poseEstimationData: poseEstimationData, bodyTrackingData: bodyTrackingData, points: points, gestureInformation: gestureInformation)
    }
}

extension CVInterface: FaceAndFacialFeaturesDetectionDelegate {
    func didUpdateFaceDetectionBoundingBox(boundingBox: FaceDetectionData) {
        self.cvInterfaceDelegate?.didUpdateFaceDetectionData(faceDetectionData: boundingBox)
    }
}

extension CVInterface: SemanticSegmentaitonDelegate {
    func didUpdateSemanticResult(semanticResult: SemanticSegmentationInformation) {
        self.isInferencing = false
        self.cvInterfaceDelegate?.didUpdateSemanticSegmentationData(semanticSegmentationData: semanticResult)
    }
}
