//
//  GameStructs.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/29/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import SpriteKit

struct SKBodyTrackingData {
    var parent : SKNode
    var top : SKNode
    var neck : SKNode
    var shoulders : SKBodyTrackingPositions
    var elbows : SKBodyTrackingPositions
    var wrists : SKBodyTrackingPositions
    var hips : SKBodyTrackingPositions
    var knees : SKBodyTrackingPositions
    var ankles : SKBodyTrackingPositions
}

struct SKBodyTrackingPositions {
    var left : SKNode
    var right : SKNode
}
