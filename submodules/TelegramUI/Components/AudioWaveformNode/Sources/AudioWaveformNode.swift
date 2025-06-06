import Foundation
import UIKit
import Display
import AsyncDisplayKit
import AudioWaveform

private final class AudioWaveformNodeParameters: NSObject {
    let waveform: AudioWaveform?
    let drawFakeSamplesIfNeeded: Bool
    let color: UIColor?
    let gravity: AudioWaveformNode.Gravity?
    let progress: CGFloat?
    let trimRange: Range<CGFloat>?
    
    init(waveform: AudioWaveform?, drawFakeSamplesIfNeeded: Bool, color: UIColor?, gravity: AudioWaveformNode.Gravity?, progress: CGFloat?, trimRange: Range<CGFloat>?) {
        self.waveform = waveform
        self.drawFakeSamplesIfNeeded = drawFakeSamplesIfNeeded
        self.color = color
        self.gravity = gravity
        self.progress = progress
        self.trimRange = trimRange
        
        super.init()
    }
}

public final class AudioWaveformNode: ASDisplayNode {
    public enum Gravity {
        case bottom
        case center
    }
    
    private var waveform: AudioWaveform?
    private var color: UIColor?
    private var gravity: Gravity?
    public var drawFakeSamplesIfNeeded = false
    
    public var progress: CGFloat? {
        didSet {
            if self.progress != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    public var trimRange: Range<CGFloat>? {
        didSet {
            if self.trimRange != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    override public init() {
        super.init()
        
        self.isOpaque = false
    }
    
    override public var frame: CGRect {
        get {
            return super.frame
        } set(value) {
            let redraw = value.size != self.frame.size
            super.frame = value
            
            if redraw {
                self.setNeedsDisplay()
            }
        }
    }
    
    public func setup(color: UIColor, gravity: Gravity, waveform: AudioWaveform?) {
        if self.color == nil || !self.color!.isEqual(color) || self.waveform != waveform || self.gravity != gravity {
            self.color = color
            self.gravity = gravity
            self.waveform = waveform
            self.setNeedsDisplay()
        }
    }
    
    override public func drawParameters(forAsyncLayer layer: _ASDisplayLayer) -> NSObjectProtocol? {
        return AudioWaveformNodeParameters(waveform: self.waveform, drawFakeSamplesIfNeeded: self.drawFakeSamplesIfNeeded, color: self.color, gravity: self.gravity, progress: self.progress, trimRange: self.trimRange)
    }
    
    @objc override public class func draw(_ bounds: CGRect, withParameters parameters: Any?, isCancelled: () -> Bool, isRasterizing: Bool) {
        let context = UIGraphicsGetCurrentContext()!
        
        if !isRasterizing {
            context.setBlendMode(.copy)
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(bounds)
        }
        
        if let parameters = parameters as? AudioWaveformNodeParameters {
            let sampleWidth: CGFloat = 2.0
            let halfSampleWidth: CGFloat = 1.0
            let distance: CGFloat = 1.0
            
            let size = bounds.size
            
            if let color = parameters.color {
                context.setFillColor(color.cgColor)
            }
            
            if let waveform = parameters.waveform {
                waveform.samples.withUnsafeBytes { rawSamples -> Void in
                    let samples = rawSamples.baseAddress!.assumingMemoryBound(to: UInt16.self)
                    
                    let peakHeight: CGFloat = 12.0
                    let maxReadSamples = waveform.samples.count / 2
                    
                    var maxSample: UInt16 = 0
                    for i in 0 ..< maxReadSamples {
                        let sample = samples[i]
                        if maxSample < sample {
                            maxSample = sample
                        }
                    }
                    
                    let numSamples = Int(floor(size.width / (sampleWidth + distance)))
                    
                    var adjustedSamples = Array<UInt16>(repeating: 0, count: numSamples)
                    var generateFakeSamples = false
                    
                    var bins: [UInt16: Int] = [:]
                    for i in 0 ..< maxReadSamples {
                        let index = min(i * numSamples / max(1, maxReadSamples), numSamples - 1)
                        let sample = samples[i]
                        if adjustedSamples[index] < sample {
                            adjustedSamples[index] = sample
                        }
                      
                        if let count = bins[sample] {
                            bins[sample] = count + 1
                        } else {
                            bins[sample] = 1
                        }
                    }
                    
                    var sortedSamples: [(UInt16, Int)] = []
                    var totalCount: Int = 0
                    for (sample, count) in bins {
                        if sample > 0 {
                            sortedSamples.append((sample, count))
                            totalCount += count
                        }
                    }
                    sortedSamples.sort { $0.1 > $1.1 }
                    
                    let topSamples = sortedSamples.prefix(1)
                    let topCount = topSamples.map{ $0.1 }.reduce(.zero, +)
                    var topCountPercent: Float = 0.0
                    if bins.count > 0 {
                        topCountPercent = Float(topCount) / Float(totalCount)
                    }
                    
                    if parameters.drawFakeSamplesIfNeeded && topCountPercent > 0.75 {
                        generateFakeSamples = true
                    }
                    
                    if generateFakeSamples {
                        if maxSample < 10 {
                            maxSample = 20
                        }
                        for i in 0 ..< maxReadSamples {
                            let index = i * numSamples / maxReadSamples
                            adjustedSamples[index] = UInt16.random(in: 6...maxSample)
                        }
                    }
                    
                    let invScale = 1.0 / max(1.0, CGFloat(maxSample))
                    
                    var clipRange: Range<CGFloat>?
                    if let trimRange = parameters.trimRange {
                        clipRange = trimRange.lowerBound * size.width ..< trimRange.upperBound * size.width
                    }
                    
                    for i in 0 ..< numSamples {
                        let offset = CGFloat(i) * (sampleWidth + distance)
                        if let clipRange {
                            if !clipRange.contains(offset) {
                                continue
                            }
                        }
                        
                        let peakSample = adjustedSamples[i]
                        
                        var sampleHeight = CGFloat(peakSample) * peakHeight * invScale
                        if abs(sampleHeight) > peakHeight {
                            sampleHeight = peakHeight
                        }
                        
                        let diff: CGFloat
                        let samplePosition = CGFloat(i) / CGFloat(numSamples)
                        if let position = parameters.progress, abs(position - samplePosition) < 0.01  {
                            diff = sampleWidth * 1.5
                        } else {
                            diff = sampleWidth * 1.5
                        }
                        
                        let gravityMultiplierY: CGFloat = {
                            switch parameters.gravity ?? .bottom {
                            case .bottom:
                                return 1
                            case .center:
                                return 0.5
                            }
                        }()
                        
                        let adjustedSampleHeight = sampleHeight - diff
                        if adjustedSampleHeight.isLessThanOrEqualTo(sampleWidth) {
                            context.fillEllipse(in: CGRect(x: offset, y: (size.height - sampleWidth) * gravityMultiplierY, width: sampleWidth, height: sampleWidth))
                            context.fill(CGRect(x: offset, y: (size.height - halfSampleWidth) * gravityMultiplierY, width: sampleWidth, height: halfSampleWidth))
                        } else {
                            let adjustedRect = CGRect(
                                x: offset,
                                y: (size.height - adjustedSampleHeight) * gravityMultiplierY,
                                width: sampleWidth,
                                height: adjustedSampleHeight
                            )
                            context.fill(adjustedRect)
                            context.fillEllipse(in: CGRect(x: adjustedRect.minX, y: adjustedRect.minY - halfSampleWidth, width: sampleWidth, height: sampleWidth))
                            context.fillEllipse(in: CGRect(x: adjustedRect.minX, y: adjustedRect.maxY - halfSampleWidth, width: sampleWidth, height: sampleWidth))
                        }
                    }
                }
            } else {
                context.fill(CGRect(x: halfSampleWidth, y: size.height - sampleWidth, width: size.width - sampleWidth, height: sampleWidth))
                context.fillEllipse(in: CGRect(x: 0.0, y: size.height - sampleWidth, width: sampleWidth, height: sampleWidth))
                context.fillEllipse(in: CGRect(x: size.width - sampleWidth, y: size.height - sampleWidth, width: sampleWidth, height: sampleWidth))
            }
        }
    }
}
