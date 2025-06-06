import Foundation
import Postbox

public enum EnginePeer: Equatable {
    public typealias Id = PeerId

    public struct Presence: Equatable {
        public enum Status: Comparable {
            private struct SortKey: Comparable {
                var major: Int
                var minor: Int32
                
                init(major: Int, minor: Int32) {
                    self.major = major
                    self.minor = minor
                }
                
                static func <(lhs: SortKey, rhs: SortKey) -> Bool {
                    if lhs.major != rhs.major {
                        return lhs.major < rhs.major
                    }
                    return lhs.minor < rhs.minor
                }
            }
            
            case present(until: Int32)
            case recently(isHidden: Bool)
            case lastWeek(isHidden: Bool)
            case lastMonth(isHidden: Bool)
            case longTimeAgo
            
            private var sortKey: SortKey {
                switch self {
                case let .present(until):
                    return SortKey(major: 6, minor: until)
                case .recently:
                    return SortKey(major: 4, minor: 0)
                case .lastWeek:
                    return SortKey(major: 3, minor: 0)
                case .lastMonth:
                    return SortKey(major: 2, minor: 0)
                case .longTimeAgo:
                    return SortKey(major: 1, minor: 0)
                }
            }

            public static func <(lhs: Status, rhs: Status) -> Bool {
                return lhs.sortKey < rhs.sortKey
            }
        }

        public var status: Status
        public var lastActivity: Int32

        public init(status: Status, lastActivity: Int32) {
            self.status = status
            self.lastActivity = lastActivity
        }
    }

    public struct NotificationSettings: Equatable {
        public enum MuteState: Equatable {
            case `default`
            case unmuted
            case muted(until: Int32)
        }

        public enum MessageSound: Equatable {
            case none
            case `default`
            case bundledModern(id: Int32)
            case bundledClassic(id: Int32)
            case cloud(fileId: Int64)
        }

        public enum DisplayPreviews {
            case `default`
            case show
            case hide
        }
        
        public typealias StorySettigs = PeerStoryNotificationSettings

        public var muteState: MuteState
        public var messageSound: MessageSound
        public var displayPreviews: DisplayPreviews
        public var storySettings: StorySettigs

        public init(
            muteState: MuteState,
            messageSound: MessageSound,
            displayPreviews: DisplayPreviews,
            storySettings: StorySettigs
        ) {
            self.muteState = muteState
            self.messageSound = messageSound
            self.displayPreviews = displayPreviews
            self.storySettings = storySettings
        }
    }
    
    public struct StatusSettings: Equatable {
        public struct Flags: OptionSet {
            public var rawValue: Int32
            
            public init(rawValue: Int32) {
                self.rawValue = rawValue
            }
            
            public static let canReport = Flags(rawValue: 1 << 1)
            public static let canShareContact = Flags(rawValue: 1 << 2)
            public static let canBlock = Flags(rawValue: 1 << 3)
            public static let canAddContact = Flags(rawValue: 1 << 4)
            public static let addExceptionWhenAddingContact = Flags(rawValue: 1 << 5)
            public static let autoArchived = Flags(rawValue: 1 << 7)
            public static let suggestAddMembers = Flags(rawValue: 1 << 8)

        }
        
        public var flags: Flags
        public var geoDistance: Int32?
        public var requestChatTitle: String?
        public var requestChatDate: Int32?
        public var requestChatIsChannel: Bool?
        
        public init(
            flags: Flags,
            geoDistance: Int32?,
            requestChatTitle: String?,
            requestChatDate: Int32?,
            requestChatIsChannel: Bool?
        ) {
            self.flags = flags
            self.geoDistance = geoDistance
            self.requestChatTitle = requestChatTitle
            self.requestChatDate = requestChatDate
            self.requestChatIsChannel = requestChatIsChannel
        }
        
        public func contains(_ member: Flags) -> Bool {
            return self.flags.contains(member)
        }
    }

    public enum IndexName: Equatable {
        case title(title: String, addressNames: [String])
        case personName(first: String, last: String, addressNames: [String], phoneNumber: String?)

        public var isEmpty: Bool {
            switch self {
            case let .title(title, addressNames):
                if !title.isEmpty {
                    return false
                }
                if !addressNames.isEmpty {
                    return false
                }
                return true
            case let .personName(first, last, addressNames, phoneNumber):
                if !first.isEmpty {
                    return false
                }
                if !last.isEmpty {
                    return false
                }
                if !addressNames.isEmpty {
                    return false
                }
                if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
                    return false
                }
                return true
            }
        }
    }

    case user(TelegramUser)
    case legacyGroup(TelegramGroup)
    case channel(TelegramChannel)
    case secretChat(TelegramSecretChat)

    public static func ==(lhs: EnginePeer, rhs: EnginePeer) -> Bool {
        switch lhs {
        case let .user(user):
            if case .user(user) = rhs {
                return true
            } else {
                return false
            }
        case let .legacyGroup(legacyGroup):
            if case .legacyGroup(legacyGroup) = rhs {
                return true
            } else {
                return false
            }
        case let .channel(channel):
            if case .channel(channel) = rhs {
                return true
            } else {
                return false
            }
        case let .secretChat(secretChat):
            if case .secretChat(secretChat) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}

public struct EngineGlobalNotificationSettings: Equatable {
    public struct CategorySettings: Equatable {
        public var enabled: Bool
        public var displayPreviews: Bool
        public var sound: EnginePeer.NotificationSettings.MessageSound
        public var storySettings: EnginePeer.NotificationSettings.StorySettigs
        
        public init(enabled: Bool, displayPreviews: Bool, sound: EnginePeer.NotificationSettings.MessageSound, storySettings: EnginePeer.NotificationSettings.StorySettigs) {
            self.enabled = enabled
            self.displayPreviews = displayPreviews
            self.sound = sound
            self.storySettings = storySettings
        }
    }
    
    public struct ReactionSettings: Equatable {
        public var messages: PeerReactionNotificationSettings.Sources
        public var stories: PeerReactionNotificationSettings.Sources
        public var hideSender: PeerReactionNotificationSettings.HideSender
        public var sound: EnginePeer.NotificationSettings.MessageSound
        
        public init(messages: PeerReactionNotificationSettings.Sources, stories: PeerReactionNotificationSettings.Sources, hideSender: PeerReactionNotificationSettings.HideSender, sound: EnginePeer.NotificationSettings.MessageSound) {
            self.messages = messages
            self.stories = stories
            self.hideSender = hideSender
            self.sound = sound
        }
    }
    
    public var privateChats: CategorySettings
    public var groupChats: CategorySettings
    public var channels: CategorySettings
    public var reactionSettings: ReactionSettings
    public var contactsJoined: Bool
    
    public init(
        privateChats: CategorySettings,
        groupChats: CategorySettings,
        channels: CategorySettings,
        reactionSettings: ReactionSettings,
        contactsJoined: Bool
    ) {
        self.privateChats = privateChats
        self.groupChats = groupChats
        self.channels = channels
        self.reactionSettings = reactionSettings
        self.contactsJoined = contactsJoined
    }
}

public extension EnginePeer.NotificationSettings.MuteState {
    init(_ muteState: PeerMuteState) {
        switch muteState {
        case .default:
            self = .default
        case .unmuted:
            self = .unmuted
        case let .muted(until):
            self = .muted(until: until)
        }
    }

    func _asMuteState() -> PeerMuteState {
        switch self {
        case .default:
            return .default
        case .unmuted:
            return .unmuted
        case let .muted(until):
            return .muted(until: until)
        }
    }
}

public extension EnginePeer.NotificationSettings.MessageSound {
    init(_ messageSound: PeerMessageSound) {
        switch messageSound {
        case .none:
            self = .none
        case .default:
            self = .default
        case let .bundledClassic(id):
            self = .bundledClassic(id: id)
        case let .bundledModern(id):
            self = .bundledModern(id: id)
        case let .cloud(fileId):
            self = .cloud(fileId: fileId)
        }
    }

    func _asMessageSound() -> PeerMessageSound {
        switch self {
        case .none:
            return .none
        case .default:
            return .default
        case let .bundledClassic(id):
            return .bundledClassic(id: id)
        case let .bundledModern(id):
            return .bundledModern(id: id)
        case let .cloud(fileId):
            return .cloud(fileId: fileId)
        }
    }
}

public extension EnginePeer.NotificationSettings.DisplayPreviews {
    init(_ displayPreviews: PeerNotificationDisplayPreviews) {
        switch displayPreviews {
        case .default:
            self = .default
        case .show:
            self = .show
        case .hide:
            self = .hide
        }
    }

    func _asDisplayPreviews() -> PeerNotificationDisplayPreviews {
        switch self {
        case .default:
            return .default
        case .show:
            return .show
        case .hide:
            return .hide
        }
    }
}

public extension EnginePeer.NotificationSettings {
    init(_ notificationSettings: TelegramPeerNotificationSettings) {
        self.init(
            muteState: MuteState(notificationSettings.muteState),
            messageSound: MessageSound(notificationSettings.messageSound),
            displayPreviews: DisplayPreviews(notificationSettings.displayPreviews),
            storySettings: notificationSettings.storySettings
        )
    }

    func _asNotificationSettings() -> TelegramPeerNotificationSettings {
        return TelegramPeerNotificationSettings(
            muteState: self.muteState._asMuteState(),
            messageSound: self.messageSound._asMessageSound(),
            displayPreviews: self.displayPreviews._asDisplayPreviews(),
            storySettings: self.storySettings
        )
    }
}

public extension EnginePeer.StatusSettings {
    init(_ statusSettings: PeerStatusSettings) {
        self.init(
            flags: Flags(rawValue: statusSettings.flags.rawValue),
            geoDistance: statusSettings.geoDistance,
            requestChatTitle: statusSettings.requestChatTitle,
            requestChatDate: statusSettings.requestChatDate,
            requestChatIsChannel: statusSettings.requestChatIsChannel
        )
    }
}

public extension EnginePeer.Presence {
    init(_ presence: PeerPresence) {
        if let presence = presence as? TelegramUserPresence {
            let mappedStatus: Status
            switch presence.status {
            case .none:
                mappedStatus = .longTimeAgo
            case let .present(until):
                mappedStatus = .present(until: until)
            case let .recently(isHidden):
                mappedStatus = .recently(isHidden: isHidden)
            case let .lastWeek(isHidden):
                mappedStatus = .lastWeek(isHidden: isHidden)
            case let .lastMonth(isHidden):
                mappedStatus = .lastMonth(isHidden: isHidden)
            }

            self.init(status: mappedStatus, lastActivity: presence.lastActivity)
        } else {
            preconditionFailure()
        }
    }

    func _asPresence() -> TelegramUserPresence {
        let mappedStatus: UserPresenceStatus
        switch self.status {
        case .longTimeAgo:
            mappedStatus = .none
        case let .present(until):
            mappedStatus = .present(until: until)
        case let .recently(isHidden):
            mappedStatus = .recently(isHidden: isHidden)
        case let .lastWeek(isHidden):
            mappedStatus = .lastWeek(isHidden: isHidden)
        case let .lastMonth(isHidden):
            mappedStatus = .lastMonth(isHidden: isHidden)
        }
        return TelegramUserPresence(status: mappedStatus, lastActivity: self.lastActivity)
    }
}

public extension EnginePeer.IndexName {
    init(_ indexName: PeerIndexNameRepresentation) {
        switch indexName {
        case let .title(title, addressNames):
            self = .title(title: title, addressNames: addressNames)
        case let .personName(first, last, addressNames, phoneNumber):
            self = .personName(first: first, last: last, addressNames: addressNames, phoneNumber: phoneNumber)
        }
    }

    func _asIndexName() -> PeerIndexNameRepresentation {
        switch self {
        case let .title(title, addressNames):
            return .title(title: title, addressNames: addressNames)
        case let .personName(first, last, addressNames, phoneNumber):
            return .personName(first: first, last: last, addressNames: addressNames, phoneNumber: phoneNumber)
        }
    }

    func matchesByTokens(_ other: String) -> Bool {
        return self._asIndexName().matchesByTokens(other)
    }
    
    func matchesByTokens(_ other: [ValueBoxKey]) -> Bool {
        return self._asIndexName().matchesByTokens(other)
    }

    func stringRepresentation(lastNameFirst: Bool) -> String {
        switch self {
        case let .title(title, _):
            return title
        case let .personName(first, last, _, _):
            if lastNameFirst {
                return last + first
            } else {
                return first + last
            }
        }
    }
}

public extension EnginePeer {
    var id: Id {
        return self._asPeer().id
    }

    var addressName: String? {
        return self._asPeer().addressName
    }
    
    var usernames: [TelegramPeerUsername] {
        return self._asPeer().usernames
    }

    var indexName: EnginePeer.IndexName {
        return EnginePeer.IndexName(self._asPeer().indexName)
    }

    var debugDisplayTitle: String {
        return self._asPeer().debugDisplayTitle
    }

    func restrictionText(platform: String, contentSettings: ContentSettings) -> String? {
        return self._asPeer().restrictionText(platform: platform, contentSettings: contentSettings)
    }

    var displayLetters: [String] {
        return self._asPeer().displayLetters
    }

    var profileImageRepresentations: [TelegramMediaImageRepresentation] {
        return self._asPeer().profileImageRepresentations
    }

    var smallProfileImage: TelegramMediaImageRepresentation? {
        return self._asPeer().smallProfileImage
    }

    var largeProfileImage: TelegramMediaImageRepresentation? {
        return self._asPeer().largeProfileImage
    }

    var isDeleted: Bool {
        return self._asPeer().isDeleted
    }

    var isScam: Bool {
        return self._asPeer().isScam
    }

    var isFake: Bool {
        return self._asPeer().isFake
    }

    var isVerified: Bool {
        return self._asPeer().isVerified
    }
    
    var isPremium: Bool {
        return self._asPeer().isPremium
    }
    
    var isSubscription: Bool {
        return self._asPeer().isSubscription
    }

    var isService: Bool {
        if case let .user(peer) = self {
            if peer.id.isReplies {
                return true
            }
            if peer.id.isVerificationCodes {
                return true
            }
            return (peer.id.namespace == Namespaces.Peer.CloudUser && (peer.id.id._internalGetInt64Value() == 777000 || peer.id.id._internalGetInt64Value() == 333000))
        }
        return false
    }
    
    var nameColor: PeerNameColor? {
        return self._asPeer().nameColor
    }
    
    var verificationIconFileId: Int64? {
        return self._asPeer().verificationIconFileId
    }
    
    var profileColor: PeerNameColor? {
        return self._asPeer().profileColor
    }
    
    var emojiStatus: PeerEmojiStatus? {
        return self._asPeer().emojiStatus
    }
    
    var backgroundEmojiId: Int64? {
        return self._asPeer().backgroundEmojiId
    }
    
    var profileBackgroundEmojiId: Int64? {
        return self._asPeer().profileBackgroundEmojiId
    }
}

public extension EnginePeer {
    init(_ peer: Peer) {
        switch peer {
        case let user as TelegramUser:
            self = .user(user)
        case let group as TelegramGroup:
            self = .legacyGroup(group)
        case let channel as TelegramChannel:
            self = .channel(channel)
        case let secretChat as TelegramSecretChat:
            self = .secretChat(secretChat)
        default:
            preconditionFailure("Unknown peer type")
        }
    }

    func _asPeer() -> Peer {
        switch self {
        case let .user(user):
            return user
        case let .legacyGroup(legacyGroup):
            return legacyGroup
        case let .channel(channel):
            return channel
        case let .secretChat(secretChat):
            return secretChat
        }
    }
}

public final class EngineRenderedPeer: Equatable {
    public let peerId: EnginePeer.Id
    public let peers: [EnginePeer.Id: EnginePeer]
    public let associatedMedia: [EngineMedia.Id: Media]

    public init(peerId: EnginePeer.Id, peers: [EnginePeer.Id: EnginePeer], associatedMedia: [EngineMedia.Id: Media]) {
        self.peerId = peerId
        self.peers = peers
        self.associatedMedia = associatedMedia
    }

    public init(peer: EnginePeer) {
        self.peerId = peer.id
        self.peers = [peer.id: peer]
        self.associatedMedia = [:]
    }

    public static func ==(lhs: EngineRenderedPeer, rhs: EngineRenderedPeer) -> Bool {
        if lhs.peerId != rhs.peerId {
            return false
        }
        if lhs.peers != rhs.peers {
            return false
        }
        if !areMediaDictionariesEqual(lhs.associatedMedia, rhs.associatedMedia) {
            return false
        }
        return true
    }

    public var peer: EnginePeer? {
        return self.peers[self.peerId]
    }

    public var chatMainPeer: EnginePeer? {
        if let peer = self.peers[self.peerId] {
            if case let .secretChat(secretChat) = peer {
                return self.peers[secretChat.regularPeerId]
            } else {
                return peer
            }
        } else {
            return nil
        }
    }
    
    public var chatOrMonoforumMainPeer: EnginePeer? {
        if case let .channel(channel) = self.peer, channel.flags.contains(.isMonoforum), let linkedMonoforumId = channel.linkedMonoforumId {
            return self.peers[linkedMonoforumId]
        } else {
            return self.chatMainPeer
        }
    }
}

public extension EngineRenderedPeer {
    convenience init(_ renderedPeer: RenderedPeer) {
        var mappedPeers: [EnginePeer.Id: EnginePeer] = [:]
        for (id, peer) in renderedPeer.peers {
            mappedPeers[id] = EnginePeer(peer)
        }
        self.init(peerId: renderedPeer.peerId, peers: mappedPeers, associatedMedia: renderedPeer.associatedMedia)
    }

    convenience init(message: EngineMessage) {
        self.init(RenderedPeer(message: message._asMessage()))
    }
}

public extension EngineGlobalNotificationSettings.CategorySettings {
    init(_ categorySettings: MessageNotificationSettings) {
        self.init(
            enabled: categorySettings.enabled,
            displayPreviews: categorySettings.displayPreviews,
            sound: EnginePeer.NotificationSettings.MessageSound(categorySettings.sound),
            storySettings: categorySettings.storySettings
        )
    }
    
    func _asMessageNotificationSettings() -> MessageNotificationSettings {
        return MessageNotificationSettings(
            enabled: self.enabled,
            displayPreviews: self.displayPreviews,
            sound: self.sound._asMessageSound(),
            storySettings: self.storySettings
        )
    }
}

public extension EngineGlobalNotificationSettings.ReactionSettings {
    init(_ reactionSettings: PeerReactionNotificationSettings) {
        self.init(
            messages: reactionSettings.messages,
            stories: reactionSettings.stories,
            hideSender: reactionSettings.hideSender,
            sound: EnginePeer.NotificationSettings.MessageSound(reactionSettings.sound)
        )
    }
    
    func _asReactionSettings() -> PeerReactionNotificationSettings {
        return PeerReactionNotificationSettings(
            messages: self.messages,
            stories: self.stories,
            hideSender: self.hideSender,
            sound: self.sound._asMessageSound()
        )
    }
}

public extension EngineGlobalNotificationSettings {
    init(_ globalNotificationSettings: GlobalNotificationSettingsSet) {
        self.init(
            privateChats: CategorySettings(globalNotificationSettings.privateChats),
            groupChats: CategorySettings(globalNotificationSettings.groupChats),
            channels: CategorySettings(globalNotificationSettings.channels),
            reactionSettings: ReactionSettings(globalNotificationSettings.reactionSettings),
            contactsJoined: globalNotificationSettings.contactsJoined
        )
    }
    
    func _asGlobalNotificationSettings() -> GlobalNotificationSettingsSet {
        return GlobalNotificationSettingsSet(
            privateChats: self.privateChats._asMessageNotificationSettings(),
            groupChats: self.groupChats._asMessageNotificationSettings(),
            channels: self.channels._asMessageNotificationSettings(),
            reactionSettings: self.reactionSettings._asReactionSettings(),
            contactsJoined: self.contactsJoined
        )
    }
}
