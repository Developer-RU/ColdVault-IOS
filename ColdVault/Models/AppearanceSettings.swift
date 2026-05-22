import Foundation
import SwiftUI

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .system:
            return "settings.theme.system"
        case .light:
            return "settings.theme.light"
        case .dark:
            return "settings.theme.dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case russian
    case english

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .system:
            return "settings.language.system"
        case .russian:
            return "settings.language.ru"
        case .english:
            return "settings.language.en"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .russian:
            return "ru"
        case .english:
            return "en"
        }
    }

    var locale: Locale {
        if let localeIdentifier {
            return Locale(identifier: localeIdentifier)
        }
        return Locale(identifier: "")
    }
}
