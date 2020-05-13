//
//  SemanticSegmentation.swift
//  Unity-iPhone
//
//  Created by Richmond Alake on 29/04/2020.
//

import Foundation
import Vision
import AVFoundation
import UIKit

protocol SemanticSegmentaitonDelegate {
    func didUpdateSemanticResult(semanticResult: String)
  }

class SemanticSegementation {
    
    var semanticSegmenationDelegate: SemanticSegmentaitonDelegate!
    
    // Vision Requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    // Image segmentator instance that runs image segmentation
    private var imageSegmentator: ImageSegmentator?
    // Target image to run image segmentation on.
    private var targetImage: UIImage?
    // Processed (e.g center cropped)) image from targetImage that is fed to imageSegmentator.
    private var segmentationInput: UIImage?
    // Image segmentation result.
    private var segmentationResult: SegmentationResult?
        
    // Detect when conducting inference
    var isInferencing = false

    
    
    init() {
        // Initialize an image segmentator instance.
        ImageSegmentator.newInstance { result in
          switch result {
          case let .success(segmentator):
            // Store the initialized instance for use.
            self.imageSegmentator = segmentator
          case .error(_):
            print("Failed to initialize.")
          }
        }
    }
    
    func runSemanticSegmentation(_ image: UIImage, sampleBuffer: CMSampleBuffer ) {
    
        var semanticSegmenationInformation:[String: Array<Int>?] = [
            "pixelData": [],
            "imageHeight": [],
            "imageWidth": []
        ]
    
        
        // Ensure image segmentator is intialized
        guard imageSegmentator != nil else {
            print("ERROR: Image Segmentator is not ready")
            return
        }
    
        // Cache the image
        self.targetImage = image
    
        // potentially cropped image as input to the segmentation model
        segmentationInput = image
        
        // Make sure the image is ready before performing segmentation
        guard image != nil else {
            print ("ERROR: There are no images present for segmentation")
            return
        }
        
        // Run Image segmenation
    
         imageSegmentator?.runSegmentation(
          image,
          completion: { result in
    
            // Show the segmentation result on screen
            switch result {
            case let .success(segmentationResult):
                self.segmentationResult = segmentationResult
                
                // Flatten array into 1D
                semanticSegmenationInformation["pixelData"] = segmentationResult.array.flatMap { $0 }
                semanticSegmenationInformation["imageHeight"] = [257] //segmentationResult.array.count
                semanticSegmenationInformation["imageWidth"] = [257]

                // Get the segmenation result mask and change dimension, then derive pixel data from image
//                let resizedImage = segmentationResult.resultImage.resized(to: CGSize(width: 500, height: 500))
//                let pixelData = resizedImage.pixelData()

                if let semanticSegmentationInformationJSON = try? JSONEncoder().encode(semanticSegmenationInformation) {
                    if let semanticSegmentationInformationSTRING = String(data: semanticSegmentationInformationJSON, encoding: .utf8) {
//                        self.segmentationResultToSendToUnity = semanticSegmentationInformationSTRING
                        //DispatchQueue.main.async {
                            self.semanticSegmenationDelegate?.didUpdateSemanticResult(semanticResult: semanticSegmentationInformationSTRING)
                        //}
                        
                    }
                }

                self.isInferencing = false
            case let .error(error):
                print(error.localizedDescription)
            }
          })
    }
    
}
