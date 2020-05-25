//
//  FaceAndFacialFeaturesDetection.swift
//  Unity-iPhone
//
//  Created by Richmond Alake on 04/05/2020.
//

import Foundation
import Vision
import CoreMedia

protocol FaceAndFacialFeaturesDetectionDelegate {
    func didUpdateFaceDetectionBoundingBox(boundingBox: FaceDetectionData)
}

class FaceAndFacialFeaturesDetection {
    var faceAndFacialFeaturesDetectionDelegate: FaceAndFacialFeaturesDetectionDelegate!
    
     /// Vision Requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    init() {
        self.prepareVisionRequest()
    }
    
    private func prepareVisionRequest() {
        var requests = [VNTrackObjectRequest]()

        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
            if error != nil {
                print("count: error")
            }

            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else { return }

            // DispatchQueue.main.sync {
                // Add observation to the tracking list
                for observation in results {
                    let faceTrackRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                    requests.append(faceTrackRequest)
                }

                self.trackingRequests = requests
            //}
        })

        // Detect Face and then track it
        self.detectionRequests = [faceDetectionRequest]

        self.sequenceRequestHandler = VNSequenceRequestHandler()
        
    }
    
    func runFaceAndFacialFeatureDetection(sampleBuffer: CMSampleBuffer) {
        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
    
        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }

        let exifOrientation:CGImagePropertyOrientation = .leftMirrored

        
        guard let requests = self.trackingRequests, !requests.isEmpty else {
            // No tracking object detected, so perform initial detection
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)

            do {
                guard let detectRequests = self.detectionRequests else {
                    return
                }
                try imageRequestHandler.perform(detectRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceRectangleRequest: %@", error)
            }
            return
        }
        
        do {
            try self.sequenceRequestHandler.perform(requests,
                                                     on: pixelBuffer,
                                                     orientation: exifOrientation)
        } catch let error as NSError {
            NSLog("Failed to perform SequenceRequest: %@", error)
        }
    
        // Setup the next round of tracking.
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in requests {
            
            guard let results = trackingRequest.results else {
                return
            }
            
            guard let observation = results[0] as? VNDetectedObjectObservation else {
                return
            }
            
            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        self.trackingRequests = newTrackingRequests
        
        if newTrackingRequests.isEmpty {
            // Nothing to track, so abort.
            return
        }
    
        // Perform face landmark tracking on detected faces.
        var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()
        
        // Perform landmark detection on tracked faces.
        for trackingRequest in newTrackingRequests {
            
            let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
                
                if error != nil {
                    print("FaceLandmarks error: \(String(describing: error)).")
                }
                
                guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
                    let results = landmarksRequest.results as? [VNFaceObservation] else {
                        return
                }
                
                //DispatchQueue.main.sync {
                    // Results array contains each detected face observation.
                    // The implementation below communicates the bounding box for each observation at a time
                    // as opposed to a batch update of result
                    for faceObservation in results {
                        let faceData = FaceDetectionData(x: faceObservation.boundingBox.origin.y, y: faceObservation.boundingBox.origin.x, height: faceObservation.boundingBox.width, width: faceObservation.boundingBox.height)
                        self.faceAndFacialFeaturesDetectionDelegate?.didUpdateFaceDetectionBoundingBox(boundingBox: faceData)
//                        print("bounding box:  \(faceObservation.boundingBox)")
                    }
                // }
            })
            
            guard let trackingResults = trackingRequest.results else {
                return
            }
            
            guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
                return
            }
            let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
            faceLandmarksRequest.inputFaceObservations = [faceObservation]
            
            // Continue to track detected facial landmarks.
            faceLandmarkRequests.append(faceLandmarksRequest)
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)
            
            do {
                try imageRequestHandler.perform(faceLandmarkRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceLandmarkRequest: %@", error)
            }
        }
        
    }
}
