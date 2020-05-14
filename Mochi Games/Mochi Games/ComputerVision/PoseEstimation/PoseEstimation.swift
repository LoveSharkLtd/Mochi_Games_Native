//
//  PoseEstimation.swift
//  Unity-iPhone
//
//  Created by Richmond Alake on 29/04/2020.
//

import Foundation
import Vision

protocol PoseEstimationDelegate{
    func didUpdatePoseEstimationData(poseEstimationData: String, rightWristCordinate: Any)
}

class PoseEstimation {
    var poseEstimationDelegate: PoseEstimationDelegate!
    
    // Pose estimation models (cpm_model or stacked_hourglass)
    typealias EstimationModel = cpm_model
    
    var postProcessor: HeatmapPostProcessor = HeatmapPostProcessor()
    var mvfilters: [MovingAverageFilter] = []
    
    // Detect when the model is performing inference/prediction
    var isInferencing = false
    // Post Image processing
    var request: VNCoreMLRequest?
    // COREML Container
    var visionModel: VNCoreMLModel?
    
    // Ready to capture pose indicator, only send pose information once pose infromation surpases a level of confidence
    private var poseEstimationCalibarated = false
    
    // Information to send to Unity
    var fullPoseInformationToSendToUnity: String = "{\"DJDerekData\" : { \"isGettingLow\" : false, \"isShoulderBrush\" : false, \"isHandsUp\" : false, \"calibrated\" : false }}"
    
    init() {
        // Prepare models
        setUpModel()
    }
    
    // SetUp Core ML Models
    private func setUpModel() {
        // Set up Pose Estimation Model (Stacked Hour Glass / Convolutional Pose Machines)
        if let visionModel = try? VNCoreMLModel(for: EstimationModel().model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("Cannot load the ml model")
        }
    
    }
    
    // Inferencing For Pose Esitmation
    func runPoseEstimation(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }

        // vision framework configures the input size of the image following our models's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
        self.isInferencing = false
    }
    
    // Post Processing for Pose Estimation
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if #available(iOS 12.0, *) {
        
        }
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
        let heatmaps = observations.first?.featureValue.multiArrayValue {
        
            // Post-Processing
            // convert heatmap to point array
            // using isFlipped set to true as we are using front camera
            var predictedPoints = postProcessor.convertToPredictedPoints(from: heatmaps, isFlipped: true)
            
            // Moving average filter
            if predictedPoints.count != mvfilters.count{
                mvfilters = predictedPoints.map { _ in MovingAverageFilter(limit:3)}
            }
            
            for (predictedPoint, filter) in zip(predictedPoints, mvfilters) {
                filter.add(element: predictedPoint)
            }
            
            predictedPoints = mvfilters.map { $0.averagedValue() }
            
            DispatchQueue.main.sync {
    
                // Calcualate pose and joint movement
                self.poseEstimationKeypointInformation(with: predictedPoints)
                self.isInferencing = false
    
                if #available(iOS 12.0, *) {
                
                }
            }
    
        } else {
            self.isInferencing = false
        }
    }
    
    
    // Pose estimation keypoint detection
    func poseEstimationKeypointInformation(with n_kpoints: [PredictedPoint?]) {
        
        // Gestures to be identified. Tied in with Unity
        var poseGestureInformation:[String: Bool?] = [
            "isGettingLow": false,
            "isShoulderBrush": false,
            "isHandsUp": false,
            "calibrated": self.poseEstimationCalibarated,
            "woah": false,
            "clap": false
        ]
        
        // Labels and position of joint keypoint
        let pointLabels: [String] = [
            "top",          //0
            "neck",         //1
            "R shoulder",   //2
            "R elbow",      //3
            "R wrist",      //4
            "L shoulder",   //5
            "L elbow",      //6
            "L wrist",      //7
            "R hip",        //8
            "R knee",       //9
            "R ankle",      //10
            "L hip",        //11
            "L knee",       //12
            "L ankle",      //13
        ]
        
        // Getting position of all joints for later use
        let headPosition = pointLabels.index(of: "top" )!
        let rightShoulderPosition = pointLabels.index(of: "R shoulder" ) as! Int
        let leftShoulderPosition = pointLabels.index(of: "L shoulder" ) as! Int
        let leftHipPosition = pointLabels.index(of: "L hip" ) as! Int
        let rightHipPosition = pointLabels.index(of: "R hip" ) as! Int
        let rightWristPosition = pointLabels.index(of: "R wrist") as! Int
        let leftWristPosition = pointLabels.index(of: "L wrist") as! Int
        let rightElbowPosition = pointLabels.index(of: "R elbow") as! Int
        let leftElbowPosition = pointLabels.index(of: "L elbow") as! Int


        // Setting gesture threshold and confidence values
        let heightThresholdValue = Float(0.3)
        // Used for distance between hips and wrist
        let secondaryHeightThresholdValue = Float(0.5)
        let confidenceThresholdValue = Float(0.9)
        let brushingShouldersThresholdValue = Float(0.08)
        
        // Get all location coordinates of key joints
        let headJointPositionCordinates = (n_kpoints[headPosition] != nil) ? [Float(n_kpoints[headPosition]!.maxPoint.x), Float(n_kpoints[headPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let rightHipJointPositionCordinates = (n_kpoints[rightHipPosition] != nil) ? [Float(n_kpoints[rightHipPosition]!.maxPoint.x), Float(n_kpoints[rightHipPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let leftHipJointPositionCordinates = (n_kpoints[leftHipPosition] != nil) ? [Float(n_kpoints[leftHipPosition]!.maxPoint.x), Float(n_kpoints[leftHipPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let rightWristJointPositionCordinates = (n_kpoints[rightWristPosition] != nil) ? [Float(n_kpoints[rightWristPosition]!.maxPoint.x), Float(n_kpoints[rightWristPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let leftShoulderJointPositionCordinates = (n_kpoints[leftShoulderPosition] != nil) ? [Float(n_kpoints[leftShoulderPosition]!.maxPoint.x), Float(n_kpoints[leftShoulderPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let leftWristJointPositionCordinates = (n_kpoints[leftWristPosition] != nil) ? [Float(n_kpoints[leftWristPosition]!.maxPoint.x), Float(n_kpoints[leftWristPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let rightShoulderJointPositionCordinates = (n_kpoints[rightShoulderPosition] != nil) ? [Float(n_kpoints[rightShoulderPosition]!.maxPoint.x), Float(n_kpoints[rightShoulderPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let rightElbowJointPositionCordinates = (n_kpoints[rightElbowPosition] != nil) ? [Float(n_kpoints[rightElbowPosition]!.maxPoint.x), Float(n_kpoints[rightElbowPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
        let leftElbowJointPositionCordinates = (n_kpoints[leftElbowPosition] != nil) ? [Float(n_kpoints[leftElbowPosition]!.maxPoint.x), Float(n_kpoints[leftElbowPosition]!.maxPoint.y)] : [Float(0.0), Float(0.0)]
    
        // Utilising primarily y component of the joint cordinate for vertical distance
        let distanceBetweenHeadAndRightHip = sqrt(powf((Float(headJointPositionCordinates[1]) - Float(rightHipJointPositionCordinates[1])), 2))
        let distanceBetweenHeadAndLeftHip = sqrt(powf((Float(headJointPositionCordinates[1]) - Float(rightHipJointPositionCordinates[1])), 2))
        let distanceBetweenRightWristAndLeftShoulder = sqrt(powf((Float(leftShoulderJointPositionCordinates[1]) - Float(rightWristJointPositionCordinates[1])), 2))
        let distanceBetweenLeftWristAndRightShoulder = sqrt(powf((Float(rightShoulderJointPositionCordinates[1]) - Float(leftWristJointPositionCordinates[1])), 2))
        let distanceBetweenLeftWristAndLeftHip = sqrt(powf((Float(leftHipJointPositionCordinates[1]) - Float(leftWristJointPositionCordinates[1])), 2))
        let distanceBetweenRightWristAndRightHip = sqrt(powf((Float(rightHipJointPositionCordinates[1]) - Float(rightWristJointPositionCordinates[1])), 2))
        let distanceBetweenLeftWristAndHead = sqrt(powf((Float(headJointPositionCordinates[1]) - Float(leftWristJointPositionCordinates[1])), 2))
        let distanceBetweenRightWristAndHead = sqrt(powf((Float(headJointPositionCordinates[1]) - Float(rightWristJointPositionCordinates[1])), 2))
        let distanceBetweenLeftWristAndRightElbow = sqrt(powf((Float(rightElbowJointPositionCordinates[1]) - Float(leftWristJointPositionCordinates[1])), 2))
        let distanceBetweenRightWristAndLeftElbow = sqrt(powf((Float(leftElbowJointPositionCordinates[1]) - Float(rightWristJointPositionCordinates[1])), 2))
        let distanceBetweenLeftWristAndLeftShoulder = sqrt(powf((Float(leftShoulderJointPositionCordinates[1]) - Float(leftWristJointPositionCordinates[1])), 2))
        let distanceBetweenRightWristAndRightShoulder = sqrt(powf((Float(rightShoulderJointPositionCordinates[1]) - Float(rightWristJointPositionCordinates[1])), 2))

    
        // Utilising the x component of the joint for horizontal distance
        let distanceBetweenRightWristAndLeftWrist = sqrt(powf((Float(leftWristJointPositionCordinates[0]) - Float(rightWristJointPositionCordinates[0])), 2))
        
        // Confidence score of all main joints
        let rightHipJointPositionConfidence = (n_kpoints[rightHipPosition] != nil) ? Float(n_kpoints[rightHipPosition]!.maxConfidence) : Float(0.0)
        let leftHipJointPositionConfidence = (n_kpoints[leftHipPosition] != nil) ? Float(n_kpoints[leftHipPosition]!.maxConfidence) : Float(0.0)
        let headJointPositionConfidence = (n_kpoints[headPosition] != nil) ? Float(n_kpoints[headPosition]!.maxConfidence) : Float(0.0)
        let rightWristJointPositionConfidence = (n_kpoints[rightWristPosition] != nil) ? Float(n_kpoints[rightWristPosition]!.maxConfidence) : Float(0.0)
        let leftShoulderJointPositionConfidence = (n_kpoints[leftShoulderPosition] != nil) ? Float(n_kpoints[leftShoulderPosition]!.maxConfidence) : Float(0.0)
        let rightShoulderJointPositionConfidence = (n_kpoints[rightShoulderPosition] != nil) ? Float(n_kpoints[rightShoulderPosition]!.maxConfidence) : Float(0.0)
        let leftWristJointPositionConfidence = (n_kpoints[leftWristPosition] != nil) ? Float(n_kpoints[leftWristPosition]!.maxConfidence) : Float(0.0)
    
    
        // Pose estimation is ready once all major joints have a high confidence score
        if (leftWristJointPositionConfidence > confidenceThresholdValue &&
            rightWristJointPositionConfidence > confidenceThresholdValue &&
            leftShoulderJointPositionConfidence > confidenceThresholdValue &&
            rightShoulderJointPositionConfidence > confidenceThresholdValue &&
            headJointPositionConfidence > confidenceThresholdValue &&
            leftHipJointPositionConfidence > confidenceThresholdValue &&
            rightHipJointPositionConfidence > confidenceThresholdValue) {
            poseGestureInformation["calibrated"] = true
        }
    
//
//    print("------------------------------------------")
//    print("------------------------------------------")
//    print("!! Distance between wrisrts \(distanceBetweenRightWristAndLeftWrist)") //0.04
//    print("!! Distance between left shoulder and left wrist \(distanceBetweenLeftWristAndLeftShoulder)")
//
        //if (self.poseEstimationCalibarated) {
            // MARK: LOW GESTURE
            // Use the distance between the head and the right hip to detect when the user is going low
            if (headJointPositionConfidence > confidenceThresholdValue) {
                if (distanceBetweenHeadAndRightHip <= heightThresholdValue) {
                    poseGestureInformation["isGettingLow"] = true
                } else {
                    poseGestureInformation["isGettingLow"] = false
                }
            } else {
                poseGestureInformation["isGettingLow"] = false
            }
            
            // MARK:BRUSHING SHOULDER GESTURE
            // Distance of right wrist to left shoulder
            if (rightWristJointPositionConfidence > confidenceThresholdValue) {
                if (distanceBetweenRightWristAndLeftShoulder <= brushingShouldersThresholdValue) {
                    poseGestureInformation["isShoulderBrush"] = true
                } else {
                    poseGestureInformation["isShoulderBrush"] = false
                }
            } else {
                poseGestureInformation["isShoulderBrush"] = false
            }
        
            // Distance of left wrist to right shoulder
            // Only check for distance between the left wrist to right shoulder if user if not already brushing shoulder
            if (poseGestureInformation["isShoulderBrush"] == false) {
                if (leftWristJointPositionConfidence > confidenceThresholdValue) {
                    if (distanceBetweenLeftWristAndRightShoulder <= brushingShouldersThresholdValue) {
                        poseGestureInformation["isShoulderBrush"] = true
                    } else {
                        poseGestureInformation["isShoulderBrush"] = false
                    }
                } else {
                    poseGestureInformation["isShoulderBrush"] = false
                }
            }
    
            // MARK: HANDS UP GESTURE
            if (headJointPositionConfidence > confidenceThresholdValue) {
                if (distanceBetweenRightWristAndRightHip >= secondaryHeightThresholdValue || distanceBetweenLeftWristAndLeftHip >= secondaryHeightThresholdValue) {
                    poseGestureInformation["isHandsUp"] = true
                }
            }

            // MARK: WOAH
            if (distanceBetweenLeftWristAndHead <= 0.25 && distanceBetweenLeftWristAndRightShoulder <= 0.1 && distanceBetweenRightWristAndLeftWrist <= 0.1) {
                poseGestureInformation["woah"] = true
            }  else if (distanceBetweenRightWristAndHead <= 0.25 && distanceBetweenRightWristAndLeftShoulder <= 0.25 && distanceBetweenRightWristAndLeftWrist <= 0.1) {
                poseGestureInformation["woah"] = true
            } else {
                poseGestureInformation["woah"] = false
            }
    
            // MARK: 'X' With arms
            if (distanceBetweenLeftWristAndRightElbow <= 0.05 && distanceBetweenRightWristAndLeftElbow <= 0.05 && distanceBetweenRightWristAndLeftWrist <= 0.05) {
                poseGestureInformation["x_with_arms"] = true
            } else {
                poseGestureInformation["x_with_arms"] = false
            }
    
    
            // MARK: Clap
            if (distanceBetweenRightWristAndLeftWrist  <= 0.2) {
                poseGestureInformation["clap"] = true
            }
    
            // MARK: Mop
            if (distanceBetweenRightWristAndLeftWrist <= 0.2 && (distanceBetweenLeftWristAndLeftShoulder <= 0.15 || distanceBetweenRightWristAndRightShoulder <= 0.15)) {
                poseGestureInformation["mop"] = true
            } else {
                poseGestureInformation["mop"] = true
            }
                
            // Encode gesture dictionary as JSON string and cache the json string
            if let jsonNewData = try? JSONEncoder().encode(poseGestureInformation) {
                if let jsonNewString = String(data: jsonNewData, encoding: .utf8) {
                    self.fullPoseInformationToSendToUnity = jsonNewString
                    self.poseEstimationDelegate?.didUpdatePoseEstimationData(poseEstimationData: jsonNewString, rightWristCordinate: rightWristJointPositionCordinates)
                }
            }
        //}
    
        
        // Encoding all keypoints as JSON objects
//        let keypoints = Dictionary(uniqueKeysWithValues: zip(pointLabels, n_kpoints))
    
        // Getting all the pose coordinates in json
//        if let jsonData = try? JSONEncoder().encode(keypoints) {
//            if let jsonString = String(data: jsonData, encoding: .utf8) {
//                // Pose information
//                // Encoding all pose gesture information
//            }
//        }
    
    }

}
