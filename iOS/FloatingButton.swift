//
//  FloatingButton.swift
//  iCepa
//
//  Created by Conrad Kramer on 8/26/16.
//  Copyright © 2016 Conrad Kramer. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(rgbaValue: UInt32) {
        let max = CGFloat(UInt8.max)
        self.init(red: CGFloat((rgbaValue >> 24) & 0xFF) / max,
                  green: CGFloat((rgbaValue >> 16) & 0xFF) / max,
                  blue: CGFloat((rgbaValue >> 8) & 0xFF) / max,
                  alpha: CGFloat(rgbaValue & 0xFF) / max)
    }
    
    func average(with color: UIColor) -> UIColor? {
        let r = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1),
        g = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1),
        b = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1),
        a = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        
        if self.getRed(r, green: g, blue: b, alpha: a) {
            return UIColor(red: r.pointee, green: g.pointee, blue: b.pointee, alpha: a.pointee)
        } else {
            return nil
        }
    }
}

class FloatingButton: UIButton {
 
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override var layer: CAGradientLayer {
        return super.layer as! CAGradientLayer
    }
    
    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = layer.presentation()?.value(forKeyPath: "transform.scale")
            scale.toValue = (isHighlighted ? 0.97 : 1)
            
            let shadow = CABasicAnimation(keyPath: #keyPath(CALayer.shadowRadius))
            shadow.fromValue = layer.presentation()?.value(forKeyPath: #keyPath(CALayer.shadowRadius))
            shadow.toValue = layer.shadowRadius * (isHighlighted ? 0.5 : 1)
            
            var animations = [scale, shadow]
            
            if let gradient = gradient, let average = gradient.0.average(with: gradient.1) {
                let colors = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.colors))
                colors.fromValue = layer.presentation()?.value(forKeyPath: #keyPath(CAGradientLayer.colors))
                colors.toValue = [average.cgColor, gradient.1.cgColor]
                animations.append(colors)
            }
            
            let group = CAAnimationGroup()
            group.animations = animations
            group.duration = 0.1
            group.fillMode = kCAFillModeForwards
            group.isRemovedOnCompletion = !isHighlighted
            
            layer.add(group, forKey: "FloatingButton_isHighlighted")
        }
    }
    
    var gradient: (UIColor, UIColor)? {
        didSet {
            if let gradient = gradient {
                layer.colors = [gradient.0.cgColor, gradient.1.cgColor]
            } else {
                layer.colors = []
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        titleLabel?.font = .boldSystemFont(ofSize: 14)
        setTitleColor(.white, for: .normal)
        
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5
        layer.endPoint = CGPoint(x: 1, y: 0.5)
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = 6
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
