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
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage

        let size = self.size
        let aspectRatio = size.width / size.height

        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 { // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else { // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }

        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }

        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }

        return newImage
    }
}

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
        guard let cgImage = cgImage?
            .cropping(to: .init(origin: .init(x: isLandscape ? ((size.width - size.height) * scale / 2).rounded(.down) : 0,
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
