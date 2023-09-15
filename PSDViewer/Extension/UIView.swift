//
//  UIView.swift
// Locaided
//
//  Created by Imran Balouch on 15/11/2021.
//

import Foundation
import UIKit

private var vBorderColour: UIColor = UIColor.white
private var vCornerRadius: CGFloat = 0.0
private var vBorderWidth: CGFloat = 0.0
private var vMasksToBounds: Bool = true
private var vMakeRoundedSides: Bool = false
private var vMakeCircle: Bool = false
private var vApplyGradient: Bool = false
private var vAddTriangle: Bool = false

extension UIView
{
    //MARK:- Properties
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            let color = UIColor(cgColor: layer.borderColor!)
            return color
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable
    var masksToBound: Bool {
        get {
            return layer.masksToBounds
        }
        set {
            layer.masksToBounds = newValue
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.masksToBounds = false
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    //MARK:- Methods
    func fixInView(_ container: UIView!) -> Void {
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    func fitToSelf(childView: UIView) {
        childView.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["childView": childView]
        self.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat : "H:|[childView]|",
                options          : [],
                metrics          : nil,
                views            : bindings
            ))
        self.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat : "V:|[childView]|",
                options          : [],
                metrics          : nil,
                views            : bindings
            ))
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let maskPath1 = UIBezierPath(roundedRect: bounds,
                                     byRoundingCorners: corners,
                                     cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer1 = CAShapeLayer()
        maskLayer1.frame = bounds
        maskLayer1.path = maskPath1.cgPath
        layer.mask = maskLayer1
    }
    
    func dropShowWith(Path _path: UIBezierPath) {
        layer.shadowPath = _path.cgPath
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.4
    }
    
    func applyGradient(withColours colours: [UIColor], locations: [NSNumber]? = nil) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    
    func borderDash(withRadius cornerRadius: Float, borderWidth: Float, borderColor: UIColor, dashSize: Int) {
        let currentFrame = self.bounds
        let shapeLayer = CAShapeLayer()
        let path = CGMutablePath()
        let radius = CGFloat(cornerRadius)
        
        // Points - Eight points that define the round border. Each border is defined by two points.
        let topLeftPoint = CGPoint(x: radius, y: 0)
        let topRightPoint = CGPoint(x: currentFrame.size.width - radius, y: 0)
        _ = CGPoint(x: currentFrame.size.width, y: radius)
        let middleRightBottomPoint = CGPoint(x: currentFrame.size.width, y: currentFrame.size.height - radius)
        _ = CGPoint(x: currentFrame.size.width - radius, y: currentFrame.size.height)
        let bottomLeftPoint = CGPoint(x: radius, y: currentFrame.size.height)
        _ = CGPoint(x: 0, y: currentFrame.size.height - radius)
        let middleLeftTopPoint = CGPoint(x: 0, y: radius)
        
        // Points - Four points that are the center of the corners borders.
        let cornerTopRightCenter = CGPoint(x: currentFrame.size.width - radius, y: radius)
        let cornerBottomRightCenter = CGPoint(x: currentFrame.size.width - radius, y: currentFrame.size.height - radius)
        let cornerBottomLeftCenter = CGPoint(x: radius, y: currentFrame.size.height - radius)
        let cornerTopLeftCenter = CGPoint(x: radius, y: radius)
        
        // Angles - The corner radius angles.
        let topRightStartAngle = CGFloat(Double.pi * 3 / 2)
        let topRightEndAngle = CGFloat(0)
        let bottomRightStartAngle = CGFloat(0)
        let bottmRightEndAngle = CGFloat(Double.pi / 2)
        let bottomLeftStartAngle = CGFloat(Double.pi / 2)
        let bottomLeftEndAngle = CGFloat(Double.pi)
        let topLeftStartAngle = CGFloat(Double.pi)
        let topLeftEndAngle = CGFloat(Double.pi * 3 / 2)
        
        // Drawing a border around a view.
        path.move(to: topLeftPoint)
        path.addLine(to: topRightPoint)
        path.addArc(center: cornerTopRightCenter,
                    radius: radius,
                    startAngle: topRightStartAngle,
                    endAngle: topRightEndAngle,
                    clockwise: false)
        path.addLine(to: middleRightBottomPoint)
        path.addArc(center: cornerBottomRightCenter,
                    radius: radius,
                    startAngle: bottomRightStartAngle,
                    endAngle: bottmRightEndAngle,
                    clockwise: false)
        path.addLine(to: bottomLeftPoint)
        path.addArc(center: cornerBottomLeftCenter,
                    radius: radius,
                    startAngle: bottomLeftStartAngle,
                    endAngle: bottomLeftEndAngle,
                    clockwise: false)
        path.addLine(to: middleLeftTopPoint)
        path.addArc(center: cornerTopLeftCenter,
                    radius: radius,
                    startAngle: topLeftStartAngle,
                    endAngle: topLeftEndAngle,
                    clockwise: false)
        
        // Path is set as the shapeLayer object's path.
        shapeLayer.path = path;
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.frame = currentFrame
        shapeLayer.masksToBounds = false
        shapeLayer.setValue(0, forKey: "isCircle")
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = borderColor.cgColor
        shapeLayer.lineWidth = CGFloat(borderWidth)
        shapeLayer.lineDashPattern = [NSNumber(value: dashSize), NSNumber(value: dashSize)]
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        
        self.layer.addSublayer(shapeLayer)
        self.layer.cornerRadius = radius;
    }
    
    func addDashBorder() {
        let color = UIColor.black.cgColor
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = (self.frame.size)
        let shapeRect = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 1
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [2,2]
        shapeLayer.path = UIBezierPath(rect: shapeRect).cgPath
        
        self.layer.addSublayer(shapeLayer)
    }
    
    func addTapGesture(withSelector selector: Selector) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: selector)
        tap.cancelsTouchesInView = false
        tap.numberOfTapsRequired = 1
        addGestureRecognizer(tap)
    }
    
    func heartAnimation(duration: CGFloat, fromValue: CGFloat, toValue: CGFloat) {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = CFTimeInterval(duration) //0.4
        pulse.fromValue = fromValue
        pulse.toValue = toValue
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.initialVelocity = 0.5
        pulse.damping = 0.8
        layer.add(pulse, forKey: "heartBeat")
    }
    
    @IBInspectable var masksToBounds: Bool {
        get {
            return vMasksToBounds
        }
        set {
            layer.masksToBounds = newValue
            vMasksToBounds = newValue
            layoutIfNeeded()
            
        }
    }
    
    func takeScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if (image != nil) {
            return image!
        }
        return UIImage()
    }
    
    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.toValue = toValue
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        self.layer.add(animation, forKey: nil)
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    class func fromNib<T : UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    
}

extension UIView {

  // OUTPUT 1
  func dropShadow(scale: Bool = true) {
    layer.masksToBounds = false
      layer.shadowColor = UIColor.lightGray.cgColor
    layer.shadowOpacity = 1
    layer.shadowOffset = CGSize(width: -1, height: 1)
      layer.shadowRadius = 12

    layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    layer.shouldRasterize = true
    layer.rasterizationScale = scale ? UIScreen.main.scale : 1
  }

  // OUTPUT 2
  func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
    layer.masksToBounds = false
    layer.shadowColor = color.cgColor
    layer.shadowOpacity = opacity
    layer.shadowOffset = offSet
    layer.shadowRadius = radius

    layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    layer.shouldRasterize = true
    layer.rasterizationScale = scale ? UIScreen.main.scale : 1
  }
}



