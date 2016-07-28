//
//  UIView+LayoutUtils.swift
//  WebWrapper
//
//  Created by Magnus Eriksson on 16/01/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit

extension UIView {
    
    func addViewsHorizontally(_ views: [UIView]) {
        
        var prevView: UIView?
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            if prevView == nil {
                //First view - Pin to view's leading anchor
                view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                //All other views - to to previous view's trailing anchor
                view.leadingAnchor.constraint(equalTo: prevView!.trailingAnchor).isActive = true
            }
            
            prevView = view;
        }
        
        //Last view - pin to container view's trailing anchor
        prevView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    func reportAmbiguity () {
        for subview in subviews {
            if subview.hasAmbiguousLayout {
                NSLog("Found ambigious layout: \(subview)")
            }
            
            if subview.subviews.count > 0 {
                subview.reportAmbiguity()
            }
        }
    }
    
    func listConstraints() {
        for subview in subviews {
            let arr1 = subview.constraintsAffectingLayout(for: .horizontal)
            let arr2 = subview.constraintsAffectingLayout(for: .vertical)
            NSLog("\n\n%@\nH: %@\nV:%@", subview, arr1, arr2)
            if subview.subviews.count > 0 {
                subview.listConstraints()
            }
        }
    }
}
