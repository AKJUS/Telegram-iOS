import Foundation
import UIKit
import Postbox
import TelegramCore
import PersistentStringHash

public final class VideoMediaResourceAdjustments: PostboxCoding, Equatable {
    public let data: MemoryBuffer
    public let digest: MemoryBuffer
    public let isStory: Bool
    
    public init(data: MemoryBuffer, digest: MemoryBuffer, isStory: Bool = false) {
        self.data = data
        self.digest = digest
        self.isStory = isStory
    }
    
    public init(decoder: PostboxDecoder) {
        self.data = decoder.decodeBytesForKey("d")!
        self.digest = decoder.decodeBytesForKey("h")!
        self.isStory = decoder.decodeBoolForKey("s", orElse: false)
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeBytes(self.data, forKey: "d")
        encoder.encodeBytes(self.digest, forKey: "h")
        encoder.encodeBool(self.isStory, forKey: "s")
    }
    
    public static func ==(lhs: VideoMediaResourceAdjustments, rhs: VideoMediaResourceAdjustments) -> Bool {
        return lhs.data == rhs.data && lhs.digest == rhs.digest && lhs.isStory == rhs.isStory
    }
}

public struct VideoLibraryMediaResourceId {
    public let localIdentifier: String
    public let adjustmentsDigest: MemoryBuffer?
    
    public var uniqueId: String {
        if let adjustmentsDigest = self.adjustmentsDigest {
            return "vi-\(self.localIdentifier.replacingOccurrences(of: "/", with: "_"))-\(adjustmentsDigest.description)"
        } else {
            return "vi-\(self.localIdentifier.replacingOccurrences(of: "/", with: "_"))"
        }
    }
    
    public var hashValue: Int {
        return self.localIdentifier.hashValue
    }
}

public enum VideoLibraryMediaResourceConversion: PostboxCoding, Equatable {
    case passthrough
    case compress(VideoMediaResourceAdjustments?)
    
    public init(decoder: PostboxDecoder) {
        switch decoder.decodeInt32ForKey("v", orElse: 0) {
            case 0:
                self = .passthrough
            case 1:
                self = .compress(decoder.decodeObjectForKey("adj", decoder: { VideoMediaResourceAdjustments(decoder: $0) }) as? VideoMediaResourceAdjustments)
            default:
                self = .compress(nil)
        }
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        switch self {
            case .passthrough:
                encoder.encodeInt32(0, forKey: "v")
            case let .compress(adjustments):
                encoder.encodeInt32(1, forKey: "v")
                if let adjustments = adjustments {
                    encoder.encodeObject(adjustments, forKey: "adj")
                } else {
                    encoder.encodeNil(forKey: "adj")
                }
        }
    }
    
    public static func ==(lhs: VideoLibraryMediaResourceConversion, rhs: VideoLibraryMediaResourceConversion) -> Bool {
        switch lhs {
            case .passthrough:
                if case .passthrough = rhs {
                    return true
                } else {
                    return false
                }
            case let .compress(lhsAdjustments):
                if case let .compress(rhsAdjustments) = rhs, lhsAdjustments == rhsAdjustments {
                    return true
                } else {
                    return false
                }
        }
    }
}

public final class VideoLibraryMediaResource: TelegramMediaResource {
    public let localIdentifier: String
    public let conversion: VideoLibraryMediaResourceConversion
    
    public var size: Int64? {
        return nil
    }
    
    public var headerSize: Int32 {
        return 32 * 1024
    }
    
    public init(localIdentifier: String, conversion: VideoLibraryMediaResourceConversion) {
        self.localIdentifier = localIdentifier
        self.conversion = conversion
    }
    
    public required init(decoder: PostboxDecoder) {
        self.localIdentifier = decoder.decodeStringForKey("i", orElse: "")
        self.conversion = (decoder.decodeObjectForKey("conv", decoder: { VideoLibraryMediaResourceConversion(decoder: $0) }) as? VideoLibraryMediaResourceConversion) ?? .compress(nil)
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.localIdentifier, forKey: "i")
        encoder.encodeObject(self.conversion, forKey: "conv")
    }
    
    public var id: MediaResourceId {
        var adjustmentsDigest: MemoryBuffer?
        switch self.conversion {
            case .passthrough:
                break
            case let .compress(adjustments):
                adjustmentsDigest = adjustments?.digest
        }
        return MediaResourceId(VideoLibraryMediaResourceId(localIdentifier: self.localIdentifier, adjustmentsDigest: adjustmentsDigest).uniqueId)
    }
    
    public func isEqual(to: MediaResource) -> Bool {
        if let to = to as? VideoLibraryMediaResource {
            return self.localIdentifier == to.localIdentifier && self.conversion == to.conversion
        } else {
            return false
        }
    }
}

public struct LocalFileVideoMediaResourceId {
    public let randomId: Int64
    
    public var uniqueId: String {
        return "lvi-\(self.randomId)"
    }
    
    public var hashValue: Int {
        return self.randomId.hashValue
    }
}

public final class LocalFileVideoMediaResource: TelegramMediaResource {
    public var size: Int64? {
        return nil
    }
    
    public let randomId: Int64
    public let paths: [String]
    public let adjustments: VideoMediaResourceAdjustments?
    
    public var headerSize: Int32 {
        return 32 * 1024
    }
    
    public init(randomId: Int64, path: String, adjustments: VideoMediaResourceAdjustments?) {
        self.randomId = randomId
        self.paths = [path]
        self.adjustments = adjustments
    }
    
    public init(randomId: Int64, paths: [String], adjustments: VideoMediaResourceAdjustments?) {
        self.randomId = randomId
        self.paths = paths
        self.adjustments = adjustments
    }
    
    public required init(decoder: PostboxDecoder) {
        self.randomId = decoder.decodeInt64ForKey("i", orElse: 0)
        let paths = decoder.decodeStringArrayForKey("ps")
        if !paths.isEmpty {
            self.paths = paths
        } else {
            self.paths = [decoder.decodeStringForKey("p", orElse: "")]
        }
        self.adjustments = decoder.decodeObjectForKey("a", decoder: { VideoMediaResourceAdjustments(decoder: $0) }) as? VideoMediaResourceAdjustments
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt64(self.randomId, forKey: "i")
        encoder.encodeStringArray(self.paths, forKey: "ps")
        if let adjustments = self.adjustments {
            encoder.encodeObject(adjustments, forKey: "a")
        } else {
            encoder.encodeNil(forKey: "a")
        }
    }
    
    public var id: MediaResourceId {
        return MediaResourceId(LocalFileVideoMediaResourceId(randomId: self.randomId).uniqueId)
    }
    
    public func isEqual(to: MediaResource) -> Bool {
        if let to = to as? LocalFileVideoMediaResource {
            return self.randomId == to.randomId && self.paths == to.paths && self.adjustments == to.adjustments
        } else {
            return false
        }
    }
}

public struct LocalFileAudioMediaResourceId {
    public let randomId: Int64
    
    public var uniqueId: String {
        return "lad-\(self.randomId)"
    }
    
    public var hashValue: Int {
        return self.randomId.hashValue
    }
}

public final class LocalFileAudioMediaResource: TelegramMediaResource {
    public var size: Int64? {
        return nil
    }
    
    public let randomId: Int64
    public let path: String
    public let trimRange: Range<Double>?
    
    public var headerSize: Int32 {
        return 32 * 1024
    }
    
    public init(randomId: Int64, path: String, trimRange: Range<Double>?) {
        self.randomId = randomId
        self.path = path
        self.trimRange = trimRange
    }
    
    public required init(decoder: PostboxDecoder) {
        self.randomId = decoder.decodeInt64ForKey("i", orElse: 0)
        self.path = decoder.decodeStringForKey("p", orElse: "")
        
        if let trimLowerBound = decoder.decodeOptionalDoubleForKey("tl"), let trimUpperBound = decoder.decodeOptionalDoubleForKey("tu") {
            self.trimRange = trimLowerBound ..< trimUpperBound
        } else {
            self.trimRange = nil
        }
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt64(self.randomId, forKey: "i")
        encoder.encodeString(self.path, forKey: "p")
        
        if let trimRange = self.trimRange {
            encoder.encodeDouble(trimRange.lowerBound, forKey: "tl")
            encoder.encodeDouble(trimRange.upperBound, forKey: "tu")
        } else {
            encoder.encodeNil(forKey: "tl")
            encoder.encodeNil(forKey: "tu")
        }
    }
    
    public var id: MediaResourceId {
        return MediaResourceId(LocalFileAudioMediaResourceId(randomId: self.randomId).uniqueId)
    }
    
    public func isEqual(to: MediaResource) -> Bool {
        if let to = to as? LocalFileAudioMediaResource {
            return self.randomId == to.randomId && self.path == to.path && self.trimRange == to.trimRange
        } else {
            return false
        }
    }
}

public struct PhotoLibraryMediaResourceId {
    public let localIdentifier: String
    public let resourceId: Int64
    
    public var uniqueId: String {
        if self.resourceId != 0 {
            return "ph-\(self.localIdentifier.replacingOccurrences(of: "/", with: "_"))-\(self.resourceId)"
        } else {
            return "ph-\(self.localIdentifier.replacingOccurrences(of: "/", with: "_"))"
        }
    }
    
    public var hashValue: Int {
        return self.localIdentifier.hashValue
    }
}

public enum MediaImageFormat: Int32 {
    case jpeg
    case jxl
}

public class PhotoLibraryMediaResource: TelegramMediaResource {
    public var size: Int64? {
        return nil
    }
    
    public let localIdentifier: String
    public let uniqueId: Int64
    public let width: Int32?
    public let height: Int32?
    public let format: MediaImageFormat?
    public let quality: Int32?
    public let forceHd: Bool
    
    public init(localIdentifier: String, uniqueId: Int64, width: Int32? = nil, height: Int32? = nil, format: MediaImageFormat? = nil, quality: Int32? = nil, forceHd: Bool = false) {
        self.localIdentifier = localIdentifier
        self.uniqueId = uniqueId
        self.width = width
        self.height = height
        self.format = format
        self.quality = quality
        self.forceHd = forceHd
    }
    
    public required init(decoder: PostboxDecoder) {
        self.localIdentifier = decoder.decodeStringForKey("i", orElse: "")
        self.uniqueId = decoder.decodeInt64ForKey("uid", orElse: 0)
        self.width = decoder.decodeOptionalInt32ForKey("w")
        self.height = decoder.decodeOptionalInt32ForKey("h")
        self.format = decoder.decodeOptionalInt32ForKey("f").flatMap(MediaImageFormat.init(rawValue:))
        self.quality = decoder.decodeOptionalInt32ForKey("q")
        self.forceHd = decoder.decodeBoolForKey("hd", orElse: false)
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.localIdentifier, forKey: "i")
        encoder.encodeInt64(self.uniqueId, forKey: "uid")
        if let width = self.width {
            encoder.encodeInt32(width, forKey: "w")
        } else {
            encoder.encodeNil(forKey: "w")
        }
        if let height = self.height {
            encoder.encodeInt32(height, forKey: "h")
        } else {
            encoder.encodeNil(forKey: "h")
        }
        if let format = self.format {
            encoder.encodeInt32(format.rawValue, forKey: "f")
        } else {
            encoder.encodeNil(forKey: "f")
        }
        if let quality = self.quality {
            encoder.encodeInt32(quality, forKey: "q")
        } else {
            encoder.encodeNil(forKey: "q")
        }
        encoder.encodeBool(self.forceHd, forKey: "hd")
    }
    
    public var id: MediaResourceId {
        return MediaResourceId(PhotoLibraryMediaResourceId(localIdentifier: self.localIdentifier, resourceId: self.uniqueId).uniqueId)
    }
    
    public func isEqual(to: MediaResource) -> Bool {
        if let to = to as? PhotoLibraryMediaResource {
            if self.localIdentifier != to.localIdentifier {
                return false
            }
            if self.uniqueId != to.uniqueId {
                return false
            }
            if self.width != to.width {
                return false
            }
            if self.height != to.height {
                return false
            }
            if self.format != to.format {
                return false
            }
            if self.quality != to.quality {
                return false
            }
            if self.forceHd != to.forceHd {
                return false
            }
            return true
        } else {
            return false
        }
    }
}

public struct LocalFileGifMediaResourceId {
    public let randomId: Int64
    
    public var uniqueId: String {
        return "lgi-\(self.randomId)"
    }
    
    public var hashValue: Int {
        return self.randomId.hashValue
    }
}

public final class LocalFileGifMediaResource: TelegramMediaResource {
    public var size: Int64? {
        return nil
    }
    
    public let randomId: Int64
    public let path: String
    
    public var headerSize: Int32 {
        return 32 * 1024
    }
    
    public init(randomId: Int64, path: String) {
        self.randomId = randomId
        self.path = path
    }
    
    public required init(decoder: PostboxDecoder) {
        self.randomId = decoder.decodeInt64ForKey("i", orElse: 0)
        self.path = decoder.decodeStringForKey("p", orElse: "")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt64(self.randomId, forKey: "i")
        encoder.encodeString(self.path, forKey: "p")
    }
    
    public var id: MediaResourceId {
        return MediaResourceId(LocalFileGifMediaResourceId(randomId: self.randomId).uniqueId)
    }
    
    public func isEqual(to: MediaResource) -> Bool {
        if let to = to as? LocalFileGifMediaResource {
            return self.randomId == to.randomId && self.path == to.path
        } else {
            return false
        }
    }
}


public struct BundleResourceId {
    public let nameHash: Int64
    
    public var uniqueId: String {
        return "bundle-\(nameHash)"
    }
    
    public var hashValue: Int {
        return self.nameHash.hashValue
    }
}

public class BundleResource: TelegramMediaResource {
    public var size: Int64? {
        return nil
    }
    
    public let nameHash: Int64
    public let path: String
    
    public init(name: String, path: String) {
        self.nameHash = Int64(bitPattern: name.persistentHashValue)
        self.path = path
    }
    
    public required init(decoder: PostboxDecoder) {
        self.nameHash = decoder.decodeInt64ForKey("h", orElse: 0)
        self.path = decoder.decodeStringForKey("p", orElse: "")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt64(self.nameHash, forKey: "h")
        encoder.encodeString(self.path, forKey: "p")
    }
    
    public var id: MediaResourceId {
        return MediaResourceId(BundleResourceId(nameHash: self.nameHash).uniqueId)
    }
    
    public func isEqual(to: MediaResource) -> Bool {
        if let to = to as? BundleResource {
            return self.nameHash == to.nameHash
        } else {
            return false
        }
    }
}
