//
//  ImageUtils.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 26.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    var pxheight: CGFloat {
        size.height * scale
    }
    var pxwidth: CGFloat {
        size.width * scale
    }
    var isPortrait: Bool { size.height > size.width }
    var isLandscape: Bool { size.width > size.height }
    var breadth: CGFloat { min(size.width, size.height) * scale }
    var breadthSize: CGSize { .init(width: breadth, height: breadth) }
    var breadthRect: CGRect { .init(origin: .zero, size: breadthSize) }
    var circleMasked: UIImage? {
        if isSymbolImage {
            return self
        }
        guard let cgImage = cgImage?
            .cropping(to: .init(
                origin: .init(x: isLandscape ? ((size.width - size.height) * scale / 2).rounded(.down) : 0,
                              y: isPortrait ? ((size.height - size.width) * scale / 2).rounded(.down) : 0),
                size: breadthSize)) else { return nil }
        let format = imageRendererFormat
        format.opaque = false
        return UIGraphicsImageRenderer(size: breadthSize, format: format).image { _ in
            UIBezierPath(ovalIn: breadthRect).addClip()
            UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation)
                .draw(in: .init(origin: .zero, size: breadthSize))
        }
    }
}
