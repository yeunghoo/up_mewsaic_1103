// Delivery-only resampling of imagegen masters. No gameplay screenshots are altered.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let jobs: [(String, String, Int, Int, Double)] = [
    ("header-master.png", "Header/Mewsaic-Nook-Header-3840x1646.png", 3840, 1646, 0.465),
    ("header-master.png", "Header/Mewsaic-Nook-Header-5244x2950.png", 5244, 2950, 0.5),
    ("search-master-wide.png", "SearchResults/Mewsaic-Nook-Search-3840x2560.png", 3840, 2560, 0.5),
    ("search-master-wide.png", "SearchResults/Mewsaic-Nook-Search-1920x1280.png", 1920, 1280, 0.5),
    ("search-master-wide.png", "SearchResults/Mewsaic-Nook-Search-5244x2950.png", 5244, 2950, 0.5)
]
for (input, output, width, height, focusY) in jobs {
    let source = CGImageSourceCreateWithURL(root.appendingPathComponent("source/" + input) as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let ratio = Double(width) / Double(height)
    let cropWidth = min(Double(image.width), Double(image.height) * ratio)
    let cropHeight = cropWidth / ratio
    let x = (Double(image.width) - cropWidth) / 2
    let y = max(0, min(Double(image.height) - cropHeight, Double(image.height) * focusY - cropHeight / 2))
    let cropped = image.cropping(to: CGRect(x: x, y: y, width: cropWidth, height: cropHeight))!
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.interpolationQuality = .high
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
    let destination = CGImageDestinationCreateWithURL(root.appendingPathComponent(output) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
    print("Exported \(output)")
}
