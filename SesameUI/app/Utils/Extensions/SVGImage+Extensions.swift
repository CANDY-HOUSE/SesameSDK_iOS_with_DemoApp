//
//  SVGImage+Extensions.swift
//
//  Created by xu.shuifeng on 2019/7/3.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import SVGKit

extension SVGKImage {
    
    func fill(color: UIColor) {
        if let shapeLayer = caLayerTree.shapeLayer() {
            shapeLayer.fillColor = color.cgColor
        }
    }
}

extension String{
    func toMail() -> String {
        return self.lowercased().replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
    }
}

fileprivate extension CALayer {
    
    func shapeLayer() -> CAShapeLayer? {
        guard let sublayers = sublayers else {
            return nil
        }
        for layer in sublayers {
            if let shape = layer as? CAShapeLayer {
                return shape
            }
            return layer.shapeLayer()
        }
        return nil
    }
}
