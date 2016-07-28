//
//  APSlidableTabPageController.swift
//  WebWrapper
//
//  Created by Magnus Eriksson on 14/01/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit

//TODO: Think about the transition methods of the child view controllers.
//TODO: Make UI configurable. Make use of UIAppearance?

public struct APSlidableTabPageControllerFactory {
    
    static public func make(childViewControllers: [UIViewController]) -> APSlidableTabPageController {
        
        let nib = UINib(nibName: "APSlidableTabPageController",
              bundle: Bundle(for: APSlidableTabPageController.self))
        .instantiate(withOwner: nil, options: nil)
        
        let vc = nib.first as! APSlidableTabPageController
        vc.viewControllers = childViewControllers
        return vc
    }
    
}

public class APSlidableTabPageController: UIViewController, UIScrollViewDelegate  {
    
    //MARK: Properties
    @IBOutlet public weak var indexBarScrollView: UIScrollView!
    @IBOutlet public weak var indexBarContainerView: UIView!
    @IBOutlet public weak var indexBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet public weak var indexIndicatorView: UIView!
    @IBOutlet public weak var indexIndicatorViewCenterXConstraint: NSLayoutConstraint!
    private var indexIndicatorViewWidthConstraint: NSLayoutConstraint?
    
    @IBOutlet public weak var contentScrollView: UIScrollView!
    @IBOutlet public weak var contentContainerView: UIView!
    
    public var indexBarTextColor = UIColor.white {
        didSet { indexBarElements.forEach { label in label.textColor = indexBarTextColor } }
    }
    
    public var indexBarHighlightedTextColor = UIColor.darkGray {
        didSet { indexBarElements.forEach { label in label.highlightedTextColor = indexBarHighlightedTextColor } }
    }
    
    private var indexBarElements: [UILabel] = []
    
    //Decides whether the indexBar should scroll to follow the index indicator view.
    private var indexBarShouldTrackIndicatorView = true
    
    //Saves the current page before the trait collection changes
    private var pageBeforeTraitCollectionChange: Int = 0
    
    public var viewControllers: [UIViewController] = [] {
        willSet {
            removeContentView()
        }
        
        didSet {
            setupContentView()
            setupIndexBar()
            updateIndexIndicatorXPosition(percentage: 0)
        }
    }
    
    
    //MARK: Rotation related events
    
    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        pageBeforeTraitCollectionChange = contentScrollView.currentPage()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        //Restore previous page.
        //A slight delay is required since the scroll view's frame size has not yet been updated to reflect the new trait collection.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.contentScrollView.scrollToPageAtIndex(index: self.pageBeforeTraitCollectionChange, animated: true)
            
            //Update the indicator view position manully in case no scroll was performed
            self.updateIndexIndicatorXPosition(percentage: self.contentScrollView.horizontalPercentScrolled())
            self.scrollToIndexIndicatorView()
        }
    }
    
    
    
    //MARK: Setup
    
    private func setupIndexBar() {
        indexBarElements.forEach { element in element.removeFromSuperview() }
        indexBarElements = createIndexBarElements()
        indexBarContainerView.addViewsHorizontally(indexBarElements)
        
        NSLayoutConstraint.activate(
            indexBarElements.map { element -> NSLayoutConstraint in
                element.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: indexBarElementWidthMultiplier())
            })
        
        indexIndicatorViewWidthConstraint?.isActive = false
        indexIndicatorViewWidthConstraint = indexIndicatorView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: indexBarElementWidthMultiplier())
        indexIndicatorViewWidthConstraint?.isActive = true
    }
    
    private func createIndexBarElements() -> [UILabel] {
        var indexBarElements: [UILabel] = []
        for i in 0..<viewControllers.count {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.text = viewControllers[i].title
            label.textColor = indexBarTextColor
            label.highlightedTextColor = indexBarHighlightedTextColor
            indexBarElements.append(label)
        }
        return indexBarElements
    }
    
    private func indexBarElementWidth() -> CGFloat {
        return view.bounds.size.width * indexBarElementWidthMultiplier()
    }
    
    private func indexBarElementWidthMultiplier() -> CGFloat {
        let maxNumberOfElementsPerScreen = 3.5
        let numberOfElements = Double(viewControllers.count > 0 ? viewControllers.count : 1)
        let multiplier = numberOfElements > maxNumberOfElementsPerScreen ?
            CGFloat(1) / CGFloat(maxNumberOfElementsPerScreen) :
            CGFloat(1) / CGFloat(numberOfElements)
        return multiplier
    }
    
    
    private func setupContentView() {
        let vcViews = viewControllers.map { vc -> UIView in
            addChildViewController(vc)
            vc.didMove(toParentViewController: self)
            return vc.view
        }
        
        contentContainerView.addViewsHorizontally(vcViews)
        
        NSLayoutConstraint.activate(
            vcViews.map { vcView -> NSLayoutConstraint in
                vcView.widthAnchor.constraint(equalTo: view.widthAnchor)
            })
        
        contentScrollView.setHorizontalContentOffset(0)
    }
    
    private func removeContentView() {
        viewControllers.forEach { vc in
            vc.willMove(toParentViewController: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
        }
    }
    
    
    
    
    
    
    //MARK: UIScrollViewDelegate
    
    /**
    Navigates to the corresponding view controller of the index that was tapped
    */
    @IBAction func onIndexBarTapped(sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: sender.view)
        let indexOfElementAtTouchPoint = Int(touchPoint.x / indexBarElementWidth())
        
        //Don't scroll the index bar while moving indicator view
        indexBarShouldTrackIndicatorView = false
        
        contentScrollView.scrollToPageAtIndex(index: indexOfElementAtTouchPoint, animated: true)
    }
    
    
    /**
     Updates the position of the 'indexIndicatorView' based on the scroll-percentage of the 'content scroll view'.
     */
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == contentScrollView {
            updateIndexIndicatorXPosition(percentage: contentScrollView.horizontalPercentScrolled())
        }
    }
    
    /**
     Updates the position of the 'indexIndicatorView' by 'xPercent'
     
     If the new position of the 'indexIndicatorView' is outside of the current page and tracking is set to true:
     - the content offset of the 'index bar' is updated accordingly.
     
     */
    private func updateIndexIndicatorXPosition(percentage percentageHorizontalOffset: CGFloat) {
        let indexIndicatorWidth = indexBarElementWidth()
        
        //Divide 'indexIndicatorWidth' by two since we're using the center of the line as x
        let newCenterX = (indexBarScrollView.contentSize.width - indexIndicatorWidth) * percentageHorizontalOffset + indexIndicatorWidth/2
        indexIndicatorViewCenterXConstraint.constant = newCenterX
        
        highlightIndexBarElement(at: newCenterX)
        
        if indexBarShouldTrackIndicatorView {
            trackIndicatorView()
        }
    }
    
    private func trackIndicatorView() {
        let indicatorLeftX = indexIndicatorView.frame.origin.x
        let indicatorRightX = indicatorLeftX + indexIndicatorView.frame.width
        let frameLeftX = indexBarScrollView.contentOffset.x
        let frameRightX = frameLeftX + indexBarScrollView.frame.size.width
        
        let shouldScrollRight = indicatorRightX > frameRightX
        let shouldScrollLeft = indicatorLeftX < frameLeftX
        
        if shouldScrollRight {
            let newX = indexIndicatorView.frame.origin.x + indexIndicatorView.bounds.width - view.bounds.width
            indexBarScrollView.setHorizontalContentOffset(newX)
        } else if shouldScrollLeft  {
            let newX = indexIndicatorView.frame.origin.x
            indexBarScrollView.setHorizontalContentOffset(newX)
        }
    }
    
    /**
     Highlights the index bar element at position 'X'
     */
    private func highlightIndexBarElement(at x: CGFloat) {
        let indexOfElementAtXPosition = Int(x / indexBarElementWidth())
        for (index, label) in indexBarElements.enumerated() {
            label.isHighlighted = index == indexOfElementAtXPosition
        }
    }
    
    
    /**
     Called when the user taps on an element in the index bar, which triggers the content view to scroll.
     After scrolling has occurred, scroll to make the 'index scroll view' visible.
     */
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView == contentScrollView {
            scrollToIndexIndicatorView()
            
            //Restore tracking of indicator view
            indexBarShouldTrackIndicatorView = true
        }

    }
    
    /**
     After scrolling the 'content scroll view', scroll to make the 'index scroll view' visible.
     Called when the user manually scrolls the content scroll view.
     */
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == contentScrollView {
            scrollToIndexIndicatorView()
        }
    }
    
    func scrollToIndexIndicatorView() {
        let indexViewIsVisible = indexBarScrollView.bounds.contains(indexIndicatorView.frame)
        if indexViewIsVisible == false {
            indexBarScrollView.scrollRectToVisible(indexIndicatorView.frame, animated: true)
        }
    }
}
