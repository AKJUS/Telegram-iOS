import Foundation
import Postbox
import SwiftSignalKit
import TelegramApi
import MtProtoKit


public func updateGlobalNotificationSettingsInteractively(postbox: Postbox, _ f: @escaping (GlobalNotificationSettingsSet) -> GlobalNotificationSettingsSet) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> Void in
        transaction.updatePreferencesEntry(key: PreferencesKeys.globalNotifications, { current in
            if let current = current?.get(GlobalNotificationSettings.self) {
                return PreferencesEntry(GlobalNotificationSettings(toBeSynchronized: f(current.effective), remote: current.remote))
            } else {
                let settings = f(GlobalNotificationSettingsSet.defaultSettings)
                return PreferencesEntry(GlobalNotificationSettings(toBeSynchronized: settings, remote: settings))
            }
        })
        transaction.globalNotificationSettingsUpdated()
    }
}

public func resetPeerNotificationSettings(network: Network) -> Signal<Void, NoError> {
    return network.request(Api.functions.account.resetNotifySettings())
        |> retryRequestIfNotFrozen
        |> mapToSignal { _ in return Signal<Void, NoError>.complete() }
}

private enum SynchronizeGlobalSettingsData: Equatable {
    case none
    case fetch
    case push(GlobalNotificationSettingsSet)
    
    static func ==(lhs: SynchronizeGlobalSettingsData, rhs: SynchronizeGlobalSettingsData) -> Bool {
        switch lhs {
            case .none:
                if case .none = rhs {
                    return true
                } else {
                    return false
                }
            case .fetch:
                if case .fetch = rhs {
                    return true
                } else {
                    return false
                }
            case let .push(settings):
                if case .push(settings) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

func managedGlobalNotificationSettings(postbox: Postbox, network: Network) -> Signal<Void, NoError> {
    let data = postbox.preferencesView(keys: [PreferencesKeys.globalNotifications])
    |> map { view -> SynchronizeGlobalSettingsData in
        if let preferences = view.values[PreferencesKeys.globalNotifications]?.get(GlobalNotificationSettings.self) {
            if let settings = preferences.toBeSynchronized {
                return .push(settings)
            } else {
                return .none
            }
        } else {
            return .fetch
        }
    }
    let action = data
    |> distinctUntilChanged
    |> mapToSignal { data -> Signal<Void, NoError> in
        switch data {
            case .none:
                return .complete()
            case .fetch:
                return fetchedNotificationSettings(network: network)
                |> mapToSignal { settings -> Signal<Void, NoError> in
                    return postbox.transaction { transaction -> Void in
                        transaction.updatePreferencesEntry(key: PreferencesKeys.globalNotifications, { current in
                            if let current = current?.get(GlobalNotificationSettings.self) {
                                return PreferencesEntry(GlobalNotificationSettings(toBeSynchronized: current.toBeSynchronized, remote: settings))
                            } else {
                                return PreferencesEntry(GlobalNotificationSettings(toBeSynchronized: nil, remote: settings))
                            }
                        })
                        transaction.globalNotificationSettingsUpdated()
                    }
                }
            case let .push(settings):
                return pushedNotificationSettings(network: network, settings: settings)
                    |> then(postbox.transaction { transaction -> Void in
                        transaction.updatePreferencesEntry(key: PreferencesKeys.globalNotifications, { current in
                            if let current = current?.get(GlobalNotificationSettings.self), current.toBeSynchronized == settings {
                                return PreferencesEntry(GlobalNotificationSettings(toBeSynchronized: nil, remote: settings))
                            } else {
                                return current
                            }
                        })
                        transaction.globalNotificationSettingsUpdated()
                    })
        }
    }
    
    return action
}

private func fetchedNotificationSettings(network: Network) -> Signal<GlobalNotificationSettingsSet, NoError> {
    let chats = network.request(Api.functions.account.getNotifySettings(peer: Api.InputNotifyPeer.inputNotifyChats))
    let users = network.request(Api.functions.account.getNotifySettings(peer: Api.InputNotifyPeer.inputNotifyUsers))
    let channels = network.request(Api.functions.account.getNotifySettings(peer: Api.InputNotifyPeer.inputNotifyBroadcasts))
    let contactsJoinedMuted = network.request(Api.functions.account.getContactSignUpNotification())
    let reactions = network.request(Api.functions.account.getReactionsNotifySettings())
    
    return combineLatest(chats, users, channels, contactsJoinedMuted, reactions)
    |> retryRequestIfNotFrozen
    |> mapToSignal { data in
        guard let (chats, users, channels, contactsJoinedMuted, reactions) = data else {
            return .complete()
        }
        let chatsSettings: MessageNotificationSettings
        switch chats {
        case let .peerNotifySettings(_, showPreviews, _, muteUntil, iosSound, _, desktopSound, storiesMuted, storiesHideSender, storiesIosSound, _, storiesDesktopSound):
            let sound: Api.NotificationSound?
            let storiesSound: Api.NotificationSound?
            #if os(iOS)
            sound = iosSound
            storiesSound = storiesIosSound
            #elseif os(macOS)
            sound = desktopSound
            storiesSound = storiesDesktopSound
            #endif
            
            let enabled: Bool
            if muteUntil != nil && muteUntil != 0 {
                enabled = false
            } else {
                enabled = true
            }
            let displayPreviews: Bool
            if let showPreviews = showPreviews, case .boolFalse = showPreviews {
                displayPreviews = false
            } else {
                displayPreviews = true
            }
            
            let storiesMutedValue: PeerStoryNotificationSettings.Mute
            if let storiesMuted = storiesMuted {
                storiesMutedValue = storiesMuted == .boolTrue ? .muted : .unmuted
            } else {
                storiesMutedValue = .default
            }
            
            var storiesHideSenderValue: PeerStoryNotificationSettings.HideSender
            if let storiesHideSender = storiesHideSender {
                storiesHideSenderValue = storiesHideSender == .boolTrue ? .hide : .show
            } else {
                storiesHideSenderValue = .default
            }
            
            chatsSettings = MessageNotificationSettings(
                enabled: enabled,
                displayPreviews: displayPreviews,
                sound: PeerMessageSound(apiSound: sound ?? .notificationSoundDefault),
                storySettings: PeerStoryNotificationSettings(
                    mute: storiesMutedValue,
                    hideSender: storiesHideSenderValue,
                    sound: PeerMessageSound(apiSound: sound ?? .notificationSoundDefault)
                )
            )
        }
        
        let userSettings: MessageNotificationSettings
        switch users {
        case let .peerNotifySettings(_, showPreviews, _, muteUntil, iosSound, _, desktopSound, storiesMuted, storiesHideSender, storiesIosSound, _, storiesDesktopSound):
            let sound: Api.NotificationSound?
            let storiesSound: Api.NotificationSound?
            #if os(iOS)
            sound = iosSound
            storiesSound = storiesIosSound
            #elseif os(macOS)
            sound = desktopSound
            storiesSound = storiesDesktopSound
            #endif
            
            let enabled: Bool
            if muteUntil != nil && muteUntil != 0 {
                enabled = false
            } else {
                enabled = true
            }
            let displayPreviews: Bool
            if let showPreviews = showPreviews, case .boolFalse = showPreviews {
                displayPreviews = false
            } else {
                displayPreviews = true
            }
            
            let storiesMutedValue: PeerStoryNotificationSettings.Mute
            if let storiesMuted = storiesMuted {
                storiesMutedValue = storiesMuted == .boolTrue ? .muted : .unmuted
            } else {
                storiesMutedValue = .default
            }
            
            var storiesHideSenderValue: PeerStoryNotificationSettings.HideSender
            if let storiesHideSender = storiesHideSender {
                storiesHideSenderValue = storiesHideSender == .boolTrue ? .hide : .show
            } else {
                storiesHideSenderValue = .default
            }
            
            userSettings = MessageNotificationSettings(
                enabled: enabled,
                displayPreviews: displayPreviews,
                sound: PeerMessageSound(apiSound: sound ?? .notificationSoundDefault),
                storySettings: PeerStoryNotificationSettings(
                    mute: storiesMutedValue,
                    hideSender: storiesHideSenderValue,
                    sound: PeerMessageSound(apiSound: sound ?? .notificationSoundDefault)
                )
            )
        }
        
        let channelSettings: MessageNotificationSettings
        switch channels {
        case let .peerNotifySettings(_, showPreviews, _, muteUntil, iosSound, _, desktopSound, storiesMuted, storiesHideSender, storiesIosSound, _, storiesDesktopSound):
            let sound: Api.NotificationSound?
            let storiesSound: Api.NotificationSound?
            #if os(iOS)
            sound = iosSound
            storiesSound = storiesIosSound
            #elseif os(macOS)
            sound = desktopSound
            storiesSound = storiesDesktopSound
            #endif
            
            let enabled: Bool
            if muteUntil != nil && muteUntil != 0 {
                enabled = false
            } else {
                enabled = true
            }
            let displayPreviews: Bool
            if let showPreviews = showPreviews, case .boolFalse = showPreviews {
                displayPreviews = false
            } else {
                displayPreviews = true
            }
            
            let storiesMutedValue: PeerStoryNotificationSettings.Mute
            if let storiesMuted = storiesMuted {
                storiesMutedValue = storiesMuted == .boolTrue ? .muted : .unmuted
            } else {
                storiesMutedValue = .default
            }
            
            var storiesHideSenderValue: PeerStoryNotificationSettings.HideSender
            if let storiesHideSender = storiesHideSender {
                storiesHideSenderValue = storiesHideSender == .boolTrue ? .hide : .show
            } else {
                storiesHideSenderValue = .default
            }
            
            channelSettings = MessageNotificationSettings(
                enabled: enabled,
                displayPreviews: displayPreviews,
                sound: PeerMessageSound(apiSound: sound ?? .notificationSoundDefault),
                storySettings: PeerStoryNotificationSettings(
                    mute: storiesMutedValue,
                    hideSender: storiesHideSenderValue,
                    sound: PeerMessageSound(apiSound: sound ?? .notificationSoundDefault)
                )
            )
        }
        
        let reactionSettings: PeerReactionNotificationSettings
        switch reactions {
        case let .reactionsNotifySettings(_, messagesNotifyFrom, storiesNotifyFrom, sound, showPreviews):
            let mappedMessages: PeerReactionNotificationSettings.Sources
            if let messagesNotifyFrom {
                switch messagesNotifyFrom {
                case .reactionNotificationsFromAll:
                    mappedMessages = .everyone
                case .reactionNotificationsFromContacts:
                    mappedMessages = .contacts
                }
            } else {
                mappedMessages = .nobody
            }
            
            let mappedStories: PeerReactionNotificationSettings.Sources
            if let storiesNotifyFrom {
                switch storiesNotifyFrom {
                case .reactionNotificationsFromAll:
                    mappedStories = .everyone
                case .reactionNotificationsFromContacts:
                    mappedStories = .contacts
                }
            } else {
                mappedStories = .nobody
            }
            
            reactionSettings = PeerReactionNotificationSettings(
                messages: mappedMessages,
                stories: mappedStories,
                hideSender: showPreviews == .boolFalse ? .hide : .show,
                sound: PeerMessageSound(apiSound: sound)
            )
        }
        
        return .single(GlobalNotificationSettingsSet(privateChats: userSettings, groupChats: chatsSettings, channels: channelSettings, reactionSettings: reactionSettings, contactsJoined: contactsJoinedMuted == .boolFalse))
    }
}

private func apiInputPeerNotifySettings(_ settings: MessageNotificationSettings) -> Api.InputPeerNotifySettings {
    let muteUntil: Int32?
    if settings.enabled {
        muteUntil = 0
    } else {
        muteUntil = Int32.max
    }
    let sound: Api.NotificationSound? = settings.sound.apiSound
    var flags: Int32 = 0
    flags |= (1 << 0)
    if muteUntil != nil {
        flags |= (1 << 2)
    }
    if sound != nil {
        flags |= (1 << 3)
    }
    
    let storiesMuted: Api.Bool?
    switch settings.storySettings.mute {
    case .default:
        storiesMuted = nil
    case .muted:
        storiesMuted = .boolTrue
    case .unmuted:
        storiesMuted = .boolFalse
    }
    if storiesMuted != nil {
        flags |= (1 << 6)
    }
    
    let storiesHideSender: Api.Bool?
    switch settings.storySettings.hideSender {
    case .default:
        storiesHideSender = nil
    case .hide:
        storiesHideSender = .boolTrue
    case .show:
        storiesHideSender = .boolFalse
    }
    if storiesHideSender != nil {
        flags |= (1 << 7)
    }
    
    let storiesSound: Api.NotificationSound? = settings.storySettings.sound.apiSound
    if storiesSound != nil {
        flags |= (1 << 8)
    }
    
    return .inputPeerNotifySettings(flags: flags, showPreviews: settings.displayPreviews ? .boolTrue : .boolFalse, silent: nil, muteUntil: muteUntil, sound: sound, storiesMuted: storiesMuted, storiesHideSender: storiesHideSender, storiesSound: storiesSound)
}

private func pushedNotificationSettings(network: Network, settings: GlobalNotificationSettingsSet) -> Signal<Void, NoError> {
    let pushedChats = network.request(Api.functions.account.updateNotifySettings(peer: Api.InputNotifyPeer.inputNotifyChats, settings: apiInputPeerNotifySettings(settings.groupChats)))
    |> `catch` { _ -> Signal<Api.Bool, NoError> in
        return .single(.boolFalse)
    }
    
    let pushedUsers = network.request(Api.functions.account.updateNotifySettings(peer: Api.InputNotifyPeer.inputNotifyUsers, settings: apiInputPeerNotifySettings(settings.privateChats)))
    |> `catch` { _ -> Signal<Api.Bool, NoError> in
        return .single(.boolFalse)
    }
    
    let pushedChannels = network.request(Api.functions.account.updateNotifySettings(peer: Api.InputNotifyPeer.inputNotifyBroadcasts, settings: apiInputPeerNotifySettings(settings.channels)))
    |> `catch` { _ -> Signal<Api.Bool, NoError> in
        return .single(.boolFalse)
    }
    
    let pushedContactsJoined = network.request(Api.functions.account.setContactSignUpNotification(silent: settings.contactsJoined ? .boolFalse : .boolTrue))
    |> `catch` { _ -> Signal<Api.Bool, NoError> in
        return .single(.boolFalse)
    }
    
    var reactionFlags: Int32 = 0
    
    var reactionsMessages: Api.ReactionNotificationsFrom?
    switch settings.reactionSettings.messages {
    case .nobody:
        break
    case .everyone:
        reactionsMessages = .reactionNotificationsFromAll
    case .contacts:
        reactionsMessages = .reactionNotificationsFromContacts
    }
    if reactionsMessages != nil {
        reactionFlags |= 1 << 0
    }
    
    var reactionsStories: Api.ReactionNotificationsFrom?
    switch settings.reactionSettings.stories {
    case .nobody:
        break
    case .everyone:
        reactionsStories = .reactionNotificationsFromAll
    case .contacts:
        reactionsStories = .reactionNotificationsFromContacts
    }
    if reactionsStories != nil {
        reactionFlags |= 1 << 1
    }
    
    let inputReactionSettings: Api.ReactionsNotifySettings = .reactionsNotifySettings(
        flags: reactionFlags,
        messagesNotifyFrom: reactionsMessages,
        storiesNotifyFrom: reactionsStories,
        sound: settings.reactionSettings.sound.apiSound,
        showPreviews: settings.reactionSettings.hideSender == .hide ? .boolFalse : .boolTrue
    )
    let pushedReactions = network.request(Api.functions.account.setReactionsNotifySettings(settings: inputReactionSettings))
    |> map(Optional.init)
    |> `catch` { _ -> Signal<Api.ReactionsNotifySettings?, NoError> in
        return .single(nil)
    }
    
    return combineLatest(pushedChats, pushedUsers, pushedChannels, pushedContactsJoined, pushedReactions)
    |> mapToSignal { _ -> Signal<Void, NoError> in return .complete() }
}
