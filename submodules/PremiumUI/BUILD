load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_resource_bundle",
    "apple_resource_group",
)
load("//build-system/bazel-utils:plist_fragment.bzl",
    "plist_fragment",
)

filegroup(
    name = "PremiumUIMetalResources",
    srcs = glob([
        "MetalResources/**/*.*",
    ]),
    visibility = ["//visibility:public"],
)

plist_fragment(
    name = "PremiumUIBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>org.telegram.PremiumUI</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>PremiumUI</string>
    """
)

apple_resource_bundle(
    name = "PremiumUIBundle",
    infoplists = [
        ":PremiumUIBundleInfoPlist",
    ],
    resources = [
        ":PremiumUIMetalResources",
    ],
)

filegroup(
    name = "PremiumUIResources",
    srcs = glob([
        "Resources/**/*",
    ], exclude = ["Resources/**/.*"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "PremiumUI",
    module_name = "PremiumUI",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    data = [
        ":PremiumUIBundle",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramStringFormatting:TelegramStringFormatting",
        "//submodules/AppBundle:AppBundle",
        "//submodules/AnimatedStickerNode:AnimatedStickerNode",
        "//submodules/TelegramAnimatedStickerNode:TelegramAnimatedStickerNode",
        "//submodules/SolidRoundedButtonNode:SolidRoundedButtonNode",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/ReactionSelectionNode:ReactionSelectionNode",
        "//submodules/InAppPurchaseManager:InAppPurchaseManager",
        "//submodules/ConfettiEffect:ConfettiEffect",
        "//submodules/TextFormat:TextFormat",
        "//submodules/GZip:GZip",
        "//submodules/InstantPageCache:InstantPageCache",
        "//submodules/MediaPlayer:UniversalMediaPlayer",
        "//submodules/TelegramUniversalVideoContent:TelegramUniversalVideoContent",
        "//submodules/RadialStatusNode:RadialStatusNode",
        "//submodules/ShimmerEffect:ShimmerEffect",
        "//submodules/LegacyComponents:LegacyComponents",
        "//submodules/CheckNode:CheckNode",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/Components/ViewControllerComponent:ViewControllerComponent",
        "//submodules/Components/MultilineTextComponent:MultilineTextComponent",
        "//submodules/Components/MultilineTextWithEntitiesComponent:MultilineTextWithEntitiesComponent",
        "//submodules/Components/SheetComponent:SheetComponent",
        "//submodules/Components/BundleIconComponent:BundleIconComponent",
        "//submodules/Components/SolidRoundedButtonComponent:SolidRoundedButtonComponent",
        "//submodules/Components/BlurredBackgroundComponent:BlurredBackgroundComponent",
        "//submodules/TelegramUI/Components/EmojiStatusComponent",
        "//submodules/TelegramUI/Components/AnimationCache:AnimationCache",
        "//submodules/TelegramUI/Components/MultiAnimationRenderer:MultiAnimationRenderer",
        "//submodules/TelegramUI/Components/Stories/AvatarStoryIndicatorComponent",
        "//submodules/Components/BalancedTextComponent",
        "//submodules/ItemListPeerItem:ItemListPeerItem",
        "//submodules/ItemListPeerActionItem:ItemListPeerActionItem",
        "//submodules/TelegramUI/Components/ItemListDatePickerItem:ItemListDatePickerItem",
        "//submodules/TelegramUI/Components/ShareWithPeersScreen",
        "//submodules/TelegramUI/Components/ButtonComponent",
        "//submodules/TelegramUI/Components/Utils/RoundedRectWithTailPath",
        "//submodules/CountrySelectionUI",
        "//submodules/TelegramUI/Components/Stories/PeerListItemComponent",
        "//submodules/InvisibleInkDustNode",
        "//submodules/AlertUI",
        "//submodules/TelegramUI/Components/Chat/MergedAvatarsNode",
        "//submodules/TelegramUI/Components/LottieComponent",
        "//submodules/TelegramUI/Components/ListSectionComponent",
        "//submodules/TelegramUI/Components/ListActionItemComponent",
        "//submodules/TelegramUI/Components/EmojiStatusSelectionComponent",
        "//submodules/TelegramUI/Components/EntityKeyboard",
        "//submodules/TelegramUI/Components/PremiumPeerShortcutComponent",
        "//submodules/TelegramUI/Components/EmojiActionIconComponent",
        "//submodules/TelegramUI/Components/ScrollComponent",
        "//submodules/TelegramUI/Components/Premium/PremiumStarComponent",
        "//submodules/TelegramUI/Components/Premium/PremiumCoinComponent",
    ],
    visibility = [
        "//visibility:public",
    ],
)
