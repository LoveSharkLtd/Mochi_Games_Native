//
//  BodyTrackingData.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/14/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import CoreImage


struct BodyTrackingData {
    var top : BodyTrackingPositions
    var neck : BodyTrackingPositions
    var shoulders : BodyTrackingPositions
    var elbow : BodyTrackingPositions
    var wrist : BodyTrackingPositions
    var hip : BodyTrackingPositions
    var knee : BodyTrackingPositions
    var ankle : BodyTrackingPositions
}

struct BodyTrackingPositions {
    var left : CGPoint?
    var middle : CGPoint?
    var right : CGPoint?
    var confidenceLeft : Double?
    var confidenceMiddle : Double?
    var confidenceRight : Double?
}

