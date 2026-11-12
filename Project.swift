import ProjectDescription

let organizationName = "2025C6.OffStage"

/// Same minimum as the released 1.0.3; without it Tuist uses the SDK version.
let deploymentTargets: DeploymentTargets = .iOS("18.5")

let baseInfoPlist: [String: Plist.Value] = [
    "CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
    "UILaunchScreen": [
        "UIColorName": "",
        "UIImageName": "",
    ],
    "CFBundleShortVersionString": "1.0.4",
    "CFBundleVersion": "4",
    "NSLocationWhenInUseUsageDescription": "현재 위치를 기반으로 주변 정류장 정보를 제공하기 위해 위치 정보가 필요합니다.",
    "NSLocationAlwaysAndWhenInUseUsageDescription": "백그라운드에서도 위치를 수집하여 앱을 열었을 때 빠르게 근처 정류장 정보를 제공합니다.",
    "NSLocationAlwaysUsageDescription": "백그라운드에서도 위치를 수집하여 앱을 열었을 때 빠르게 근처 정류장 정보를 제공합니다.",
    "UIBackgroundModes": .array([.string("location")]),
    "NSCameraUsageDescription": "버스 인식을 위해 카메라 접근이 필요합니다.",
    "NSMicrophoneUsageDescription": "음성 검색 기능을 위해 마이크 접근 권한이 필요합니다.",
    "NSSpeechRecognitionUsageDescription": "음성으로 버스 번호나 정류장을 검색하기 위해 음성 인식 권한이 필요합니다.",
    "ITSAppUsesNonExemptEncryption": .boolean(false),
    "UIDesignRequiresCompatibility": .boolean(true),
    "UIUserInterfaceStyle": "Dark",
    "UISupportedInterfaceOrientations": [
        "UIInterfaceOrientationPortrait",
    ],
]

let formatScript: TargetScript = .pre(
    path: .relativeToRoot("Scripts/swiftformat.sh"),
    name: "SwiftFormat (mise, --lint)",
    basedOnDependencyAnalysis: false
)
let lintScript: TargetScript = .pre(
    path: .relativeToRoot("Scripts/swiftlint.sh"),
    name: "SwiftLint (mise)",
    basedOnDependencyAnalysis: false
)

let busAPI = Target.target(
    name: "BusAPI",
    destinations: [.iPhone],
    product: .framework,
    bundleId: "\(organizationName).BusAPI",
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(with: baseInfoPlist),
    sources: ["Modules/BusAPI/Sources/**"],
    dependencies: [
        .external(name: "Moya"),
        .external(name: "Logging"),
    ]
)

let busAPITests = Target.target(
    name: "BusAPITests",
    destinations: [.iPhone],
    product: .unitTests,
    bundleId: "\(organizationName).BusAPITests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/BusAPI/Tests/**"],
    dependencies: [
        .target(name: "BusAPI"),
    ]
)

let configurations: [Configuration] = [
    .debug(name: "Debug-Dev", xcconfig: .relativeToRoot("Config/Dev.xcconfig")),
    .release(name: "Release-Dev", xcconfig: .relativeToRoot("Config/Dev.xcconfig")),
    .debug(name: "Debug-Prod", xcconfig: .relativeToRoot("Config/Prod.xcconfig")),
    .release(name: "Release-Prod", xcconfig: .relativeToRoot("Config/Prod.xcconfig")),
]

let app = Target.target(
    name: "버스온다",
    destinations: [.iPhone],
    product: .app,
    bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER)",
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(with: baseInfoPlist),
    sources: ["OffStageApp/Sources/**"],
    resources: ["OffStageApp/Resources/**", "OffStageApp/Resources/*.mlmodel"],
    scripts: [formatScript, lintScript],
    dependencies: [
        .target(name: "BusAPI"),
        .external(name: "GRDB"),
    ],
    settings: .settings(configurations: configurations)
)

let settings = Settings.settings(configurations: configurations)

let project = Project(
    name: "버스온다",
    settings: settings,
    targets: [busAPI, busAPITests, app],
    schemes: [
        .scheme(
            name: "버스온다 (Dev)",
            buildAction: .buildAction(targets: ["버스온다"]),
            runAction: .runAction(configuration: .configuration("Debug-Dev")),
            archiveAction: .archiveAction(configuration: .configuration("Release-Dev"))
        ),
        .scheme(
            name: "버스온다",
            buildAction: .buildAction(targets: ["버스온다"]),
            testAction: .targets(["BusAPITests"], configuration: .configuration("Debug-Prod")),
            runAction: .runAction(configuration: .configuration("Debug-Prod")),
            archiveAction: .archiveAction(configuration: .configuration("Release-Prod"))
        ),
    ]
)
