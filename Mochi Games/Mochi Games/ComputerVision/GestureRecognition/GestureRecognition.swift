//
//  GestureRecognition.swift
//  Unity-iPhone
//
//  Created by Richmond Alake on 29/04/2020.
//

import Foundation
import CoreImage

protocol GestureRecognitionDelegate {
    func didUpdateGestureData(gestureResult: Any)
}

class GestureRecognition {
    var gestureRecognitionDelegate: GestureRecognitionDelegate!
    // TensorFlow Lite Gesture Recognition Model
    // Handles all data preprocessing and makes calls to run inference
    private var modelDataHandler = ModelDataHandler(modelFileInfo: Model.modelInfo, labelsFileInfo: Model.labelsInfo)
    
    
    func runGestureRecognition(pixelBuffer: CVPixelBuffer) {
        let result = modelDataHandler?.runModel(onFrame: pixelBuffer)
        gestureRecognitionDelegate.didUpdateGestureData(gestureResult: result)
        
    }

}
