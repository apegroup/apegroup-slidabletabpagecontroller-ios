//
//  Bundle+APSlidableTabPageController.swift
//  APSlidableTabPageController
//
//  Created by Magnus Eriksson on 21/01/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

extension Bundle {
    
    static func frameworkBundle() -> Bundle? {
        let FrameworkBundleID = "com.apegroup.APSlidableTabPageController"
        return Bundle(identifier: FrameworkBundleID)
    }
}
