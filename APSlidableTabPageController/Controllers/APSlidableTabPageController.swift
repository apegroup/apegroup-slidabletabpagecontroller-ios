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
        
        let nib = UINib(nibName: String(describing: APSlidableTabPageController.self),
                        bundle: Bundle(for: APSlidableTabPageController.self))
            .instantiate(withOwner: nil, options: nil)
        
        let vc = nib.first as! APSlidableTabPageController
        vc.viewControllers = childViewControllers
        return vc
    }
}

public protocol APSlidableTabPageControllerDelegate: class {
    func slidableTabPageControllerDidChangeCurrentPage(pageIndex: Int)
}

public class APSlidableTabPageController: UIViewController, UIScrollViewDelegate  {
    
    public enum IndexBarPosition {
        case top
        case bottom
    }
    
    //MARK: IBOutlets
    
    @IBOutlet weak var verticalStackView: UIStackView!
    @IBOutlet public weak var indexBarScrollView: UIScrollView!
    @IBOutlet public weak var indexBarContainerView: UIView!
    @IBOutlet public weak var indexBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet public weak var indexIndicatorView: UIView!
    @IBOutlet public weak var indexIndicatorViewCenterXConstraint: NSLayoutConstraint!
    private var indexIndicatorViewWidthConstraint: NSLayoutConstraint?
    
    @IBOutlet public weak var contentScrollView: UIScrollView!
    @IBOutlet public weak var contentContainerView: UIView!
    
    public weak var delegate: APSlidableTabPageControllerDelegate?
    
    //MARK: Properties
    
    private var indexBarElements: [UIView] = []
    
    //Decides whether the indexBar should scroll to follow the index indicator view.
    private var indexBarShouldTrackIndicatorView = true
    
    //The current page before the trait collection changes, e.g. prior to rotation occurrs
    private var pageIndexBeforeTraitCollectionChange: Int = 0
    
    //Keeps track of the current page index in order to track scroll direction (i.e. if scrolling backwards or forwards)
    public private(set) var currentPageIndex: Int = 0 {
        didSet {
            guard let delegate = delegate else { return }
            if oldValue != currentPageIndex {
                delegate.slidableTabPageControllerDidChangeCurrentPage(pageIndex: currentPageIndex)
            }
        }
    }
    
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

    //MARK: Configurable
    
    public var maxNumberOfIndexBarElementsPerScreen = 3.5 {
        didSet {
            setupIndexBar()
            updateIndexIndicatorXPosition(percentage: 0)
        }
    }
    
    public var indexBarPosition: IndexBarPosition = .top {
        didSet {
            let index: Int
            switch indexBarPosition {
            case oldValue:          return                                     //Already at specified position
            case .top:              index = 0                                  //First
            case .bottom:           index = verticalStackView.subviews.count-1 //Last
            }
            
            DispatchQueue.main.async {
                self.verticalStackView.insertArrangedSubview(self.indexBarScrollView, at: index)
            }
        }
    }
    
    public var indexBarElementColor = UIColor.black {
        didSet {
            indexBarElements.forEach { element in
                element.tintColor = indexBarElementColor
                if let label = element as? UILabel {
                    label.textColor = indexBarElementColor
                }
            }
        }
    }
    
    public var indexBarElementHighlightedColor = UIColor.red {
        didSet {
            indexBarElements.forEach { element in
                if let label = element as? UILabel {
                    label.highlightedTextColor = indexBarElementHighlightedColor
                }
            }
        }
    }
    
    
    
    //MARK: Rotation related events
    
    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        pageIndexBeforeTraitCollectionChange = contentScrollView.currentPage()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        //Restore previous page.
        //A slight delay is required since the scroll view's frame size has not yet been updated to reflect the new trait collection.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                //Scroll the index indicator view to visible only after the its position has been completely updated
                self.scrollIndexIndicatorViewToVisible()
            }
            
            self.contentScrollView.scrollToPageAtIndex(self.pageIndexBeforeTraitCollectionChange, animated: false)
            
            //Update the indicator view position manually in case no scroll was performed
            self.updateIndexIndicatorXPosition(percentage: self.contentScrollView.horizontalPercentScrolled())
            CATransaction.commit()
        }
    }
    
    
    //MARK: Setup
    
    private func setupIndexBar() {
        guard viewControllers.count > 0 else {
            return
        }
        
        indexBarElements.forEach { $0.removeFromSuperview() }
        indexBarElements = createIndexBarElements()
        indexBarContainerView.addViewsHorizontally(indexBarElements)
        
        NSLayoutConstraint.activate(
            indexBarElements.map { element -> NSLayoutConstraint in
                element.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: indexBarElementWidthMultiplier())
            })
        
        indexIndicatorViewWidthConstraint?.isActive = false
        let clampedWidth = clampedIndexIndicatorWidth(width: indexBarElements.first!.intrinsicContentSize.width)
        indexIndicatorViewWidthConstraint = indexIndicatorView.widthAnchor.constraint(equalToConstant: clampedWidth)
        indexIndicatorViewWidthConstraint?.isActive = true
    }
    
    
    /// Returns a clamped width within the min and max values
    private func clampedIndexIndicatorWidth(width: CGFloat) -> CGFloat {
        let minWidth: CGFloat = 15
        let maxWidth = indexBarElementWidth()
        return max(minWidth, min(maxWidth, width))
    }
    
    /**
     Creates an index bar element for each view controller.
     If the view controller has tab bar item images, then they will be used as the index bar element.
     Else the view controller's title will be used.
 
     */
    private func createIndexBarElements() -> [UIView] {
        return viewControllers.map { vc in
            if let image = vc.tabBarItem.image {
                let imageView = UIImageView(image: image, highlightedImage: vc.tabBarItem.selectedImage)
                imageView.contentMode = .center
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.tintColor = indexBarElementColor
                return imageView
            } else {
                let label = UILabel()
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = vc.title
                label.textColor = indexBarElementColor
                label.highlightedTextColor = indexBarElementHighlightedColor
                return label
            }
        }
    }
    
    private func indexBarElementWidth() -> CGFloat {
        return view.bounds.size.width * indexBarElementWidthMultiplier()
    }
    
    private func indexBarElementWidthMultiplier() -> CGFloat {
        let numberOfElements = Double(viewControllers.count > 0 ? viewControllers.count : 1)
        let multiplier = numberOfElements > maxNumberOfIndexBarElementsPerScreen ?
            CGFloat(1) / CGFloat(maxNumberOfIndexBarElementsPerScreen) :
            CGFloat(1) / CGFloat(numberOfElements)
        return multiplier
    }
    
    
    private func setupContentView() {
        let vcViews = viewControllers.map { vc -> UIView in
            addChild(vc)
            vc.didMove(toParent: self)
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
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
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
        
        contentScrollView.scrollToPageAtIndex(indexOfElementAtTouchPoint, animated: true)
    }
    
    /**
     Updates the width of the 'indexIndicatorView' based on the transition progress and width delta of the source and destination index bar elements.
     Updates the position of the 'indexIndicatorView' based on the scroll-percentage of the 'content scroll view'.
     */
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == contentScrollView {
            
            //"percentScrolledInPage" represents the X-scroll percentage within the current page, starting at index 0.
            //E.g. if the scroll view is 50% between page 5 and 6, the  will be 4.5
            let percentScrolledInPage = contentScrollView.horizontalPercentScrolledInCurrentPage()
            let percentScrolledInTotal = contentScrollView.horizontalPercentScrolled()
            
            let isGoingBackwards = contentScrollView.currentPage() < currentPageIndex
            var transitionProgress = percentScrolledInPage - CGFloat(contentScrollView.currentPage())
            if isGoingBackwards {
                //If we're moving left, normalise the progress so that it always starts from 0 --> 1
                transitionProgress = (1 - transitionProgress)
            }
            
            //The index of the leftmost element involved in the transition
            let transitionLeftElementIndex = contentScrollView.currentPage()
            let transitionRightElementIndex = transitionLeftElementIndex + 1
            
            let transitionSourceElementIndex = isGoingBackwards ? transitionRightElementIndex : transitionLeftElementIndex
            let transitionDestinationElementIndex = isGoingBackwards ? transitionLeftElementIndex : transitionRightElementIndex
            
            updateIndexIndicatorWidth(sourceElementIndex: transitionSourceElementIndex,
                                      destElementIndex: transitionDestinationElementIndex,
                                      transitionProgress: transitionProgress)
            
            updateIndexIndicatorXPosition(percentage: percentScrolledInTotal)
        }
    }
    
    /**
     Updates the width of the 'indexIndicatorView' by calculating the width delta 
     of the source and the destination elements involved in the transition and multiplying the delta with the transition progress.
     */
    private func updateIndexIndicatorWidth(sourceElementIndex: Int, destElementIndex: Int, transitionProgress: CGFloat) {
        //Ensure indices are within bounds
        var safeSourceIndex = sourceElementIndex >= 0 ? sourceElementIndex : 0
        safeSourceIndex = safeSourceIndex < indexBarElements.count ? safeSourceIndex : (indexBarElements.count - 1)
        
        var safeDestIndex = destElementIndex >= 0 ? destElementIndex : 0
        safeDestIndex = safeDestIndex < indexBarElements.count ? safeDestIndex : (indexBarElements.count - 1)
        
        //Fetch elements
        let sourceElement = indexBarElements[safeSourceIndex]
        let destElement = indexBarElements[safeDestIndex]
        
        //Calculate width
        let sourceElementWidth = clampedIndexIndicatorWidth(width: sourceElement.intrinsicContentSize.width)
        let destinationElementWidth = clampedIndexIndicatorWidth(width: destElement.intrinsicContentSize.width)
        let delta = destinationElementWidth - sourceElementWidth
        let newWidth = sourceElementWidth + (delta * transitionProgress)
        indexIndicatorViewWidthConstraint!.constant = clampedIndexIndicatorWidth(width: newWidth)
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

        for (index, view) in indexBarElements.enumerated() {
            let isHighlighted = index == indexOfElementAtXPosition
            
            if let imageView = view as? UIImageView {
                imageView.isHighlighted = isHighlighted
                imageView.tintColor = isHighlighted ? indexBarElementHighlightedColor : indexBarElementColor
            } else if let label = view as? UILabel {
                label.isHighlighted = isHighlighted
            }
        }
    }
    
    /**
     Called when the user taps on an element in the index bar, which triggers the content view to scroll.
     After scrolling of the 'contentScrollView' has occurred, scroll to make the 'index scroll view' visible.
     */
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView == contentScrollView {
            scrollIndexIndicatorViewToVisible()
            
            //Restore tracking of indicator view
            indexBarShouldTrackIndicatorView = true
            
            //Save the current page index
            currentPageIndex = contentScrollView.currentPage()
        }
    }
    
    /**
     Called when the user manually scrolls the content scroll view.
     After scrolling the 'content scroll view', scroll to make the 'index scroll view' visible.
     */
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == contentScrollView {
            scrollIndexIndicatorViewToVisible()
            
            //Restore tracking of indicator view
            indexBarShouldTrackIndicatorView = true
            
            //Save the current page index
            currentPageIndex = contentScrollView.currentPage()
        }
    }
    
    /**
     Scrolls to make the 'index scroll view' (including a small margin) visible.
     */
    func scrollIndexIndicatorViewToVisible() {
        let frameWithMargin = indexIndicatorView.frame.insetBy(dx: -20, dy: 0)
        indexBarScrollView.scrollRectToVisible(frameWithMargin, animated: true)
    }
}
