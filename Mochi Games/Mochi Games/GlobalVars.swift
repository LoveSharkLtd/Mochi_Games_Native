//
//  GlobalVars.swift
//  Mochi Games
//
//  Created by Sam Weekes on 4/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import UIKit



func createButton(width : CGFloat, height : CGFloat, title : String, textSize : CGFloat?) -> UIButton {
    // Normal rounded button, with a bottom shadow
    // when calling this function will need to do the following
    // 1 - reposition the button (either by .center or .frame.origin)
    // 2 - add Targets to it - MUST INCLUDE ButtonUp / ButtonDown in the functions called (for the button animations)
    // 3 - add to whatever view it's attaching to.
    let fontSize = textSize != nil ? textSize : sHR * 12 / 667 // most common text size is 12 - so can be nil when calling function
    let colorBorder = #colorLiteral(red: 0.6858896613, green: 0.123863779, blue: 0.4012340009, alpha: 1)
    let textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    var w = width
    if (((1920 / 1080) / (sH / sW)) > 1.1 && w / sW >= 0.9) {
        w = sHR * 335 / 667
    }
    
    let btn = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: w, height: height))
    btn.showsTouchWhenHighlighted = false
    
    let border = UIView(frame: CGRect(x: 0.0, y: 0.5 * height + sHR * 3 / 667, width: w, height: height * 0.5))
    border.backgroundColor = colorBorder
    border.isUserInteractionEnabled = false
    border.layer.cornerRadius = sHR * 5 / 667
    btn.addSubview(border)
    
    let bg = UIView(frame: CGRect(x: 0.0, y: 0.0, width: w, height: height))
    bg.backgroundColor = #colorLiteral(red: 0.8549019608, green: 0.1529411765, blue: 0.5019607843, alpha: 1)
    bg.isUserInteractionEnabled = false
    bg.layer.cornerRadius = sHR * 5 / 667
    btn.addSubview(bg)
    
    let txt = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: w, height: height))
    txt.isUserInteractionEnabled = false
    txt.textColor = textColor
    txt.textAlignment = .center
    txt.font = UIFont.systemFont(ofSize: fontSize!, weight: .heavy)//.boldSystemFont(ofSize: fontSize!)
    txt.text = title
    bg.addSubview(txt)
    
    return btn
}

/* SOME GLOBAL VARS FOR LAZINESS  */

func updateScreenScales() {
    sW = UIScreen.main.bounds.size.width
    sH = UIScreen.main.bounds.size.height
    sHR = sH * (1920.0 / 1080.0) / (sH / sW)
    if (sHR / sH > 1.1) { sHR = sH * (4 / 3) / (sH / sW) }
    sWP = sW
    sHP = sH
    
    let _sHR = (1920 / 1080) / (sH / sW)
    
    if _sHR < 0.9 {
        _deviceType = .tall
        if #available(iOS 13.0, *) {
            sHP = sH * 758.0 / 812.0
        }
    } else if _sHR > 1.1 {
        _deviceType = .iPad
        sHR = sH
        if #available(iOS 13.0, *) {
            // until apple sorts it's crap out we can't use !fullscreen modals for the modal VCs
//                sHP = sH * 1006 / 1194
//                sWP = sW * 712 / 834
        }
    }
    
}

enum deviceType {
    case normal // any non iPad / non iPhone X type device
    case tall // any iPhone X type device
    case iPad // any iPad type device
}

/* Device Vars */
var sH : CGFloat = 0.0 // screen height
var sW : CGFloat = 0.0 // screen width
var sHR : CGFloat = 0.0 // corrected screen height, mainly for iPhone X dimensions
var sHP : CGFloat = 0.0 // height for presentViewController : normal devices = sH : tall devices = sH * 758 / 812 : iPads = 1006 x 712
var sWP : CGFloat = 0.0 // only really different for ipads
var _deviceType : deviceType = .normal // what device is being used - for adding padding to top and bottom as and when needed - also to set maximum widths for ipads.
