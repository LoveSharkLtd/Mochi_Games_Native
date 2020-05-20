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
    func didUpdateSemanticResult(semanticResult: SemanticSegmentationInformation)
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
    
    func runSemanticSegmentation(_ pixelBuffer: CVPixelBuffer ) {
        // Ensure image segmentator is intialized
        guard imageSegmentator != nil else {
            print("ERROR: Image Segmentator is not ready")
            return
        }
    
         imageSegmentator?.runSegmentation(
          pixelBuffer,
          completion: { result in
    
            // Show the segmentation result on screen
            switch result {
            case let .success(segmentationResult):
                self.segmentationResult = segmentationResult
                var semanticSegmenationInformation = SemanticSegmentationInformation()

                
                // Flatten array into 1D
//                semanticSegmenationInformation.pixelData = segmentationResult.array.compactMap { $0 }
                var tempData:[[Int]] = []
                for row in segmentationResult.array {
                    var rowData: [Int] = []
                    for pixel in row {
                        let temp = pixel == 15 ? 1 : 0
                        rowData.append(temp)
                    }
                    tempData.append(rowData)
                }
                semanticSegmenationInformation.pixelData = tempData
                semanticSegmenationInformation.imageHeight = [257] //segmentationResult.array.count
                semanticSegmenationInformation.imageWidth = [257]
                semanticSegmenationInformation.pixelBuffer = segmentationResult.pixelBuffer
//                semanticSegmenationInformation.resultImage = [segmentationResult.resultImage]
//                semanticSegmenationInformation.overlayImage = [segmentationResult.overlayImage]
                                
                // Get the segmenation result mask and change dimension, then derive pixel data from image
//                let resizedImage = segmentationResult.resultImage.resized(to: CGSize(width: 500, height: 500))
//                let pixelData = resizedImage.pixelData()

                //if let semanticSegmentationInformationJSON = try? JSONEncoder().encode(semanticSegmenationInformation) {
                    //if let semanticSegmentationInformationSTRING = String(data: semanticSegmentationInformationJSON, encoding: .utf8) {
//                        self.segmentationResultToSendToUnity = semanticSegmentationInformationSTRING
                        //DispatchQueue.main.async {
                            self.semanticSegmenationDelegate?.didUpdateSemanticResult(semanticResult: semanticSegmenationInformation)
                        //}
                        
                    //}
                //}

                self.isInferencing = false
            case let .error(error):
                print(error.localizedDescription)
            }
          })
    }
    
}

struct SemanticSegmentationInformation {
    var pixelBuffer : CVPixelBuffer?
    var pixelData: [[Int]] = []
    var imageHeight: [Int] = []
    var imageWidth: [Int] = []
    var resultImage: [UIImage] = []
    var overlayImage: [UIImage] = []
}
