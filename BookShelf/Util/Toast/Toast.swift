//
//  Toast.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import UIKit

final class Toast: NSObject {
    
    // MARK: - Singleton
    private static let shared = Toast()
    
    
    // MARK: - Initializer
    private override init() {   // This prevents others from using the default initializer for this calls
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillShow(notification:)),     name: UIResponder.keyboardWillShowNotification,       object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillHide(notification:)),     name: UIResponder.keyboardWillHideNotification,       object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardFrameChanged(notification:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        
        if #available(iOS 13, *) {
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didReceiveOrientationChanged(notification:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: - Value
    // MARK: Private
    private var appearedToasts = Set<ToastView>()
    
    private var isKeyboardAppeard     = false
    private var keyboardFrame: CGRect = .zero
    
    private lazy var containerView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    
    
    // MARK: - Function
    // MARK: Public
    
    /// Show toast with message.
    /// The view is added as a sub-view of the first window.
    ///
    /// - Parameters:
    ///   - message: Messages.
    static func show(message: String?) {
        DispatchQueue.main.async { Toast.shared.show(message: message) }
    }
    
    static func set() {
        DispatchQueue.main.async { let _ = Toast.shared }
    }
    
    // MARK: Private
    private func show(message: String?) {
        guard let message = message else { return }
        let toastView = ToastView(frame: .zero)
        toastView.translatesAutoresizingMaskIntoConstraints = false
        toastView.isUserInteractionEnabled                  = false
        toastView.backgroundColor                           = UIColor(named: "black") ?? #colorLiteral(red: 0.1254901961, green: 0.1411764706, blue: 0.1607843137, alpha: 1)
        toastView.alpha                                     = 0
        
        // Line spacing 3.0pt
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment         = .center
        paragraphStyle.lineBreakMode     = .byWordWrapping
        paragraphStyle.minimumLineHeight = 17.0
        paragraphStyle.maximumLineHeight = 17.0
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled                  = false
        label.backgroundColor                           = .clear
        label.numberOfLines                             = 0
        label.attributedText = NSAttributedString(string: message, attributes: [.font            : UIFont.systemFont(ofSize: 13.0),
                                                                                .foregroundColor : #colorLiteral(red: 0.9999369979, green: 1, blue: 0.9998725057, alpha: 1),
                                                                                .paragraphStyle  : paragraphStyle])
        
        // Add the label
        toastView.addSubview(label)
        label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 18.0).isActive    = true
        label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -18.0).isActive = true
        label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 9.0).isActive             = true
        label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -11.0).isActive     = true
        
        
        // Add the toast
        containerView.addSubview(toastView)
        toastView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 25.0).isActive = true
        toastView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -25.0).isActive = true
        toastView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive                              = true
        
        toastView.bottomConstraint = toastView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: isKeyboardAppeard == true ? -(keyboardFrame.height + 10.0) : -90.0)
        toastView.bottomConstraint?.isActive = true
        
        
        DispatchQueue.main.async {
            // Remove all toast views.
            self.appearedToasts.reversed().forEach { self.dismiss(toastView: $0) }
        
            // Add toastView container.
            self.present(toastView: toastView)
        }
    }
    
    private func present(toastView: ToastView) {
        if appearedToasts.count == 0, containerView.superview == nil {
            guard let first = UIApplication.shared.windows.first else { return }
            first.addSubview(containerView)
            
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: first.leadingAnchor, constant: 25.0).isActive = true
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: first.trailingAnchor, constant: -25.0).isActive = true
            containerView.centerXAnchor.constraint(equalTo: first.centerXAnchor).isActive                              = true
            containerView.bottomAnchor.constraint(equalTo: first.bottomAnchor).isActive                                = true
        }
        
        appearedToasts.insert(toastView)
        
        // Animation
        containerView.layoutIfNeeded()
        
        toastView.alpha = 0
        UIView.animate(withDuration: 0.1, delay: 0.15, options: .curveEaseInOut) {
            toastView.alpha     = 1.0
            toastView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
            toastView.transform = .identity
            
        } completion: { finished in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.dismiss(toastView: toastView)
            }
        }
    }
    
    private func dismiss(toastView: ToastView?) {
        guard let toastView = toastView, let index = appearedToasts.firstIndex(of: toastView) else { return }
        appearedToasts.remove(at: index)
        
        // Animation
        DispatchQueue.main.async {
            toastView.alpha = 0
            
            UIView.animate(withDuration: 0.1, delay: 0.15, options: .curveEaseInOut) {
                toastView.alpha     = 1.0
                toastView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            }
            
            UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                toastView.transform = .identity
                
            } completion: { finished in
                toastView.removeFromSuperview()
            }
        }
    
        guard appearedToasts.isEmpty == true, containerView.superview != nil else { return }
        containerView.removeFromSuperview()
    }
    
    
    // MARK: - Notification
    @objc private func didReceiveOrientationChanged(notification: Notification) {
        guard let window = UIApplication.shared.windows.first else { return }
        DispatchQueue.main.async {
            self.containerView.frame = window.bounds
            self.containerView.layoutIfNeeded()
        }
    }
    
    @objc private func didReceiveKeyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo, let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        isKeyboardAppeard = true
        keyboardFrame = frame
        
        DispatchQueue.main.async {
            for toastView in self.appearedToasts {
                if toastView.bottomConstraint == nil {
                    toastView.bottomConstraint = toastView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: -(self.keyboardFrame.height + 10.0))
                }
            }
            
            UIView.animate(withDuration: duration) { self.containerView.layoutIfNeeded() }
        }
    }
    
    @objc private func didReceiveKeyboardWillHide(notification: Notification) {
        guard let userInfo = notification.userInfo, let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        isKeyboardAppeard = false
        keyboardFrame = frame
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration) { self.containerView.layoutIfNeeded() }
        }
    }
    
    @objc private func didReceiveKeyboardFrameChanged(notification: Notification) {
        guard isKeyboardAppeard == true, let userInfo = notification.userInfo, let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        keyboardFrame = frame
        
        DispatchQueue.main.async {
            for toastView in self.appearedToasts {
                guard let bottomConstraint = toastView.bottomConstraint else { continue }
                bottomConstraint.constant = -(self.keyboardFrame.height + 10.0)
            }
            
            UIView.animate(withDuration: duration) { self.containerView.layoutIfNeeded() }
        }
    }
}

