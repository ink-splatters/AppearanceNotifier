//
//  Inspired by:
////  UserConfiguration.swift
////  Amethyst
////
////  Created by Ian Ynda-Hummel on 5/8/16.
////  Copyright © 2016 Ian Ynda-Hummel. All rights reserved.

import Cocoa
import Foundation
import Yams

enum DefaultFloat: Equatable {
    case floating
    case notFloating

    fileprivate static func from(_ bool: Bool) -> DefaultFloat {
        return bool ? .floating : .notFloating
    }
}

protocol ConfigurationStorage {
    func object(forKey key: ConfigurationKey) -> Any?
    func array(forKey key: ConfigurationKey) -> [Any]?
    func bool(forKey key: ConfigurationKey) -> Bool
    func float(forKey key: ConfigurationKey) -> Float
    func stringArray(forKey key: ConfigurationKey) -> [String]?

    func set(_ value: Any?, forKey key: ConfigurationKey)
    func set(_ value: Bool, forKey key: ConfigurationKey)
}

extension UserDefaults: ConfigurationStorage {
    func object(forKey key: ConfigurationKey) -> Any? {
        return object(forKey: key.rawValue)
    }

    func array(forKey key: ConfigurationKey) -> [Any]? {
        return array(forKey: key.rawValue)
    }

    func bool(forKey key: ConfigurationKey) -> Bool {
        return bool(forKey: key.rawValue)
    }

    func float(forKey key: ConfigurationKey) -> Float {
        return float(forKey: key.rawValue)
    }

    func stringArray(forKey key: ConfigurationKey) -> [String]? {
        return stringArray(forKey: key.rawValue)
    }

    func set(_ value: Any?, forKey key: ConfigurationKey) {
        set(value, forKey: key.rawValue)
    }

    func set(_ value: Bool, forKey key: ConfigurationKey) {
        set(value, forKey: key.rawValue)
    }
}

enum ConfigurationKey: String {
    // TODO:
//     case layouts = "layouts"
//     case commandMod = "mod"
//     case commandKey = "key"
//     case mod1 = "mod1"
//     case mod2 = "mod2"
//     case mod3 = "mod3"
//     case mod4 = "mod4"
//     case windowMargins = "window-margins"
//     case smartWindowMargins = "smart-window-margins"
//     case windowMarginSize = "window-margin-size"
//     case windowMinimumHeight = "window-minimum-height"
//     case windowMinimumWidth = "window-minimum-width"
//     case windowMaxCount = "window-max-count"
//     case floatingBundleIdentifiers = "floating"
//     case floatingBundleIdentifiersIsBlacklist = "floating-is-blacklist"
//     case ignoreMenuBar = "ignore-menu-bar"
//     case floatSmallWindows = "float-small-windows"
//     case mouseFollowsFocus = "mouse-follows-focus"
//     case focusFollowsMouse = "focus-follows-mouse"
//     case mouseSwapsWindows = "mouse-swaps-windows"
//     case mouseResizesWindows = "mouse-resizes-windows"
//     case layoutHUD = "enables-layout-hud"
//     case layoutHUDOnSpaceChange = "enables-layout-hud-on-space-change"
//     case useCanaryBuild = "use-canary-build"
//     case newWindowsToMain = "new-windows-to-main"
//     case followSpaceThrownWindows = "follow-space-thrown-windows"
//     case windowResizeStep = "window-resize-step"
//     case screenPaddingLeft = "screen-padding-left"
//     case screenPaddingRight = "screen-padding-right"
//     case screenPaddingTop = "screen-padding-top"
//     case screenPaddingBottom = "screen-padding-bottom"
//     case debugLayoutInfo = "debug-layout-info"
//     case restoreLayoutsOnLaunch = "restore-layouts-on-launch"
//     case disablePaddingOnBuiltinDisplay = "disable-padding-on-builtin-display"
}

extension ConfigurationKey: CaseIterable {}

class UserConfiguration: NSObject {
    static let shared = UserConfiguration()
    private let storage: ConfigurationStorage

    var configurationYAML: [String: Any]?

    init(storage: ConfigurationStorage) {
        self.storage = storage
    }

    override convenience init() {
        self.init(storage: UserDefaults.standard)
    }

    private func configurationValueForKey<T>(_ key: ConfigurationKey) -> T? {
        return configurationValue(forKeyValue: key.rawValue)
    }

    private func configurationValue<T>(forKeyValue keyValue: String) -> T? {
        if let yamlValue = configurationYAML?[keyValue] {
            if yamlValue is NSNull {
                return nil
            } else {
                return yamlValue as? T
            }
        }

        return nil
    }

    func load() {
        loadConfigurationFile()
        loadConfiguration()
    }

    func loadConfiguration() {
        for key in ConfigurationKey.allCases {
            let value: Any? = configurationValueForKey(key)
            let existingValue = storage.object(forKey: key)

            let hasLocalConfigurationValue = value != nil
            let hasExistingValue = (existingValue != nil)

            guard hasLocalConfigurationValue || !hasExistingValue else {
                continue
            }

            if hasLocalConfigurationValue {
                storage.set(value, forKey: key)
            }
        }
    }

    private func yamlForConfig(at path: String) -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: path, isDirectory: nil) else {
            return nil
        }

        let configPath = URL(fileURLWithPath: path)

        guard let string = try? String(contentsOf: configPath) else {
            return nil
        }

        do {
            let yaml = try Yams.load(yaml: string)
            return yaml as? [String: Any]
        } catch {
            log.debug(error)
            return nil
        }
    }

    private func loadConfigurationFile() {
        let xdgConfigPath = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? NSHomeDirectory().appending("/.config")
        let appearanceNotifierXDGConfigPath = xdgConfigPath.appending("/appearance-notifier")
        let appearanceNotifierYAMLConfigPath = NSHomeDirectory().appending("/.appearance-notifier.yml")
        let appearanceNotifierJSONConfigPath = NSHomeDirectory().appending("/.appearance-notifier")
        let defaultAmethystConfigPath = Bundle.main.path(forResource: "default", ofType: "appearance-notifier")

        var isDirectory: ObjCBool = false
        /**
         Prioritiy order for config files:
         1. yml in home dir
         2. yml in xdg path
         3. json in home dir
         4. default json
         */
        if FileManager.default.fileExists(atPath: appearanceNotifierYAMLConfigPath, isDirectory: &isDirectory) {
            configurationYAML = yamlForConfig(at: appearanceNotifierYAMLConfigPath)

            if configurationYAML == nil {
                log.error("error loading configuration as yaml")

                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Error loading configuration"
                alert.runModal()
            }
        } else if FileManager.default.fileExists(atPath: appearanceNotifierXDGConfigPath, isDirectory: &isDirectory) {
            configurationYAML = yamlForConfig(at: isDirectory.boolValue ? appearanceNotifierXDGConfigPath.appending("/appearance-notifier.yml") : appearanceNotifierXDGConfigPath)

            if configurationYAML == nil {
                log.error("error loading configuration as yaml")

                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Error loading configuration"
                alert.runModal()
            }
        }
    }
}
