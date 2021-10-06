//
//  Transition.swift
//  BaseKitSwift
//
//  Created by ldc on 2021/7/16.
//  Copyright © 2021 Xiamen Hanin. All rights reserved.
//

import UIKit

open class BKPopoverViewController: UIViewController {
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    
    open var dimmingViewUserInteractionEnabled: Bool { true }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize.init(width: 300, height: 300)
        
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
    }
}

extension BKPopoverViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return BKScaleAnimatedTransitioning()
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return BKScaleAnimatedTransitioning()
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let temp = BKPopoverPresentationController(presentedViewController: presented, presenting: presenting)
        temp.dimmingViewUserInteractionEnabled = dimmingViewUserInteractionEnabled
        return temp
    }
}

class BKPopoverPresentationController: UIPresentationController {
    
    var dimmingView: UIView?
    
    var dimmingViewUserInteractionEnabled = true
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        dimmingView?.frame = containerView!.frame
        self.presentedView?.frame = self.frameOfPresentedViewInContainerView
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        let containerBounds = containerView!.bounds
        let contentSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerBounds.size)
        let x = (containerBounds.width - contentSize.width)/2
        let y = (containerBounds.height - contentSize.height)/2
        return CGRect.init(origin: CGPoint.init(x: x, y: y), size: contentSize)
    }
    
    override func presentationTransitionWillBegin() {
        
        if let containter = containerView {
            let temp = UIView.init(frame: containter.bounds)
            temp.alpha = 0
            temp.backgroundColor = UIColor.black
            temp.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            temp.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.closePresentedViewController)))
            temp.isUserInteractionEnabled = dimmingViewUserInteractionEnabled
            containter.addSubview(temp)
            dimmingView = temp
            
            let coord = presentingViewController.transitionCoordinator
            coord?.animate(alongsideTransition: { (_) in
                temp.alpha = 0.6
            }, completion: nil)
        }
    }
    
    @objc func closePresentedViewController() {
        
        presentedViewController.bk_dismiss()
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        
        if !completed {
            dimmingView = nil
        }
    }
    
    override func dismissalTransitionWillBegin() {
        
        let coord = presentingViewController.transitionCoordinator
        coord?.animate(alongsideTransition: { (_) in
            self.dimmingView?.alpha = 0
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        
        if completed {
            dimmingView = nil
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if container === self.presentedViewController {
            containerView?.setNeedsLayout()
        }
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        
        if container === presentedViewController {
            return container.preferredContentSize
        }else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }
}

class BKScaleAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    
    var transitionContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 0.35
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let toViewController = transitionContext.viewController(forKey: .to)!
        let fromViewController = transitionContext.viewController(forKey: .from)!
        let isPresenting = toViewController.presentingViewController == fromViewController
        
        if isPresenting {
            let toView = transitionContext.view(forKey: .to)!
            let containerView = transitionContext.containerView
            let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
            
            toView.frame = finalFrame
            containerView.addSubview(toView)
            
            toView.layer.removeAnimation(forKey: "transform")
            var animation = CAKeyframeAnimation.init(keyPath: "transform")
            animation.duration = transitionDuration(using: transitionContext)
            animation.values = [
                NSValue.init(caTransform3D:toView.layer.transform),
                NSValue.init(caTransform3D:CATransform3DScale(toView.layer.transform, 1.05, 1.05, 1.0)),
                NSValue.init(caTransform3D:CATransform3DScale(toView.layer.transform, 0.95, 0.95, 1.0)),
                NSValue.init(caTransform3D:toView.layer.transform)
            ]
            animation.isRemovedOnCompletion = true
            toView.layer.add(animation, forKey:"transform")
            
            toView.layer.removeAnimation(forKey: "opacity")
            animation = CAKeyframeAnimation.init(keyPath: "opacity")
            animation.delegate = self
            animation.duration = transitionDuration(using: transitionContext)
            animation.values = [0,1]
            animation.isRemovedOnCompletion = true
            toView.layer.add(animation, forKey:"opacity")
            self.transitionContext = transitionContext
        }else {
            let fromView = transitionContext.view(forKey: .from)!
            
            fromView.alpha = 1
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseInOut], animations: {
                fromView.alpha = 0
            }) { (_) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
        guard let transitionContext = transitionContext else { return }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        self.transitionContext = nil
    }
}

open class BKBottomPopverViewController: UIViewController {
    
    open var needCornerCrop: Bool { true }
    
    open var dimmingViewUserInteractionEnabled: Bool { true }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.layer.shadowColor = UIColor(red: 21/255.0, green: 21/255.0, blue: 21/255.0, alpha: 0.3).cgColor
        view.layer.shadowOffset = CGSize.init(width: 0, height: 0)
        view.layer.shadowOpacity = 0.8
        view.layer.shadowRadius = 7
        view.layer.cornerRadius = 2
        if needCornerCrop {
            view.layer.mask = bgMaskLayer
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if needCornerCrop {
            bgMaskLayer.frame = view.bounds
            bgMaskLayer.path = UIBezierPath.init(roundedRect: view.bounds, byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight], cornerRadii: CGSize.init(width: 16, height: 16)).cgPath
        }
    }
    
    lazy var bgMaskLayer: CAShapeLayer = {
        let temp = CAShapeLayer.init()
        return temp
    }()
}

extension BKBottomPopverViewController: UIViewControllerTransitioningDelegate {
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let temp = BKBottomPopverPresentationController.init(presentedViewController: presented, presenting: presenting)
        temp.dimmingViewUserInteractionEnabled = dimmingViewUserInteractionEnabled
        return temp
    }
}

open class BKAutoResizeBottomPopverViewController: BKBottomPopverViewController {
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if preferredContentSize.height != contentView.frame.size.height {
            preferredContentSize = CGSize.init(width: 0, height: contentView.frame.size.height)
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        contentView.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
        }
    }
    
    public lazy var contentView: UIView = {
        let temp = UIView()
        temp.backgroundColor = UIColor.clear
        view.addSubview(temp)
        return temp
    }()
}

class BKBottomPopverPresentationController: UIPresentationController {
    
    var dimmingViewUserInteractionEnabled = true
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        let containerBounds = containerView!.bounds
        var size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerBounds.size)
        if #available(iOS 11.0, *) {
            size.height += containerView!.safeAreaInsets.bottom
        }
        size.width = ScreenWidth
        return CGRect.init(origin: CGPoint.init(x: 0, y: containerBounds.height - size.height), size: size)
    }
    
    @objc func closePresentedViewController() {
        
        presentedViewController.bk_dismiss()
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: {
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
        })
    }
    
    override func presentationTransitionWillBegin() {
        
        super.presentationTransitionWillBegin()
        if let temp = containerView {
            dimmingView.frame = temp.bounds
            dimmingView.alpha = 0
            temp.addSubview(dimmingView)
            let coord = presentedViewController.transitionCoordinator
            coord?.animate(alongsideTransition: { (_) in
                self.dimmingView.alpha = 1
            }, completion: nil)
        }
    }
    
    override func dismissalTransitionWillBegin() {
        
        let coord = presentingViewController.transitionCoordinator
        coord?.animate(alongsideTransition: { (_) in
            self.dimmingView.alpha = 0
        }, completion: nil)
    }
    
    lazy var dimmingView: UIView = {
        let temp = UIControl()
        temp.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        temp.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        temp.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.closePresentedViewController)))
        temp.isUserInteractionEnabled = dimmingViewUserInteractionEnabled
        return temp
    }()
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if container === self.presentedViewController {
            containerView?.setNeedsLayout()
        }
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        
        if container === presentedViewController {
            return container.preferredContentSize
        }else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }
}
