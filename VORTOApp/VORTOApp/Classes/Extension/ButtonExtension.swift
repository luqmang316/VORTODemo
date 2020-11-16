//
//  ButtonExtension.swift
//  VORTOApp
//
//  Created by Muhammad Luqman on 11/15/20.
//

import UIKit

extension UIButton{
    
    func RoundCornerLabel(cornerRadius: CGFloat) {
        
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
}
