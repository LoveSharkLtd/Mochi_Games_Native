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
    func didUpdatePoseEstimationData(poseEstimationData: Any, rightWristCordinate: Any)
    func didUpdateFaceDetectionData(faceDetectionData: Any)
    func didUpdateSemanticSegmentationData(semanticSegmentationData: Any)
}

class CVInterface {
    
    var cvInterfaceDelegate: CVInterfaceDelegate!
        
    // Instances of CV techniques
    private let gestureRecognition = GestureRecognition()
    private let poseEstimation = PoseEstimation()
    private let faceDetection = FaceAndFacialFeaturesDetection()
    private let semanticSegmentation = SemanticSegementation()
    
    
    func load() {
        self.gestureRecognition.gestureRecognitionDelegate = self
        self.poseEstimation.poseEstimationDelegate = self
        self.faceDetection.faceAndFacialFeaturesDetectionDelegate = self
        self.semanticSegmentation.semanticSegmenationDelegate = self
        Camera.shared().delegate = self
        Camera.shared().setUp()
    }
    
}

extension CVInterface: CameraDelegate {
    
    func cameraSessionDidBegin() {
    
    }

    func didUpdatePixelBuffer(pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, sampleBuffer: CMSampleBuffer) {
        self.cvInterfaceDelegate?.didUpdatePixelBuffer(pixelBuffer: pixelBuffer, formatDescription: formatDescription)
        self.gestureRecognition.runGestureRecognition(pixelBuffer: pixelBuffer)
        self.poseEstimation.runPoseEstimation(pixelBuffer: pixelBuffer)
        self.faceDetection.runFaceAndFacialFeatureDetection(sampleBuffer: sampleBuffer)
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        let cg_image = context.createCGImage(image, from: image.extent)!
        self.semanticSegmentation.runSemanticSegmentation(UIImage(cgImage: cg_image), sampleBuffer: sampleBuffer)
    }
    
}

extension CVInterface: GestureRecognitionDelegate {
    func didUpdateGestureData(gestureResult: Any) {
        self.cvInterfaceDelegate?.didUpdateGestureRecognitionData(gestureRecognitionData: gestureResult)
    }
}

extension CVInterface: PoseEstimationDelegate {
    func didUpdatePoseEstimationData(poseEstimationData: String, rightWristCordinate: Any) {
        self.cvInterfaceDelegate?.didUpdatePoseEstimationData(poseEstimationData: poseEstimationData, rightWristCordinate: rightWristCordinate)
    }
}

extension CVInterface: FaceAndFacialFeaturesDetectionDelegate {
    func didUpdateFaceDetectionBoundingBox(boundingBox: Any) {
        self.cvInterfaceDelegate?.didUpdateFaceDetectionData(faceDetectionData: boundingBox)
    }
}

extension CVInterface: SemanticSegmentaitonDelegate {
    func didUpdateSemanticResult(semanticResult: String) {
        self.cvInterfaceDelegate?.didUpdateSemanticSegmentationData(semanticSegmentationData: semanticResult)
    }
}
