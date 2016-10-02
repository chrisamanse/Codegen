//
//  VerticalProgressView.swift
//  Codegen
//
//  Created by Chris Amanse on 10/02/2016.
//
//

import UIKit

@IBDesignable
public class VerticalProgressView: UIView {
    @IBInspectable
    public var progress: Float = 1 {
        didSet {
            updateFillProgress()
        }
    }
    
    @IBInspectable
    public var borderWidth: CGFloat = 1.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable
    public var borderColor: UIColor = UIColor.black {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable
    public var fillColor: UIColor = UIColor.black {
        didSet {
            colorFillLayer()
        }
    }
    
    internal let fillLayer = CAShapeLayer()
    internal var fillPath: UIBezierPath {
        // Shorten rect for fill depending on progress
        let height = CGFloat(progress) * bounds.height
        let y0 = bounds.height - height
        
        let rect = CGRect(x: 0, y: y0, width: bounds.width, height: height)
        
        return UIBezierPath(rect: rect)
    }
    
    public override func prepareForInterfaceBuilder() {
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        
        colorFillLayer()
        layoutFillLayer()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        customInitialization()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        customInitialization()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func customInitialization() {
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        
        fillLayer.strokeColor = UIColor.clear.cgColor
        colorFillLayer()
        layoutFillLayer()
        
        layer.addSublayer(fillLayer)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutFillLayer()
    }
    
    private func colorFillLayer() {
        fillLayer.fillColor = fillColor.cgColor
    }
    
    private func layoutFillLayer() {
        fillLayer.frame = bounds
        fillLayer.path = fillPath.cgPath
    }
    
    private func updateFillProgress() {
        fillLayer.path = fillPath.cgPath
    }
}
