//
//  BodyTrackingData.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/14/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation


struct BodyTrackingData {
    var top : [Float]
    var neck : BodyTrackingPositions
    var shoulders : BodyTrackingPositions
    var elbow : BodyTrackingPositions
    var wrist : BodyTrackingPositions
    var hip : BodyTrackingPositions
    var knee : BodyTrackingPositions
    var ankle : BodyTrackingPositions
}

struct BodyTrackingPositions {
    var left : [Float]
    var right : [Float]
    var confidenceLeft : Float
    var confidenceRight : Float
}

