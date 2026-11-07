import Foundation
import AVFoundation
import AppKit
import ImageIO
import UniformTypeIdentifiers
import CoreText

// Preserve the real app capture and explicitly identify its simulator provenance.
let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let asset = AVURLAsset(url: input)
guard let track = asset.tracks(withMediaType: .video).first else { fatalError("No video track") }
let composition = AVMutableComposition()
let video = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
try video.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: track, at: .zero)
video.preferredTransform = track.preferredTransform
let transformed = CGRect(origin: .zero, size: track.naturalSize).applying(track.preferredTransform)
let size = CGSize(width: abs(transformed.width), height: abs(transformed.height))
let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: video)
layerInstruction.setTransform(track.preferredTransform, at: .zero)
instruction.layerInstructions = [layerInstruction]
let videoComposition = AVMutableVideoComposition()
videoComposition.renderSize = size
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
videoComposition.instructions = [instruction]
let parent = CALayer()
parent.frame = CGRect(origin: .zero, size: size)
let picture = CALayer()
picture.frame = parent.bounds
parent.addSublayer(picture)
let banner = CALayer()
banner.frame = CGRect(x: 0, y: 0, width: size.width, height: 70)
banner.backgroundColor = NSColor(calibratedRed: 0.04, green: 0.13, blue: 0.15, alpha: 0.94).cgColor
parent.addSublayer(banner)
let textContext = CGContext(data: nil, width: Int(size.width), height: 70, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
textContext.setFillColor(NSColor(calibratedRed: 0.04, green: 0.13, blue: 0.15, alpha: 1).cgColor)
textContext.fill(CGRect(x: 0, y: 0, width: size.width, height: 70))
let text = NSAttributedString(string: "SIMULATOR DEMONSTRATION · v1.0.0", attributes: [
    NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("HelveticaNeue-Medium" as CFString, 28, nil),
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): NSColor.white.cgColor])
let line = CTLineCreateWithAttributedString(text)
textContext.textPosition = CGPoint(x: (size.width - CTLineGetTypographicBounds(line, nil, nil, nil)) / 2, y: 23)
CTLineDraw(line, textContext)
banner.contents = textContext.makeImage()
videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: picture, in: parent)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset1920x1080)!
exporter.outputURL = output
exporter.outputFileType = .mp4
exporter.shouldOptimizeForNetworkUse = true
exporter.videoComposition = videoComposition
let item = AVMutableMetadataItem()
item.identifier = .commonIdentifierDescription
item.value = "iOS Simulator demonstration of Mewsaic Nook 1.0.0. Not a physical-device recording." as NSString
exporter.metadata = [item]
var finished = false
exporter.exportAsynchronously { finished = true }
while !finished { RunLoop.current.run(until: Date().addingTimeInterval(0.2)) }
guard exporter.status == .completed else { fatalError("Export failed: \(String(describing: exporter.error))") }
let final = AVURLAsset(url: output)
let finalTrack = final.tracks(withMediaType: .video).first!
print("Exported \(output.lastPathComponent), \(CMTimeGetSeconds(final.duration)) seconds, \(finalTrack.naturalSize)")
let generator = AVAssetImageGenerator(asset: final)
generator.appliesPreferredTrackTransform = true
let frames = output.deletingLastPathComponent().appendingPathComponent("validation-frames", isDirectory: true)
try FileManager.default.createDirectory(at: frames, withIntermediateDirectories: true)
for second in [1.0, 10, 25, 45, 65, 80, 100, CMTimeGetSeconds(final.duration) - 2] {
    guard second < CMTimeGetSeconds(final.duration) else { continue }
    let image = try generator.copyCGImage(at: CMTime(seconds: second, preferredTimescale: 600), actualTime: nil)
    let file = frames.appendingPathComponent("frame-\(Int(second)).png")
    let destination = CGImageDestinationCreateWithURL(file as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    precondition(CGImageDestinationFinalize(destination))
}
